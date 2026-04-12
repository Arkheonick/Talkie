import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vocab_folder.dart';

class VocabFolderService {
  static const _foldersBox = 'vocab_folders';
  static const _aliasesBox = 'lesson_aliases';

  Box? _folders;
  Box? _aliases;

  Future<void> init() async {
    _folders = await Hive.openBox(_foldersBox);
    _aliases = await Hive.openBox(_aliasesBox);
  }

  // ── Folders ────────────────────────────────────────────────────────────────

  List<VocabFolder> getFoldersForLesson(String lessonId) {
    if (_folders == null) return [];
    return _folders!.values
        .whereType<String>()
        .map((raw) {
          try {
            return VocabFolder.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<VocabFolder>()
        .where((f) => f.lessonId == lessonId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<VocabFolder> getAllFolders() {
    if (_folders == null) return [];
    return _folders!.values
        .whereType<String>()
        .map((raw) {
          try {
            return VocabFolder.fromJson(
                jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<VocabFolder>()
        .toList();
  }

  Future<VocabFolder> createFolder(String lessonId, String name) async {
    final folder = VocabFolder(
      id: VocabFolder.generateId(lessonId),
      lessonId: lessonId,
      name: name,
      createdAt: DateTime.now(),
    );
    await _folders?.put(folder.id, jsonEncode(folder.toJson()));
    return folder;
  }

  Future<void> renameFolder(VocabFolder folder, String newName) async {
    folder.name = newName;
    await _folders?.put(folder.id, jsonEncode(folder.toJson()));
  }

  Future<void> deleteFolder(String folderId) async {
    await _folders?.delete(folderId);
  }

  // ── Lesson aliases (user-defined display names) ────────────────────────────

  String getLessonDisplayName(String lessonId, String defaultTitle) {
    return _aliases?.get(lessonId) as String? ?? defaultTitle;
  }

  Future<void> setLessonDisplayName(String lessonId, String name) async {
    await _aliases?.put(lessonId, name);
  }

  Map<String, String> getAllAliases() {
    if (_aliases == null) return {};
    final result = <String, String>{};
    for (final key in _aliases!.keys) {
      final val = _aliases!.get(key);
      if (val is String) result[key as String] = val;
    }
    return result;
  }
}
