class Equipment {
  static const String companyBoxCategory = 'ארגז חופל';
  static const String legacyVestCategory = 'וסט חובש';
  static const String vestPrefix = 'וסט חובש::';

  static String vestCategoryFor(String medicId) => '$vestPrefix$medicId';

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

  bool get isCompanyBox => category == companyBoxCategory;

  bool get isAnyMedicVest =>
      category == legacyVestCategory || category.startsWith(vestPrefix);

  String? get vestOwnerId =>
      category.startsWith(vestPrefix) ? category.substring(vestPrefix.length) : null;

  bool belongsToMedicVest(String medicId, {required bool includeLegacyUnassigned}) {
    if (category == vestCategoryFor(medicId)) return true;
    if (includeLegacyUnassigned && category == legacyVestCategory) return true;
    return false;
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    final rawExp = map['expiration_date']?.toString();
    String? resolvedExp = rawExp;
    String? resolvedImg = map['image_path']?.toString();
    if (rawExp != null && rawExp.startsWith('IMG:')) {
      resolvedImg = (resolvedImg != null && resolvedImg.isNotEmpty)
          ? resolvedImg
          : rawExp.substring(4);
      resolvedExp = null;
    }

    return Equipment(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? 'כללי',
      itemType: map['item_type'] ?? 'מתכלה',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      minimumRequired: (map['minimum_required'] as num?)?.toInt() ?? 0,
      expirationDate: resolvedExp,
      status: map['status'] ?? 'IN_STOCK',
      unitId: map['unit_id'],
      imagePath: (resolvedImg != null && resolvedImg.isNotEmpty) ? resolvedImg : null,
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
  /// Encodes `data:` photos safely in `expiration_date` (`TEXT`) with `IMG:` prefix.
  Map<String, dynamic> toSupabaseMap() {
    final String? cloudExp = (imagePath != null && imagePath!.startsWith('data:'))
        ? 'IMG:$imagePath'
        : expirationDate;
    return {
      'id': id,
      'name': name,
      'category': category,
      'item_type': itemType,
      'quantity': quantity,
      'minimum_required': minimumRequired,
      'expiration_date': cloudExp,
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
    bool clearImagePath = false,
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
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }
}
