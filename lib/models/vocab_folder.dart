class VocabFolder {
  final String id;
  final String lessonId;
  String name;
  final DateTime createdAt;

  VocabFolder({
    required this.id,
    required this.lessonId,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lessonId': lessonId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VocabFolder.fromJson(Map<String, dynamic> j) => VocabFolder(
        id: j['id'] as String,
        lessonId: j['lessonId'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  static String generateId(String lessonId) =>
      'folder_${lessonId}_${DateTime.now().millisecondsSinceEpoch}';
}
