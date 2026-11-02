import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/equipment.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chopel_app/features/dashboard/providers.dart';

final equipmentDatabaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

class EquipmentNotifier extends AsyncNotifier<List<Equipment>> {
  @override
  FutureOr<List<Equipment>> build() async {
    return _loadEquipment();
  }

  Future<List<Equipment>> _loadEquipment() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return [];
    
    final cacheKey = 'cached_equipment_${user!.unitId}';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await Supabase.instance.client
          .from('equipment')
          .select()
          .eq('unit_id', user.unitId!)
          .order('name');
          
      final items = (response as List).map((map) => Equipment.fromMap(map)).toList();
      
      // Cache locally for offline resilience
      try {
        final jsonList = items.map((e) => e.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
      } catch (_) {}
      
      return items;
    } catch (e) {
      // Offline fallback: load from cached json
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedStr) as List;
          return decoded.map((m) => Equipment.fromMap(m as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      // If no cache, return empty list rather than hard crash
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEquipment());
  }

  /// Optimistically adjust quantity directly from the list (+1 / -1)
  Future<void> adjustQuantity(String id, int delta) async {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = currentList[index];
    final newQty = (item.quantity + delta).clamp(0, 9999);
    if (newQty == item.quantity) return;

    final newStatus = newQty < item.minimumRequired 
        ? 'MISSING' 
        : (item.status == 'EXPIRING_SOON' ? 'EXPIRING_SOON' : 'OK');

    final updatedItem = item.copyWith(quantity: newQty, status: newStatus);
    final updatedList = List<Equipment>.from(currentList);
    updatedList[index] = updatedItem;

    // Optimistic UI update
    state = AsyncValue.data(updatedList);

    // Update local cache immediately
    final user = AuthService().currentUser;
    if (user?.unitId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = updatedList.map((e) => e.toMap()).toList();
        await prefs.setString('cached_equipment_${user!.unitId}', jsonEncode(jsonList));
      } catch (_) {}
    }

    // Refresh dashboard metrics
    ref.invalidate(dashboardMetricsProvider);

    // Sync to Supabase in background
    try {
      await Supabase.instance.client
          .from('equipment')
          .update({'quantity': newQty, 'status': newStatus})
          .eq('id', id);
    } catch (_) {}

    // Sync to local SQLite if present
    try {
      final db = await DatabaseService().database;
      await db.update('equipment', {'quantity': newQty, 'status': newStatus}, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }
}

final equipmentProvider = AsyncNotifierProvider<EquipmentNotifier, List<Equipment>>(() {
  return EquipmentNotifier();
});

// For Combat Medic viewing their assigned equipment
final myAssignmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = AuthService().currentUser;
  if (user?.id == null) return [];

  // Since Supabase allows inner joins natively, we can query it directly
  // We query equipment_assignments and join the equipment table
  final response = await Supabase.instance.client
      .from('equipment_assignments')
      .select('id, verification_status, equipment:equipment_id(name, expiration_date)')
      .eq('medic_id', user!.id);
      
  // Transform response to match the old rawQuery output
  return response.map((row) {
    final eq = row['equipment'] as Map<String, dynamic>? ?? {};
    return {
      'assignment_id': row['id'],
      'verification_status': row['verification_status'],
      'name': eq['name'],
      'expiration_date': eq['expiration_date']
    };
  }).toList();
});
