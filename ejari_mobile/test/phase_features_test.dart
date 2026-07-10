import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';
import 'package:ejari_mobile/services/subscription_service.dart';
import 'package:ejari_mobile/utils/wallet_category_labels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await MaintenanceService.initDemoRequests();
  });

  group('Wallet category labels', () {
    test('maps rent deposit and refund categories', () {
      expect(
        WalletCategoryLabels.labelFor({'category': 'rent'}),
        'إيجار',
      );
      expect(
        WalletCategoryLabels.labelFor({'category': 'booking_deposit'}),
        'عربون',
      );
      expect(
        WalletCategoryLabels.labelFor({'type': 'refund'}),
        'استرداد',
      );
    });

    test('filters transactions by Arabic category', () {
      final rent = {'category': 'rent', 'type': 'expense'};
      final deposit = {'category': 'booking_deposit', 'type': 'escrow'};
      final refund = {'type': 'refund'};

      expect(WalletCategoryLabels.matchesFilter(rent, 'إيجار'), isTrue);
      expect(WalletCategoryLabels.matchesFilter(deposit, 'عربون'), isTrue);
      expect(WalletCategoryLabels.matchesFilter(refund, 'استرداد'), isTrue);
      expect(WalletCategoryLabels.matchesFilter(rent, 'استرداد'), isFalse);
    });
  });

  group('Admin global search extensions', () {
    test('finds bed booking by bed label', () async {
      final results = await DataService.adminGlobalSearch('سرير 3');
      expect(
        results.any((r) => r['type'] == 'booking' || r['type'] == 'contract'),
        isTrue,
      );
    });

    test('finds subscription by plan name', () async {
      await SubscriptionService.activatePlan(
        'owner@ejari.app',
        'silver',
      );
      final results = await DataService.adminGlobalSearch('فضي');
      expect(results.any((r) => r['type'] == 'subscription'), isTrue);
    });
  });

  group('Owner property performance', () {
    test('returns non-zero demo metrics for owner properties', () async {
      final items =
          await DataService.getOwnerPropertyPerformance('owner@ejari.app');
      expect(items, isNotEmpty);
      for (final p in items) {
        expect((p['views'] as num?) ?? 0, greaterThan(0));
      }
    });
  });

  group('Payment reminders', () {
    test('sendPaymentReminder creates tenant notification', () async {
      final before = await DataService.getNotificationsForUser('user@ejari.app');
      await DataService.sendPaymentReminder(
        tenantEmail: 'user@ejari.app',
        bookingId: 'demo_req_1',
        ownerEmail: 'owner@ejari.app',
      );
      final after = await DataService.getNotificationsForUser('user@ejari.app');
      expect(after.length, greaterThan(before.length));
    });
  });
}
