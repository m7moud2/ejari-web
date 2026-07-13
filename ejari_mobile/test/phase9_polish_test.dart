import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/screens/changelog_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  group('Phase 9 — admin pending counts', () {
    test('pendingProperties counts listing status, not KYC', () async {
      final stats = await DataService.getAdminDashboardStats();
      final pendingProps = (stats['pendingProperties'] as num?)?.toInt() ?? -1;
      final pendingKyc =
          (stats['pendingVerifications'] as num?)?.toInt() ?? -1;

      expect(pendingProps, greaterThanOrEqualTo(0));
      expect(pendingKyc, greaterThanOrEqualTo(0));

      final all = await DataService.getAllProperties(approvedOnly: false);
      final expected =
          all.where((p) => p['status'] == 'pending').length;
      expect(pendingProps, expected);
    });

    test('systemAlerts includes property and KYC queues', () async {
      final stats = await DataService.getAdminDashboardStats();
      final disputes = (stats['openDisputes'] as num?)?.toInt() ?? 0;
      final payments = (stats['pendingPayments'] as num?)?.toInt() ?? 0;
      final props = (stats['pendingProperties'] as num?)?.toInt() ?? 0;
      final kyc = (stats['pendingVerifications'] as num?)?.toInt() ?? 0;
      final alerts = (stats['systemAlerts'] as num?)?.toInt() ?? 0;
      expect(alerts, disputes + payments + props + kyc);
    });
  });

  group('Phase 9 — release UX wiring', () {
    test('changelog lists 1.2.3 track and owner polish', () {
      final latest = ChangelogScreen.releases.first;
      expect(latest.version, '1.2.3');
      expect(
        latest.items.any((i) => i.contains('معاينة') || i.contains('تابع')),
        isTrue,
      );
      expect(
        latest.items.any((i) => i.contains('المالك') || i.contains('تحصيل')),
        isTrue,
      );
    });

    test('owner monthly report still exports', () async {
      final report =
          await DataService.exportOwnerMonthlyReport('owner@ejari.app');
      expect(report['reportLabel']?.toString(), contains('تقرير شهري'));
      expect(report['propertiesCount'], isA<int>());
    });
  });
}
