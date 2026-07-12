import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/offline_cache_service.dart';
import 'package:ejari_mobile/services/push_notification_service.dart';
import 'package:ejari_mobile/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DataService.propertiesLoadedFromCache = false;
    await OfflineCacheService.resetForTests();
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 6 — admin daily report PDF', () {
    test('exportAdminDailyReport includes bookings and KYC metrics', () async {
      final report = await DataService.exportAdminDailyReport();
      expect(report['totalUsers'], isNotNull);
      expect(report['todayBookings'], isNotNull);
      expect(report['platformRevenue'], isNotNull);
      expect(report['pendingVerifications'], isNotNull);
      expect(report['openDisputes'], isNotNull);
      expect(report['generatedAt'], isNotNull);
    });

    test('PdfExportService has shareAdminDailyReportPdf method', () {
      expect(PdfExportService.shareAdminDailyReportPdf, isNotNull);
    });
  });

  group('Phase 6 — push notification categories', () {
    test('all 5 categories defined with Arabic labels', () {
      expect(PushNotificationCategory.values.length, 5);
      expect(
        PushNotificationCategory.paymentOverdue.labelAr,
        'دفعات متأخرة',
      );
      expect(
        PushNotificationCategory.subscriptionExpiring.labelAr,
        'انتهاء الاشتراك',
      );
      expect(
        PushNotificationCategory.bookingCheckIn.labelAr,
        'موعد الدخول',
      );
      expect(
        PushNotificationCategory.newBookingRequest.labelAr,
        'طلبات حجز جديدة',
      );
    });

    test('category toggle persists in SharedPreferences', () async {
      await PushNotificationService.setCategoryEnabled(
        PushNotificationCategory.promotions,
        false,
      );
      final enabled = await PushNotificationService.isCategoryEnabled(
        PushNotificationCategory.promotions,
      );
      expect(enabled, isFalse);

      await PushNotificationService.setCategoryEnabled(
        PushNotificationCategory.promotions,
        true,
      );
      final reEnabled = await PushNotificationService.isCategoryEnabled(
        PushNotificationCategory.promotions,
      );
      expect(reEnabled, isTrue);
    });

    test('master toggle disables all categories', () async {
      await PushNotificationService.setEnabled(false);
      expect(await PushNotificationService.isEnabled(), isFalse);
      expect(
        await PushNotificationService.isCategoryEnabled(
          PushNotificationCategory.paymentOverdue,
        ),
        isFalse,
      );
      await PushNotificationService.setEnabled(true);
    });
  });

  group('Phase 6 — offline cache', () {
    test('save and load properties cache', () async {
      final props = await DataService.getAllProperties();
      expect(props, isNotEmpty);

      await OfflineCacheService.savePropertiesCache(props);
      final cached = await OfflineCacheService.loadCachedProperties();
      expect(cached.length, props.length);
      expect(cached.first['title'], props.first['title']);
    });

    test('save and load favorites cache', () async {
      await AuthService.login('user@ejari.app', 'user123');
      await DataService.toggleFavorite({
        'id': 'offline-prop',
        'title': 'شقة مخزّنة',
        'price': '4000',
      });
      final favs = await DataService.getFavorites();
      await OfflineCacheService.saveFavoritesCache(favs);

      final cached = await OfflineCacheService.loadCachedFavorites();
      expect(cached.any((f) => f['title'] == 'شقة مخزّنة'), isTrue);
    });

    test('loadProperties returns fromCache when API fallback used', () async {
      DataService.propertiesLoadedFromCache = true;
      final result = await OfflineCacheService.loadProperties();
      expect(result.items, isNotEmpty);
      expect(result.fromCache, isTrue);
    });
  });
}
