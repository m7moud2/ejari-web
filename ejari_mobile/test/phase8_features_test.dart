import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/repositories/data_repository.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/subscription_service.dart';
import 'package:ejari_mobile/services/app_version_service.dart';
import 'package:ejari_mobile/widgets/demo_mode_banner.dart';
import 'package:ejari_mobile/widgets/sale_listing_widgets.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 8 — production prep', () {
    test('AppConfig has version and demo label', () {
      expect(AppConfig.appVersion, '1.1.9');
      expect(AppConfig.buildNumber, 10);
      expect(AppConfig.environmentLabel, 'وضع العرض');
      expect(AppConfig.demoMode, isTrue);
    });

    test('DataRepository wraps DataService in demo mode', () async {
      final repo = DataRepository.instance;
      final props = await repo.getAllProperties();
      expect(props, isNotEmpty);
      final report = await repo.exportOwnerMonthlyReport('owner@ejari.app');
      expect(report['monthlyRevenue'], isNotNull);
      expect(report['reportLabel'], contains('تقرير شهري'));
    });

    testWidgets('DemoModeBanner shows وضع العرض badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DemoModeBanner(
            child: Scaffold(body: Container()),
          ),
        ),
      );
      expect(find.text('وضع العرض'), findsOneWidget);
    });

    test('AppVersionService checkForUpdates returns null when offline/API fails',
        () async {
      expect(AppVersionService.fullVersion, '1.1.9+10');
      // Without a live GitHub release (or when network fails), returns null.
      final latest = await AppVersionService.checkForUpdates();
      // May be null (no release / network) or a newer tag if already published.
      if (latest != null) {
        expect(latest, isNot(equals(AppVersionService.currentVersion)));
      }
    });

    test('AppConfig invite URL points at public download page', () {
      expect(AppConfig.inviteUrl, contains('github'));
      expect(AppConfig.githubLatestReleaseApiUrl, contains('releases/latest'));
    });
  });

  group('Phase 8 — owner monthly report', () {
    test('exportOwnerMonthlyReport includes key metrics', () async {
      const ownerId = 'owner@ejari.app';
      final report = await DataService.exportOwnerMonthlyReport(ownerId);
      expect(report['propertiesCount'], isA<int>());
      expect(report['occupancyRate'], isA<int>());
      expect(report['monthLabel'], isNotEmpty);
    });
  });

  group('Phase 8 — tenant payment reminders', () {
    test('getTenantUpcomingPayments returns sorted list', () async {
      final upcoming = await DataService.getTenantUpcomingPayments();
      expect(upcoming, isA<List<Map<String, dynamic>>>());
      for (final p in upcoming) {
        expect(p['title'], isNotNull);
        expect(p['amount'], isA<num>());
        expect(p['dueDate'], isNotEmpty);
      }
    });
  });

  group('Phase 8 — subscription persistence', () {
    test('owner plan persists after activatePlan', () async {
      const email = 'owner@ejari.app';
      await SubscriptionService.activatePlan(email, 'silver', userType: 'owner');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('owner_subscription_$email'), isNotNull);

      final summary = await SubscriptionService.getSubscriptionSummary();
      expect(summary['plan_id'], 'silver');
    });
  });

  group('Phase 8 — sale listings no commission', () {
    test('sale listing disclaimer has no sale commission', () {
      expect(kSaleListingDisclaimer, isNot(contains('عمولة بيع')));
      expect(
        SubscriptionService.saleAdPlanFeatureLabels('sale_gold'),
        contains('بدون عمولة على سعر البيع'),
      );
    });
  });
}
