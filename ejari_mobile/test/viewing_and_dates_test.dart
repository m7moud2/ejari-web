import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ejari_mobile/models/viewing_appointment.dart';
import 'package:ejari_mobile/services/viewing_appointment_service.dart';
import 'package:ejari_mobile/utils/date_utils.dart';
import 'package:ejari_mobile/utils/rental_rules.dart';
import 'package:ejari_mobile/utils/rental_schedule_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DateParsing', () {
    test('parses ISO and rejects null text', () {
      expect(DateParsing.parse('2026-07-13T14:30:00.000Z'), isNotNull);
      expect(DateParsing.parse('null'), isNull);
      expect(DateParsing.parse(''), isNull);
      expect(DateParsing.parse(null), isNull);
    });

    test('display never returns literal null', () {
      expect(DateParsing.display(null), '—');
      expect(DateParsing.display('null'), '—');
      expect(DateParsing.display('2026-08-01'), isNot(contains('null')));
    });

    test('normalizeBookingDates unifies aliases', () {
      final booking = <String, dynamic>{
        'requestDate': '2026-07-01T10:00:00.000Z',
        'leaseStartDate': '2026-08-01T00:00:00.000Z',
        'leaseEndDate': '2027-02-01T00:00:00.000Z',
      };
      DateParsing.normalizeBookingDates(booking);
      expect(booking['createdAt'], isNotNull);
      expect(booking['checkInDate'], isNotNull);
      expect(booking['checkOutDate'], isNotNull);
      expect(booking['startDate'], booking['checkInDate']);
    });

    test('bookingCheckIn prefers checkInDate', () {
      final dt = DateParsing.bookingCheckIn({
        'checkInDate': '2026-09-15T00:00:00.000Z',
        'leaseStartDate': '2026-09-01T00:00:00.000Z',
      });
      expect(dt?.day, 15);
    });
  });

  group('Refund window with checkIn (≥48h)', () {
    final checkIn = DateTime(2026, 8, 10, 12, 0);

    test('refundable at exactly 48 hours', () {
      final cancel = DateTime(2026, 8, 8, 12, 0);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        true,
      );
    });

    test('not refundable at 47 hours', () {
      final cancel = DateTime(2026, 8, 8, 13, 0);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        false,
      );
    });

    test('refundable well before check-in', () {
      final cancel = DateTime(2026, 8, 7, 12, 0);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        true,
      );
    });
  });

  group('Installment due dates from check-in', () {
    test('monthly dues start at checkIn then +1 month', () {
      final checkIn = DateTime(2026, 1, 15);
      final booking = {
        'checkInDate': checkIn.toIso8601String(),
        'leaseStartDate': checkIn.toIso8601String(),
        'leaseMonths': 6,
        'duration': '6 شهر',
        'durationLabel': '6 شهر',
        'monthlyRent': 10000,
        'showInstallments': true,
        'status': 'approved',
        'paidMonths': 0,
      };
      final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
      expect(snapshot['startDate'], checkIn);
      final firstDue = snapshot['startDate'] as DateTime;
      final second = RentalScheduleUtils.addMonths(firstDue, 1);
      expect(second.month, 2);
      expect(second.day, 15);
    });
  });

  group('ViewingStatus transitions', () {
    test('requested → confirmed → completed', () {
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.requested,
          ViewingStatus.confirmed,
        ),
        true,
      );
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.confirmed,
          ViewingStatus.completed,
        ),
        true,
      );
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.completed,
          ViewingStatus.confirmed,
        ),
        false,
      );
    });

    test('requested → rejected / cancelled', () {
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.requested,
          ViewingStatus.rejected,
        ),
        true,
      );
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.requested,
          ViewingStatus.cancelled,
        ),
        true,
      );
    });

    test('confirmed → no_show', () {
      expect(
        ViewingStatus.canTransition(
          ViewingStatus.confirmed,
          ViewingStatus.noShow,
        ),
        true,
      );
    });

    test('arabic labels', () {
      expect(ViewingStatus.arabicLabel(ViewingStatus.requested),
          contains('انتظار'));
      expect(ViewingStatus.arabicLabel(ViewingStatus.confirmed),
          contains('مؤكد'));
    });
  });

  group('ViewingAppointmentService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('validateSlot rejects past', () {
      final err = ViewingAppointmentService.validateSlot(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(err, isNotNull);
    });

    test('validateSlot accepts future daytime', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slot = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16);
      expect(ViewingAppointmentService.validateSlot(slot), isNull);
    });

    test('request rejects sale listings', () async {
      final result = await ViewingAppointmentService.requestViewing(
        property: {
          'id': 'sale1',
          'title': 'شقة للبيع',
          'listingMode': 'for_sale',
          'ownerEmail': 'owner@ejari.app',
        },
        scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
      );
      expect(result['success'], false);
      expect(result['message']?.toString(), contains('الإيجار'));
    });

    test('owner status update enforces ownership', () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'owner@ejari.app',
        'current_user_role': 'owner',
        'viewing_appointments_v1': [
          '{"id":"v1","propertyId":"p1","propertyTitle":"شقة","tenantEmail":"user@ejari.app","tenantName":"مستأجر","ownerEmail":"other@ejari.app","scheduledAt":"2026-08-01T16:00:00.000","status":"requested","createdAt":"2026-07-13T10:00:00.000","tenantAttended":false,"ownerMarkedComplete":false}',
        ],
        'viewing_appointments_demo_v1': true,
      });

      final result = await ViewingAppointmentService.updateStatus(
        id: 'v1',
        newStatus: ViewingStatus.confirmed,
        actorRole: 'owner',
        actorEmail: 'owner@ejari.app',
      );
      expect(result['success'], false);
      expect(result['message']?.toString(), contains('مصرح'));
    });

    test('happy path confirm by owner', () async {
      SharedPreferences.setMockInitialValues({
        'current_user_email': 'owner@ejari.app',
        'current_user_role': 'owner',
        'viewing_appointments_v1': [
          '{"id":"v2","propertyId":"p1","propertyTitle":"شقة","tenantEmail":"user@ejari.app","tenantName":"مستأجر","ownerEmail":"owner@ejari.app","scheduledAt":"2026-08-01T16:00:00.000","status":"requested","createdAt":"2026-07-13T10:00:00.000","tenantAttended":false,"ownerMarkedComplete":false}',
        ],
        'viewing_appointments_demo_v1': true,
      });

      final result = await ViewingAppointmentService.updateStatus(
        id: 'v2',
        newStatus: ViewingStatus.confirmed,
        actorRole: 'owner',
        actorEmail: 'owner@ejari.app',
      );
      expect(result['success'], true);
      final appt = ViewingAppointment.fromJson(
        Map<String, dynamic>.from(result['appointment'] as Map),
      );
      expect(appt.status, ViewingStatus.confirmed);
      expect(appt.confirmedAt, isNotNull);
    });
  });
}
