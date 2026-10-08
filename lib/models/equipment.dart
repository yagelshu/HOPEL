class Equipment {
  final String id;
  final String name;
  final String category;
  final String itemType;
  final int quantity;
  final int minimumRequired;
  final String? expirationDate;
  final String status;
  final String? unitId;
  final String? imagePath;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.itemType,
    required this.quantity,
    required this.minimumRequired,
    this.expirationDate,
    required this.status,
    this.unitId,
    this.imagePath,
  });

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? 'כללי',
      itemType: map['item_type'] ?? 'מתכלה',
      quantity: map['quantity'],
      minimumRequired: map['minimum_required'],
      expirationDate: map['expiration_date'],
      status: map['status'],
      unitId: map['unit_id'],
      imagePath: map['image_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'item_type': itemType,
      'quantity': quantity,
      'minimum_required': minimumRequired,
      'expiration_date': expirationDate,
      'status': status,
      'unit_id': unitId,
      'image_path': imagePath,
    };
  }
}
