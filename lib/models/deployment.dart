class Deployment {
  final String id;
  final String name;
  final String startDate;
  final String? endDate;
  final String? unitId;
  final bool isActive;

  Deployment({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.unitId,
    this.isActive = true,
  });

  factory Deployment.fromMap(Map<String, dynamic> map) {
    return Deployment(
      id: map['id'],
      name: map['name'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      unitId: map['unit_id'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'unit_id': unitId,
      'is_active': isActive ? 1 : 0,
    };
  }
}
