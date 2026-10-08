class LearningContent {
  final String id;
  final String title;
  final String type;
  final String category;
  final String url;

  LearningContent({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.url,
  });

  factory LearningContent.fromMap(Map<String, dynamic> map) {
    return LearningContent(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      category: map['category'],
      url: map['url'],
    );
  }
}
