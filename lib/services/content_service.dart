import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson.dart';
import '../models/cefr_level.dart';

class ContentService {
  static const _manifestPath = 'assets/content/manifest.json';

  List<Lesson> _lessons = [];
  bool _loaded = false;

  Future<void> loadAll() async {
    if (_loaded) return;
    try {
      final manifestRaw = await rootBundle.loadString(_manifestPath);
      final manifest = jsonDecode(manifestRaw) as List;
      final futures = manifest.map((path) async {
        try {
          final raw = await rootBundle.loadString(path as String);
          return Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      _lessons = results.whereType<Lesson>().toList();
    } catch (_) {
      _lessons = [];
    }
    _loaded = true;
  }

  List<Lesson> getAll() => List.unmodifiable(_lessons);

  List<Lesson> getByDomain(String domain) =>
      _lessons.where((l) => l.domain == domain).toList();

  List<Lesson> getByLevel(CefrLevel level) =>
      _lessons.where((l) => l.level == level).toList();

  List<String> get domains =>
      _lessons.map((l) => l.domain).toSet().toList()..sort();

  Lesson? getById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  static const Map<String, Map<String, String>> domainMeta = {
    'travel': {'label': 'Voyage', 'emoji': '✈️'},
    'work': {'label': 'Travail', 'emoji': '💼'},
    'daily': {'label': 'Quotidien', 'emoji': '☕'},
    'culture': {'label': 'Culture', 'emoji': '🎨'},
    'tech': {'label': 'Tech', 'emoji': '💻'},
    'health': {'label': 'Santé', 'emoji': '🏥'},
    'social': {'label': 'Social', 'emoji': '🗣️'},
    'news': {'label': 'Actualités', 'emoji': '📰'},
  };
}
