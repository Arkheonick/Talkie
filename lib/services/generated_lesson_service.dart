import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson.dart';

class GeneratedLessonService {
  static const _boxName = 'generated_lessons';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<Lesson> loadAll() {
    if (_box == null) return [];
    return _box!.values
        .whereType<String>()
        .map((raw) {
          try {
            return Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Lesson>()
        .toList()
        .reversed
        .toList(); // most recent first
  }

  Future<void> save(Lesson lesson) async {
    await _box?.put(lesson.id, jsonEncode(_lessonToJson(lesson)));
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
  }

  Map<String, dynamic> _lessonToJson(Lesson lesson) => {
        'id': lesson.id,
        'title': lesson.title,
        'description': lesson.description,
        'domain': lesson.domain,
        'level': lesson.level.code.toLowerCase(),
        'duration_seconds': lesson.durationSeconds,
        'emoji': lesson.emoji,
        'transcript': lesson.transcript
            .map((t) => {
                  'index': t.index,
                  'speaker': t.speaker,
                  'text': t.text,
                  if (t.translation != null) 'translation': t.translation,
                })
            .toList(),
        'vocabulary': lesson.vocabulary
            .map((v) => {
                  'word': v.word,
                  'definition': v.definition,
                  'example_sentence': v.exampleSentence,
                  'translation': v.translation,
                })
            .toList(),
      };
}
