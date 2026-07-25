import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ejari_mobile/models/app_region.dart';
import 'package:ejari_mobile/services/region_service.dart';
import 'package:ejari_mobile/services/payment/payment_gateway.dart';
import 'package:ejari_mobile/services/payment/paymob_payment_gateway.dart';
import 'package:ejari_mobile/services/payment/gulf_payment_gateway.dart';
import 'package:ejari_mobile/services/mock_data_seeder.dart';
import 'package:ejari_mobile/utils/currency_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RegionService.setRegion(AppRegion.egypt);
  });

  group('CurrencyFormatter', () {
    test('formats Egypt with ج.م and no decimals by default', () async {
      await RegionService.setRegion(AppRegion.egypt);
      expect(CurrencyFormatter.symbol, 'ج.م');
      expect(CurrencyFormatter.code, 'EGP');
      expect(CurrencyFormatter.format(15000), '15,000 ج.م');
    });

    test('formats SAR and AED with decimals', () async {
      await RegionService.setRegion(AppRegion.saudiArabia);
      expect(CurrencyFormatter.format(1500), '1,500.00 ر.س');
      await RegionService.setRegion(AppRegion.uae);
      expect(CurrencyFormatter.format(1500), '1,500.00 د.إ');
    });

    test('money() alias tracks active region', () async {
      await RegionService.setRegion(AppRegion.uae);
      expect(money(100), contains('د.إ'));
    });
  });

  group('RegionService', () {
    test('persists country code and defaults Egypt', () async {
      expect(RegionService.current, AppRegion.egypt);
      await RegionService.setRegion(AppRegion.saudiArabia);
      expect(RegionService.current.countryCode, 'SA');
      await RegionService.load();
      expect(RegionService.current, AppRegion.saudiArabia);
    });

    test('filters properties by countryCode (missing = EG)', () {
      final mixed = [
        {'id': '1', 'countryCode': 'EG'},
        {'id': '2', 'countryCode': 'SA'},
        {'id': '3'}, // legacy Egyptian
      ];
      final eg = RegionService.filterProperties(mixed, region: AppRegion.egypt);
      expect(eg.map((e) => e['id']).toList(), ['1', '3']);
      final sa =
          RegionService.filterProperties(mixed, region: AppRegion.saudiArabia);
      expect(sa.map((e) => e['id']).toList(), ['2']);
    });
  });

  group('PaymentGatewayRouter', () {
    test('routes Egypt to Paymob and Gulf to stub', () {
      expect(
        PaymentGatewayRouter.forRegion(AppRegion.egypt),
        isA<PaymobPaymentGateway>(),
      );
      expect(
        PaymentGatewayRouter.forRegion(AppRegion.saudiArabia),
        isA<GulfPaymentGateway>(),
      );
      expect(
        PaymentGatewayRouter.forRegion(AppRegion.uae),
        isA<GulfPaymentGateway>(),
      );
    });

    test('Gulf stub is not configured without dart-defines', () {
      final gulf = GulfPaymentGateway(region: AppRegion.uae);
      expect(gulf.isConfigured, isFalse);
      expect(gulf.shouldUseGateway, isFalse);
    });
  });

  group('MENA demo catalogs', () {
    test('seeds KSA and UAE cities without dropping Egypt', () {
      final eg = MockDataSeeder.getEgyptianProperties();
      final sa = MockDataSeeder.getSaudiProperties();
      final ae = MockDataSeeder.getUaeProperties();
      expect(eg, isNotEmpty);
      expect(eg.every((p) => p['countryCode'] == 'EG'), isTrue);
      expect(sa.any((p) => p['location'].toString().contains('الرياض')), isTrue);
      expect(sa.any((p) => p['location'].toString().contains('جدة')), isTrue);
      expect(ae.any((p) => p['location'].toString().contains('دبي')), isTrue);
      expect(ae.any((p) => p['location'].toString().contains('أبوظبي')), isTrue);
      expect(
        MockDataSeeder.getAllRegionalProperties().length,
        eg.length + sa.length + ae.length,
      );
    });
  });
}
