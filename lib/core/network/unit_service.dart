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
        final existingUserRow = await _supabase
            .from('users')
            .select('id, unit_id')
            .eq('id', user.id)
            .maybeSingle();
        if (existingUserRow == null) {
          await _supabase.from('users').insert({
            'id': user.id,
            'name': user.name,
            'role': user.role,
            'unit_id': unitId,
            'active_deployment_id': user.activeDeploymentId,
          });
        } else if (existingUserRow['unit_id'] != unitId) {
          await _supabase
              .from('users')
              .update({'unit_id': unitId})
              .eq('id', user.id);
        }
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

      AuthService().updateCurrentUserUnit(unitId, name, joinCode, role: 'COMPANY_MEDIC');
      AuthService().updateCurrentUserDeployment(null, null);

      // 3. Seed default equipment (catalog or built-in IDF standard)
      try {
        await seedUnitEquipment(unitId);
      } catch (seedErr) {
        debugPrint('Equipment seed warning (will retry on screen open): $seedErr');
      }

      // Reload profile
      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(unitId, name, joinCode, role: 'COMPANY_MEDIC');
      AuthService().updateCurrentUserDeployment(null, null);
      return true;
    } catch (e) {
      debugPrint('Error creating unit: $e');
      rethrow;
    }
  }

  Future<bool> joinUnit(
    String code, {
    String? platoon,
    String? phoneNumber,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) return false;

    try {
      final cleanCode = code.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
      final response = await _supabase
          .from('units')
          .select()
          .eq('join_code', cleanCode)
          .maybeSingle();

      if (response == null) {
        return false; // Code not found
      }

      final unitId = response['id'] as String;

      // Get active deployment of the unit
      final activeDeploymentRes = await _supabase
          .from('deployments')
          .select('id, name')
          .eq('unit_id', unitId)
          .eq('is_active', true)
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      String? activeDeploymentId = activeDeploymentRes?['id']?.toString();
      String? activeDeploymentName = activeDeploymentRes?['name']?.toString();

      // Fallback: check the unit's COMPANY_MEDIC active_deployment_id if no active deployment row matched
      if (activeDeploymentId == null || activeDeploymentId.isEmpty) {
        try {
          final chiefRow = await _supabase
              .from('users')
              .select('active_deployment_id')
              .eq('unit_id', unitId)
              .eq('role', 'COMPANY_MEDIC')
              .limit(1)
              .maybeSingle();
          activeDeploymentId = chiefRow?['active_deployment_id']?.toString();
        } catch (_) {}
      }

      final cleanPlatoon = (platoon != null && platoon.trim().isNotEmpty) ? platoon.trim() : user.platoon;
      final cleanPhone = (phoneNumber != null && phoneNumber.trim().isNotEmpty) ? phoneNumber.trim() : user.phoneNumber;

      // Upsert user so missing profile rows are created cleanly
      try {
        await _supabase.from('users').upsert({
          'id': user.id,
          'name': user.name,
          'role': 'COMBAT_MEDIC',
          'unit_id': unitId,
          'active_deployment_id': activeDeploymentId,
          'is_on_standby': true,
          if (cleanPlatoon != null) 'platoon': cleanPlatoon,
          if (cleanPhone != null) 'phone_number': cleanPhone,
        });
      } on PostgrestException catch (_) {
        await _supabase.from('users').upsert({
          'id': user.id,
          'name': user.name,
          'role': 'COMBAT_MEDIC',
          'unit_id': unitId,
          'active_deployment_id': activeDeploymentId,
        });
      }

      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(
        unitId,
        response['name'] as String,
        response['join_code'] as String,
        role: 'COMBAT_MEDIC',
      );
      if (activeDeploymentId != null) {
        AuthService().updateCurrentUserDeployment(activeDeploymentId, activeDeploymentName);
      }
      return true;
    } catch (e) {
      debugPrint('Error joining unit: $e');
      return false;
    }
  }
}
