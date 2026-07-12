import '../config/app_config.dart';

/// Version info and update-check placeholder (Firebase Remote Config later).
class AppVersionService {
  AppVersionService._();

  static String get currentVersion => AppConfig.appVersion;
  static String get buildNumber => '${AppConfig.buildNumber}';
  static String get fullVersion => AppConfig.versionLabel;

  /// Placeholder — returns null when no newer version is advertised.
  static Future<String?> checkForUpdates() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Remote config / Play Store API would go here in production.
    return null;
  }

  static Future<bool> hasOptionalUpdate() async {
    final latest = await checkForUpdates();
    return latest != null && latest != currentVersion;
  }
}
