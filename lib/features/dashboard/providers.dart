import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/standby_medics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardDatabaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

String todayScheduleDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String encodeScheduleIconForToday(String baseIcon, {required bool isDone}) {
  final clean = (baseIcon.isEmpty ? 'clock' : baseIcon).split('@').first;
  return isDone ? '$clean@${todayScheduleDateKey()}' : clean;
}

class DashboardMetrics {
  final int activeMedicalCases;
  final int requiresAttentionCases;
  final int missingEquipment;
  final int totalEquipment;
  final int expiringEquipment;
  final int unverifiedMedics;
  final List<Map<String, dynamic>> timelineEvents;
  final List<Map<String, dynamic>> activeMedics;

  DashboardMetrics({
    required this.activeMedicalCases,
    required this.requiresAttentionCases,
    required this.missingEquipment,
    required this.totalEquipment,
    required this.expiringEquipment,
    required this.unverifiedMedics,
    required this.timelineEvents,
    required this.activeMedics,
  });

  int get equipmentReadinessPercent {
    if (totalEquipment == 0) return 100;
    return (((totalEquipment - missingEquipment) / totalEquipment) * 100).round().clamp(0, 100);
  }
}

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final user = AuthService().currentUser;
  final sb = Supabase.instance.client;

  if (user == null || user.unitId == null) {
    return DashboardMetrics(
      activeMedicalCases: 0,
      requiresAttentionCases: 0,
      missingEquipment: 0,
      totalEquipment: 0,
      expiringEquipment: 0,
      unverifiedMedics: 0,
      timelineEvents: [],
      activeMedics: [],
    );
  }

  // Each section is isolated: one failing table must not blank the whole home screen.
  Future<T> safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('dashboard section failed: $e');
      return fallback;
    }
  }

  // Medical Metrics (filtered by active deployment if available)
  int activeCases = 0;
  int attentionCases = 0;

  if (user.activeDeploymentId != null) {
    activeCases = await safe(() async => (await sb
        .from('medical_cases')
        .select('id')
        .eq('deployment_id', user.activeDeploymentId!)
        .not('status', 'in', ['CLOSED', 'COMPLETED'])).length, 0);

    attentionCases = await safe(() async => (await sb
        .from('medical_cases')
        .select('id')
        .eq('deployment_id', user.activeDeploymentId!)
        .eq('status', 'REQUIRES_ATTENTION')).length, 0);
  }

  // Equipment Metrics
  final eqRes = await safe(() => sb
      .from('equipment')
      .select('id, quantity, minimum_required, status')
      .eq('unit_id', user.unitId!), <Map<String, dynamic>>[]);

  int missingEq = 0;
  int expiringEq = 0;

  for (final eq in eqRes) {
    if (eq['status'] == 'MISSING' || ((eq['quantity'] ?? 0) as int) < ((eq['minimum_required'] ?? 0) as int)) {
      missingEq++;
    }
    if (eq['status'] == 'EXPIRING_SOON') {
      expiringEq++;
    }
  }

  // Readiness Metrics
  final assignmentsRes = await safe(() => sb
      .from('equipment_assignments')
      .select('medic_id')
      .eq('verification_status', 'PENDING'), <Map<String, dynamic>>[]);

  final uniquePendingMedics = assignmentsRes.map((r) => r['medic_id']).toSet();
  final unverified = uniquePendingMedics.length;

  // Daily schedule (with automatic 00:00 daily reset!)
  final scheduleRes = await safe(
    () => sb.from('daily_schedule').select().eq('unit_id', user.unitId!),
    <Map<String, dynamic>>[],
  );

  final todayKey = todayScheduleDateKey();
  final List<Map<String, String>> staleTasksToReset = [];

  final timeline = scheduleRes.map((s) {
    final rawIconStr = (s['icon'] ?? 'clock').toString();
    final cleanIcon = rawIconStr.split('@').first;
    final stampedDate = rawIconStr.contains('@') ? rawIconStr.split('@').last : null;
    final rawDone = s['is_done'] == true || s['is_done'] == 1;

    // A task is only considered completed today if it was stamped with today's date
    final bool isDoneToday = rawDone && stampedDate == todayKey;
    if (rawDone && !isDoneToday && s['id'] != null) {
      staleTasksToReset.add({'id': s['id'].toString(), 'icon': cleanIcon});
    }

    return <String, dynamic>{
      'id': s['id'],
      'time': (s['time'] ?? '').toString(),
      'title': s['title'],
      'actor': s['actor'],
      'icon': cleanIcon,
      'is_done': isDoneToday,
    };
  }).toList();

  if (staleTasksToReset.isNotEmpty) {
    for (final stale in staleTasksToReset) {
      sb
          .from('daily_schedule')
          .update({'is_done': false, 'icon': stale['icon']})
          .eq('id', stale['id']!)
          .then((_) {}, onError: (_) {});
    }
  }

  timeline.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

  // Medics
  final usersRecords = await safe(() => sb.from('users').select().eq('unit_id', user.unitId!), <Map<String, dynamic>>[]);
  final medics = usersRecords
      .where((u) => u['role'] == 'COMBAT_MEDIC' || u['role'] == 'COMPANY_MEDIC')
      .map((u) {
    return <String, dynamic>{
      'id': u['id'],
      'name': u['name'],
      'role': u['role'],
      'phone_number': u['phone_number'],
      'platoon': u['platoon'],
      'is_manual': u['is_manual'] == true,
      'standby': u['is_on_standby'] == true || u['is_on_standby'] == 1,
    };
  }).toList();

  // Merge locally-persisted manual standby medics
  final manualMedics = await StandbyMedicsService.getManualMedics(user.unitId);
  for (final m in manualMedics) {
    final idx = medics.indexWhere((x) => x['id'] == m['id'] || (x['name'] == m['name'] && x['is_manual'] == true));
    if (idx != -1) {
      medics[idx] = m;
    } else {
      medics.add(m);
    }
  }

  // Ensure current user is always present in medics list
  final hasMe = medics.any((m) => m['id'] == user.id);
  if (!hasMe) {
    medics.insert(0, {
      'id': user.id,
      'name': user.name.isNotEmpty ? user.name : 'חופ"ל',
      'role': user.role.isNotEmpty ? user.role : 'COMPANY_MEDIC',
      'phone_number': null,
      'platoon': null,
      'is_manual': false,
      'standby': true,
    });
  }

  return DashboardMetrics(
    activeMedicalCases: activeCases,
    requiresAttentionCases: attentionCases,
    missingEquipment: missingEq,
    totalEquipment: eqRes.length,
    expiringEquipment: expiringEq,
    unverifiedMedics: unverified,
    timelineEvents: timeline,
    activeMedics: medics,
  );
});
