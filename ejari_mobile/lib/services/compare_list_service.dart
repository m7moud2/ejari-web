import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Compare up to 2 properties side-by-side.
class CompareListService {
  static const int maxItems = 2;
  static const String _key = 'compare_property_ids';

  static Future<List<String>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<Map<String, dynamic>> toggle(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    if (ids.contains(propertyId)) {
      ids.remove(propertyId);
      await prefs.setStringList(_key, ids);
      return {'added': false, 'count': ids.length, 'ids': ids};
    }
    if (ids.length >= maxItems) {
      return {'added': false, 'count': ids.length, 'ids': ids, 'full': true};
    }
    ids.add(propertyId);
    await prefs.setStringList(_key, ids);
    return {'added': true, 'count': ids.length, 'ids': ids};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<List<Map<String, dynamic>>> getProperties() async {
    final ids = await getIds();
    if (ids.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final props = prefs.getStringList('properties') ?? [];
    final result = <Map<String, dynamic>>[];
    for (final raw in props) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final id = m['id']?.toString() ?? '';
        if (ids.contains(id)) result.add(m);
      } catch (_) {}
    }
    return result;
  }
}
