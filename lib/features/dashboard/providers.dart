import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/utils/date_formatter.dart';
import 'package:chopel_app/core/auth/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardDatabaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

class DashboardMetrics {
  final int activeMedicalCases;
  final int requiresAttentionCases;
  final int missingEquipment;
  final int expiringEquipment;
  final int unverifiedMedics;
  final List<Map<String, dynamic>> timelineEvents;
  final List<Map<String, dynamic>> activeMedics;

  DashboardMetrics({
    required this.activeMedicalCases,
    required this.requiresAttentionCases,
    required this.missingEquipment,
    required this.expiringEquipment,
    required this.unverifiedMedics,
    required this.timelineEvents,
    required this.activeMedics,
  });
}

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final user = AuthService().currentUser;
  final sb = Supabase.instance.client;
  
  if (user == null || user.unitId == null) {
    return DashboardMetrics(
      activeMedicalCases: 0,
      requiresAttentionCases: 0,
      missingEquipment: 0,
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
      // ignore: avoid_print
      print('dashboard section failed: $e');
      return fallback;
    }
  }

  // Medical Metrics (filtered by active deployment if available, else unit)
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
  final missingEqRes = await safe(() => sb
      .from('equipment')
      .select('id, quantity, minimum_required, status')
      .eq('unit_id', user.unitId!), <Map<String, dynamic>>[]);
  
  int missingEq = 0;
  int expiringEq = 0; // Requires date parsing, keeping logic simple for now
  
  for (final eq in missingEqRes) {
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

  // Daily schedule
  final scheduleRes = await safe(() => sb.from('daily_schedule').select().eq('unit_id', user.unitId!), <Map<String, dynamic>>[]);
  final timeline = scheduleRes.map((s) {
    return <String, dynamic>{
      'id': s['id'],
      'time': (s['time'] ?? '').toString(),
      'title': s['title'],
      'actor': s['actor'],
      'icon': s['icon'],
      'is_done': s['is_done'] == true || s['is_done'] == 1,
    };
  }).toList();
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
      'is_manual': u['is_manual'] == true,
      'standby': u['is_on_standby'] == true || u['is_on_standby'] == 1,
    };
  }).toList();

  return DashboardMetrics(
    activeMedicalCases: activeCases,
    requiresAttentionCases: attentionCases,
    missingEquipment: missingEq,
    expiringEquipment: expiringEq,
    unverifiedMedics: unverified,
    timelineEvents: timeline,
    activeMedics: medics,
  );
});
