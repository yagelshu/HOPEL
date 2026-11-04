import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/utils/default_equipment_catalog.dart';

class UnitService {
  final _supabase = Supabase.instance.client;

  /// Seeds the 50-item IDF standard equipment list for [unitId] in Supabase.
  /// Tries `equipment_catalog` first, falling back to [DefaultEquipmentCatalog].
  Future<List<Map<String, dynamic>>> seedUnitEquipment(String unitId) async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await _supabase.from('users').upsert({
          'id': user.id,
          'name': user.name,
          'role': user.role,
          'unit_id': unitId,
          'active_deployment_id': user.activeDeploymentId,
        });
      } catch (_) {}
    }

    List<Map<String, dynamic>> catalog = [];
    try {
      final res = await _supabase.from('equipment_catalog').select();
      catalog = List<Map<String, dynamic>>.from(res);
    } catch (_) {}

    final equipmentToInsert = DefaultEquipmentCatalog.buildRowsForUnit(
      unitId,
      catalogSource: catalog,
    );

    if (equipmentToInsert.isNotEmpty) {
      await _supabase.from('equipment').insert(equipmentToInsert);
    }
    return equipmentToInsert;
  }

  Future<bool> createUnit(String name) async {
    final user = AuthService().currentUser;
    if (user == null) return false;

    try {
      final unitId = const Uuid().v4();
      final joinCode = const Uuid().v4().substring(0, 6).toUpperCase();

      // 1. Create Unit
      await _supabase.from('units').insert({
        'id': unitId,
        'name': name,
        'join_code': joinCode,
      });

      // 2. Upsert User Role and Unit (deployment will be named on the next screen)
      await _supabase.from('users').upsert({
        'id': user.id,
        'name': user.name,
        'role': 'COMPANY_MEDIC',
        'unit_id': unitId,
        'active_deployment_id': null,
      });

      // 3. Seed default equipment (catalog or built-in IDF standard)
      try {
        await seedUnitEquipment(unitId);
      } catch (seedErr) {
        debugPrint('Equipment seed warning (will retry on screen open): $seedErr');
      }

      // Reload profile
      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(unitId, name, joinCode);
      AuthService().updateCurrentUserDeployment(null, null);
      return true;
    } catch (e) {
      debugPrint('Error creating unit: $e');
      rethrow;
    }
  }

  Future<bool> joinUnit(String code) async {
    final user = AuthService().currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('join_code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        return false; // Code not found
      }

      final unitId = response['id'];

      // Get active deployment of the unit
      final activeDeploymentRes = await _supabase
          .from('deployments')
          .select('id')
          .eq('unit_id', unitId)
          .eq('is_active', true)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      final activeDeploymentId = activeDeploymentRes?['id'];

      // Upsert user so missing profile rows are created cleanly
      await _supabase.from('users').upsert({
        'id': user.id,
        'name': user.name,
        'role': 'COMBAT_MEDIC',
        'unit_id': unitId,
        'active_deployment_id': activeDeploymentId,
      });

      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(
        unitId,
        response['name'] as String,
        response['join_code'] as String,
      );
      return true;
    } catch (e) {
      debugPrint('Error joining unit: $e');
      return false;
    }
  }
}
