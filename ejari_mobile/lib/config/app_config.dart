import 'package:flutter/foundation.dart';

/// Build-time configuration shared by the mobile app.
///
/// Production builds must provide API_BASE_URL. Demo data is enabled by
/// default only in debug builds and can be overridden with DEMO_MODE.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _demoModeValue = String.fromEnvironment('DEMO_MODE');
  static bool get demoMode {
    if (_demoModeValue == 'true') return true;
    if (_demoModeValue == 'false') return false;
    return kDebugMode;
  }

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
