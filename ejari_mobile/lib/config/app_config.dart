import 'package:flutter/foundation.dart';

/// Build-time configuration shared by the mobile app.
///
/// Production builds must provide [apiBaseUrl]. Demo data is enabled by
/// default only in debug builds and can be overridden with DEMO_MODE.
class AppConfig {
  /// Keep in sync with pubspec.yaml `version` (name part).
  static const String appVersion = '1.1.7';
  static const int buildNumber = 8;

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _demoModeValue = String.fromEnvironment('DEMO_MODE');

  /// Public invite link for share-app flows.
  static const String inviteUrl = String.fromEnvironment(
    'INVITE_URL',
    defaultValue: 'https://ejari.app/download',
  );

  /// Play Store listing (placeholder until published).
  static const String playStoreUrl = String.fromEnvironment(
    'PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=com.ejari.mobile',
  );

  static bool get demoMode {
    if (_demoModeValue == 'true') return true;
    if (_demoModeValue == 'false') return false;
    return kDebugMode;
  }

  static bool get isProduction => !demoMode && !kDebugMode;

  static String get environmentLabel =>
      demoMode ? 'وضع العرض' : (isProduction ? 'إنتاج' : 'تطوير');

  static String get versionLabel => '$appVersion+$buildNumber';

  static String get resolvedApiBaseUrl {
    final configured = apiBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (configured.isNotEmpty) return configured;

    if (kDebugMode) {
      // Use the Mac's local network IP so the real device can connect over Wi-Fi
      // without needing a stable USB cable for `adb reverse`.
      return 'http://10.64.120.170:5050/api';
    }

    throw StateError(
      'API_BASE_URL is required for release builds. '
      'Build with --dart-define=API_BASE_URL=https://example.com/api',
    );
  }
}
