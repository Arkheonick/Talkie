class VocabularyEntry {
  final String word;
  final String definition;
  final String exampleSentence;
  final String translation;
  final DateTime timestamp;

  VocabularyEntry({
    required this.word,
    required this.definition,
    required this.exampleSentence,
    required this.translation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'word': word,
        'definition': definition,
        'exampleSentence': exampleSentence,
        'translation': translation,
        'timestamp': timestamp.toIso8601String(),
      };

  factory VocabularyEntry.fromJson(Map<String, dynamic> json) =>
      VocabularyEntry(
        word: json['word'] as String,
        definition: json['definition'] as String,
        exampleSentence: json['exampleSentence'] as String,
        translation: json['translation'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
