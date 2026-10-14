class Soldier {
  final String id;
  final String name;
  final String? personalNumber;
  final String? platoon;
  final String? unitId;
  final String? phoneNumber;

  Soldier({
    required this.id,
    required this.name,
    this.personalNumber,
    this.platoon,
    this.unitId,
    this.phoneNumber,
  });

  static final _legacyPattern = RegExp(r'^(.*?)\s*\((\d+)\)\s*$');

  /// Label for pickers/search: "ישראל ישראלי · 1234567"
  String get displayLabel =>
      (personalNumber == null || personalNumber!.isEmpty) ? name : '$name · $personalNumber';

  factory Soldier.fromMap(Map<String, dynamic> map) {
    String name = (map['name'] ?? '').toString();
    String? pn = map['personal_number']?.toString();
    // Backward compat: legacy rows stored "Name (1234567)" in name.
    final m = _legacyPattern.firstMatch(name);
    if (m != null) {
      name = m.group(1)!.trim();
      pn ??= m.group(2);
    }
    return Soldier(
      id: map['id'].toString(),
      name: name,
      personalNumber: (pn == null || pn.isEmpty) ? null : pn,
      platoon: map['platoon']?.toString(),
      unitId: map['unit_id']?.toString(),
      phoneNumber: map['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'personal_number': personalNumber,
      'platoon': platoon,
      'unit_id': unitId,
      'phone_number': phoneNumber,
    };
  }
}
