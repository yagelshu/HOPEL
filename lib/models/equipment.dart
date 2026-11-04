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
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      minimumRequired: (map['minimum_required'] as num?)?.toInt() ?? 0,
      expirationDate: map['expiration_date'],
      status: map['status'] ?? 'IN_STOCK',
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

  /// Columns present in the Supabase `public.equipment` table.
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'item_type': itemType,
      'quantity': quantity,
      'minimum_required': minimumRequired,
      if (expirationDate != null) 'expiration_date': expirationDate,
      'status': status,
      if (unitId != null) 'unit_id': unitId,
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    String? itemType,
    int? quantity,
    int? minimumRequired,
    String? expirationDate,
    String? status,
    String? unitId,
    String? imagePath,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
      minimumRequired: minimumRequired ?? this.minimumRequired,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      unitId: unitId ?? this.unitId,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
