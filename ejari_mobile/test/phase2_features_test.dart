import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/demo_flow_service.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_user_email': 'user@ejari.app',
    });
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await MaintenanceService.initDemoRequests();
  });

  group('Demo flow service', () {
    test('ensureFlowBooking creates shared_egy1 demo booking', () async {
      final booking = await DemoFlowService.ensureFlowBooking();
      expect(booking['propertyId'], 'shared_egy1');
      expect(booking['id'], DemoFlowService.bookingId);
    });

    test('getSteps returns 9 Arabic steps', () async {
      final steps = await DemoFlowService.getSteps();
      expect(steps.length, 9);
      expect(steps.first['title'], contains('البحث'));
    });

    test('advance pay and approve updates booking status', () async {
      await DemoFlowService.ensureFlowBooking();
      final pay = await DemoFlowService.advanceStep('pay');
      expect(pay['success'], isTrue);
      final approve = await DemoFlowService.advanceStep('approve');
      expect(approve['success'], isTrue);
      final booking =
          await DataService.findBookingById(DemoFlowService.bookingId);
      expect(booking?['status'], 'approved');
    });
  });

  group('Maintenance SLA', () {
    test('high priority SLA is 24 hours', () {
      expect(
        MaintenanceStatus.slaDuration('high'),
        const Duration(hours: 24),
      );
    });

    test('medium priority SLA is 48 hours', () {
      expect(
        MaintenanceStatus.slaDuration('medium'),
        const Duration(hours: 48),
      );
    });

    test('overdue request detected', () {
      final overdue = {
        'status': MaintenanceStatus.submitted,
        'priority': 'high',
        'createdAt':
            DateTime.now().subtract(const Duration(hours: 30)).toIso8601String(),
      };
      expect(MaintenanceStatus.isSlaOverdue(overdue), isTrue);
    });

    test('rateTechnician stores rating', () async {
      await MaintenanceService.initDemoRequests();
      final ok = await MaintenanceService.rateTechnician(
        'MNT-DEMO-003',
        4,
        feedback: 'جيد',
      );
      expect(ok, isTrue);
    });
  });

  group('Corporate B2B enhancements', () {
    test('bulk invoice summary has totals', () async {
      final bulk = await DataService.getCorporateBulkInvoiceSummary();
      expect(bulk['grandTotal'], isA<int>());
      expect(bulk['invoiceCount'], isA<int>());
    });

    test('corporate wallet summary tracks spend', () async {
      final wallet = await DataService.getCorporateWalletSummary();
      expect(wallet['balance'], greaterThan(0));
      expect(wallet['totalSpend'], isA<num>());
    });

    test('assignEmployeeToBedBooking creates corporate booking', () async {
      final result = await DataService.assignEmployeeToBedBooking(
        employeeId: 'emp_test_1',
        employeeName: 'اختبار موظف',
        propertyId: 'shared_egy1',
        bedId: 'bed_1',
        bedLabel: 'سرير 1',
      );
      expect(result['success'], isTrue);
    });
  });

  group('Notifications polish', () {
    test('unread count and category breakdown', () async {
      await DataService.addNotificationToUser(
        'user@ejari.app',
        'تأخر في الدفع ⚠️',
        'قسط متأخر',
        type: 'payment_overdue',
      );
      final count = await DataService.getUnreadNotificationCount();
      expect(count, greaterThan(0));
      final cats = await DataService.getUnreadCountByCategory();
      expect(cats['all'], greaterThan(0));
    });

    test('area average price returns market data', () async {
      final avg = await DataService.getAreaAveragePrice('المعادي');
      expect(avg['average'], greaterThan(0));
    });
  });
}
