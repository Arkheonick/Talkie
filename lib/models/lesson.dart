import 'cefr_level.dart';

class TranscriptLine {
  final int index;
  final String speaker; // 'native' | 'learner'
  final String text;
  final String? translation;

  const TranscriptLine({
    required this.index,
    required this.speaker,
    required this.text,
    this.translation,
  });

  factory TranscriptLine.fromJson(Map<String, dynamic> j) => TranscriptLine(
        index: j['index'] as int,
        speaker: j['speaker'] as String,
        text: j['text'] as String,
        translation: j['translation'] as String?,
      );
}

class LessonVocabulary {
  final String word;
  final String definition;
  final String exampleSentence;
  final String translation;

  const LessonVocabulary({
    required this.word,
    required this.definition,
    required this.exampleSentence,
    required this.translation,
  });

  factory LessonVocabulary.fromJson(Map<String, dynamic> j) => LessonVocabulary(
        word: j['word'] as String,
        definition: j['definition'] as String,
        exampleSentence: j['example_sentence'] as String,
        translation: j['translation'] as String,
      );
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String domain;
  final CefrLevel level;
  final int durationSeconds;
  final List<TranscriptLine> transcript;
  final List<LessonVocabulary> vocabulary;
  final String emoji;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.level,
    required this.durationSeconds,
    required this.transcript,
    required this.vocabulary,
    this.emoji = '🎧',
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        domain: j['domain'] as String,
        level: CefrLevel.fromString(j['level'] as String),
        durationSeconds: j['duration_seconds'] as int,
        transcript: (j['transcript'] as List)
            .map((e) => TranscriptLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        vocabulary: (j['vocabulary'] as List)
            .map((e) => LessonVocabulary.fromJson(e as Map<String, dynamic>))
            .toList(),
        emoji: j['emoji'] as String? ?? '🎧',
      );

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (s == 0) return '${m}min';
    return '${m}m${s.toString().padLeft(2, '0')}s';
  }
}
