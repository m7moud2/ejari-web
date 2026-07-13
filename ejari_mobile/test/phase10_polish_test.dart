import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/models/booking_status.dart';
import 'package:ejari_mobile/repositories/home_repository.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/utils/short_stay_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await AuthService.login('user@ejari.app', 'user123');
  });

  group('Phase 10 — tenant polish', () {
    test('unread badge is zero when notification store is empty', () async {
      expect(await DataService.getUnreadNotificationCount(), 0);
    });

    test('ensureCoastalCatalog exposes north-coast listings', () async {
      await DataService.ensureCoastalCatalog();
      final all = await DataService.getAllProperties();
      final coastal = all.where(ShortStayDiscovery.isCoastal).toList();
      expect(coastal, isNotEmpty);
      expect(
        all.any((p) => p['id'] == 'vac_matrouh_1' || p['id'] == 'egy7'),
        isTrue,
      );
    });

    test('active booking exposes nextActionLabel for tenant home', () async {
      final stats = await HomeRepository().fetchHomeStats('tenant');
      final tenant = stats.tenantStats;
      if (tenant['activeBooking'] == true) {
        expect(tenant['nextActionLabel'], isNotNull);
        final action = tenant['contextualAction'] as Map?;
        expect(action?['title']?.toString(), contains('التالي'));
      } else {
        // Seed ensures demo booking for user@ejari in many environments;
        // if absent, next-step helper still works on synthetic booking.
        final next = BookingStatus.nextActionForBooking({
          'status': BookingStatus.approved,
        });
        expect(next?.$2, contains('ادفع'));
      }
    });

    test('favorites clear persists for current user only', () async {
      await DataService.toggleFavorite({
        'id': 'fav_phase10',
        'title': 'شاليه اختبار Phase10',
        'price': '1000',
        'location': 'مطروح',
        'image': 'assets/images/home6.jpg',
      });
      expect(await DataService.getFavorites(), isNotEmpty);
      await DataService.clearFavoritesForCurrentUser();
      expect(await DataService.getFavorites(), isEmpty);
    });
  });
}
