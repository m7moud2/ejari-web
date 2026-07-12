import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/subscription_service.dart';
import 'package:ejari_mobile/services/bed_hierarchy_service.dart';
import 'package:ejari_mobile/services/home_stats_cache.dart';
import 'package:ejari_mobile/models/home_stats_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 5 — home stats cache', () {
    test('save and load cached stats by role', () async {
      final stats = HomeStatsModel(
        tenantStats: {'userName': 'اختبار'},
        ownerStats: {'propertiesCount': 3},
        techStats: {'activeJobs': 2},
        adminStats: {'totalUsers': 10},
      );
      await HomeStatsCache.save('tenant', stats);
      final loaded = await HomeStatsCache.load('tenant');
      expect(loaded, isNotNull);
      expect(loaded!.tenantStats['userName'], 'اختبار');
      expect(loaded.ownerStats['propertiesCount'], 3);
    });
  });

  group('Phase 5 — favorites sync', () {
    test('favorites persist per user email across reload', () async {
      await AuthService.login('user@ejari.app', 'user123');
      await DataService.toggleFavorite({
        'id': 'prop1',
        'title': 'شقة تجريبية',
        'price': '5000',
      });
      final favs = await DataService.getFavorites();
      expect(favs.length, 1);
      expect(favs.first['title'], 'شقة تجريبية');

      await DataService.syncFavoritesOnLogin('user@ejari.app');
      final afterSync = await DataService.getFavorites();
      expect(afterSync.length, 1);
    });
  });

  group('Phase 5 — subscription expiry', () {
    test('days until expiry computed correctly', () async {
      await AuthService.login('owner@ejari.app', 'owner123');
      final prefs = await SharedPreferences.getInstance();
      final end = DateTime.now().add(const Duration(days: 5));
      await prefs.setString(
        'owner_subscription_owner@ejari.app',
        '{"plan":"silver","type":"owner","end_date":"${end.toIso8601String()}","active":true}',
      );
      final days = await SubscriptionService.getDaysUntilExpiry();
      expect(days, isNotNull);
      expect(days!, lessThanOrEqualTo(5));
      expect(days, greaterThanOrEqualTo(4));
    });
  });

  group('Phase 5 — bed status inline', () {
    test('updateBedStatus changes bed to maintenance', () async {
      final props = await DataService.getOwnerProperties('owner@ejari.app');
      final shared = props.firstWhere(
        (p) =>
            p['accommodationType'] == 'bed' ||
            p['accommodationType'] == 'shared_room',
        orElse: () => props.first,
      );
      final tree = BedHierarchyService.buildTree(shared);
      final beds = (tree['rooms'] as List?)?.expand(
            (r) => (r['beds'] as List?) ?? [],
          ) ??
          [];
      if (beds.isEmpty) return;

      final bedId = beds.first['id']?.toString() ?? '';
      final ok = await BedHierarchyService.updateBedStatus(
        propertyId: shared['id']?.toString() ?? '',
        bedId: bedId,
        status: 'maintenance',
      );
      expect(ok, isTrue);
    });
  });

  group('Phase 5 — admin daily report', () {
    test('exportAdminDailyReport returns key metrics', () async {
      final report = await DataService.exportAdminDailyReport();
      expect(report['totalUsers'], isNotNull);
      expect(report['generatedAt'], isNotNull);
      expect(report['pendingVerifications'], isNotNull);
    });
  });

  group('Phase 5 — batch payment reminders', () {
    test('batchSendPaymentReminders sends to overdue tenants', () async {
      final count = await DataService.batchSendPaymentReminders(
        'owner@ejari.app',
        [
          {
            'email': 'tenant@ejari.app',
            'id': 'bk1',
            'status': 'متأخر',
          },
        ],
      );
      expect(count, 1);
    });
  });
}
