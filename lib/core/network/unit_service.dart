import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/database/database_service.dart';

class UnitService {
  final _supabase = Supabase.instance.client;

  Future<bool> createUnit(String name) async {
    final user = AuthService().currentUser;
    if (user == null) return false;

    try {
      final unitId = const Uuid().v4();
      final joinCode = const Uuid().v4().substring(0, 6).toUpperCase();
      
      // Before syncing, wipe old local data if any, so the user starts fresh
      // Before syncing, wipe old local data if any, so the user starts fresh
      // Removed legacy SQLite clear
      
      // 1. Create Unit
      await _supabase.from('units').insert({
        'id': unitId,
        'name': name,
        'join_code': joinCode,
      });

      // 1.5. Create Default Deployment
      final deploymentId = const Uuid().v4();
      await _supabase.from('deployments').insert({
        'id': deploymentId,
        'name': 'תעסוקה ראשונית',
        'start_date': DateTime.now().toIso8601String(),
        'unit_id': unitId,
        'is_active': true,
      });

      // 2. Update User Role and Unit and Deployment
      await _supabase.from('users').update({
        'role': 'COMPANY_MEDIC',
        'unit_id': unitId,
        'active_deployment_id': deploymentId,
      }).eq('id', user.id);
      
      // 3. Seed default equipment from catalog
      final catalog = await _supabase.from('equipment_catalog').select();
      final List<Map<String, dynamic>> equipmentToInsert = catalog.map((item) {
        return {
          'id': const Uuid().v4(),
          'name': item['name'],
          'quantity': item['minimum_required'], // Starts fully stocked
          'minimum_required': item['minimum_required'],
          'status': 'IN_STOCK', // Fully stocked
          'category': item['category'],
          'item_type': item['item_type'],
          'unit_id': unitId,
        };
      }).toList();
      
      if (equipmentToInsert.isNotEmpty) {
        await _supabase.from('equipment').insert(equipmentToInsert);
      }
      
      // Reload profile
      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(unitId, name, joinCode);
      return true;
    } catch (e) {
      print('Error creating unit: $e');
      throw Exception('שגיאה מהשרת: $e');
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

      // Update user
      await _supabase.from('users').update({
        'role': 'COMBAT_MEDIC',
        'unit_id': unitId,
        'active_deployment_id': activeDeploymentId,
      }).eq('id', user.id);
      
      await AuthService().loadProfile();
      AuthService().updateCurrentUserUnit(unitId, response['name'] as String, response['join_code'] as String);
      return true;
    } catch (e) {
      print('Error joining unit: $e');
      return false;
    }
  }
}
