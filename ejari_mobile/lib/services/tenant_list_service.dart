import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner tenant blacklist / preferred lists.
class TenantListService {
  static String _key(String ownerId, String type) => 'tenant_${type}_$ownerId';

  static Future<List<Map<String, dynamic>>> getList(
    String ownerId,
    String type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(ownerId, type)) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map)).toList();
  }

  static Future<bool> addTenant({
    required String ownerId,
    required String type,
    required String tenantEmail,
    required String tenantName,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(ownerId, type);
    final list = prefs.getStringList(key) ?? [];
    if (list.any((e) {
      try {
        return (jsonDecode(e) as Map)['email'] == tenantEmail;
      } catch (_) {
        return false;
      }
    })) {
      return false;
    }
    list.add(jsonEncode({
      'email': tenantEmail,
      'name': tenantName,
      'note': note ?? '',
      'addedAt': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(key, list);
    return true;
  }

  static Future<void> removeTenant({
    required String ownerId,
    required String type,
    required String tenantEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(ownerId, type);
    final list = prefs.getStringList(key) ?? [];
    list.removeWhere((e) {
      try {
        return (jsonDecode(e) as Map)['email'] == tenantEmail;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(key, list);
  }

  static Future<bool> isBlacklisted(String ownerId, String tenantEmail) async {
    final list = await getList(ownerId, 'blacklist');
    return list.any((t) => t['email'] == tenantEmail);
  }

  static Future<bool> isPreferred(String ownerId, String tenantEmail) async {
    final list = await getList(ownerId, 'preferred');
    return list.any((t) => t['email'] == tenantEmail);
  }
}
