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
}
