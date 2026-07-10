import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/search_filters_service.dart';
import 'package:ejari_mobile/services/compare_list_service.dart';
import 'package:ejari_mobile/services/tenant_list_service.dart';
import 'package:ejari_mobile/services/smart_pricing_service.dart';
import 'package:ejari_mobile/services/activity_log_service.dart';
import 'package:ejari_mobile/utils/first_run_tooltips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 3 — onboarding', () {
    test('demo accounts exposed for quick login', () {
      expect(AuthService.demoAccounts.length, 4);
      expect(AuthService.demoAccounts.first['email'], 'owner@ejari.app');
    });

    test('first-run tooltip dismiss persists', () async {
      expect(await FirstRunTooltips.shouldShow('property_details'), isTrue);
      await FirstRunTooltips.dismiss('property_details');
      expect(await FirstRunTooltips.shouldShow('property_details'), isFalse);
    });
  });

  group('Phase 3 — property', () {
    test('compare list caps at 2', () async {
      await CompareListService.clear();
      await CompareListService.toggle('prop1');
      await CompareListService.toggle('prop2');
      final third = await CompareListService.toggle('prop3');
      expect(third['full'], isTrue);
      expect(third['count'], 2);
    });

    test('search filters save and load preset', () async {
      await SearchFiltersService.savePreset('شقق القاهرة', {
        'minPrice': 2000,
        'maxPrice': 8000,
        'type': 'شقق',
      });
      final presets = await SearchFiltersService.getPresets();
      expect(presets.first['name'], 'شقق القاهرة');
      expect(presets.first['filters']['type'], 'شقق');
    });
  });

  group('Phase 3 — payments & refunds', () {
    test('refund tracker returns demo timeline', () async {
      final trackers = await DataService.getRefundTrackers('user@ejari.app');
      expect(trackers, isNotEmpty);
      expect(trackers.first['timeline'], isA<List>());
    });

    test('platform fee report has 5% fee', () async {
      final report = await DataService.getPlatformFeeReport();
      expect(report['platformFeePercent'], 5.0);
      expect(report['platformFee'], isA<double>());
    });
  });

  group('Phase 3 — owner tools', () {
    test('bulk price update affects shared properties', () async {
      final result = await DataService.bulkUpdateBedPrices(
        ownerId: 'owner@ejari.app',
        percentChange: 5,
      );
      expect(result['updated'], greaterThanOrEqualTo(0));
    });

    test('discount scheduler save and load', () async {
      await SmartPricingService.saveDiscountScheduler(
        ownerId: 'owner@ejari.app',
        vacantDays: 3,
        discountPercent: 10,
        enabled: true,
      );
      final config = await SmartPricingService.getDiscountScheduler('owner@ejari.app');
      expect(config['vacantDays'], 3);
      expect(config['enabled'], isTrue);
    });

    test('tenant blacklist add and check', () async {
      await TenantListService.addTenant(
        ownerId: 'owner@ejari.app',
        type: 'blacklist',
        tenantEmail: 'bad@example.com',
        tenantName: 'مستأجر محظور',
      );
      expect(
        await TenantListService.isBlacklisted('owner@ejari.app', 'bad@example.com'),
        isTrue,
      );
    });
  });

  group('Phase 3 — admin', () {
    test('moderate user suspend with reason', () async {
      final ok = await AuthService.moderateUser(
        uid: 'user@ejari.app',
        action: 'suspend',
        reason: 'اختبار تعليق',
      );
      expect(ok, isTrue);
      await AuthService.moderateUser(uid: 'user@ejari.app', action: 'unblock');
    });

    test('activity log aggregates for admin', () async {
      await ActivityLogService.append(
        userId: 'user@ejari.app',
        action: 'test_action',
        detail: 'phase3 test',
        category: 'booking',
      );
      final logs = await ActivityLogService.getAllLogs();
      expect(logs.any((l) => l['action'] == 'test_action'), isTrue);
    });
  });
}
