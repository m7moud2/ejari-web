import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persist search filter presets for quick reuse.
class SearchFiltersService {
  static const String _savedKey = 'saved_search_filters';
  static const String _lastKey = 'last_search_filters';

  static Future<void> savePreset(String name, Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedKey) ?? [];
    final entry = jsonEncode({'name': name, 'filters': filters, 'savedAt': DateTime.now().toIso8601String()});
    raw.removeWhere((e) {
      try {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return m['name'] == name;
      } catch (_) {
        return false;
      }
    });
    raw.insert(0, entry);
    await prefs.setStringList(_savedKey, raw.take(10).toList());
  }

  static Future<void> saveLast(Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, jsonEncode(filters));
  }

  static Future<Map<String, dynamic>?> loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedKey) ?? [];
    return raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return {
        'name': m['name']?.toString() ?? 'بحث محفوظ',
        'filters': Map<String, dynamic>.from(m['filters'] as Map? ?? {}),
        'savedAt': m['savedAt']?.toString() ?? '',
      };
    }).toList();
  }

  static Future<bool> deletePreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedKey) ?? [];
    final before = raw.length;
    raw.removeWhere((e) {
      try {
        return (jsonDecode(e) as Map)['name'] == name;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_savedKey, raw);
    return raw.length < before;
  }
}
