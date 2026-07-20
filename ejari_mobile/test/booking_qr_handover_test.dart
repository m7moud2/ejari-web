import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/models/booking_status.dart';
import 'package:ejari_mobile/services/booking_qr_service.dart';
import 'package:ejari_mobile/services/check_in_out_service.dart';
import 'package:ejari_mobile/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('QR handover cycle', () {
    test('QR not ready until paid', () {
      expect(
        BookingQrService.isQrReady({'status': BookingStatus.approved}),
        false,
      );
      expect(
        BookingQrService.isQrReady({'status': BookingStatus.depositPaid}),
        false,
      );
      expect(
        BookingQrService.isQrReady({'status': BookingStatus.paid}),
        true,
      );
      expect(
        BookingQrService.canConfirmHandover({
          'status': BookingStatus.paid,
        }),
        true,
      );
      expect(
        BookingQrService.canConfirmHandover({
          'status': BookingStatus.paid,
          'checkedInAt': '2026-07-01T10:00:00.000',
        }),
        false,
      );
    });

    test('generate + verify QR then confirm handover check-in', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk_qr_1","status":"paid","title":"شقة اختبار",'
          '"tenantEmail":"tenant@ejari.app","tenantName":"مستأجر",'
          '"ownerEmail":"owner@ejari.app","propertyId":"p1",'
          '"checkInDate":"2026-08-01","depositAmount":500}',
        ],
        'requests': [
          '{"id":"bk_qr_1","status":"paid","title":"شقة اختبار",'
          '"tenantEmail":"tenant@ejari.app","tenantName":"مستأجر",'
          '"ownerEmail":"owner@ejari.app","propertyId":"p1",'
          '"checkInDate":"2026-08-01","depositAmount":500}',
        ],
      });

      final booking = await DataService.findBookingById('bk_qr_1');
      expect(booking, isNotNull);

      final qr = await BookingQrService.generateForBooking(booking!);
      expect(qr['qrData']?.toString().startsWith('EJARI|'), true);

      final verify =
          await BookingQrService.verifyQrCode(qr['qrData'] as String);
      expect(verify['valid'], true);
      expect(verify['canConfirmHandover'], true);

      final handover = await CheckInOutService.confirmHandover('bk_qr_1');
      expect(handover['success'], true);
      expect(handover['handover'], true);

      final after = await DataService.findBookingById('bk_qr_1');
      expect(after?['status'], BookingStatus.active);
      expect(after?['checkedInAt'], isNotNull);

      final again = await CheckInOutService.confirmHandover('bk_qr_1');
      expect(again['success'], false);
    });

    test('handover blocked when only approved (not paid)', () async {
      SharedPreferences.setMockInitialValues({
        'bookings': [
          '{"id":"bk_qr_2","status":"approved","title":"شقة",'
          '"tenantEmail":"t@ejari.app","ownerEmail":"o@ejari.app",'
          '"propertyId":"p1","checkInDate":"2026-08-01"}',
        ],
        'requests': [
          '{"id":"bk_qr_2","status":"approved","title":"شقة",'
          '"tenantEmail":"t@ejari.app","ownerEmail":"o@ejari.app",'
          '"propertyId":"p1","checkInDate":"2026-08-01"}',
        ],
      });

      final r = await CheckInOutService.confirmHandover('bk_qr_2');
      expect(r['success'], false);
      expect(r['message']?.toString().contains('دفع'), true);
    });

    test('next action after paid is show QR', () {
      final next = BookingStatus.nextActionForBooking({
        'status': BookingStatus.paid,
      });
      expect(next?.$3, 'qr_checkin');

      final wait = BookingStatus.nextActionForBooking({
        'status': BookingStatus.depositPaid,
      });
      expect(wait?.$3, 'wait');
    });
  });
}
