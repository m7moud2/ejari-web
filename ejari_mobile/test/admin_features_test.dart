import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/chat_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';
import 'package:ejari_mobile/services/support_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await DataService.initDemoReceipts();
    await MaintenanceService.initDemoRequests();
  });

  group('Admin global search', () {
    test('finds booking, contract, receipt, maintenance, and user', () async {
      final bookingResults =
          await DataService.adminGlobalSearch('demo_req_1');
      expect(
        bookingResults.any(
            (r) => r['type'] == 'booking' || r['type'] == 'contract'),
        isTrue,
      );

      final contractResults =
          await DataService.adminGlobalSearch('CTR-DEMO-002');
      expect(contractResults.any((r) => r['type'] == 'contract'), isTrue);

      final receiptResults =
          await DataService.adminGlobalSearch('RCP-DEMO-001');
      expect(receiptResults.any((r) => r['type'] == 'receipt'), isTrue);

      final maintenanceResults =
          await DataService.adminGlobalSearch('MNT-DEMO-001');
      expect(maintenanceResults.any((r) => r['type'] == 'maintenance'), isTrue);

      final userResults =
          await DataService.adminGlobalSearch('user@ejari.app');
      expect(userResults.any((r) => r['type'] == 'user'), isTrue);

      final accountIdResults =
          await DataService.adminGlobalSearch('EJR-100002');
      expect(accountIdResults.any((r) => r['type'] == 'user'), isTrue);
      expect(
        accountIdResults.firstWhere((r) => r['type'] == 'user')['data']['email'],
        'user@ejari.app',
      );
    });
  });

  group('Support tickets', () {
    test('user ticket appears for admin and admin reply notifies user', () async {
      final ticketId = await SupportService.createTicket(
        userEmail: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        subject: 'مشكلة في الحجز',
        message: 'لا أستطيع إكمال الدفع',
      );

      final all = await SupportService.getAllTickets();
      expect(all.any((t) => t['id'] == ticketId), isTrue);

      await SupportService.addReply(
        ticketId: ticketId,
        senderEmail: SupportService.adminEmail,
        senderName: 'دعم إيجاري',
        text: 'نعمل على حل المشكلة الآن',
        isAdmin: true,
      );

      final updated = await SupportService.getTicketById(ticketId);
      expect(updated?['status'], 'in_progress');
      expect((updated?['replies'] as List).length, 1);

      final adminNotes = await DataService.getAdminNotifications();
      expect(
        adminNotes.any((n) => n['type'] == 'support' && n['refId'] == ticketId),
        isTrue,
      );
    });

    test('status updates persist', () async {
      final ticketId = await SupportService.createTicket(
        userEmail: 'user@ejari.app',
        userName: 'مستأجر تجريبي',
        subject: 'استفسار',
        message: 'سؤال بسيط',
      );

      await SupportService.updateStatus(ticketId, 'resolved');
      final ticket = await SupportService.getTicketById(ticketId);
      expect(ticket?['status'], 'resolved');
    });
  });

  group('Demo chat', () {
    test('messages sync both ways for user and admin', () async {
      final chatId = await ChatService.startChat(
        'user@ejari.app',
        ChatService.adminEmail,
        'دعم إيجاري',
        'استفسار دعم فني',
        user1Name: 'مستأجر تجريبي',
      );

      await ChatService.sendMessage(chatId, 'user@ejari.app', 'مرحباً، أحتاج مساعدة');
      await ChatService.sendMessage(
          chatId, ChatService.adminEmail, 'أهلاً، كيف يمكننا مساعدتك؟');

      final userChats = await ChatService.getChats('user@ejari.app');
      final adminChats = await ChatService.getChats(ChatService.adminEmail);
      expect(userChats.any((c) => c['id'] == chatId), isTrue);
      expect(adminChats.any((c) => c['id'] == chatId), isTrue);

      final messages = await ChatService.getMessages(chatId);
      expect(messages.length, greaterThanOrEqualTo(2));

      final adminNotes = await DataService.getAdminNotifications();
      expect(
        adminNotes.any((n) => n['type'] == 'support' && n['refId'] == chatId),
        isTrue,
      );
    });
  });
}
