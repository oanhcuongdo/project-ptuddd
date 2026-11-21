import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/entities/child_profile.dart';
import '../../shared/entities/attempt_log.dart';

class StorageService {
  static const String _keyProfile = 'soroban_child_profile';
  static const String _keyLogs = 'soroban_attempt_logs';

  Future<ChildProfile> getChildProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfile);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return ChildProfile.fromMap(map);
      } catch (_) {}
    }
    // Mặc định cho bé mới
    return ChildProfile(
      id: 'child_default',
      name: 'Bé Yêu',
      age: 5,
      streakCount: 3,
      lastActiveDate: DateTime.now().toIso8601String(),
      unlockedBadgeIds: const ['star_starter', 'streak_3_days'],
      currentLevel: 1,
    );
  }

  Future<void> saveChildProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
  }

  Future<void> saveAttemptLog(AttemptLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getRecentLogs();
    logs.insert(0, log);
    if (logs.length > 50) logs.removeLast(); // Giữ tối đa 50 log gần nhất
    final listMap = logs.map((e) => e.toMap()).toList();
    await prefs.setString(_keyLogs, jsonEncode(listMap));
  }

  Future<List<AttemptLog>> getRecentLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLogs);
    if (jsonStr == null) return [];
    try {
      final List dynamicList = jsonDecode(jsonStr);
      return dynamicList.map((e) => AttemptLog.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
