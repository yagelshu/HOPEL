import 'dart:convert';
import 'package:chopel_app/core/models/note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesFetchResult {
  final List<Note> notes;
  final bool isFromCache;

  const NotesFetchResult({
    required this.notes,
    required this.isFromCache,
  });
}

class NotesRepository {
  static String _cacheKey(String unitId, String userId) => 'cached_notes_${unitId}_$userId';

  Future<NotesFetchResult> fetchNotes(String unitId, String currentUserId) async {
    try {
      final sb = Supabase.instance.client;
      final response = await sb
          .from('notes')
          .select()
          .eq('unit_id', unitId)
          .order('created_at', ascending: false);

      final filtered = response.where((map) {
        final isPrivate = map['is_private'] == true || map['is_private'] == 1;
        return !isPrivate || map['user_id'] == currentUserId;
      }).toList();

      final notes = filtered.map((map) => Note.fromMap(map)).toList();
      await saveCachedNotes(unitId, currentUserId, notes);
      return NotesFetchResult(notes: notes, isFromCache: false);
    } catch (_) {
      final cached = await getCachedNotes(unitId, currentUserId);
      return NotesFetchResult(notes: cached, isFromCache: true);
    }
  }

  Future<List<Note>> getNotesByUnit(String unitId, String currentUserId) async {
    final res = await fetchNotes(unitId, currentUserId);
    return res.notes;
  }

  Future<void> saveCachedNotes(String unitId, String currentUserId, List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(notes.map((n) => n.toMap()).toList());
      await prefs.setString(_cacheKey(unitId, currentUserId), encoded);
    } catch (_) {}
  }

  Future<List<Note>> getCachedNotes(String unitId, String currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(unitId, currentUserId));
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Note.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addNote(Note note) async {
    final payload = <String, dynamic>{
      'id': note.id,
      'unit_id': note.unitId,
      'user_id': note.userId,
      'content': note.content,
      'is_private': note.isPrivate,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };

    await Supabase.instance.client.from('notes').insert(payload);
  }

  Future<void> updateNote(Note note) async {
    final payload = <String, dynamic>{
      'content': note.content,
      'is_private': note.isPrivate,
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };

    await Supabase.instance.client
        .from('notes')
        .update(payload)
        .eq('id', note.id);
  }

  Future<void> deleteNote(String noteId) async {
    await Supabase.instance.client
        .from('notes')
        .delete()
        .eq('id', noteId);
  }
}
