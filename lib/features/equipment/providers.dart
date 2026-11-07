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
  final Set<String> _seedingMedicIds = {};

  @override
  FutureOr<List<Equipment>> build() async {
    return _loadEquipment();
  }

  Future<void> _persistLocalCache(String unitId, List<Equipment> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((e) => e.toMap()).toList();
      await prefs.setString('cached_equipment_$unitId', jsonEncode(jsonList));
    } catch (_) {}
  }

  Map<String, String> _readCachedImages(SharedPreferences prefs, String cacheKey) {
    final result = <String, String>{};
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr == null || cachedStr.isEmpty) return result;
    try {
      final decoded = jsonDecode(cachedStr) as List;
      for (final raw in decoded) {
        if (raw is Map) {
          final id = raw['id']?.toString();
          final img = raw['image_path']?.toString();
          if (id != null && img != null && img.isNotEmpty) {
            result[id] = img;
          }
        }
      }
    } catch (_) {}
    return result;
  }

  Future<List<Equipment>> _loadEquipment() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return [];

    final unitId = user!.unitId!;
    final cacheKey = 'cached_equipment_$unitId';
    final seededKey = 'equipment_seeded_$unitId';
    final prefs = await SharedPreferences.getInstance();
    final cachedImages = _readCachedImages(prefs, cacheKey);

    try {
      final response = await Supabase.instance.client
          .from('equipment')
          .select()
          .eq('unit_id', unitId)
          .order('name');

      var items = (response as List).map((map) {
        final eq = Equipment.fromMap(Map<String, dynamic>.from(map));
        if (eq.imagePath == null && cachedImages.containsKey(eq.id)) {
          return eq.copyWith(imagePath: cachedImages[eq.id]);
        }
        return eq;
      }).toList();

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

      await _persistLocalCache(unitId, items);
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
      await _persistLocalCache(unitId, fallbackItems);
      return fallbackItems;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEquipment());
  }

  /// Explicitly loads the standard IDF equipment kit into the unit.
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
      await _persistLocalCache(unitId, items);

      state = AsyncValue.data(items);
      ref.invalidate(dashboardMetricsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Ensures that [medicId] has a personal standard IDF `וסט חובש` initialized.
  Future<void> ensureMedicVestSeeded(
    String medicId, {
    required bool includeLegacyUnassigned,
  }) async {
    if (medicId.isEmpty || _seedingMedicIds.contains(medicId)) return;
    final user = AuthService().currentUser;
    final unitId = user?.unitId;
    if (unitId == null) return;

    final currentList = state.value;
    if (currentList == null) return;

    final alreadyExists = currentList.any(
      (e) => e.belongsToMedicVest(medicId, includeLegacyUnassigned: includeLegacyUnassigned),
    );
    if (alreadyExists) return;

    _seedingMedicIds.add(medicId);
    try {
      final rows = DefaultEquipmentCatalog.buildMedicVestRows(unitId, medicId);
      final seededVestItems = rows.map((m) => Equipment.fromMap(m)).toList();
      final updatedList = <Equipment>[...currentList, ...seededVestItems]
        ..sort((a, b) => a.name.compareTo(b.name));

      // Instant 0ms optimistic state update
      state = AsyncValue.data(updatedList);
      await _persistLocalCache(unitId, updatedList);
      ref.invalidate(dashboardMetricsProvider);

      // Persist to Supabase in background (skip cloud insert for synthetic demo preview IDs if needed,
      // though `category` is plain text and unit_id is valid so cloud insert works for real & manual medics too!)
      if (!medicId.startsWith('demo_medic_')) {
        try {
          await Supabase.instance.client.from('equipment').insert(rows);
        } catch (e) {
          debugPrint('ensureMedicVestSeeded cloud insert warning: $e');
        }
      }
    } finally {
      _seedingMedicIds.remove(medicId);
    }
  }

  /// Optimistically inserts or updates an equipment item (including its base64 photo) in 0ms.
  Future<void> upsertItem(Equipment item) async {
    final currentList = List<Equipment>.from(state.value ?? []);
    final existingIdx = currentList.indexWhere((e) => e.id == item.id);
    if (existingIdx != -1) {
      currentList[existingIdx] = item;
    } else {
      currentList.add(item);
      currentList.sort((a, b) => a.name.compareTo(b.name));
    }

    // 0ms optimistic update so UI & photo update immediately
    state = AsyncValue.data(currentList);

    final unitId = item.unitId ?? AuthService().currentUser?.unitId;
    if (unitId != null) {
      await _persistLocalCache(unitId, currentList);
    }
    ref.invalidate(dashboardMetricsProvider);

    if (unitId != null) {
      await Supabase.instance.client.from('equipment').upsert(item.toSupabaseMap());
    }

    try {
      final db = await DatabaseService().database;
      final localMap = item.toMap();
      if (existingIdx != -1) {
        await db.update('equipment', localMap, where: 'id = ?', whereArgs: [item.id]);
      } else {
        await db.insert('equipment', localMap);
      }
    } catch (_) {}
  }

  /// Optimistically removes an equipment item in 0ms.
  Future<void> deleteItem(String id) async {
    final currentList = List<Equipment>.from(state.value ?? []);
    currentList.removeWhere((e) => e.id == id);
    state = AsyncValue.data(currentList);

    final unitId = AuthService().currentUser?.unitId;
    if (unitId != null) {
      await _persistLocalCache(unitId, currentList);
    }
    ref.invalidate(dashboardMetricsProvider);

    await Supabase.instance.client.from('equipment').delete().eq('id', id);

    try {
      final db = await DatabaseService().database;
      await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
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

    // 0ms optimistic UI update
    state = AsyncValue.data(updatedList);

    final user = AuthService().currentUser;
    if (user?.unitId != null) {
      await _persistLocalCache(user!.unitId!, updatedList);
    }

    ref.invalidate(dashboardMetricsProvider);

    // Sync to Supabase in background (preserves IMG: photo in expiration_date!)
    try {
      await Supabase.instance.client
          .from('equipment')
          .upsert(updatedItem.toSupabaseMap());
    } catch (_) {}

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
