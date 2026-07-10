import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/chat_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/support_bot_service.dart';
import 'package:ejari_mobile/services/support_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
  });

  group('Support bot shortcuts', () {
    test('all 9 shortcuts are defined with Arabic labels', () {
      expect(SupportBotService.shortcuts.length, 9);
      expect(
        SupportBotService.shortcuts.any((s) => s.id == 'payment'),
        isTrue,
      );
      expect(
        SupportBotService.shortcuts.any((s) => s.id == 'escalate' && s.isEscalation),
        isTrue,
      );
    });

    test('payment shortcut returns helpful Arabic reply', () async {
      final chatId = await ChatService.getOrCreateSupportChat(
        'user@ejari.app',
        'مستأجر تجريبي',
      );

      final action = await SupportBotService.handleShortcut(
        chatId: chatId,
        shortcutId: 'payment',
        userId: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        userEmail: 'user@ejari.app',
      );

      expect(action.showFeedback, isTrue);
      expect(action.botText, contains('الدفع'));

      final messages = await ChatService.getMessages(chatId);
      expect(messages.any((m) => m['isBot'] == true), isTrue);
      expect(messages.any((m) => m['isShortcut'] == true), isTrue);
    });

    test('keyword fallback matches booking terms', () async {
      final chatId = await ChatService.getOrCreateSupportChat(
        'user@ejari.app',
        'مستأجر تجريبي',
      );

      final action = await SupportBotService.handleFreeText(
        chatId: chatId,
        text: 'أريد إلغاء حجزي واسترداد المبلغ',
        userId: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        userEmail: 'user@ejari.app',
      );

      expect(action, isNotNull);
      expect(action!.botText, contains('الحجز'));
      expect(action.showFeedback, isTrue);
    });

    test('escalation creates ticket with bot history and switches to live', () async {
      final chatId = await ChatService.getOrCreateSupportChat(
        'user@ejari.app',
        'مستأجر تجريبي',
      );

      await SupportBotService.initializeChat(chatId);
      await SupportBotService.handleShortcut(
        chatId: chatId,
        shortcutId: 'payment',
        userId: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        userEmail: 'user@ejari.app',
      );

      final action = await SupportBotService.escalateToLiveAgent(
        chatId: chatId,
        userId: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        userEmail: 'user@ejari.app',
        reason: 'طلب التحدث مع موظف',
      );

      expect(action.escalated, isTrue);
      expect(await SupportBotService.isEscalated(chatId), isTrue);
      expect(await ChatService.getSupportMode(chatId), 'live');

      final tickets = await SupportService.getAllTickets();
      final ticket = tickets.firstWhere((t) => t['chatId'] == chatId);
      expect(ticket['botCouldntResolve'], isTrue);
      expect((ticket['botHistory'] as List).isNotEmpty, isTrue);

      final adminNotes = await DataService.getAdminNotifications();
      expect(
        adminNotes.any((n) => n['type'] == 'support' && n['refId'] == chatId),
        isTrue,
      );
    });

    test('negative feedback suggests escalation after threshold', () async {
      final chatId = await ChatService.getOrCreateSupportChat(
        'owner@ejari.app',
        'مالك تجريبي',
      );

      await SupportBotService.handleShortcut(
        chatId: chatId,
        shortcutId: 'booking',
        userId: 'owner@ejari.app',
        userName: 'مالك تجريبي',
        userEmail: 'owner@ejari.app',
      );

      await SupportBotService.handleFeedback(
        chatId: chatId,
        helped: false,
        userId: 'owner@ejari.app',
        userName: 'مالك تجريبي',
        userEmail: 'owner@ejari.app',
      );
      await SupportBotService.handleFeedback(
        chatId: chatId,
        helped: false,
        userId: 'owner@ejari.app',
        userName: 'مالك تجريبي',
        userEmail: 'owner@ejari.app',
      );

      final action = await SupportBotService.handleFeedback(
        chatId: chatId,
        helped: false,
        userId: 'owner@ejari.app',
        userName: 'مالك تجريبي',
        userEmail: 'owner@ejari.app',
      );

      expect(action.escalated, isTrue);
    });
  });
}
