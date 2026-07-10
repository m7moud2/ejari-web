import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/models/booking_status.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/utils/booking_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookingStatus state machine', () {
    test('submitted can move to deposit_paid', () {
      expect(
        BookingStatus.canTransition(
            BookingStatus.submitted, BookingStatus.depositPaid),
        true,
      );
    });

    test('deposit_paid can move to approved', () {
      expect(
        BookingStatus.canTransition(
            BookingStatus.depositPaid, BookingStatus.approved),
        true,
      );
    });

    test('approved can move to paid', () {
      expect(
        BookingStatus.canTransition(BookingStatus.approved, BookingStatus.paid),
        true,
      );
    });

    test('completed is terminal', () {
      expect(
        BookingStatus.canTransition(
            BookingStatus.completed, BookingStatus.cancelled),
        false,
      );
    });

    test('deposit_paid cannot skip to paid', () {
      expect(
        BookingStatus.canTransition(BookingStatus.depositPaid, BookingStatus.paid),
        false,
      );
    });
  });

  group('BookingValidator', () {
    test('detects overlapping bookings', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 9, 1);
      final conflict = BookingValidator.hasDateConflict(
        existingBookings: [
          {
            'id': 'b1',
            'propertyId': 'p1',
            'status': BookingStatus.depositPaid,
            'leaseStartDate': start.toIso8601String(),
            'leaseEndDate': end.toIso8601String(),
          },
        ],
        propertyId: 'p1',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 10, 1),
      );
      expect(conflict, true);
    });

    test('rejects tampered monthly rent', () async {
      await DataService.initProperties();
      final property = (await DataService.getAllProperties()).first;
      final result = BookingValidator.validateRequest(
        request: {
          'propertyId': property['id'],
          'monthlyRent': '1',
          'depositAmount': '500',
          'leaseStartDate':
              DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'leaseEndDate':
              DateTime.now().add(const Duration(days: 40)).toIso8601String(),
          'durationType': 'شهر',
          'durationCount': 1,
        },
        existingBookings: [],
        property: property,
      );
      expect(result['valid'], false);
    });
  });

  group('DataService transition enforcement', () {
    test('invalid transition is rejected', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk3","status":"deposit_paid","ownerId":"owner@ejari.app","tenantEmail":"user@ejari.app"}',
        ],
        'requests': [
          '{"id":"bk3","status":"deposit_paid","ownerId":"owner@ejari.app","tenantEmail":"user@ejari.app"}',
        ],
      });

      final ok = await DataService.updateRequestStatus('bk3', BookingStatus.paid);
      expect(ok, false);
    });

    test('valid owner approval transition succeeds', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk4","status":"deposit_paid","ownerId":"owner@ejari.app","ownerEmail":"owner@ejari.app","tenantEmail":"user@ejari.app","title":"شقة"}',
        ],
        'requests': [
          '{"id":"bk4","status":"deposit_paid","ownerId":"owner@ejari.app","ownerEmail":"owner@ejari.app","tenantEmail":"user@ejari.app","title":"شقة"}',
        ],
        'current_user_email': 'owner@ejari.app',
      });

      final ok =
          await DataService.updateRequestStatus('bk4', BookingStatus.approved);
      expect(ok, true);

      final requests = await DataService.getOwnerRequests('owner@ejari.app');
      expect(requests.first['status'], BookingStatus.approved);
    });
  });
}
