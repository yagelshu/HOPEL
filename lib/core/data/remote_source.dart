import 'package:supabase_flutter/supabase_flutter.dart';

/// The only place in the app that talks to the database for synced tables.
/// Abstracted so tests can swap in an in-memory fake.
abstract class RemoteSource {
  Future<List<Map<String, dynamic>>> select(
    String table, {
    required Map<String, Object> eq,
    String? orderBy,
    bool ascending = false,
  });

  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  Future<void> delete(String table, String id);
}

class SupabaseRemoteSource implements RemoteSource {
  static const _timeout = Duration(seconds: 12);
  static const _chunk = 200;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    required Map<String, Object> eq,
    String? orderBy,
    bool ascending = false,
  }) async {
    var query = _client.from(table).select();
    eq.forEach((col, val) => query = query.eq(col, val));
    final List<Map<String, dynamic>> rows = orderBy == null
        ? await query.timeout(_timeout)
        : await query.order(orderBy, ascending: ascending).timeout(_timeout);
    return rows;
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    for (var i = 0; i < rows.length; i += _chunk) {
      final part = rows.sublist(i, (i + _chunk).clamp(0, rows.length));
      await _client.from(table).upsert(part).timeout(_timeout);
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    await _client.from(table).delete().eq('id', id).timeout(_timeout);
  }
}
