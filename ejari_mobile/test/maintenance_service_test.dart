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

  group('MaintenanceStatus', () {
    test('normalize maps aliases including arrived', () {
      expect(MaintenanceStatus.normalize('pending'), MaintenanceStatus.submitted);
      expect(MaintenanceStatus.normalize('en_route'), MaintenanceStatus.enRoute);
      expect(MaintenanceStatus.normalize('arrived'), MaintenanceStatus.arrived);
      expect(MaintenanceStatus.normalize('وصل'), MaintenanceStatus.arrived);
      expect(MaintenanceStatus.normalize('waiting_for_confirmation'),
          MaintenanceStatus.pendingClientConfirm);
    });

    test('tracking steps are 8 Arabic stages', () {
      expect(MaintenanceStatus.trackingStepsAr.length, 8);
      expect(MaintenanceStatus.trackingStepIndex(MaintenanceStatus.arrived), 3);
      expect(MaintenanceStatus.trackingStepIndex(MaintenanceStatus.paid), 7);
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

    test('full flow assign → arrive → complete → confirm → pay', () async {
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

      var req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.enRoute);

      await MaintenanceService.markArrived(id, 'tech@ejari.app');
      req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.arrived);

      await MaintenanceService.startJob(id, 'tech@ejari.app');
      await MaintenanceService.completeJob(id, 'tech@ejari.app', 300);

      req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.pendingClientConfirm);

      final confirmed = await MaintenanceService.confirmCompletion(
        id,
        'user@ejari.app',
      );
      expect(confirmed, isTrue);

      req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.completed);

      final pay = await MaintenanceService.confirmAndPay(
        requestId: id,
        tenantId: 'user@ejari.app',
        useWallet: true,
        confirmIfNeeded: false,
      );
      expect(pay['success'], isTrue);

      req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']), MaintenanceStatus.paid);
      expect(req['paymentStatus'], 'paid');

      final techBalance =
          await WalletService.getBalance(userId: 'tech@ejari.app');
      expect(techBalance, greaterThan(0));
    });

    test('confirmAndPay from pending_client_confirm still works', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy1',
        category: 'ac',
        priority: 'high',
        title: 'تكييف',
        description: 'لا يبرد',
      );
      await MaintenanceService.assignTechnician(id, 'tech@ejari.app');
      await MaintenanceService.acceptJob(id, 'tech@ejari.app');
      await MaintenanceService.markEnRoute(id, 'tech@ejari.app');
      await MaintenanceService.markArrived(id, 'tech@ejari.app');
      await MaintenanceService.startJob(id, 'tech@ejari.app');
      await MaintenanceService.completeJob(id, 'tech@ejari.app', 200);

      final pay = await MaintenanceService.confirmAndPay(
        requestId: id,
        tenantId: 'user@ejari.app',
      );
      expect(pay['success'], isTrue);
      final req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']), MaintenanceStatus.paid);
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

    test('dispute after completion', () async {
      final id = await MaintenanceService.createRequest(
        userId: 'user@ejari.app',
        propertyId: 'egy1',
        category: 'plumbing',
        priority: 'urgent',
        title: 'تسريب',
        description: 'عاجل',
      );
      await MaintenanceService.assignTechnician(id, 'tech@ejari.app');
      await MaintenanceService.acceptJob(id, 'tech@ejari.app');
      await MaintenanceService.markEnRoute(id, 'tech@ejari.app');
      await MaintenanceService.markArrived(id, 'tech@ejari.app');
      await MaintenanceService.startJob(id, 'tech@ejari.app');
      await MaintenanceService.completeJob(id, 'tech@ejari.app', 180);
      await MaintenanceService.disputeCompletion(
        id,
        'user@ejari.app',
        'الجودة غير مرضية',
      );
      final req = await MaintenanceService.getRequest(id);
      expect(MaintenanceStatus.normalize(req!['status']),
          MaintenanceStatus.disputed);
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
