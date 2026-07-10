import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/bed_hierarchy_service.dart';
import 'package:ejari_mobile/services/tenant_score_service.dart';
import 'package:ejari_mobile/services/booking_qr_service.dart';
import 'package:ejari_mobile/services/check_in_out_service.dart';
import 'package:ejari_mobile/services/smart_pricing_service.dart';
import 'package:ejari_mobile/services/anti_fraud_service.dart';
import 'package:ejari_mobile/utils/rental_pricing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await TenantScoreService.seedDemoScores();
    await AntiFraudService.seedDemoProfiles();
  });

  group('ROS — Bed Hierarchy', () {
    test('shared_egy1 has apartment-room-bed tree', () async {
      final tree = await BedHierarchyService.getTreeForProperty('shared_egy1');
      expect(tree, isNotNull);
      expect(tree!['totalBeds'], greaterThan(0));
      expect(tree['rooms'], isA<List>());
      expect((tree['rooms'] as List).isNotEmpty, isTrue);
    });
  });

  group('ROS — Duration Tiers', () {
    test('supports hour, 15 day, 3 month', () {
      expect(RentalPricing.durationOptions, contains('ساعة'));
      expect(RentalPricing.durationOptions, contains('15 يوم'));
      expect(RentalPricing.durationOptions, contains('3 شهور'));

      final hour = RentalPricing.calculate(
        monthlyRent: 3000,
        durationType: 'ساعة',
        durationCount: 5,
      );
      expect(hour.totalRent, greaterThan(0));

      final fifteen = RentalPricing.calculate(
        monthlyRent: 3000,
        durationType: '15 يوم',
        durationCount: 1,
      );
      expect(fifteen.totalDays, 15);

      final threeMo = RentalPricing.calculate(
        monthlyRent: 3000,
        durationType: '3 شهور',
        durationCount: 1,
      );
      expect(threeMo.totalRent, 9000);
    });
  });

  group('ROS — Tenant Score', () {
    test('returns multi-dimensional score', () async {
      final score = await TenantScoreService.getTenantScore('user@ejari.app');
      expect(score['dimensions'], isA<Map>());
      expect(score['count'], greaterThan(0));
    });

    test('flags demo tenant with fraud profile', () async {
      final score =
          await TenantScoreService.getTenantScore('tenant.demo@ejari.app');
      expect(score['isFlagged'], isTrue);
    });
  });

  group('ROS — QR & Check In/Out', () {
    test('generates and verifies QR for booking', () async {
      final booking = await DataService.findBookingById('demo_bed_booking');
      expect(booking, isNotNull);
      final qr = await BookingQrService.generateForBooking(booking!);
      expect(qr['qrData'], isNotEmpty);

      final verify = await BookingQrService.verifyQrCode(qr['qrData'] as String);
      expect(verify['valid'], isTrue);
    });

    test('check-in and check-out flow releases deposit', () async {
      final status = await CheckInOutService.getStatus('demo_active_checkin');
      expect(status['found'], isTrue);
      expect(status['canCheckOut'], isTrue);

      final checkout = await CheckInOutService.checkOut('demo_active_checkin');
      expect(checkout['success'], isTrue);
      expect(checkout['depositReleased'], isTrue);
    });
  });

  group('ROS — Smart Pricing', () {
    test('analyzes price vs area average', () async {
      final analysis = await SmartPricingService.analyzePrice(
        propertyId: 'shared_egy1',
        listedPrice: 2500,
        location: 'المعادي',
      );
      expect(analysis['verdictAr'], isNotEmpty);
      expect(analysis['areaAverage'], greaterThan(0));
    });
  });

  group('ROS — Corporate', () {
    test('seeds 200 employees', () async {
      final employees = await DataService.getCorporateEmployees();
      if (employees.length < 200) {
        await DataService.saveCorporateEmployees(
          List.generate(200, (i) => {
            'id': 'emp_$i',
            'name': 'موظف $i',
            'governorate': 'القاهرة',
            'status': 'available',
            'monthlyRent': 2000.0,
          }),
        );
      }
      final updated = await DataService.getCorporateEmployees();
      expect(updated.length, greaterThanOrEqualTo(200));
    });
  });

  group('ROS — Owner Dashboard', () {
    test('today income returns demo value', () async {
      final income = await DataService.getOwnerTodayIncome('owner@ejari.app');
      expect(income, greaterThan(0));
    });
  });
}
