import 'package:ejari_mobile/models/booking_status.dart';
import 'package:ejari_mobile/screens/booking_track_screen.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await WalletService.init(userId: 'user@ejari.app');
    await AuthService.login('user@ejari.app', 'user123');
    await AuthService.setUserRole('tenant');
  });

  Widget wrap(Widget child) {
    return ChangeNotifierProvider.value(
      value: LiveSyncService.instance,
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  group('detailedTrackTimeline', () {
    test('has 10 happy-path steps with Arabic labels', () {
      final steps = BookingStatus.detailedTrackTimeline({
        'status': BookingStatus.depositPaid,
      });
      expect(steps.length, 10);
      expect(steps.first['label'], 'طلب مُرسل');
      expect(steps[1]['label'], 'دفع العربون / المقدم');
      expect(steps[2]['label'], 'موافقة المالك');
      expect(steps[3]['label'], 'إكمال الدفع');
      expect(steps[4]['label'], 'العقد جاهز');
      expect(steps[5]['label'], 'QR جاهز للدخول');
      expect(steps[6]['label'], contains('تسجيل الدخول'));
      expect(steps[7]['label'], 'الإقامة جارية');
      expect(steps[8]['label'], contains('تسجيل الخروج'));
      expect(steps.last['label'], contains('استرداد'));
    });

    test('marks owner-approval as current after deposit', () {
      final steps = BookingStatus.detailedTrackTimeline({
        'status': BookingStatus.depositPaid,
      });
      final current = steps.where((s) => s['active'] == true).toList();
      expect(current, isNotEmpty);
      expect(current.first['label'], 'موافقة المالك');
    });

    test('nextActionForBooking returns pay after approval', () {
      final next = BookingStatus.nextActionForBooking({
        'status': BookingStatus.approved,
      });
      expect(next?.$2, 'ادفع الآن');
      expect(next?.$3, 'pay');
    });
  });

  group('BookingTrackScreen', () {
    testWidgets('renders track title and timeline for booking map',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final booking = {
        'id': 'track_test_1',
        'title': 'شقة التجريب للتتبع',
        'status': BookingStatus.depositPaid,
        'location': 'القاهرة',
        'depositAmount': 2000,
        'remainingAmount': 8000,
        'monthlyRent': 10000,
        'leaseTotal': 10000,
        'image': 'assets/images/home1.jpg',
        'checkInDate':
            DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'accommodationType': 'full_unit',
      };

      await tester.pumpWidget(
        wrap(BookingTrackScreen(booking: booking)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تابع حجزك'), findsWidgets);
      expect(find.text('شقة التجريب للتتبع'), findsOneWidget);
      expect(find.text('مسار الحجز'), findsWidgets);
      expect(find.text('طلب مُرسل'), findsOneWidget);
      expect(find.text('دفع العربون / المقدم'), findsOneWidget);
      expect(find.textContaining('ادفع'), findsNothing);
      expect(find.textContaining('موافقة المالك'), findsWidgets);
    });

    testWidgets('shows pay CTA when approved', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const BookingTrackScreen(
            booking: {
              'id': 'track_pay_1',
              'title': 'وحدة جاهزة للدفع',
              'status': BookingStatus.approved,
              'remainingAmount': 5000,
              'depositAmount': 1000,
              'monthlyRent': 6000,
              'leaseTotal': 6000,
              'location': 'الجيزة',
              'image': 'assets/images/home1.jpg',
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('ادفع الآن'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('تفصيل الدفع'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('تفصيل الدفع'), findsOneWidget);
    });

    testWidgets('shows not-found for missing booking id', (tester) async {
      await tester.pumpWidget(
        wrap(const BookingTrackScreen(bookingId: 'does_not_exist_xyz')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('لم يتم العثور على الحجز'), findsOneWidget);
    });
  });
}
