class Soldier {
  final String id;
  final String name;
  final String? platoon;
  final String? unitId;
  final String? phoneNumber;

  Soldier({
    required this.id,
    required this.name,
    this.platoon,
    this.unitId,
    this.phoneNumber,
  });

  factory Soldier.fromMap(Map<String, dynamic> map) {
    return Soldier(
      id: map['id'],
      name: map['name'],
      platoon: map['platoon'],
      unitId: map['unit_id'],
      phoneNumber: map['phone_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'platoon': platoon,
      'unit_id': unitId,
      'phone_number': phoneNumber,
    };
  }
}
