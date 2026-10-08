class Unit {
  final String id;
  final String name;
  final String? joinCode;

  Unit({
    required this.id,
    required this.name,
    this.joinCode,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      joinCode: map['join_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'join_code': joinCode,
    };
  }
}
