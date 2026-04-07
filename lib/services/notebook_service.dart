import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notebook_entry.dart';

class NotebookService {
  static const _boxName = 'notebook';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<NotebookEntry> loadAll() {
    if (_box == null) return [];
    return _box!.values
        .whereType<String>()
        .map((raw) {
          try {
            return NotebookEntry.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotebookEntry>()
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> save(NotebookEntry entry) async {
    await _box?.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
  }

  Future<void> toggleMastered(NotebookEntry entry) async {
    entry.isMastered = !entry.isMastered;
    await save(entry);
  }

  bool contains(String word, String lessonId) {
    return loadAll().any(
      (e) => e.word.toLowerCase() == word.toLowerCase() && e.lessonId == lessonId,
    );
  }
}
