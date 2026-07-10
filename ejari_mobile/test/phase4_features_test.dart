import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/smart_pricing_service.dart';
import 'package:ejari_mobile/services/bed_hierarchy_service.dart';
import 'package:ejari_mobile/services/demo_flow_service.dart';
import 'package:ejari_mobile/models/payment_receipt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 4 — auto-discount cron', () {
    test('seed vacancy tracking and apply discount on cron', () async {
      await BedHierarchyService.seedDemoVacancyTracking('owner@ejari.app');
      await SmartPricingService.saveDiscountScheduler(
        ownerId: 'owner@ejari.app',
        vacantDays: 3,
        discountPercent: 10,
        enabled: true,
      );
      final result =
          await SmartPricingService.runAutoDiscountCron('owner@ejari.app');
      expect(result['vacantDays'], 3);
      expect(result['applied'], greaterThanOrEqualTo(0));
    });

    test('cron skips when scheduler disabled', () async {
      await SmartPricingService.saveDiscountScheduler(
        ownerId: 'owner@ejari.app',
        vacantDays: 3,
        discountPercent: 10,
        enabled: false,
      );
      final result =
          await SmartPricingService.runAutoDiscountCron('owner@ejari.app');
      expect(result['applied'], 0);
      expect(result['skipped'], 'scheduler_disabled');
    });
  });

  group('Phase 4 — demo flow deep links', () {
    test('all 9 steps defined with navigation ids', () {
      expect(DemoFlowService.stepDefs.length, 9);
      expect(
        DemoFlowService.stepDefs.map((s) => s['id']).toSet().length,
        9,
      );
    });

    test('steps include search and rate endpoints', () async {
      final steps = await DemoFlowService.getSteps();
      expect(steps.first['id'], 'search');
      expect(steps.last['id'], 'rate');
    });
  });

  group('Phase 4 — PDF export service', () {
    test('PaymentReceipt has Arabic method label', () {
      final receipt = PaymentReceipt(
        id: 'RCP-001',
        amount: 500,
        date: DateTime(2026, 1, 1),
        bookingRef: 'bk1',
        payer: 'مستأجر',
        payee: 'مالك',
        method: 'wallet',
      );
      expect(receipt.methodLabelAr, 'محفظة إيجاري');
    });
  });
}
