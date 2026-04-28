import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quiz_result.dart';

class QuizResultService {
  static const _boxName = 'quiz_results';
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<QuizResult> loadAll() {
    if (_box == null) return [];
    return _box!.values
        .whereType<String>()
        .map((raw) {
          try {
            return QuizResult.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<QuizResult>()
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  QuizResult? getBestForTheme(String themeId) {
    final results = loadAll().where((r) => r.themeId == themeId).toList();
    if (results.isEmpty) return null;
    return results.reduce((a, b) => a.bestTier >= b.bestTier ? a : b);
  }

  Future<void> save(QuizResult result) async {
    await _box?.put(result.id, jsonEncode(result.toJson()));
  }
}
