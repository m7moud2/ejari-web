import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_user_email': 'user@ejari.app',
      'wallet_balances_v2':
          '{"user@ejari.app":15000,"tech@ejari.app":0,"admin@ejari.app":0}',
    });
  });

  group('MaintenanceService lifecycle', () {
    test('createRequest starts at submitted with timeline', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy1',
        propertyTitle: 'شقة تجريبية',
        category: 'plumbing',
        priority: 'high',
        title: 'تسريب',
        description: 'تسريب في الحمام',
      );

      final req = await MaintenanceService.getRequest(id);
      expect(req, isNotNull);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.submitted);
      expect((req['timeline'] as List).isNotEmpty, isTrue);
    });

    test('full flow assign → complete → pay', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy1',
        category: 'electrical',
        priority: 'medium',
        title: 'كهرباء',
        description: 'عطل',
      );

      await MaintenanceService.assignTechnician(id, 'tech@ejari.app');
      await MaintenanceService.acceptJob(id, 'tech@ejari.app');
      await MaintenanceService.markEnRoute(id, 'tech@ejari.app');
      await MaintenanceService.startJob(id, 'tech@ejari.app');
      await MaintenanceService.completeJob(id, 'tech@ejari.app', 300);

      var req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.pendingClientConfirm);

      final pay = await MaintenanceService.confirmAndPay(
        requestId: id,
        tenantId: 'user@ejari.app',
        useWallet: true,
      );
      expect(pay['success'], isTrue);

      req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']), MaintenanceStatus.paid);
      expect(req['paymentStatus'], 'paid');

      final techBalance =
          await WalletService.getBalance(userId: 'tech@ejari.app');
      expect(techBalance, greaterThan(0));
    });

    test('reject job sets rejected status', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy2',
        category: 'ac',
        priority: 'low',
        title: 'تكييف',
        description: 'فحص',
      );
      await MaintenanceService.assignTechnician(id, 'tech@ejari.app');
      await MaintenanceService.rejectJob(id, 'tech@ejari.app', 'مشغول');

      final req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.rejected);
    });
  });

  group('Provider delegation', () {
    test('getProviderRequests reads from maintenance store', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy1',
        category: 'cleaning',
        priority: 'medium',
        title: 'تنظيف',
        description: 'تنظيف شامل',
      );
      await MaintenanceService.assignTechnician(id, 'tech@ejari.app');

      final jobs = await DataService.getProviderRequests('tech@ejari.app');
      expect(jobs.any((j) => j['id'] == id), isTrue);
    });
  });
}
