class EquipmentAssignment {
  final String id;
  final String equipmentId;
  final String medicId;
  final String verificationStatus;

  EquipmentAssignment({
    required this.id,
    required this.equipmentId,
    required this.medicId,
    required this.verificationStatus,
  });

  factory EquipmentAssignment.fromMap(Map<String, dynamic> map) {
    return EquipmentAssignment(
      id: map['id'],
      equipmentId: map['equipment_id'],
      medicId: map['medic_id'],
      verificationStatus: map['verification_status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'medic_id': medicId,
      'verification_status': verificationStatus,
    };
  }
}
