abstract class DatabaseRepository {
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy});
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]);
  Future<int> insert(String table, Map<String, Object?> values);
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs});
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});
  Future<void> clear();
  Future<T> transaction<T>(Future<T> Function(DatabaseRepository txn) action);
}
