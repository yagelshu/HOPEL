import 'package:sqflite/sqflite.dart';
import 'database_repository.dart';

class SqliteDatabaseRepository implements DatabaseRepository {
  final DatabaseExecutor _db;

  SqliteDatabaseRepository(this._db);

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) {
    return _db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) {
    return _db.rawQuery(sql, arguments);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) {
    return _db.insert(table, values);
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs}) {
    return _db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> clear() async {
    final tables = [
      'units',
      'users',
      'soldiers',
      'medical_cases',
      'equipment',
      'equipment_assignments',
      'audit_logs',
      'sync_queue',
      'deployments',
      'notes',
      'daily_schedule'
    ];
    for (final table in tables) {
      try {
        await _db.delete(table);
      } catch (_) {
        // Table might not exist yet
      }
    }
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseRepository txn) action) async {
    if (_db is Database) {
      return await (_db as Database).transaction((txn) async {
        return await action(SqliteDatabaseRepository(txn));
      });
    } else {
      return await action(this);
    }
  }
}
