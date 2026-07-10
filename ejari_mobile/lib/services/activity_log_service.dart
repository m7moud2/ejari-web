import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// سجل نشاط append-only لكل مستخدم — للمراجعة والإشعارات.
class ActivityLogService {
  static const String _prefix = 'activity_log_';

  static String _keyFor(String userId) => '$_prefix$userId';

  static Future<void> append({
    required String userId,
    required String action,
    required String detail,
    String? category,
    String? refId,
  }) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode({
      'action': action,
      'detail': detail,
      'category': category ?? 'general',
      'refId': refId,
      'date': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(key, list);
  }

  static Future<List<Map<String, dynamic>>> getForUser(String userId) async {
    if (userId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFor(userId)) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }
}
