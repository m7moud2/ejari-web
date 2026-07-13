import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/chat_service.dart';
import 'package:ejari_mobile/services/support_bot_service.dart';

/// Regression: Android release APK must use local demo auth (not Firebase/API).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
  });

  group('Android release demo auth', () {
    test('demoMode is enabled by default for distributed builds', () {
      expect(AppConfig.demoMode, isTrue);
      expect(AppConfig.authTimeout.inSeconds, greaterThanOrEqualTo(5));
      expect(AppConfig.authTimeout.inSeconds, lessThanOrEqualTo(8));
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
