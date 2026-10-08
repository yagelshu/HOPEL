import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/models/equipment.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final equipmentDatabaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

class EquipmentNotifier extends AsyncNotifier<List<Equipment>> {
  @override
  FutureOr<List<Equipment>> build() async {
    return _loadEquipment();
  }

  Future<List<Equipment>> _loadEquipment() async {
    final user = AuthService().currentUser;
    if (user?.unitId == null) return [];
    
    final response = await Supabase.instance.client
        .from('equipment')
        .select()
        .eq('unit_id', user!.unitId!);
        
    return response.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadEquipment());
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
