import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const _boxName = 'user_profile';
  static const _key = 'profile';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  UserProfile load() {
    final raw = _box?.get(_key) as String?;
    if (raw == null) return UserProfile.defaults();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.defaults();
    }
  }

  Future<void> save(UserProfile profile) async {
    await _box?.put(_key, jsonEncode(profile.toJson()));
  }
}
