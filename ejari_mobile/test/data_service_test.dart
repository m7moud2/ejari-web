import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('DataService demo persistence', () {
    test('initDemoBookings seeds owner@ejari.app requests', () async {
      await DataService.initProperties();
      await DataService.initDemoBookings();

      final requests = await DataService.getOwnerRequests('owner@ejari.app');
      expect(requests.length, greaterThanOrEqualTo(2));
      expect(
        requests.any((r) =>
            r['status'] == 'pending' || r['status'] == 'submitted'),
        isTrue,
      );
      expect(
        requests.any((r) => r['status'] == 'deposit_paid'),
        isTrue,
      );
    });

    test('getOwnerBookings filters by owner not fake placeholders', () async {
      await DataService.initProperties();
      await DataService.initDemoBookings();

      final ownerBookings =
          await DataService.getOwnerBookings('owner@ejari.app');
      expect(ownerBookings, isNotEmpty);
      expect(
        ownerBookings.any((b) => b['id']?.toString() == 'demo_req_1'),
        isTrue,
      );
    });

    test('updateProperty persists edits', () async {
      await DataService.initProperties();
      final all = await DataService.getAllProperties(approvedOnly: false);
      final original = all.first;
      final id = original['id']?.toString() ?? '';
      expect(id, isNotEmpty);

      await DataService.updateProperty(id, {
        'title': 'عقار معدّل للاختبار',
        'price': '9999',
      });
      final updated = await DataService.getAllProperties(approvedOnly: false);
      final match = updated.firstWhere((p) => p['id']?.toString() == id);
      expect(match['title'], 'عقار معدّل للاختبار');
      expect(match['price'], '9999');
      expect(match['id'], id);
    });

    test('updatePropertyActive persists toggle', () async {
      await DataService.initProperties();
      final all = await DataService.getAllProperties(approvedOnly: false);
      final id = all.first['id']?.toString() ?? '';
      expect(id, isNotEmpty);

      await DataService.updatePropertyActive(id, false);
      final updated = await DataService.getAllProperties(approvedOnly: false);
      final match = updated.firstWhere((p) => p['id']?.toString() == id);
      expect(match['isActive'], false);
    });
  });

  group('DataService refund enforcement', () {
    test('cancelBookingWithRefund returns zero inside 48h window', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk1","title":"شقة","depositAmount":"1000","tenantEmail":"user@ejari.app","status":"deposit_paid"}',
        ],
        'requests': [
          '{"id":"bk1","title":"شقة","depositAmount":"1000","ownerId":"owner@ejari.app","status":"deposit_paid"}',
        ],
        'current_user_email': 'user@ejari.app',
      });

      final checkIn = DateTime.now().add(const Duration(days: 1));
      final result = await DataService.cancelBookingWithRefund(
        bookingId: 'bk1',
        checkInDate: checkIn,
        depositAmount: 1000,
      );

      expect(result['refundable'], false);
      expect(result['refundAmount'], 0.0);
    });

    test('cancelBookingWithRefund refunds when >= 2 days before check-in', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk2","title":"فيلا","depositAmount":"2000","tenantEmail":"user@ejari.app","status":"deposit_paid"}',
        ],
        'requests': [
          '{"id":"bk2","title":"فيلا","depositAmount":"2000","ownerId":"owner@ejari.app","status":"deposit_paid"}',
        ],
        'current_user_email': 'user@ejari.app',
      });

      final checkIn = DateTime.now().add(const Duration(days: 5));
      final result = await DataService.cancelBookingWithRefund(
        bookingId: 'bk2',
        checkInDate: checkIn,
        depositAmount: 2000,
      );

      expect(result['refundable'], true);
      expect(result['refundAmount'], 2000.0);

      final bookings = await DataService.getBookings();
      expect(bookings.first['status'], 'deposit_refunded');
    });
  });

  group('Shared accommodation', () {
    test('initDemoOccupancy seeds 23 tenants for owner', () async {
      await DataService.initProperties();
      await DataService.initDemoOccupancy();
      final tenants =
          await DataService.getOccupancyTenants('owner@ejari.app');
      expect(tenants.length, 23);
    });

    test('getOccupancyCalendar returns vacant beds', () async {
      await DataService.initProperties();
      final cal = await DataService.getOccupancyCalendar('shared_egy1');
      expect(cal['vacantCount'], greaterThan(0));
      expect(cal['occupiedByDate'], isA<Map>());
    });

    test('rateTenant and getTenantRating work', () async {
      await rateTenant();
      final rating = await DataService.getTenantRating('user@ejari.app');
      expect(rating['count'], greaterThan(0));
    });

    test('setDynamicPricing persists', () async {
      await DataService.initProperties();
      final result = await DataService.setDynamicPricing(
        'shared_egy1',
        daily: 160,
        weekly: 850,
        monthly: 2600,
      );
      expect(result['daily'], 160);
      final loaded = await DataService.getDynamicPricing('shared_egy1');
      expect(loaded?['daily'], 160);
    });

    test('isPreEntryPaid detects paid status', () {
      expect(
        DataService.isPreEntryPaid({
          'preEntryPaid': true,
          'depositPaid': true,
          'firstPeriodPaid': true,
        }),
        isTrue,
      );
      expect(
        DataService.isPreEntryPaid({'paymentStatus': 'deposit_paid'}),
        isFalse,
      );
    });
  });
}

Future<void> rateTenant() async {
  await DataService.rateTenant(
    tenantEmail: 'user@ejari.app',
    rating: 4.5,
    paymentReliability: 4.0,
    ownerEmail: 'owner@ejari.app',
  );
}
