import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/core/auth/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

final soldiersProvider = FutureProvider<List<Soldier>>((ref) async {
  final user = AuthService().currentUser;
  if (user?.unitId == null) return [];
  
  final response = await Supabase.instance.client
      .from('soldiers')
      .select()
      .eq('unit_id', user!.unitId!);
      
  return response.map((map) => Soldier.fromMap(map)).toList();
});

// An AsyncNotifier to manage and fetch medical cases, triggering UI rebuilds when modified.
class MedicalCasesNotifier extends AsyncNotifier<List<MedicalCase>> {
  @override
  FutureOr<List<MedicalCase>> build() async {
    return _loadCases();
  }

  Future<List<MedicalCase>> _loadCases() async {
    final user = AuthService().currentUser;
    
    if (user == null || user.activeDeploymentId == null) return [];
    
    final response = await Supabase.instance.client
        .from('medical_cases')
        .select()
        .eq('deployment_id', user.activeDeploymentId!)
        .order('created_date', ascending: false);
        
    return response.map((map) => MedicalCase.fromMap(map)).toList();
  }

  // Call this after using SyncEngine to add/update/delete cases
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCases());
  }
}

final medicalCasesProvider = AsyncNotifierProvider<MedicalCasesNotifier, List<MedicalCase>>(() {
  return MedicalCasesNotifier();
});
