import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/network/unit_service.dart';
import 'package:chopel_app/core/utils/default_equipment_catalog.dart';
import 'package:chopel_app/features/dashboard/providers.dart';
import 'package:chopel_app/models/equipment.dart';

final equipmentDatabaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

class EquipmentNotifier extends AsyncNotifier<List<Equipment>> {
  @override
  FutureOr<List<Equipment>> build() async {
    return _loadEquipment();
  }

  Future<List<Equipment>> _loadEquipment() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return [];

    final unitId = user!.unitId!;
    final cacheKey = 'cached_equipment_$unitId';
    final seededKey = 'equipment_seeded_$unitId';
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await Supabase.instance.client
          .from('equipment')
          .select()
          .eq('unit_id', unitId)
          .order('name');

      var items = (response as List)
          .map((map) => Equipment.fromMap(Map<String, dynamic>.from(map)))
          .toList();

      // Auto-seed standard IDF equipment once for units that have 0 items yet
      if (items.isEmpty && !(prefs.getBool(seededKey) ?? false)) {
        try {
          final seededRows = await UnitService().seedUnitEquipment(unitId);
          items = seededRows.map((m) => Equipment.fromMap(m)).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          await prefs.setBool(seededKey, true);
          ref.invalidate(dashboardMetricsProvider);
        } catch (seedErr) {
          debugPrint('Cloud equipment seed failed, falling back to local standard kit: $seedErr');
          final fallbackRows = DefaultEquipmentCatalog.buildRowsForUnit(unitId);
          items = fallbackRows.map((m) => Equipment.fromMap(m)).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
        }
      } else if (items.isNotEmpty) {
        await prefs.setBool(seededKey, true);
      }

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
          final cachedItems = decoded
              .map((m) => Equipment.fromMap(Map<String, dynamic>.from(m)))
              .toList();
          if (cachedItems.isNotEmpty) return cachedItems;
        } catch (_) {}
      }

      // First-time offline fallback: provide standard IDF kit locally
      final fallbackRows = DefaultEquipmentCatalog.buildRowsForUnit(unitId);
      final fallbackItems = fallbackRows.map((m) => Equipment.fromMap(m)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      try {
        await prefs.setString(
          cacheKey,
          jsonEncode(fallbackItems.map((e) => e.toMap()).toList()),
        );
      } catch (_) {}
      return fallbackItems;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEquipment());
  }

  /// Explicitly loads the 50-item standard IDF equipment kit into the unit.
  Future<void> seedStandardCatalog() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return;

    final unitId = user!.unitId!;
    state = const AsyncValue.loading();

    try {
      List<Map<String, dynamic>> rows;
      try {
        rows = await UnitService().seedUnitEquipment(unitId);
      } catch (e) {
        debugPrint('seedStandardCatalog cloud insert warning: $e');
        rows = DefaultEquipmentCatalog.buildRowsForUnit(unitId);
      }

      final items = rows.map((m) => Equipment.fromMap(m)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('equipment_seeded_$unitId', true);
      await prefs.setString(
        'cached_equipment_$unitId',
        jsonEncode(items.map((e) => e.toMap()).toList()),
      );

      state = AsyncValue.data(items);
      ref.invalidate(dashboardMetricsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
        : (item.status == 'EXPIRING_SOON' ? 'EXPIRING_SOON' : 'IN_STOCK');

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

    // Sync to Supabase in background (upsert handles locally-seeded items too)
    try {
      await Supabase.instance.client
          .from('equipment')
          .upsert(updatedItem.toSupabaseMap());
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

  final response = await Supabase.instance.client
      .from('equipment_assignments')
      .select('id, verification_status, equipment:equipment_id(name, expiration_date)')
      .eq('medic_id', user!.id);

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
