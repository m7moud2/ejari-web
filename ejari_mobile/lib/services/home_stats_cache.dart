import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_stats_model.dart';

/// Cache home dashboard stats for instant load on next visit.
class HomeStatsCache {
  HomeStatsCache._();

  static const String _prefix = 'home_stats_cache_v1_';

  static Future<void> save(String role, HomeStatsModel stats) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'tenantStats': stats.tenantStats,
      'ownerStats': stats.ownerStats,
      'techStats': stats.techStats,
      'adminStats': stats.adminStats,
      'cachedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString('$_prefix$role', payload);
  }

  static Future<HomeStatsModel?> load(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$role');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return HomeStatsModel(
        tenantStats: Map<String, dynamic>.from(
          map['tenantStats'] as Map? ?? {},
        ),
        ownerStats: Map<String, dynamic>.from(
          map['ownerStats'] as Map? ?? {},
        ),
        techStats: Map<String, dynamic>.from(
          map['techStats'] as Map? ?? {},
        ),
        adminStats: Map<String, dynamic>.from(
          map['adminStats'] as Map? ?? {},
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> cachedAt(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$role');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(map['cachedAt']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
