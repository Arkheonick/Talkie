import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class SessionStorageService {
  static const String _boxName = 'sessions';

  Box get _box => Hive.box(_boxName);

  Future<void> save(Session session) async {
    await _box.put(session.id, jsonEncode(session.toJson()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<Session> loadAll() {
    return _box.values
        .map((v) => Session.fromJson(jsonDecode(v as String)))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
}
