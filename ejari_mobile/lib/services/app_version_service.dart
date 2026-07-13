import '../config/app_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Version info and GitHub Releases-based update check.
class AppVersionService {
  AppVersionService._();

  static String get currentVersion => AppConfig.appVersion;
  static String get buildNumber => '${AppConfig.buildNumber}';
  static String get fullVersion => AppConfig.versionLabel;

  /// Last resolved download URL from a successful update check.
  static String? latestDownloadUrl;

  /// Returns the newer semver tag (e.g. `1.1.9`) if GitHub has a later release.
  /// Returns null when already up to date or the check fails (offline / rate limit).
  static Future<String?> checkForUpdates({http.Client? client}) async {
    latestDownloadUrl = null;
    final httpClient = client ?? http.Client();
    final ownedClient = client == null;
    try {
      final uri = Uri.parse(AppConfig.githubLatestReleaseApiUrl);
      final response = await httpClient
          .get(
            uri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'ejari-mobile',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final tag = (body['tag_name'] as String?)?.trim() ?? '';
      final latest = tag.startsWith('v') || tag.startsWith('V')
          ? tag.substring(1)
          : tag;
      if (latest.isEmpty) return null;

      final assets = body['assets'];
      String? apkUrl;
      if (assets is List) {
        for (final asset in assets) {
          if (asset is! Map<String, dynamic>) continue;
          final name = (asset['name'] as String?) ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }
      latestDownloadUrl = apkUrl ??
          body['html_url'] as String? ??
          AppConfig.inviteUrl;

      if (!_isNewerVersion(latest, currentVersion)) return null;
      return latest;
    } catch (_) {
      return null;
    } finally {
      if (ownedClient) httpClient.close();
    }
  }

  static Future<bool> hasOptionalUpdate({http.Client? client}) async {
    final latest = await checkForUpdates(client: client);
    return latest != null && latest != currentVersion;
  }

  /// Opens the APK / release page for the latest known update.
  static Future<bool> openUpdateDownload() async {
    final raw = latestDownloadUrl ?? AppConfig.inviteUrl;
    final url = Uri.tryParse(raw);
    if (url == null) return false;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Compare dotted versions; true if [candidate] > [current].
  static bool _isNewerVersion(String candidate, String current) {
    List<int> parts(String v) => v
        .split(RegExp(r'[^0-9]+'))
        .where((p) => p.isNotEmpty)
        .map(int.parse)
        .toList();

    final a = parts(candidate);
    final b = parts(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left > right) return true;
      if (left < right) return false;
    }
    return false;
  }
}
