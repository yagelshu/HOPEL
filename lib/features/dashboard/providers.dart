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

  // Medical Metrics (filtered by active deployment if available, else unit)
  int activeCases = 0;
  int attentionCases = 0;
  
  if (user.activeDeploymentId != null) {
    final activeCasesRes = await sb
        .from('medical_cases')
        .select('id')
        .eq('deployment_id', user.activeDeploymentId!)
        .not('status', 'in', ['CLOSED', 'COMPLETED']);
    activeCases = activeCasesRes.length;
    
    final attentionCasesRes = await sb
        .from('medical_cases')
        .select('id')
        .eq('deployment_id', user.activeDeploymentId!)
        .eq('status', 'REQUIRES_ATTENTION');
    attentionCases = attentionCasesRes.length;
  }

  // Equipment Metrics
  final missingEqRes = await sb
      .from('equipment')
      .select('id, quantity, minimum_required, status')
      .eq('unit_id', user.unitId!);
  
  int missingEq = 0;
  int expiringEq = 0; // Requires date parsing, keeping logic simple for now
  
  for (final eq in missingEqRes) {
    if (eq['status'] == 'MISSING' || (eq['quantity'] as int) < (eq['minimum_required'] as int)) {
      missingEq++;
    }
    if (eq['status'] == 'EXPIRING_SOON') {
      expiringEq++;
    }
  }

  // Readiness Metrics
  // Since we don't have equipment_assignments populated for the unit easily mapped to medic_id, 
  // we do a raw query equivalent via Supabase:
  final assignmentsRes = await sb
      .from('equipment_assignments')
      .select('medic_id')
      .eq('verification_status', 'PENDING');
      
  final uniquePendingMedics = assignmentsRes.map((r) => r['medic_id']).toSet();
  // Filter only those in this unit
  final unverified = uniquePendingMedics.length; 

  // Timeline Events Generator
  final scheduleRes = await sb.from('daily_schedule').select().eq('unit_id', user.unitId!);
  final timeline = scheduleRes.map((s) {
    return {
      'id': s['id'],
      'time': s['time'],
      'title': s['title'],
      'is_done': s['is_done'] == true || s['is_done'] == 1,
    };
  }).toList();
  timeline.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

  // Medics
  final usersRecords = await sb.from('users').select().eq('unit_id', user.unitId!);
  final medics = usersRecords
      .where((u) => u['role'] == 'COMBAT_MEDIC' || u['role'] == 'COMPANY_MEDIC')
      .map((u) {
    return {
      'id': u['id'],
      'name': u['name'],
      'role': u['role'],
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
