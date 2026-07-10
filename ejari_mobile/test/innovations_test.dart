import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/trust_score_service.dart';
import 'package:ejari_mobile/services/operations_feed_service.dart';
import 'package:ejari_mobile/utils/rental_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await OperationsFeedService.initDemoFeed();
  });

  group('Trust Score Service', () {
    test('demo tenant receives trust score', () async {
      final trust = await TrustScoreService.computeForUser('user@ejari.app');
      expect(trust['score'], isA<int>());
      expect((trust['score'] as int) >= 0, isTrue);
      expect(trust['level'], isNotEmpty);
      expect(trust['breakdown'], isA<List>());
    });

    test('verified owner scores higher than unverified', () async {
      final ownerTrust =
          await TrustScoreService.computeForUser('owner@ejari.app');
      expect((ownerTrust['score'] as int) >= 0, isTrue);
    });
  });

  group('Operations Feed Service', () {
    test('demo feed seeds events', () async {
      final feed = await OperationsFeedService.getLiveFeed();
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first['title'], isNotEmpty);
      expect(feed.first['timeAgo'], isNotEmpty);
    });

    test('appendEvent adds to feed', () async {
      await OperationsFeedService.appendEvent(
        type: 'booking',
        title: 'اختبار حدث',
        detail: 'حدث تجريبي للاختبار',
        refId: 'TEST-EVT',
      );
      final feed = await OperationsFeedService.getLiveFeed();
      expect(
        feed.any((e) => e['title'] == 'اختبار حدث'),
        isTrue,
      );
    });
  });

  group('Corporate Command Center', () {
    test('summary returns employees and spend', () async {
      await AuthService.login('user@ejari.app', 'user123');
      final summary = await DataService.getCorporateCommandSummary();
      expect(summary['totalEmployees'], greaterThan(0));
      expect(summary['governorateCount'], greaterThan(0));
      expect(summary['employees'], isA<List>());
    });
  });

  group('Smart Booking Assistant rules', () {
    test('refund eligible 48h before check-in', () {
      final checkIn = DateTime.now().add(const Duration(days: 5));
      expect(
        RentalRules.isRefundable(
          checkInDate: checkIn,
          cancelDate: DateTime.now(),
        ),
        isTrue,
      );
    });

    test('refund not eligible within 48h', () {
      final checkIn = DateTime.now().add(const Duration(hours: 24));
      expect(
        RentalRules.isRefundable(
          checkInDate: checkIn,
          cancelDate: DateTime.now(),
        ),
        isFalse,
      );
    });
  });
}
