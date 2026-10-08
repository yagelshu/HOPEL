// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:convert';
import 'database_repository.dart';
import 'mock_database_repository.dart';

Future<DatabaseRepository> getPlatformDatabase() async {
  final repo = MockDatabaseRepository();
  
  final savedState = html.window.localStorage['hopal_mock_db_v2'];
  if (savedState != null) {
    try {
      Map<String, dynamic> decoded = jsonDecode(savedState);
      repo.data = decoded.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)));
      
      // Auto-fix for previously wiped equipment
      if (repo.data['equipment'] == null || repo.data['equipment']!.isEmpty) {
        final tempRepo = MockDatabaseRepository();
        await tempRepo.seed();
        repo.data['equipment'] = tempRepo.data['equipment']!;
        repo.data['learning_content'] = tempRepo.data['learning_content']!;
      }
    } catch (e) {
      await repo.seed();
    }
  } else {
    await repo.seed();
  }
  
  repo.onDataChanged = () {
    html.window.localStorage['hopal_mock_db_v2'] = jsonEncode(repo.data);
  };
  
  return repo;
}
