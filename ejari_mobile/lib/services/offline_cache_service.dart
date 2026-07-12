import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_service.dart';

/// وضع بدون اتصال — تخزين العقارات والمفضلة محلياً وعرضها عند انقطاع الشبكة.
class OfflineCacheService {
  OfflineCacheService._();

  static const String _propertiesCacheKey = 'offline_properties_cache_v1';
  static const String _favoritesCacheKey = 'offline_favorites_cache_v1';
  static const String _lastFetchKey = 'offline_last_fetch_was_cache';

  static bool _lastFetchFromCache = false;

  static bool get lastFetchFromCache => _lastFetchFromCache;

  /// هل يُعرض شريط «وضع بدون اتصال».
  static Future<bool> shouldShowOfflineBanner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lastFetchKey) ?? _lastFetchFromCache;
  }

  static Future<void> _markFromCache(bool value) async {
    _lastFetchFromCache = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lastFetchKey, value);
  }

  /// حفظ لقطة العقارات بعد تحميل ناجح.
  static Future<void> savePropertiesCache(
    List<Map<String, dynamic>> properties,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _propertiesCacheKey,
      properties.map((e) => jsonEncode(e)).toList(),
    );
    await prefs.setString(
      '${_propertiesCacheKey}_at',
      DateTime.now().toIso8601String(),
    );
  }

  /// قراءة العقارات المخزّنة محلياً.
  static Future<List<Map<String, dynamic>>> loadCachedProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_propertiesCacheKey) ?? [];
    if (raw.isEmpty) {
      return DataService.getAllProperties();
    }
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  /// حفظ لقطة المفضلة.
  static Future<void> saveFavoritesCache(
    List<Map<String, dynamic>> favorites,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesCacheKey,
      favorites.map((e) => jsonEncode(e)).toList(),
    );
  }

  /// قراءة المفضلة المخزّنة.
  static Future<List<Map<String, dynamic>>> loadCachedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesCacheKey) ?? [];
    if (raw.isEmpty) {
      return DataService.getFavorites();
    }
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  /// تحميل العقارات — شبكة أولاً ثم التخزين المحلي.
  static Future<({List<Map<String, dynamic>> items, bool fromCache})>
      loadProperties({bool approvedOnly = true}) async {
    try {
      final items =
          await DataService.getAllProperties(approvedOnly: approvedOnly);
      if (!DataService.propertiesLoadedFromCache) {
        await savePropertiesCache(items);
        await _markFromCache(false);
        return (items: items, fromCache: false);
      }
      await _markFromCache(true);
      return (items: items, fromCache: true);
    } catch (e) {
      debugPrint('OfflineCacheService properties fallback: $e');
      await _markFromCache(true);
      final cached = await loadCachedProperties();
      return (items: cached, fromCache: true);
    }
  }

  /// تحميل المفضلة — من التخزين مع محاولة تحديث.
  static Future<({List<Map<String, dynamic>> items, bool fromCache})>
      loadFavorites() async {
    try {
      final items = await DataService.getFavorites();
      await saveFavoritesCache(items);
      final fromCache = await shouldShowOfflineBanner();
      return (items: items, fromCache: fromCache);
    } catch (e) {
      debugPrint('OfflineCacheService favorites fallback: $e');
      await _markFromCache(true);
      final cached = await loadCachedFavorites();
      return (items: cached, fromCache: true);
    }
  }

  /// للاختبارات — إعادة ضبط الحالة.
  static Future<void> resetForTests() async {
    _lastFetchFromCache = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFetchKey);
  }
}
