import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:ejari_mobile/utils/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('debug configuration has a usable API address', () {
    expect(AppConfig.resolvedApiBaseUrl, startsWith('http'));
  });

  test('demo mode never waits for a remote API', () async {
    final response = await ApiClient.get('/health');

    expect(response.statusCode, 501);
    expect(response.body, contains('"demo":true'));
  });

  test('demo accounts are seeded locally without an API dependency', () async {
    SharedPreferences.setMockInitialValues(const {});

    await AuthService.initDemoAccounts();

    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users_list') ?? const <String>[];
    expect(
        users,
        containsAll(<String>[
          'owner@ejari.app',
          'user@ejari.app',
          'tech@ejari.app',
          'admin@ejari.app',
        ]));
    expect(prefs.getString('ejari_token'), isNull);
  });

  test('Arabic font is bundled into both themes', () {
    expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily, 'Tajawal');
    expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily, 'Tajawal');
  });

  test('brand palette matches current Ejari theme colors', () {
    expect(AppTheme.primaryColor, const Color(0xFF0F3A30));
    expect(AppTheme.primaryLight, const Color(0xFF1B594B));
    expect(AppTheme.accentColor, const Color(0xFFB58D3D));
    expect(AppTheme.backgroundColor, const Color(0xFFF8F9FA));
    expect(AppTheme.surfaceColor, const Color(0xFFFFFFFF));
    expect(AppTheme.textPrimary, const Color(0xFF1E293B));
    expect(AppTheme.textSecondary, const Color(0xFF64748B));
    expect(AppTheme.errorColor, const Color(0xFFDC2626));
    expect(AppTheme.successColor, const Color(0xFF16A34A));
  });

  test('primary actions and body text meet readable contrast', () {
    double ratio(Color foreground, Color background) {
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
              ? foreground.computeLuminance()
              : background.computeLuminance();
      final darker =
          foreground.computeLuminance() < background.computeLuminance()
              ? foreground.computeLuminance()
              : background.computeLuminance();
      return (lighter + 0.05) / (darker + 0.05);
    }

    expect(
        ratio(Colors.white, AppTheme.primaryColor), greaterThanOrEqualTo(4.5));
    expect(
      ratio(AppTheme.textPrimary, AppTheme.backgroundColor),
      greaterThanOrEqualTo(4.5),
    );
  });
}
