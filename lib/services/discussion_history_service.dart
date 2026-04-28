import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class DiscussionHistoryService {
  static const _boxName = 'discussion_history';
  static const _key = 'messages';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<Map<String, String>> load() {
    final raw = _box?.get(_key) as String?;
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map((m) => {
                'role': m['role'] as String,
                'text': m['text'] as String,
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, String>> messages) async {
    await _box?.put(_key, jsonEncode(messages));
  }

  Future<void> clear() async {
    await _box?.delete(_key);
  }
}
