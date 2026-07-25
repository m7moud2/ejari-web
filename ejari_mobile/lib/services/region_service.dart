import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_region.dart';

/// Persists and broadcasts the active country/region.
///
/// Demo: SharedPreferences. Production can also mirror onto the user profile
/// via [persistToProfile] when AuthService exposes a writable profile field.
class RegionService {
  RegionService._();

  static const String prefsKey = 'app_region_country';
  static const String profileFieldKey = 'countryCode';

  /// Default Egypt — preserves existing Egyptian demo QA.
  static final ValueNotifier<AppRegion> notifier =
      ValueNotifier<AppRegion>(AppRegion.egypt);

  static AppRegion get current => notifier.value;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      final region = AppRegionX.tryParse(saved) ?? AppRegion.egypt;
      if (notifier.value != region) {
        notifier.value = region;
      }
    } catch (e) {
      debugPrint('RegionService.load skipped: $e');
    }
  }

  static Future<void> setRegion(
    AppRegion region, {
    Map<String, dynamic>? profilePatch,
  }) async {
    if (notifier.value == region && profilePatch == null) return;
    notifier.value = region;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, region.countryCode);
    } catch (e) {
      debugPrint('RegionService.setRegion prefs failed: $e');
    }
    if (profilePatch != null) {
      profilePatch[profileFieldKey] = region.countryCode;
    }
  }

  /// Keep listings that match the active region.
  /// Missing/empty [countryCode] is treated as Egypt (backward compatible).
  static List<Map<String, dynamic>> filterProperties(
    List<Map<String, dynamic>> properties, {
    AppRegion? region,
  }) {
    final code = (region ?? current).countryCode;
    return properties.where((p) {
      final raw = p['countryCode']?.toString().trim();
      if (raw == null || raw.isEmpty) {
        return code == AppRegion.egypt.countryCode;
      }
      return raw.toUpperCase() == code;
    }).toList();
  }

  /// Tag Egyptian seed rows without mutating call sites everywhere.
  static Map<String, dynamic> withCountry(
    Map<String, dynamic> property,
    AppRegion region,
  ) {
    return {
      ...property,
      'countryCode': region.countryCode,
      'currencyCode': region.currencyCode,
    };
  }
}
