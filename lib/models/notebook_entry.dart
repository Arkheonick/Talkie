class NotebookEntry {
  final String id;
  final String word;
  final String definition;
  final String exampleSentence;
  final String translation;
  final String lessonId;
  final String lessonTitle;
  final DateTime savedAt;
  bool isMastered;
  String? folderId; // null = unsorted (lesson root)

  NotebookEntry({
    required this.id,
    required this.word,
    required this.definition,
    required this.exampleSentence,
    required this.translation,
    required this.lessonId,
    required this.lessonTitle,
    required this.savedAt,
    this.isMastered = false,
    this.folderId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'definition': definition,
        'exampleSentence': exampleSentence,
        'translation': translation,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'savedAt': savedAt.toIso8601String(),
        'isMastered': isMastered,
        if (folderId != null) 'folderId': folderId,
      };

  factory NotebookEntry.fromJson(Map<String, dynamic> j) => NotebookEntry(
        id: j['id'] as String,
        word: j['word'] as String,
        definition: j['definition'] as String,
        exampleSentence: j['exampleSentence'] as String,
        translation: j['translation'] as String,
        lessonId: j['lessonId'] as String,
        lessonTitle: j['lessonTitle'] as String? ?? '',
        savedAt: DateTime.parse(j['savedAt'] as String),
        isMastered: j['isMastered'] as bool? ?? false,
        folderId: j['folderId'] as String?,
      );
}
