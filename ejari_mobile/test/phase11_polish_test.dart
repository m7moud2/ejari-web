import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/models/booking_status.dart';
import 'package:ejari_mobile/models/viewing_appointment.dart';
import 'package:ejari_mobile/repositories/home_repository.dart';
import 'package:ejari_mobile/screens/changelog_screen.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/viewing_appointment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 11 — booking track CTAs', () {
    test('viewing next-action is actionable for deposit_paid', () {
      final next = BookingStatus.nextActionForBooking({
        'status': BookingStatus.depositPaid,
      });
      expect(next, isNotNull);
      expect(next!.$3, 'viewing');
      expect(next.$2, contains('معاينة'));
    });

    test('pay next-action remains for approved bookings', () {
      final next = BookingStatus.nextActionForBooking({
        'status': BookingStatus.approved,
      });
      expect(next?.$3, 'pay');
    });
  });

  group('Phase 11 — owner home access', () {
    test('owner stats expose pendingViewings and collection fields', () async {
      await AuthService.login('owner@ejari.app', 'owner123');
      final stats = await HomeRepository().fetchHomeStats('owner');
      final owner = stats.ownerStats;
      expect(owner.containsKey('pendingViewings'), isTrue);
      expect(owner.containsKey('pendingCollection'), isTrue);
      expect(owner['pendingViewings'], isA<num>());
      expect(owner['pendingCollection'], isA<num>());
    });

    test('owner contextual prefers pending viewings when present', () async {
      await AuthService.login('owner@ejari.app', 'owner123');
      await ViewingAppointmentService.ensureDemoSeed();
      final stats = await HomeRepository().fetchHomeStats('owner');
      final action = stats.ownerStats['contextualAction'] as Map?;
      final pending =
          (stats.ownerStats['pendingViewings'] as num?)?.toInt() ?? 0;
      if (pending > 0) {
        expect(action?['icon'], 'viewings');
        expect(action?['title']?.toString(), contains('معاينة'));
      }
    });
  });

  group('Phase 11 — cross-role notifications', () {
    test('viewing request notifies tenant and owner', () async {
      await AuthService.login('user@ejari.app', 'user123');
      final props = await DataService.getAllProperties();
      final property = Map<String, dynamic>.from(props.first);
      property['ownerEmail'] = 'owner@ejari.app';
      property['ownerId'] = 'owner@ejari.app';

      final slot = DateTime.now().add(const Duration(days: 5, hours: 3));
      final result = await ViewingAppointmentService.requestViewing(
        property: property,
        scheduledAt: DateTime(slot.year, slot.month, slot.day, 17, 0),
        note: 'phase11-viewing',
      );
      expect(result['success'], isTrue);

      final tenantNotes =
          await DataService.getNotificationsForUser('user@ejari.app');
      final ownerNotes =
          await DataService.getNotificationsForUser('owner@ejari.app');
      expect(
        tenantNotes.any((n) =>
            n['type'] == 'viewing' &&
            (n['title']?.toString() ?? '').contains('معاينة')),
        isTrue,
      );
      expect(
        ownerNotes.any((n) =>
            n['type'] == 'viewing' &&
            (n['title']?.toString() ?? '').contains('معاينة')),
        isTrue,
      );

      final viewId = result['id']?.toString() ?? '';
      expect(viewId, isNotEmpty);

      await AuthService.login('owner@ejari.app', 'owner123');
      final confirm = await ViewingAppointmentService.updateStatus(
        id: viewId,
        newStatus: ViewingStatus.confirmed,
        actorRole: 'owner',
        actorEmail: 'owner@ejari.app',
      );
      expect(confirm['success'], isTrue);

      final tenantAfter =
          await DataService.getNotificationsForUser('user@ejari.app');
      expect(
        tenantAfter.any((n) =>
            (n['title']?.toString() ?? '').contains('تأكيد') ||
            (n['title']?.toString() ?? '').contains('مؤكد') ||
            (n['body']?.toString() ?? '').contains('مؤكدة')),
        isTrue,
      );
    });

    test('booking payment notifies both parties', () async {
      await AuthService.login('user@ejari.app', 'user123');
      final bookings = await DataService.getBookings();
      expect(bookings, isNotEmpty);
      final booking = Map<String, dynamic>.from(bookings.first);
      final id = booking['id']?.toString() ?? '';
      expect(id, isNotEmpty);

      await DataService.updateRequestStatus(id, BookingStatus.approved);
      final pay = await DataService.payForBooking(
        id,
        amount: 500,
        method: 'wallet',
        useWallet: false,
      );
      expect(pay['success'], isTrue);

      final tenantNotes =
          await DataService.getNotificationsForUser('user@ejari.app');
      final ownerEmail =
          booking['ownerEmail']?.toString() ?? booking['ownerId']?.toString();
      if (ownerEmail != null && ownerEmail.isNotEmpty) {
        final ownerNotes =
            await DataService.getNotificationsForUser(ownerEmail);
        expect(
          ownerNotes.any((n) =>
              n['type'] == 'booking' ||
              (n['title']?.toString() ?? '').contains('دفع') ||
              (n['title']?.toString() ?? '').contains('عربون') ||
              (n['body']?.toString() ?? '').contains('دفع')),
          isTrue,
        );
      }
      expect(tenantNotes, isNotEmpty);
    });
  });

  group('Phase 11 — release metadata', () {
    test('version bumped to 1.2.3', () {
      expect(AppConfig.appVersion, '1.2.3');
      expect(AppConfig.buildNumber, 14);
    });

    test('changelog lists 1.2.3 polish items', () {
      final latest = ChangelogScreen.releases.first;
      expect(latest.version, '1.2.3');
      expect(latest.items.any((i) => i.contains('معاينة')), isTrue);
      expect(latest.items.any((i) => i.contains('دفع')), isTrue);
      expect(latest.items.any((i) => i.contains('المالك')), isTrue);
    });
  });
}
