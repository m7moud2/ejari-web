import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/chat_service.dart';
import 'package:ejari_mobile/services/support_bot_service.dart';

/// Demo-mode regression: offline auth must work without live Firebase (CI/tests).
/// Release APKs use real Firebase (kReleaseMode → demoMode=false).
/// Web always stays in demo unless DEMO_MODE=false is forced.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
  });

  group('Demo-mode offline auth (debug / CI)', () {
    test('demoMode is enabled by default in debug/tests', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.authTimeout.inSeconds, greaterThanOrEqualTo(5));
      expect(AppConfig.authTimeout.inSeconds, lessThanOrEqualTo(8));
    });

    test('friendlyAuthError hides raw Firebase configuration codes', () {
      final mapped = AuthService.friendlyAuthError(
        FirebaseAuthException(
          code: 'configuration-not-found',
          message: 'CONFIG',
        ),
      );
      expect(mapped.contains('firebase_auth'), isFalse);
      expect(mapped.contains('configuration-not-found'), isFalse);
      expect(mapped.toLowerCase(), isNot(contains('firebase_auth')));
      expect(
        mapped.contains('تجربة') || mapped.contains('Firebase'),
        isTrue,
      );
    });

    test('signup still works after firebase-style failure messages', () async {
      // Local path in demoMode — simulates post-fallback success.
      final ok = await AuthService.signUp({
        'name': 'مستخدم شبكة',
        'email': 'offline.fallback@ejari.app',
        'password': 'pass1234',
        'phone': '01000000001',
        'type': 'tenant',
      });
      expect(ok, isTrue);
      final user =
          await AuthService.login('offline.fallback@ejari.app', 'pass1234');
      expect(user?['email'], 'offline.fallback@ejari.app');
    });

    test('demo login works offline without Firebase', () async {
      final user = await AuthService.login('user@ejari.app', 'user123');
      expect(user, isNotNull);
      expect(user!['email'], 'user@ejari.app');
      expect(user['role'], 'tenant');
      expect(await AuthService.isLoggedIn(), isTrue);

      final current = await AuthService.getCurrentUser();
      expect(current?['email'], 'user@ejari.app');
    });

    test('owner quick-demo account logs in', () async {
      final user = await AuthService.login('owner@ejari.app', 'owner123');
      expect(user?['role'], 'owner');
    });

    test('signup creates local account offline', () async {
      final ok = await AuthService.signUp({
        'name': 'مستخدم جديد',
        'email': 'new.user@ejari.app',
        'password': 'pass1234',
        'phone': '01000000000',
        'type': 'tenant',
      });
      expect(ok, isTrue);

      final user = await AuthService.login('new.user@ejari.app', 'pass1234');
      expect(user?['email'], 'new.user@ejari.app');
      expect(user?['offlineSignup'], isTrue);
    });

    test('support chat opens and bot shortcuts work offline', () async {
      await AuthService.login('user@ejari.app', 'user123');
      final chatId = await ChatService.getOrCreateSupportChat(
        'user@ejari.app',
        'مستأجر تجريبي',
      );
      expect(chatId, isNotEmpty);

      await SupportBotService.initializeChat(chatId);
      final messages = await ChatService.getMessages(chatId);
      expect(messages, isNotEmpty);
      expect(
        messages.any((m) => m['isBot'] == true || m['senderId'] == 'support_bot'),
        isTrue,
      );

      await ChatService.sendMessage(chatId, 'user@ejari.app', 'مرحبا');
      final after = await ChatService.getMessages(chatId);
      expect(after.length, greaterThan(messages.length));
    });

    test('wrong password fails quickly without hanging', () async {
      expect(
        () => AuthService.login('user@ejari.app', 'wrong'),
        throwsA(isA<String>()),
      );
    });
  });
}
