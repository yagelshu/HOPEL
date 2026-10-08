class Note {
  final String id;
  final String unitId;
  final String userId;
  final String content;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.unitId,
    required this.userId,
    required this.content,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unit_id': unitId,
      'user_id': userId,
      'content': content,
      'is_private': isPrivate ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      unitId: map['unit_id'],
      userId: map['user_id'],
      content: map['content'],
      isPrivate: map['is_private'] == 1 || map['is_private'] == true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Note copyWith({
    String? id,
    String? unitId,
    String? userId,
    String? content,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
