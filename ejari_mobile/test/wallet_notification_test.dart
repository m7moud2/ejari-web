import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('WalletService per-user debit', () {
    test('payFromWallet deducts tenant balance and rejects insufficient funds',
        () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'user@ejari.app',
        'wallet_balances_v2': '{"user@ejari.app":1000}',
      });

      await WalletService.init(userId: 'user@ejari.app');
      final before = await WalletService.getBalance(userId: 'user@ejari.app');

      final ok = await WalletService.payFromWallet(
        title: 'اختبار',
        amount: 500,
        category: 'rent',
        bookingId: 'bk-test',
        userId: 'user@ejari.app',
      );
      expect(ok, isTrue);

      final after = await WalletService.getBalance(userId: 'user@ejari.app');
      expect(after, before - 500);

      final fail = await WalletService.payFromWallet(
        title: 'اختبار',
        amount: 99999,
        category: 'rent',
        bookingId: 'bk-fail',
        userId: 'user@ejari.app',
      );
      expect(fail, isFalse);
    });

    test('owner receives credit minus platform fee after payment', () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'owner@ejari.app',
        'wallet_balances_v2': '{"owner@ejari.app":0,"admin@ejari.app":0}',
        'wallet_pending_v2': '{"owner@ejari.app":0}',
      });

      await WalletService.creditOwnerFromPayment(
        ownerId: 'owner@ejari.app',
        totalAmount: 10000,
        bookingId: 'bk-owner',
        title: 'إيجار تجريبي',
      );

      final summary =
          await WalletService.getWalletSummary(userId: 'owner@ejari.app');
      expect(summary['pending'], 9500.0);

      final adminBalance =
          await WalletService.getBalance(userId: 'admin@ejari.app');
      expect(adminBalance, 500.0);
    });
  });

  group('Notifications per account', () {
    test('tenant only sees own notifications', () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'user@ejari.app',
      });

      await DataService.addNotificationToUser(
        'user@ejari.app',
        'إشعار مستأجر',
        'تفاصيل للمستأجر',
      );
      await DataService.addNotificationToUser(
        'owner@ejari.app',
        'إشعار مالك',
        'تفاصيل للمالك',
      );
      await DataService.addNotificationToUser(
        'admin@ejari.app',
        'إشعار إداري',
        'حجز للمراجعة',
        adminFeed: true,
      );

      final tenantNotes = await DataService.getNotifications();
      expect(
          tenantNotes.every((n) => n['userEmail'] == 'user@ejari.app'), isTrue);
      expect(tenantNotes.any((n) => n['title'] == 'إشعار مستأجر'), isTrue);
      expect(tenantNotes.any((n) => n['title'] == 'إشعار مالك'), isFalse);

      SharedPreferences.setMockInitialValues({
        'current_user_email': 'admin@ejari.app',
        'notifications':
            (await SharedPreferences.getInstance()).getStringList('notifications') ??
                [],
      });

      final adminNotes = await DataService.getAdminNotifications();
      expect(adminNotes.any((n) => n['feedType'] == 'admin'), isTrue);
    });
  });

  group('Payment receipts', () {
    test('createPaymentReceipt persists and retrieves by user', () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'user@ejari.app',
      });

      final receipt = await DataService.createPaymentReceipt(
        amount: 3000,
        bookingRef: 'bk-rcp',
        payer: 'user@ejari.app',
        payee: 'owner@ejari.app',
        method: 'wallet',
        title: 'عربون شقة',
      );

      expect(receipt.id.startsWith('RCP-'), isTrue);

      final userReceipts =
          await DataService.getReceiptsForUser('user@ejari.app');
      expect(userReceipts.any((r) => r.id == receipt.id), isTrue);

      final found = await DataService.getReceiptById(receipt.id);
      expect(found?.amount, 3000);
    });
  });
}
