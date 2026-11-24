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

class SoldiersNotifier extends AsyncNotifier<List<Soldier>> {
  @override
  FutureOr<List<Soldier>> build() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return [];
    final cacheKey = 'cached_soldiers_${user!.unitId}';
    final cached = await _readCache(cacheKey);
    if (cached.isNotEmpty) {
      unawaited(_refreshInBackground(user.unitId!, cacheKey));
      return cached;
    }
    return _fetchFromCloud(user.unitId!, cacheKey, fallback: cached);
  }

  Future<List<Soldier>> _readCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        return decoded.map((m) => Soldier.fromMap(Map<String, dynamic>.from(m as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Soldier>> _fetchFromCloud(
    String unitId,
    String cacheKey, {
    List<Soldier> fallback = const [],
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('soldiers')
          .select()
          .eq('unit_id', unitId)
          .timeout(const Duration(seconds: 5));

      final soldiers = (response as List)
          .map((map) => Soldier.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();

      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = soldiers.map((s) => s.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
      } catch (_) {}

      return soldiers;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _refreshInBackground(String unitId, String cacheKey) async {
    final fresh = await _fetchFromCloud(unitId, cacheKey, fallback: state.value ?? const []);
    if (fresh.isNotEmpty || (state.value?.isEmpty ?? true)) {
      state = AsyncValue.data(fresh);
    }
  }
}

final soldiersProvider = AsyncNotifierProvider<SoldiersNotifier, List<Soldier>>(() {
  return SoldiersNotifier();
});

// An AsyncNotifier to manage and fetch medical cases, triggering UI rebuilds when modified.
class MedicalCasesNotifier extends AsyncNotifier<List<MedicalCase>> {
  @override
  FutureOr<List<MedicalCase>> build() async {
    final user = AuthService().currentUser;
    if (user == null || user.activeDeploymentId == null) return [];
    final cacheKey = 'cached_cases_${user.activeDeploymentId}';
    final cached = await _readCache(cacheKey);
    if (cached != null) {
      unawaited(_refreshInBackground(user.activeDeploymentId!, cacheKey));
      return cached;
    }
    return _loadCases();
  }

  Future<List<MedicalCase>?> _readCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        return decoded.map((m) => MedicalCase.fromMap(Map<String, dynamic>.from(m as Map))).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _refreshInBackground(String deploymentId, String cacheKey) async {
    try {
      final fresh = await _loadCases();
      state = AsyncValue.data(fresh);
    } catch (_) {}
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
          .order('created_date', ascending: false)
          .timeout(const Duration(seconds: 5));

      final cases = (response as List)
          .map((map) => MedicalCase.fromMap(Map<String, dynamic>.from(map as Map)))
          .toList();

      // Save to local cache in background
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = cases.map((c) => c.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
      } catch (_) {}

      return cases;
    } catch (e) {
      // Network failed or offline - return from cache
      return await _readCache(cacheKey) ?? [];
    }
  }

  // Call this after using SyncEngine to add/update/delete cases
  Future<void> refresh() async {
    final fresh = await _loadCases();
    state = AsyncValue.data(fresh);
  }
}

final medicalCasesProvider = AsyncNotifierProvider<MedicalCasesNotifier, List<MedicalCase>>(() {
  return MedicalCasesNotifier();
});
