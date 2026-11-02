import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

final soldiersProvider = FutureProvider<List<Soldier>>((ref) async {
  final user = AuthService().currentUser;
  if (user?.unitId == null) return [];
  
  final cacheKey = 'cached_soldiers_${user!.unitId}';
  try {
    final response = await Supabase.instance.client
        .from('soldiers')
        .select()
        .eq('unit_id', user.unitId!);
        
    final soldiers = response.map((map) => Soldier.fromMap(map)).toList();
    
    // Save to local cache in background
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = soldiers.map((s) => s.toMap()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (_) {}
    
    return soldiers;
  } catch (e) {
    // Network failed or offline - return from cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        return decoded.map((m) => Soldier.fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
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
    
    final cacheKey = 'cached_cases_${user.activeDeploymentId}';
    try {
      final response = await Supabase.instance.client
          .from('medical_cases')
          .select()
          .eq('deployment_id', user.activeDeploymentId!)
          .order('created_date', ascending: false);
          
      final cases = response.map((map) => MedicalCase.fromMap(map)).toList();
      
      // Save to local cache in background
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = cases.map((c) => c.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
      } catch (_) {}
      
      return cases;
    } catch (e) {
      // Network failed or offline - return from cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString(cacheKey);
        if (cachedStr != null && cachedStr.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedStr);
          return decoded.map((m) => MedicalCase.fromMap(m as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
      return [];
    }
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

