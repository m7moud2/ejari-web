import 'package:ejari_mobile/models/viewing_appointment.dart';
import 'package:ejari_mobile/screens/changelog_screen.dart';
import 'package:ejari_mobile/screens/my_viewings_screen.dart';
import 'package:ejari_mobile/screens/payment_reminders_screen.dart';
import 'package:ejari_mobile/screens/views/owner_home_view.dart';
import 'package:ejari_mobile/screens/views/tenant_home_view.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
import 'package:ejari_mobile/services/viewing_appointment_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:ejari_mobile/providers/auth_provider.dart';
import 'package:ejari_mobile/providers/home_provider.dart';
import 'package:ejari_mobile/providers/property_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await ViewingAppointmentService.ensureDemoSeed();
  });

  Widget shell(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider.value(value: LiveSyncService.instance),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: home),
    );
  }

  test('demo viewings include requested and confirmed for QA path', () async {
    final all = await ViewingAppointmentService.getAll();
    final ids = all.map((a) => a.id).toSet();
    expect(ids.contains('view_demo_1'), isTrue);
    expect(ids.contains('view_demo_confirmed'), isTrue);

    final requested = all.firstWhere((a) => a.id == 'view_demo_1');
    final confirmed = all.firstWhere((a) => a.id == 'view_demo_confirmed');
    expect(ViewingStatus.normalize(requested.status), ViewingStatus.requested);
    expect(ViewingStatus.normalize(confirmed.status), ViewingStatus.confirmed);
  });

  testWidgets('tenant home surfaces معاينة and payment reminders entry',
      (tester) async {
    await WalletService.init(userId: 'user@ejari.app');
    await AuthService.login('user@ejari.app', 'user123');
    await AuthService.setUserRole('tenant');

    await tester.pumpWidget(shell(const Scaffold(body: TenantHomeView())));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('معاينة'), findsWidgets);
    expect(find.text('ادفع'), findsOneWidget);
    expect(find.text('صيانة'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
    expect(find.text('الدفع'), findsOneWidget); // quick-look → reminders
  });

  testWidgets('owner home surfaces صيانة beside معاينة and QR', (tester) async {
    await WalletService.init(userId: 'owner@ejari.app');
    await AuthService.login('owner@ejari.app', 'owner123');
    await AuthService.setUserRole('owner');

    await tester.pumpWidget(shell(const Scaffold(body: OwnerHomeView())));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('معاينة'), findsWidgets);
    expect(find.text('تحقق QR'), findsOneWidget);
    expect(find.text('صيانة'), findsOneWidget);
    expect(find.text('شجرة الأسرّة'), findsNothing);
  });

  testWidgets('payment reminders screen builds', (tester) async {
    await WalletService.init(userId: 'user@ejari.app');
    await AuthService.login('user@ejari.app', 'user123');
    await AuthService.setUserRole('tenant');

    await tester.pumpWidget(shell(const PaymentRemindersScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('تذكيرات الدفع'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
  });

  testWidgets('my viewings loads demo appointments', (tester) async {
    await WalletService.init(userId: 'user@ejari.app');
    await AuthService.login('user@ejari.app', 'user123');
    await AuthService.setUserRole('tenant');

    await tester.pumpWidget(shell(const MyViewingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('مواعيدي للمعاينة'), findsOneWidget);
    expect(find.textContaining('شقة فاخرة'), findsWidgets);
  });

  test('changelog starts with 1.3.14', () {
    final latest = ChangelogScreen.releases.first;
    expect(latest.version, '1.3.14');
    expect(latest.items.any((i) => i.contains('معاينة')), isTrue);
  });
}
