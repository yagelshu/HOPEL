import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DraftService {
  static const _key = 'offline_drafts';

  static Future<void> saveDraft(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final draftsStr = prefs.getString(_key);
    List<dynamic> drafts = draftsStr != null ? jsonDecode(draftsStr) : [];
    drafts.add(payload);
    await prefs.setString(_key, jsonEncode(drafts));
  }

  static Future<List<Map<String, dynamic>>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsStr = prefs.getString(_key);
    if (draftsStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(draftsStr);
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> clearDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
  
  static Future<bool> hasDrafts() async {
    final drafts = await getDrafts();
    return drafts.isNotEmpty;
  }
  
  static Future<int> syncDrafts() async {
    final drafts = await getDrafts();
    if (drafts.isEmpty) return 0;
    
    int successCount = 0;
    final List<Map<String, dynamic>> remainingDrafts = [];
    
    for (final draft in drafts) {
      try {
        await Supabase.instance.client.from('medical_cases').insert(draft);
        successCount++;
      } catch (e) {
        remainingDrafts.add(draft); // Keep it if it fails
      }
    }
    
    if (remainingDrafts.isEmpty) {
      await clearDrafts();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(remainingDrafts));
    }
    
    return successCount;
  }
}
