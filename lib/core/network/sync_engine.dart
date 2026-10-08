import 'dart:convert';
import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncEngine {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;

  SyncEngine._internal();

  /// Queues a local mutation to be synced to the server later.
  /// Also logs the action to `audit_logs` for conflict resolution.
  Future<void> queueMutation({
    required String entityType,
    required String action, // INSERT, UPDATE, DELETE
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseService().database;
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    final userId = AuthService().currentUser?.id ?? 'SYSTEM';

    // Ensure updated timestamp is injected for Last-Write-Wins
    if (action == 'UPDATE' || action == 'INSERT') {
      if (entityType == 'medical_cases') {
        payload['updated_date'] = now;
      }
    }

    await db.transaction((txn) async {
      // 1. Write the history audit log (Data Loss Prevention / History Preservation)
      await txn.insert('audit_logs', {
        'id': uuid.v4(),
        'user_id': userId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'timestamp': now,
      });

      // 2. Queue the actual mutation for the sync worker
      await txn.insert('sync_queue', {
        'id': uuid.v4(),
        'entity_type': entityType,
        'action': action,
        'payload': jsonEncode(payload),
        'created_at': now,
      });

      // 3. Update the local entity directly for instant UI feedback
      if (action == 'INSERT') {
        try {
          await txn.insert(entityType, payload);
        } catch (e) {
          await txn.update(
            entityType,
            payload,
            where: 'id = ?',
            whereArgs: [entityId],
          );
        }
      } else if (action == 'UPDATE') {
        await txn.update(
          entityType,
          payload,
          where: 'id = ?',
          whereArgs: [entityId],
        );
      } else if (action == 'DELETE') {
        await txn.delete(
          entityType,
          where: 'id = ?',
          whereArgs: [entityId],
        );
      }
    });
  }

  Future<void> runSyncWorker() async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> queue = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );

    if (queue.isEmpty) return;
    final supa = Supabase.instance.client;

    for (var item in queue) {
      try {
        final entityType = item['entity_type'] as String;
        final action = item['action'] as String;
        final payload = jsonDecode(item['payload'] as String);

        if (action == 'INSERT') {
          await supa.from(entityType).insert(payload);
        } else if (action == 'UPDATE') {
          await supa.from(entityType).update(payload).eq('id', payload['id']);
        } else if (action == 'DELETE') {
          final payloadData = payload as Map<String, dynamic>;
          await supa.from(entityType).delete().eq('id', payloadData['id']);
        }

        // Remove from local queue if successful
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (e) {
        print("Failed to sync item to Supabase: $e");
        // Keep in queue for next retry
      }
    }
  }

  Future<void> fetchFromCloud(String entityType, {String? unitId}) async {
    final supa = Supabase.instance.client;
    final db = await DatabaseService().database;
    
    try {
      var query = supa.from(entityType).select();
      
      // If fetching unit-specific data, filter by unitId to avoid downloading the entire database
      if (unitId != null && (entityType == 'users' || entityType == 'medical_cases' || entityType == 'equipment' || entityType == 'soldiers')) {
        query = query.eq('unit_id', unitId);
      }
      
      final data = await query;
      
      await db.transaction((txn) async {
        for (var row in data) {
          // Convert bool to int for SQLite
          final safeRow = Map<String, dynamic>.from(row);
          safeRow.forEach((key, value) {
            if (value is bool) {
              safeRow[key] = value ? 1 : 0;
            }
          });

          try {
            await txn.insert(entityType, safeRow);
          } catch (e) {
            await txn.update(
              entityType,
              safeRow,
              where: 'id = ?',
              whereArgs: [safeRow['id']],
            );
          }
        }
      });
    } catch (e) {
      print("Failed to fetch $entityType from Supabase: $e");
    }
  }
}
