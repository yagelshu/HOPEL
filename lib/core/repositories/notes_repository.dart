import 'package:chopel_app/core/database/database_service.dart';
import 'package:chopel_app/core/network/sync_engine.dart';
import 'package:chopel_app/core/models/note_model.dart';
import 'package:uuid/uuid.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class NotesRepository {
  Future<List<Note>> getNotesByUnit(String unitId, String currentUserId) async {
    final sb = Supabase.instance.client;
    final response = await sb
        .from('notes')
        .select()
        .eq('unit_id', unitId)
        .order('created_at', ascending: false);
        
    // Apply is_private logic: return note if it's not private OR if user_id matches
    final filtered = response.where((map) {
      final isPrivate = map['is_private'] == true || map['is_private'] == 1;
      return !isPrivate || map['user_id'] == currentUserId;
    }).toList();
    
    return filtered.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> addNote(Note note) async {
    final map = note.toMap();
    
    // Convert boolean is_private for Supabase
    final payload = Map<String, dynamic>.from(map);
    payload['is_private'] = note.isPrivate;

    await Supabase.instance.client.from('notes').insert(payload);
  }

  Future<void> updateNote(Note note) async {
    final map = note.toMap();
    final payload = Map<String, dynamic>.from(map);
    payload['is_private'] = note.isPrivate;

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
