import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowUpReminder {
  final String id;
  final String caseId;
  final String soldierId;
  final String soldierName;
  final String type; // 'מדידת חום חוזרת', 'בדיקת לחץ דם ומדדים', 'מנת תרופה הבאה', 'מעקב חבישה/פצע'
  final DateTime dueTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? measuredValue;
  final String? notes;

  const FollowUpReminder({
    required this.id,
    required this.caseId,
    required this.soldierId,
    required this.soldierName,
    required this.type,
    required this.dueTime,
    this.isCompleted = false,
    this.completedAt,
    this.measuredValue,
    this.notes,
  });

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueTime);

  Map<String, dynamic> toMap() => {
        'id': id,
        'case_id': caseId,
        'soldier_id': soldierId,
        'soldier_name': soldierName,
        'type': type,
        'due_time': dueTime.toIso8601String(),
        'is_completed': isCompleted,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        if (measuredValue != null) 'measured_value': measuredValue,
        if (notes != null) 'notes': notes,
      };

  factory FollowUpReminder.fromMap(Map<String, dynamic> map) => FollowUpReminder(
        id: map['id']?.toString() ?? '',
        caseId: map['case_id']?.toString() ?? '',
        soldierId: map['soldier_id']?.toString() ?? '',
        soldierName: map['soldier_name']?.toString() ?? 'חייל',
        type: map['type']?.toString() ?? 'מעקב שגרתי',
        dueTime: DateTime.tryParse(map['due_time']?.toString() ?? '') ?? DateTime.now(),
        isCompleted: map['is_completed'] == true,
        completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? ''),
        measuredValue: map['measured_value']?.toString(),
        notes: map['notes']?.toString(),
      );

  FollowUpReminder copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    String? measuredValue,
    String? notes,
  }) =>
      FollowUpReminder(
        id: id,
        caseId: caseId,
        soldierId: soldierId,
        soldierName: soldierName,
        type: type,
        dueTime: dueTime,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        measuredValue: measuredValue ?? this.measuredValue,
        notes: notes ?? this.notes,
      );
}

class FollowUpReminderService {
  static const _storageKey = 'follow_up_reminders_v1';
  static final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  static Future<List<FollowUpReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      final reminders = list.map((m) => FollowUpReminder.fromMap(m as Map<String, dynamic>)).toList();
      reminders.sort((a, b) => a.dueTime.compareTo(b.dueTime));
      return reminders;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveReminders(List<FollowUpReminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    pendingCountNotifier.value = list.where((r) => !r.isCompleted).length;
  }

  static Future<void> addReminder(FollowUpReminder reminder) async {
    final current = await getReminders();
    final updated = List<FollowUpReminder>.from(current)..add(reminder);
    await _saveReminders(updated);
  }

  static Future<void> completeReminder(String id, {String? measuredValue}) async {
    final current = await getReminders();
    final updated = current.map((r) {
      if (r.id == id) {
        return r.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
          measuredValue: measuredValue,
        );
      }
      return r;
    }).toList();
    await _saveReminders(updated);
  }

  static Future<void> deleteReminder(String id) async {
    final current = await getReminders();
    final updated = current.where((r) => r.id != id).toList();
    await _saveReminders(updated);
  }

  static Future<List<FollowUpReminder>> getPendingReminders() async {
    final all = await getReminders();
    return all.where((r) => !r.isCompleted).toList();
  }

  static Future<List<FollowUpReminder>> getRemindersForCase(String caseId) async {
    final all = await getReminders();
    return all.where((r) => r.caseId == caseId).toList();
  }

  static Future<List<FollowUpReminder>> getRemindersForSoldier(String soldierId) async {
    final all = await getReminders();
    return all.where((r) => r.soldierId == soldierId).toList();
  }
}

