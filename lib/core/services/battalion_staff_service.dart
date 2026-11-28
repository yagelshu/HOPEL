import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chopel_app/core/auth/auth_service.dart';
import 'package:chopel_app/core/services/follow_up_reminder_service.dart';
import 'package:chopel_app/core/utils/platoon_helper.dart';
import 'package:chopel_app/models/medical_case.dart';
import 'package:chopel_app/models/soldier.dart';

class StaffContact {
  final String id;
  final String name;
  final String phone;
  /// 'רופא' | 'פראמדיק' for matab; 'חוג"ד' | 'מחליף חוג"ד' for hogad
  final String role;
  /// 'matab' | 'hogad'
  final String group;
  final bool isOnDuty;
  final DateTime updatedAt;

  StaffContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.group,
    this.isOnDuty = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  StaffContact copyWith({
    String? name,
    String? phone,
    String? role,
    String? group,
    bool? isOnDuty,
    DateTime? updatedAt,
  }) {
    return StaffContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      group: group ?? this.group,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'group': group,
        'is_on_duty': isOnDuty,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StaffContact.fromMap(Map<String, dynamic> map) {
    return StaffContact(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? (map['group'] == 'hogad' ? 'חוג"ד' : 'רופא'),
      group: map['group']?.toString() ?? 'matab',
      isOnDuty: map['is_on_duty'] == true,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get displayLabel {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '$role ($phone)';
    return '$trimmedName ($role)';
  }
}

class BattalionStaffService {
  static const String storageKey = 'battalion_staff_contacts_v1';
  static const String cloudConfigPrefix = '__HOPEL_UNIT_CONFIG_V1__:';

  static const String groupMatab = 'matab';
  static const String groupHogad = 'hogad';

  static const List<String> matabRoles = ['רופא', 'פראמדיק'];
  static const List<String> hogadRoles = ['חוג"ד', 'מחליף חוג"ד'];

  /// Loads all staff contacts, migrating legacy single-contact preferences if needed.
  static Future<List<StaffContact>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    List<StaffContact> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded
            .map((e) => StaffContact.fromMap(Map<String, dynamic>.from(e as Map)))
            .where((c) => c.phone.trim().isNotEmpty)
            .toList();
      } catch (_) {}
    }

    bool migrated = false;

    // Migrate legacy doctor_phone_number if no matab contacts exist yet
    if (!list.any((c) => c.group == groupMatab)) {
      final legacyDocPhone = prefs.getString('doctor_phone_number')?.trim() ?? '';
      final legacyDocName = prefs.getString('doctor_name')?.trim() ?? '';
      if (legacyDocPhone.isNotEmpty) {
        list.add(
          StaffContact(
            id: 'legacy_matab_primary',
            name: legacyDocName,
            phone: legacyDocPhone,
            role: 'רופא',
            group: groupMatab,
            isOnDuty: true,
          ),
        );
        migrated = true;
      }
    }

    // Migrate legacy hogad_phone_number if no hogad contacts exist yet
    if (!list.any((c) => c.group == groupHogad)) {
      final legacyHogadPhone = prefs.getString('hogad_phone_number')?.trim() ?? '';
      final legacyHogadName = prefs.getString('hogad_name')?.trim() ?? '';
      if (legacyHogadPhone.isNotEmpty) {
        list.add(
          StaffContact(
            id: 'legacy_hogad_primary',
            name: legacyHogadName,
            phone: legacyHogadPhone,
            role: 'חוג"ד',
            group: groupHogad,
            isOnDuty: true,
          ),
        );
        migrated = true;
      }
    }

    if (migrated) {
      await _saveAllInternal(prefs, list, syncToCloud: false);
    }

    return list;
  }

  static Future<List<StaffContact>> loadGroup(String group) async {
    final all = await loadAll();
    final filtered = all.where((c) => c.group == group).toList();
    // Sort so on-duty comes first
    filtered.sort((a, b) {
      if (a.isOnDuty && !b.isOnDuty) return -1;
      if (!a.isOnDuty && b.isOnDuty) return 1;
      return a.name.compareTo(b.name);
    });
    return filtered;
  }

  static Future<StaffContact?> getActiveContact(String group) async {
    final groupList = await loadGroup(group);
    if (groupList.isEmpty) return null;
    return groupList.where((c) => c.isOnDuty).firstOrNull ?? groupList.first;
  }

  static Future<void> upsertContact(StaffContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();

    // If this contact is marked on-duty, or is the first in its group, handle on-duty flags
    final groupPeers = all.where((c) => c.group == contact.group && c.id != contact.id).toList();
    final shouldBeOnDuty = contact.isOnDuty || groupPeers.isEmpty || !groupPeers.any((c) => c.isOnDuty);

    final updated = <StaffContact>[];
    bool found = false;

    for (final existing in all) {
      if (existing.id == contact.id) {
        updated.add(contact.copyWith(isOnDuty: shouldBeOnDuty, updatedAt: DateTime.now()));
        found = true;
      } else if (existing.group == contact.group && shouldBeOnDuty) {
        updated.add(existing.copyWith(isOnDuty: false));
      } else {
        updated.add(existing);
      }
    }

    if (!found) {
      updated.add(contact.copyWith(isOnDuty: shouldBeOnDuty, updatedAt: DateTime.now()));
    }

    await _saveAllInternal(prefs, updated, syncToCloud: true);
  }

  static Future<void> setOnDuty(String id, String group) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final updated = all.map((c) {
      if (c.group != group) return c;
      return c.copyWith(isOnDuty: c.id == id, updatedAt: DateTime.now());
    }).toList();
    await _saveAllInternal(prefs, updated, syncToCloud: true);
  }

  static Future<void> deleteContact(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final removed = all.where((c) => c.id == id).firstOrNull;
    all.removeWhere((c) => c.id == id);

    // Ensure at least one remaining contact in the group is marked on-duty
    if (removed != null) {
      final remainingInGroup = all.where((c) => c.group == removed.group).toList();
      if (remainingInGroup.isNotEmpty && !remainingInGroup.any((c) => c.isOnDuty)) {
        final firstId = remainingInGroup.first.id;
        for (int i = 0; i < all.length; i++) {
          if (all[i].id == firstId) {
            all[i] = all[i].copyWith(isOnDuty: true);
            break;
          }
        }
      }
    }

    await _saveAllInternal(prefs, all, syncToCloud: true);
  }

  static Future<void> _saveAllInternal(
    SharedPreferences prefs,
    List<StaffContact> list, {
    required bool syncToCloud,
  }) async {
    await prefs.setString(
      storageKey,
      jsonEncode(list.map((c) => c.toMap()).toList()),
    );

    // Keep legacy keys synchronized with the active on-duty contact for 100% compatibility
    final activeMatab = list.where((c) => c.group == groupMatab && c.isOnDuty).firstOrNull ??
        list.where((c) => c.group == groupMatab).firstOrNull;
    if (activeMatab != null) {
      await prefs.setString('doctor_name', activeMatab.name);
      await prefs.setString('doctor_phone_number', activeMatab.phone);
    } else {
      await prefs.remove('doctor_name');
      await prefs.remove('doctor_phone_number');
    }

    final activeHogad = list.where((c) => c.group == groupHogad && c.isOnDuty).firstOrNull ??
        list.where((c) => c.group == groupHogad).firstOrNull;
    if (activeHogad != null) {
      await prefs.setString('hogad_name', activeHogad.name);
      await prefs.setString('hogad_phone_number', activeHogad.phone);
    } else {
      await prefs.remove('hogad_name');
      await prefs.remove('hogad_phone_number');
    }

    if (syncToCloud) {
      // Non-blocking cloud sync for the unit
      pushUnitConfigToCloud().ignore();
    }
  }

  /// Merges incoming staff contacts from P2P or Cloud Config.
  static Future<int> mergeContacts(List<dynamic> rawContacts) async {
    if (rawContacts.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final local = await loadAll();
    final mapById = {for (final c in local) c.id: c};

    int mergedCount = 0;
    for (final raw in rawContacts) {
      if (raw is! Map) continue;
      final incoming = StaffContact.fromMap(Map<String, dynamic>.from(raw));
      if (incoming.phone.trim().isEmpty) continue;

      // Also check if same phone & group already exists under a different ID
      final duplicateByPhone = mapById.values
          .where((c) => c.group == incoming.group && _cleanDigits(c.phone) == _cleanDigits(incoming.phone))
          .firstOrNull;

      final targetKey = duplicateByPhone?.id ?? incoming.id;
      final existing = mapById[targetKey];

      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        mapById[targetKey] = incoming;
        mergedCount++;
      }
    }

    if (mergedCount > 0) {
      final resultList = mapById.values.toList();
      // Normalize on-duty so each group has at most 1 on-duty (picking most recently updated on-duty)
      for (final grp in [groupMatab, groupHogad]) {
        final onDutyInGroup = resultList.where((c) => c.group == grp && c.isOnDuty).toList();
        if (onDutyInGroup.length > 1) {
          onDutyInGroup.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final winnerId = onDutyInGroup.first.id;
          for (int i = 0; i < resultList.length; i++) {
            if (resultList[i].group == grp) {
              resultList[i] = resultList[i].copyWith(isOnDuty: resultList[i].id == winnerId);
            }
          }
        }
      }
      await _saveAllInternal(prefs, resultList, syncToCloud: false);
    }

    return mergedCount;
  }

  static String _cleanDigits(String p) => p.replaceAll(RegExp(r'\D'), '');

  /// Pushes the current unit staff contacts to a shared unit config record in Supabase `notes`.
  static Future<void> pushUnitConfigToCloud() async {
    try {
      final user = AuthService().currentUser;
      final unitId = user?.unitId;
      if (unitId == null || unitId.isEmpty) return;

      final contacts = await loadAll();
      final reminders = await FollowUpReminderService.getReminders();
      final payloadJson = jsonEncode({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'staff_contacts': contacts.map((c) => c.toMap()).toList(),
        'follow_up_reminders': reminders.map((r) => r.toMap()).toList(),
      });
      final content = '$cloudConfigPrefix$payloadJson';

      final sb = Supabase.instance.client;
      final existing = await sb
          .from('notes')
          .select('id')
          .eq('unit_id', unitId)
          .like('content', '$cloudConfigPrefix%')
          .maybeSingle();

      final nowIso = DateTime.now().toUtc().toIso8601String();
      if (existing != null && existing['id'] != null) {
        await sb.from('notes').update({
          'content': content,
          'updated_at': nowIso,
        }).eq('id', existing['id']);
      } else {
        await sb.from('notes').insert({
          'id': const Uuid().v4(),
          'unit_id': unitId,
          'user_id': user!.id,
          'content': content,
          'is_private': false,
          'created_at': nowIso,
          'updated_at': nowIso,
        });
      }
    } catch (_) {}
  }

  /// Applies cloud config JSON string if encountered when fetching unit notes.
  static Future<void> applyCloudConfigContent(String rawContent) async {
    if (!rawContent.startsWith(cloudConfigPrefix)) return;
    try {
      final jsonPart = rawContent.substring(cloudConfigPrefix.length);
      final map = jsonDecode(jsonPart) as Map<String, dynamic>;
      final contacts = map['staff_contacts'] as List<dynamic>? ?? const [];
      await mergeContacts(contacts);
      final reminders = map['follow_up_reminders'] as List<dynamic>? ?? const [];
      await FollowUpReminderService.mergeReminders(reminders);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Matab Queue ("מסדר מט"ב / לבדיקת רופא היום")
  // ---------------------------------------------------------------------------
  static const String matabCategory = 'בדיקת מט"ב';

  /// Returns true if [medicalCase] is open and marked as waiting for Matab/Doctor examination.
  static bool isCaseInMatabQueue(MedicalCase medicalCase) {
    if (medicalCase.status == 'COMPLETED') return false;
    final cat = (medicalCase.category ?? '').trim();
    final desc = (medicalCase.description ?? '').trim();
    return cat == matabCategory ||
        cat == 'בדיקת רופא' ||
        desc.contains('בקשת תור לרופא') ||
        desc.contains('ממתין למט"ב') ||
        desc.contains('בדיקת מט"ב');
  }

  /// Builds a structured WhatsApp report of all soldiers waiting for Matab examination today.
  static String buildMatabQueueMessage({
    required List<MedicalCase> cases,
    required List<Soldier> soldiers,
    String? unitName,
  }) {
    final queueCases = cases.where(isCaseInMatabQueue).toList();
    final soldierMap = {for (final s in soldiers) s.id: s};

    // Sort urgent cases first
    queueCases.sort((a, b) {
      final aUrgent = a.severity == 'דחוף' || a.severity == 'קריטי';
      final bUrgent = b.severity == 'דחוף' || b.severity == 'קריטי';
      if (aUrgent && !bUrgent) return -1;
      if (!aUrgent && bUrgent) return 1;
      return b.createdDate.compareTo(a.createdDate);
    });

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final headerUnit = (unitName != null && unitName.trim().isNotEmpty) ? ' - $unitName' : '';

    final sb = StringBuffer();
    sb.writeln('🩺 *מסדר מט"ב / רשימת חיילים לבדיקה$headerUnit*');
    sb.writeln('📅 *תאריך:* $dateStr | *סה"כ לבדיקה:* ${queueCases.length}');
    sb.writeln('────────────────────');

    if (queueCases.isEmpty) {
      sb.writeln('אין כרגע חיילים הממתינים לבדיקת מט"ב.');
      return sb.toString();
    }

    for (int i = 0; i < queueCases.length; i++) {
      final c = queueCases[i];
      final s = soldierMap[c.soldierId];
      final name = s?.name ?? 'חייל';
      final pn = (s?.personalNumber != null && s!.personalNumber!.isNotEmpty) ? ' (מ.א ${s.personalNumber})' : '';
      final platoon = (s?.platoon != null && s!.platoon!.trim().isNotEmpty)
          ? ' | ${PlatoonHelper.formatDisplay(s.platoon)}'
          : '';
      final urgentBadge = (c.severity == 'דחוף' || c.severity == 'קריטי') ? ' 🔴 *[דחוף]*' : '';

      sb.writeln('${i + 1}. *$name*$pn$platoon$urgentBadge');
      if (s != null && s.hasAllergies) {
        sb.writeln('   🚨 *רגישות:* ${s.allergies}');
      }
      final cleanDesc = (c.description ?? 'ללא פירוט').replaceAll('\n', ' ').trim();
      sb.writeln('   📋 *תלונה:* $cleanDesc');
    }

    sb.writeln('────────────────────');
    sb.writeln('נשלח מאפליקציית חופ"ל.');
    return sb.toString();
  }
}
