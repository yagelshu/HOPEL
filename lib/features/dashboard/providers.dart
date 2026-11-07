import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/standby_medics_service.dart';
import 'package:chopel_app/models/equipment.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  DashboardMetrics copyWith({
    int? activeMedicalCases,
    int? requiresAttentionCases,
    int? missingEquipment,
    int? totalEquipment,
    int? expiringEquipment,
    int? unverifiedMedics,
    List<Map<String, dynamic>>? timelineEvents,
    List<Map<String, dynamic>>? activeMedics,
  }) {
    return DashboardMetrics(
      activeMedicalCases: activeMedicalCases ?? this.activeMedicalCases,
      requiresAttentionCases: requiresAttentionCases ?? this.requiresAttentionCases,
      missingEquipment: missingEquipment ?? this.missingEquipment,
      totalEquipment: totalEquipment ?? this.totalEquipment,
      expiringEquipment: expiringEquipment ?? this.expiringEquipment,
      unverifiedMedics: unverifiedMedics ?? this.unverifiedMedics,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      activeMedics: activeMedics ?? this.activeMedics,
    );
  }
}

class DashboardMetricsNotifier extends AsyncNotifier<DashboardMetrics> {
  final Map<String, bool> _demoStandbyOverrides = {};

  @override
  FutureOr<DashboardMetrics> build() async {
    return _fetchMetrics();
  }

  Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('dashboard section failed: $e');
      return fallback;
    }
  }

  Future<DashboardMetrics> _fetchMetrics() async {
    final auth = AuthService();
    final user = auth.currentUser;
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

    final unitId = user.unitId!;
    final depId = user.activeDeploymentId;

    // Execute all Supabase + local queries in parallel for snappy loading
    final casesFuture = depId != null
        ? _safe(
            () async => List<Map<String, dynamic>>.from(
              await sb
                  .from('medical_cases')
                  .select('id, status')
                  .eq('deployment_id', depId)
                  .not('status', 'in', ['CLOSED', 'COMPLETED']),
            ),
            <Map<String, dynamic>>[],
          )
        : Future.value(<Map<String, dynamic>>[]);

    final eqFuture = _safe(
      () async => List<Map<String, dynamic>>.from(
        await sb
            .from('equipment')
            .select('id, category, quantity, minimum_required, status')
            .eq('unit_id', unitId),
      ),
      <Map<String, dynamic>>[],
    );

    final assignmentsFuture = _safe(
      () async => List<Map<String, dynamic>>.from(
        await sb
            .from('equipment_assignments')
            .select('medic_id')
            .eq('verification_status', 'PENDING'),
      ),
      <Map<String, dynamic>>[],
    );

    final scheduleFuture = _safe(
      () async => List<Map<String, dynamic>>.from(
        await sb.from('daily_schedule').select().eq('unit_id', unitId),
      ),
      <Map<String, dynamic>>[],
    );

    final usersFuture = _safe(
      () async => List<Map<String, dynamic>>.from(
        await sb.from('users').select().eq('unit_id', unitId),
      ),
      <Map<String, dynamic>>[],
    );

    final manualMedicsFuture = StandbyMedicsService.getManualMedics(unitId);

    final results = await Future.wait<dynamic>([
      casesFuture,
      eqFuture,
      assignmentsFuture,
      scheduleFuture,
      usersFuture,
      manualMedicsFuture,
    ]);

    final openCases = results[0] as List<Map<String, dynamic>>;
    final eqRes = results[1] as List<Map<String, dynamic>>;
    final assignmentsRes = results[2] as List<Map<String, dynamic>>;
    final scheduleRes = results[3] as List<Map<String, dynamic>>;
    final usersRecords = results[4] as List<Map<String, dynamic>>;
    final manualMedics = results[5] as List<Map<String, dynamic>>;

    final int activeCases = openCases.length;
    final int attentionCases = openCases.where((c) => c['status'] == 'REQUIRES_ATTENTION').length;

    // Equipment Metrics scoped by effective role
    final bool isCompanyMedic = auth.isCompanyMedic;
    final String effectiveMedicId = auth.effectiveUserId ?? user.id;
    final scopedEq = eqRes.where((eq) {
      final cat = (eq['category'] ?? '').toString();
      if (cat.startsWith('${Equipment.vestPrefix}demo_medic_')) {
        return !isCompanyMedic && cat == Equipment.vestCategoryFor(effectiveMedicId);
      }
      if (isCompanyMedic) return true;
      return cat == Equipment.vestCategoryFor(effectiveMedicId);
    }).toList();

    int missingEq = 0;
    int expiringEq = 0;
    for (final eq in scopedEq) {
      final qty = (eq['quantity'] as num?)?.toInt() ?? 0;
      final minReq = (eq['minimum_required'] as num?)?.toInt() ?? 0;
      if (eq['status'] == 'MISSING' || qty < minReq) {
        missingEq++;
      }
      if (eq['status'] == 'EXPIRING_SOON') {
        expiringEq++;
      }
    }

    final uniquePendingMedics = assignmentsRes.map((r) => r['medic_id']).toSet();
    final unverified = uniquePendingMedics.length;

    // Auto-clean previously seeded fabricated template tasks once per unit
    const fabricatedTitles = {
      'מסדר חולים בוקר',
      'בדיקת כוננות וחוסרים בארגז חופ"ל',
      'מעקב פניות פתוחות ותדריך כוננות לילה',
    };
    var filteredScheduleRes = scheduleRes;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanFlagKey = 'cleaned_fabricated_schedule_v58_$unitId';
      if (!(prefs.getBool(cleanFlagKey) ?? false)) {
        final fabricatedIds = scheduleRes
            .where((s) => fabricatedTitles.contains((s['title'] ?? '').toString().trim()))
            .map((s) => s['id'])
            .where((id) => id != null)
            .toList();
        if (fabricatedIds.isNotEmpty) {
          filteredScheduleRes = scheduleRes
              .where((s) => !fabricatedTitles.contains((s['title'] ?? '').toString().trim()))
              .toList();
          for (final id in fabricatedIds) {
            sb.from('daily_schedule').delete().eq('id', id).then((_) {}, onError: (_) {});
          }
        }
        await prefs.setBool(cleanFlagKey, true);
      }
    } catch (_) {}

    // Daily schedule (with automatic 00:00 daily reset)
    final todayKey = todayScheduleDateKey();
    final List<Map<String, String>> staleTasksToReset = [];

    final timeline = filteredScheduleRes.map((s) {
      final rawIconStr = (s['icon'] ?? 'clock').toString();
      final cleanIcon = rawIconStr.split('@').first;
      final stampedDate = rawIconStr.contains('@') ? rawIconStr.split('@').last : null;
      final rawDone = s['is_done'] == true || s['is_done'] == 1;

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
    final medics = usersRecords
        .where((u) => u['role'] == 'COMBAT_MEDIC' || u['role'] == 'COMPANY_MEDIC')
        .map((u) {
      final idStr = u['id']?.toString() ?? '';
      final isSelf = idStr == user.id;
      return <String, dynamic>{
        'id': u['id'],
        'name': isSelf && user.name.isNotEmpty ? user.name : u['name'],
        'role': u['role'],
        'phone_number': u['phone_number'] ?? (isSelf ? user.phoneNumber : null),
        'platoon': u['platoon'] ?? (isSelf ? user.platoon : null),
        'is_manual': u['is_manual'] == true,
        'standby': u['is_on_standby'] == true || u['is_on_standby'] == 1,
      };
    }).toList();

    for (final m in manualMedics) {
      final idx = medics.indexWhere(
        (x) => x['id'] == m['id'] || (x['name'] == m['name'] && x['is_manual'] == true),
      );
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
        'phone_number': user.phoneNumber,
        'platoon': user.platoon,
        'is_manual': false,
        'standby': true,
      });
    }

    // If previewing as a custom demo medic not in the list, show them so they can test standby toggle
    if (auth.isPreviewingAsCombatMedic) {
      final preview = auth.previewMedicProfile;
      final previewId = preview?['id'];
      if (previewId != null && !medics.any((m) => m['id'] == previewId)) {
        medics.add({
          'id': previewId,
          'name': preview?['name'] ?? 'חובש לדוגמה',
          'role': 'COMBAT_MEDIC',
          'phone_number': preview?['phone'],
          'platoon': preview?['platoon'],
          'is_manual': true,
          'standby': _demoStandbyOverrides[previewId] ?? true,
        });
      }
    }

    return DashboardMetrics(
      activeMedicalCases: activeCases,
      requiresAttentionCases: attentionCases,
      missingEquipment: missingEq,
      totalEquipment: scopedEq.length,
      expiringEquipment: expiringEq,
      unverifiedMedics: unverified,
      timelineEvents: timeline,
      activeMedics: medics,
    );
  }

  /// 0ms synchronous optimistic toggle for a daily schedule task (`V` checkmark).
  Future<void> toggleScheduleTask(dynamic taskId) async {
    final current = state.value;
    if (current == null || taskId == null) return;

    final idx = current.timelineEvents.indexWhere((e) => e['id'] == taskId);
    if (idx == -1) return;

    final previousEvents = current.timelineEvents;
    final target = Map<String, dynamic>.from(previousEvents[idx]);
    final nextDone = !(target['is_done'] == true);
    final baseIcon = (target['icon'] ?? 'clock').toString();
    target['is_done'] = nextDone;

    final updatedEvents = List<Map<String, dynamic>>.from(previousEvents);
    updatedEvents[idx] = target;

    // Instant 0ms UI update
    state = AsyncValue.data(current.copyWith(timelineEvents: updatedEvents));

    try {
      await Supabase.instance.client
          .from('daily_schedule')
          .update({
            'is_done': nextDone,
            'icon': encodeScheduleIconForToday(baseIcon, isDone: nextDone),
          })
          .eq('id', taskId);
    } catch (e) {
      // Roll back on failure
      final latest = state.value;
      if (latest != null) {
        state = AsyncValue.data(latest.copyWith(timelineEvents: previousEvents));
      }
      rethrow;
    }
  }

  void upsertScheduleTaskLocally(Map<String, dynamic> task) {
    final current = state.value;
    if (current == null) return;
    final updated = List<Map<String, dynamic>>.from(current.timelineEvents);
    final idx = updated.indexWhere((e) => e['id'] == task['id']);
    if (idx != -1) {
      updated[idx] = Map<String, dynamic>.from(task);
    } else {
      updated.add(Map<String, dynamic>.from(task));
    }
    updated.sort((a, b) => (a['time'] ?? '').toString().compareTo((b['time'] ?? '').toString()));
    state = AsyncValue.data(current.copyWith(timelineEvents: updated));
  }

  void removeScheduleTaskLocally(dynamic taskId) {
    final current = state.value;
    if (current == null) return;
    final updated = current.timelineEvents.where((e) => e['id'] != taskId).toList();
    state = AsyncValue.data(current.copyWith(timelineEvents: updated));
  }

  void clearAllScheduleTasksLocally() {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(timelineEvents: const []));
  }

  /// 0ms synchronous optimistic toggle for a medic's standby status (`0 -> 1` in `חובשים במוצב`).
  Future<void> toggleMedicStandby(Map<String, dynamic> medic, bool value) async {
    final medicId = medic['id']?.toString() ?? '';
    if (medicId.isEmpty) return;

    final current = state.value;
    final previousMedics = current?.activeMedics;

    if (current != null) {
      final updatedMedics = current.activeMedics.map((m) {
        if (m['id']?.toString() == medicId) {
          return <String, dynamic>{...m, 'standby': value};
        }
        return m;
      }).toList();
      // Instant 0ms UI update
      state = AsyncValue.data(current.copyWith(activeMedics: updatedMedics));
    }

    if (medicId.startsWith('demo_medic_')) {
      _demoStandbyOverrides[medicId] = value;
      return;
    }

    final unitId = AuthService().currentUser?.unitId;
    if (medic['is_manual'] == true) {
      await StandbyMedicsService.updateStandby(unitId, medicId, value);
      return;
    }

    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_on_standby': value})
          .eq('id', medicId);
    } catch (e) {
      if (current != null && previousMedics != null) {
        state = AsyncValue.data(current.copyWith(activeMedics: previousMedics));
      }
      rethrow;
    }
  }

  void upsertMedicLocally(Map<String, dynamic> medic) {
    final current = state.value;
    if (current == null) return;
    final updated = List<Map<String, dynamic>>.from(current.activeMedics);
    final idx = updated.indexWhere((m) => m['id'] == medic['id']);
    if (idx != -1) {
      updated[idx] = Map<String, dynamic>.from(medic);
    } else {
      updated.add(Map<String, dynamic>.from(medic));
    }
    state = AsyncValue.data(current.copyWith(activeMedics: updated));
  }

  void removeMedicLocally(String medicId) {
    final current = state.value;
    if (current == null) return;
    final updated = current.activeMedics.where((m) => m['id']?.toString() != medicId).toList();
    state = AsyncValue.data(current.copyWith(activeMedics: updated));
  }
}

final dashboardMetricsProvider =
    AsyncNotifierProvider<DashboardMetricsNotifier, DashboardMetrics>(() {
  return DashboardMetricsNotifier();
});
