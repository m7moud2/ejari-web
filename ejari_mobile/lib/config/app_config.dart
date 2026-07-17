import 'package:flutter/foundation.dart';

/// Build-time configuration shared by the mobile app.
///
/// **Release APK (Android/iOS):** uses real Firebase Auth + Firestore by default.
/// **Web / debug / profile / tests:** demo mode (local SharedPreferences).
///
/// Override with `--dart-define=DEMO_MODE=true|false`.
class AppConfig {
  /// Keep in sync with pubspec.yaml `version` (name part).
  static const String appVersion = '1.3.4';
  static const int buildNumber = 20;

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _demoModeValue = String.fromEnvironment('DEMO_MODE');

  /// Public invite / download landing page (GitHub Pages or Releases).
  static const String inviteUrl = String.fromEnvironment(
    'INVITE_URL',
    defaultValue: 'https://m7moud2.github.io/ejari-web/promo/',
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
        'https://play.google.com/store/apps/details?id=com.ejari.app',
  );

  /// Privacy policy URL required by Google Play.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://m7moud2.github.io/ejari-web/docs/privacy.html',
  );

  /// Terms of service (promo/docs).
  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://m7moud2.github.io/ejari-web/docs/terms.html',
  );

  /// Auth / network wait before showing Arabic timeout + retry.
  static const Duration authTimeout = Duration(seconds: 8);

  /// Demo = local SharedPreferences. Real = Firebase Auth + Firestore.
  ///
  /// Defaults:
  /// - Web / debug / profile → demo (no Firebase Console required)
  /// - Native release APK → Firebase
  static bool get demoMode {
    if (_demoModeValue == 'true') return true;
    if (_demoModeValue == 'false') return false;
    // Local web + debug must work without Console Email/Password setup.
    if (kIsWeb || !kReleaseMode) return true;
    return false;
  }

  static bool get isProduction => !demoMode && kReleaseMode;

  static bool get usesFirebaseBackend => !demoMode;

  static String get environmentLabel =>
      demoMode ? 'وضع العرض' : (isProduction ? 'إنتاج' : 'تطوير');

  static String get versionLabel => '$appVersion+$buildNumber';

  /// Optional Express API. Empty when using Firebase-only (Spark free tier).
  static String get resolvedApiBaseUrl {
    final configured = apiBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (configured.isNotEmpty) return configured;

    if (demoMode || usesFirebaseBackend) {
      return '';
    }

    if (kDebugMode) {
      // Use the Mac's local network IP so the real device can connect over Wi-Fi
      // without needing a stable USB cable for `adb reverse`.
      return 'http://10.64.120.170:5050/api';
    }

    return '';
  }
}
