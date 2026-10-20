import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StandbyMedicsService {
  static String _key(String? unitId) => 'manual_standby_medics_${unitId ?? "default"}';

  /// Get all persisted manual standby medics
  static Future<List<Map<String, dynamic>>> getManualMedics(String? unitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_key(unitId));
      if (str == null || str.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save or update a manual standby medic locally and best-effort to Supabase
  static Future<void> saveManualMedic(String? unitId, Map<String, dynamic> medic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getManualMedics(unitId);
      final index = list.indexWhere((m) => m['id'] == medic['id']);
      if (index != -1) {
        list[index] = medic;
      } else {
        list.add(medic);
      }
      await prefs.setString(_key(unitId), jsonEncode(list));
    } catch (_) {}

    // Best-effort push to Supabase
    try {
      final payload = <String, dynamic>{
        'id': medic['id'],
        'name': medic['name'],
        'role': 'COMBAT_MEDIC',
        'is_on_standby': medic['standby'] == true,
        'is_manual': true,
      };
      if (unitId != null) payload['unit_id'] = unitId;
      if (medic['phone_number'] != null) payload['phone_number'] = medic['phone_number'];
      if (medic['platoon'] != null) payload['platoon'] = medic['platoon'];

      await Supabase.instance.client.from('users').upsert(payload);
    } catch (_) {
      // Supabase table may have constraint or be offline; local persistence already succeeded
    }
  }

  /// Update standby status for a manual medic
  static Future<void> updateStandby(String? unitId, String medicId, bool isStandby) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getManualMedics(unitId);
      final index = list.indexWhere((m) => m['id'] == medicId);
      if (index != -1) {
        list[index]['standby'] = isStandby;
        await prefs.setString(_key(unitId), jsonEncode(list));
      }
    } catch (_) {}

    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_on_standby': isStandby})
          .eq('id', medicId);
    } catch (_) {}
  }

  /// Remove a manual medic
  static Future<void> removeManualMedic(String? unitId, String medicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await getManualMedics(unitId);
      list.removeWhere((m) => m['id'] == medicId);
      await prefs.setString(_key(unitId), jsonEncode(list));
    } catch (_) {}

    try {
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', medicId);
    } catch (_) {}
  }
}
