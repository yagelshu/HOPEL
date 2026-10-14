import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:chopel_app/core/data/local_store.dart';
import 'package:chopel_app/core/data/remote_source.dart';
import 'package:chopel_app/core/data/sync_errors.dart';

/// Describes a synced table and how it is partitioned locally.
class TableSpec {
  final String table;

  /// Column used to scope the local cache (e.g. unit_id). Rows are fetched
  /// with `.eq(scopeColumn, scopeValue)`.
  final String scopeColumn;
  final String? orderBy;
  final bool ascending;

  const TableSpec(this.table, {required this.scopeColumn, this.orderBy, this.ascending = false});
}

/// A local change waiting to reach the server.
class PendingOp {
  final String id;
  final String table;
  final String kind; // 'upsert' | 'delete'
  final String scopeColumn;
  final List<Map<String, dynamic>> rows;
  final String? rowId;
  final String? scopeValue;
  final String createdAt;
  bool failed;
  String? error;

  PendingOp({
    required this.id,
    required this.table,
    required this.kind,
    required this.scopeColumn,
    this.rows = const [],
    this.rowId,
    this.scopeValue,
    required this.createdAt,
    this.failed = false,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'kind': kind,
        'scopeColumn': scopeColumn,
        'rows': rows,
        'rowId': rowId,
        'scopeValue': scopeValue,
        'createdAt': createdAt,
        'failed': failed,
        'error': error,
      };

  factory PendingOp.fromJson(Map<String, dynamic> j) => PendingOp(
        id: j['id'] as String,
        table: j['table'] as String,
        kind: j['kind'] as String,
        scopeColumn: j['scopeColumn'] as String,
        rows: ((j['rows'] as List?) ?? const []).map((r) => Map<String, dynamic>.from(r as Map)).toList(),
        rowId: j['rowId'] as String?,
        scopeValue: j['scopeValue'] as String?,
        createdAt: j['createdAt'] as String,
        failed: j['failed'] == true,
        error: j['error'] as String?,
      );

  /// Short Hebrew description for the sync status sheet.
  String get label {
    const names = {'soldiers': 'חייל', 'medical_cases': 'פנייה רפואית', 'equipment': 'ציוד'};
    final what = names[table] ?? table;
    if (kind == 'delete') return 'מחיקת $what';
    return rows.length > 1 ? '${rows.length} רשומות $what' : 'שמירת $what';
  }
}

class SyncStatus {
  final bool online;
  final bool syncing;
  final int pending;
  final int failed;
  final DateTime? lastSync;

  const SyncStatus({
    this.online = true,
    this.syncing = false,
    this.pending = 0,
    this.failed = 0,
    this.lastSync,
  });

  bool get allSynced => pending == 0 && failed == 0;
}

enum SaveOutcome {
  /// Saved on the server.
  synced,

  /// Saved on the device; will be sent automatically when reception returns.
  queued,
}

enum _Result { ok, network, rejected }

/// Offline-capable data store:
///  * reads  = last server snapshot (per scope) + pending local changes on top
///  * writes = queued in a persistent outbox, sent in order, retried when
///             reception returns. Server rejections are surfaced, never lost.
class SyncStore {
  SyncStore({required this.remote, required this.local});

  final RemoteSource remote;
  final LocalStore local;

  static const _outboxKey = 'outbox_v1';
  static const _cachePrefix = 'cache_v1|';
  static const _legacyDraftsKey = 'offline_drafts';

  final _uuid = const Uuid();
  final _changes = StreamController<String>.broadcast();
  final _statusCtrl = StreamController<SyncStatus>.broadcast();

  List<PendingOp>? _ops;
  SyncStatus _status = const SyncStatus();
  Future<void> _lock = Future.value();
  Timer? _retryTimer;

  /// Emits a table name whenever local data for that table changed.
  Stream<String> get changes => _changes.stream;
  Stream<SyncStatus> get statusStream => _statusCtrl.stream;
  SyncStatus get status => _status;

  List<PendingOp> get pendingOps => List.unmodifiable(_ops ?? const []);

  // ---------------------------------------------------------------- setup

  Future<void> init() async {
    if (_ops != null) return;
    final raw = await local.read(_outboxKey);
    _ops = raw == null
        ? []
        : (jsonDecode(raw) as List).map((e) => PendingOp.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    await _migrateLegacyDrafts();
    _emitStatus();
  }

  /// Starts automatic retries. Call once after login.
  void startAutoSync({Duration every = const Duration(seconds: 30)}) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(every, (_) {
      if ((_ops ?? const []).any((o) => !o.failed)) flush();
    });
  }

  void dispose() {
    _retryTimer?.cancel();
    _changes.close();
    _statusCtrl.close();
  }

  /// Older app versions stored offline medical cases under 'offline_drafts'.
  /// Move them into the outbox so nothing is lost after upgrading.
  Future<void> _migrateLegacyDrafts() async {
    final raw = await local.read(_legacyDraftsKey);
    if (raw == null) return;
    try {
      final drafts = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (final d in drafts) {
        d['id'] ??= _uuid.v4();
        _ops!.add(PendingOp(
          id: _uuid.v4(),
          table: 'medical_cases',
          kind: 'upsert',
          scopeColumn: 'deployment_id',
          rows: [d],
          createdAt: DateTime.now().toIso8601String(),
        ));
      }
      await _saveOps();
    } catch (_) {
      // corrupt legacy data - nothing we can recover
    }
    await local.remove(_legacyDraftsKey);
  }

  // ---------------------------------------------------------------- reads

  String _cacheKey(String table, String scopeColumn, String scopeValue) =>
      '$_cachePrefix$table|$scopeColumn|$scopeValue';

  Future<List<Map<String, dynamic>>> _readSnapshot(String key) async {
    final raw = await local.read(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeSnapshot(String key, List<Map<String, dynamic>> rows) =>
      local.write(key, jsonEncode(rows));

  /// Data available on the device right now (works with no reception).
  Future<List<Map<String, dynamic>>> readLocal(TableSpec spec, String scopeValue) async {
    await init();
    final snapshot = await _readSnapshot(_cacheKey(spec.table, spec.scopeColumn, scopeValue));
    return _overlay(spec, scopeValue, snapshot);
  }

  /// Fresh data from the server (falls back to device data with no reception).
  /// Server-side errors (e.g. outdated schema) are rethrown so they are visible.
  Future<List<Map<String, dynamic>>> fetch(TableSpec spec, String scopeValue) async {
    await init();
    try {
      final rows = await remote.select(
        spec.table,
        eq: {spec.scopeColumn: scopeValue},
        orderBy: spec.orderBy,
        ascending: spec.ascending,
      );
      await _writeSnapshot(_cacheKey(spec.table, spec.scopeColumn, scopeValue), rows);
      _setOnline(true);
      return _overlay(spec, scopeValue, rows);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      _setOnline(false);
      return readLocal(spec, scopeValue);
    }
  }

  List<Map<String, dynamic>> _overlay(TableSpec spec, String scopeValue, List<Map<String, dynamic>> base) {
    final byId = <String, Map<String, dynamic>>{
      for (final r in base) r['id'].toString(): r,
    };
    for (final op in _ops!) {
      if (op.table != spec.table) continue;
      if (op.kind == 'delete') {
        byId.remove(op.rowId);
      } else {
        for (final r in op.rows) {
          if (r[spec.scopeColumn]?.toString() == scopeValue) {
            byId[r['id'].toString()] = {...?byId[r['id'].toString()], ...r};
          }
        }
      }
    }
    final result = byId.values.toList();
    final order = spec.orderBy;
    if (order != null) {
      result.sort((a, b) {
        final c = (a[order]?.toString() ?? '').compareTo(b[order]?.toString() ?? '');
        return spec.ascending ? c : -c;
      });
    }
    return result;
  }

  // ---------------------------------------------------------------- writes

  /// Save rows (insert or update by `id`). Every row must contain `id` and
  /// the spec's scope column.
  Future<SaveOutcome> upsert(TableSpec spec, List<Map<String, dynamic>> rows) {
    return _enqueueAndTry(PendingOp(
      id: _uuid.v4(),
      table: spec.table,
      kind: 'upsert',
      scopeColumn: spec.scopeColumn,
      rows: rows.map((r) => Map<String, dynamic>.from(r)).toList(),
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<SaveOutcome> delete(TableSpec spec, String id, {String? scopeValue}) {
    return _enqueueAndTry(PendingOp(
      id: _uuid.v4(),
      table: spec.table,
      kind: 'delete',
      scopeColumn: spec.scopeColumn,
      rowId: id,
      scopeValue: scopeValue,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<SaveOutcome> _enqueueAndTry(PendingOp op) async {
    await init();
    _ops!.add(op);
    await _saveOps();
    _changes.add(op.table);
    _emitStatus();

    final results = await flush();
    switch (results[op.id]) {
      case _Result.ok:
        return SaveOutcome.synced;
      case _Result.rejected:
        // User is looking at the screen right now - undo and tell them.
        final msg = op.error ?? 'השרת דחה את השמירה';
        _ops!.remove(op);
        await _saveOps();
        _changes.add(op.table);
        _emitStatus();
        throw SaveRejected(msg);
      default:
        return SaveOutcome.queued;
    }
  }

  // ---------------------------------------------------------------- sync

  /// Sends pending changes in order. Safe to call any time, from anywhere.
  Future<Map<String, _Result>> flush() {
    final completer = Completer<Map<String, _Result>>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await _doFlush());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<Map<String, _Result>> _doFlush() async {
    await init();
    final results = <String, _Result>{};
    final queue = _ops!.where((o) => !o.failed).toList();
    if (queue.isEmpty) return results;

    _status = _copyStatus(syncing: true);
    _emitStatus();
    final touched = <String>{};

    for (final op in queue) {
      try {
        if (op.kind == 'upsert') {
          await remote.upsert(op.table, op.rows);
        } else {
          await remote.delete(op.table, op.rowId!);
        }
        _ops!.remove(op);
        await _saveOps();
        await _applyToSnapshot(op);
        results[op.id] = _Result.ok;
        touched.add(op.table);
        _setOnline(true, emit: false);
      } catch (e) {
        if (isNetworkError(e)) {
          results[op.id] = _Result.network;
          _setOnline(false, emit: false);
          break; // keep order: stop here, retry later
        }
        op.failed = true;
        op.error = describeServerError(e);
        await _saveOps();
        results[op.id] = _Result.rejected;
        touched.add(op.table);
      }
    }

    final allSent = !_ops!.any((o) => !o.failed);
    _status = _copyStatus(syncing: false, lastSync: allSent ? DateTime.now() : _status.lastSync);
    _emitStatus();
    for (final t in touched) {
      _changes.add(t);
    }
    return results;
  }

  /// After the server accepted a change, fold it into the cached snapshot so
  /// the row stays visible until the next fetch.
  Future<void> _applyToSnapshot(PendingOp op) async {
    if (op.kind == 'upsert') {
      final byScope = <String, List<Map<String, dynamic>>>{};
      for (final r in op.rows) {
        final sv = r[op.scopeColumn]?.toString();
        if (sv != null) byScope.putIfAbsent(sv, () => []).add(r);
      }
      for (final entry in byScope.entries) {
        final key = _cacheKey(op.table, op.scopeColumn, entry.key);
        final snap = await _readSnapshot(key);
        final byId = {for (final r in snap) r['id'].toString(): r};
        for (final r in entry.value) {
          byId[r['id'].toString()] = {...?byId[r['id'].toString()], ...r};
        }
        await _writeSnapshot(key, byId.values.toList());
      }
    } else if (op.scopeValue != null) {
      final key = _cacheKey(op.table, op.scopeColumn, op.scopeValue!);
      final snap = await _readSnapshot(key);
      snap.removeWhere((r) => r['id'].toString() == op.rowId);
      await _writeSnapshot(key, snap);
    }
  }

  /// Re-queue all failed changes (e.g. after fixing the DB schema).
  Future<void> retryFailed() async {
    await init();
    for (final op in _ops!) {
      op.failed = false;
      op.error = null;
    }
    await _saveOps();
    _emitStatus();
    await flush();
  }

  /// Permanently drop a failed change.
  Future<void> discard(String opId) async {
    await init();
    final op = _ops!.where((o) => o.id == opId).firstOrNull;
    _ops!.removeWhere((o) => o.id == opId);
    await _saveOps();
    if (op != null) _changes.add(op.table);
    _emitStatus();
  }

  /// Wipes cached data and the outbox (logout).
  Future<void> clearAll() async {
    await init();
    _ops!.clear();
    await local.remove(_outboxKey);
    await local.removeByPrefix(_cachePrefix);
    _status = const SyncStatus();
    _emitStatus();
  }

  // ---------------------------------------------------------------- helpers

  Future<void> _saveOps() => local.write(_outboxKey, jsonEncode(_ops!.map((o) => o.toJson()).toList()));

  void _setOnline(bool online, {bool emit = true}) {
    if (_status.online == online) return;
    _status = _copyStatus(online: online);
    if (emit) _emitStatus();
  }

  SyncStatus _copyStatus({bool? online, bool? syncing, DateTime? lastSync}) {
    final ops = _ops ?? const <PendingOp>[];
    return SyncStatus(
      online: online ?? _status.online,
      syncing: syncing ?? _status.syncing,
      pending: ops.where((o) => !o.failed).length,
      failed: ops.where((o) => o.failed).length,
      lastSync: lastSync ?? _status.lastSync,
    );
  }

  void _emitStatus() {
    _status = _copyStatus();
    if (!_statusCtrl.isClosed) _statusCtrl.add(_status);
  }
}
