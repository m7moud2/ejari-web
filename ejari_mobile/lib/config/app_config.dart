import 'package:flutter/foundation.dart';

/// Build-time configuration shared by the mobile app.
///
/// Demo mode is the default for distributed APKs so login/signup/chat work
/// offline without Firebase. Production builds must pass DEMO_MODE=false and
/// API_BASE_URL.
class AppConfig {
  /// Keep in sync with pubspec.yaml `version` (name part).
  static const String appVersion = '1.1.10';
  static const int buildNumber = 11;

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _demoModeValue = String.fromEnvironment('DEMO_MODE');

  /// Public invite / download landing page (GitHub Pages or Releases).
  static const String inviteUrl = String.fromEnvironment(
    'INVITE_URL',
    defaultValue: 'https://m7moud2.github.io/ejari-web/docs/download/',
  );

  /// Fallback when GitHub Pages is not enabled yet.
  static const String githubReleasesUrl = String.fromEnvironment(
    'GITHUB_RELEASES_URL',
    defaultValue: 'https://github.com/m7moud2/ejari-web/releases/latest',
  );

  /// GitHub Releases API — used by [AppVersionService] for update checks.
  static const String githubLatestReleaseApiUrl = String.fromEnvironment(
    'GITHUB_LATEST_RELEASE_API',
    defaultValue:
        'https://api.github.com/repos/m7moud2/ejari-web/releases/latest',
  );

  /// Play Store listing (placeholder until published).
  static const String playStoreUrl = String.fromEnvironment(
    'PLAY_STORE_URL',
    defaultValue:
        'https://play.google.com/store/apps/details?id=com.ejari.mobile',
  );

  /// Auth / network wait before showing Arabic timeout + retry.
  static const Duration authTimeout = Duration(seconds: 8);

  static bool get demoMode {
    if (_demoModeValue == 'true') return true;
    if (_demoModeValue == 'false') return false;
    // Demo-first until production cutover. Override with DEMO_MODE=false.
    return true;
  }

  static bool get isProduction => !demoMode && !kDebugMode;

  static String get environmentLabel =>
      demoMode ? 'وضع العرض' : (isProduction ? 'إنتاج' : 'تطوير');

  static String get versionLabel => '$appVersion+$buildNumber';

  static String get resolvedApiBaseUrl {
    final configured = apiBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (configured.isNotEmpty) return configured;

    if (demoMode) {
      return '';
    }

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
