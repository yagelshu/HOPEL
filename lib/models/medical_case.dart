class MedicalCase {
  final String id;
  final String soldierId;
  final String status;
  final String? description;
  final String? followUpDate;
  final String createdDate;
  final String? updatedDate;
  final String? closedDate;
  final String? imagePath;
  final String? deploymentId;
  final String? category;
  final String? severity;

  MedicalCase({
    required this.id,
    required this.soldierId,
    required this.status,
    this.description,
    this.followUpDate,
    required this.createdDate,
    this.updatedDate,
    this.closedDate,
    this.imagePath,
    this.deploymentId,
    this.category,
    this.severity,
  });

  factory MedicalCase.fromMap(Map<String, dynamic> map) {
    return MedicalCase(
      id: map['id'],
      soldierId: map['soldier_id'],
      status: map['status'],
      description: map['description'],
      followUpDate: map['follow_up_date'],
      createdDate: map['created_date'],
      updatedDate: map['updated_date'],
      closedDate: map['closed_date'],
      imagePath: map['image_path'],
      deploymentId: map['deployment_id'],
      category: map['category'] ?? 'שגרת מרפאה',
      severity: map['severity'] ?? 'שגרה',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'soldier_id': soldierId,
      'status': status,
      'description': description,
      'follow_up_date': followUpDate,
      'created_date': createdDate,
      'updated_date': updatedDate,
      'closed_date': closedDate,
      'image_path': imagePath,
      'deployment_id': deploymentId,
      'category': category ?? 'שגרת מרפאה',
      'severity': severity ?? 'שגרה',
    };
  }
}
