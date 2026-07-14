import 'package:ejari_mobile/screens/home_screen.dart';
import 'package:ejari_mobile/screens/profile_screen.dart';
import 'package:ejari_mobile/screens/provider_jobs_screen.dart';
import 'package:ejari_mobile/screens/provider_timeline_screen.dart';
import 'package:ejari_mobile/screens/provider_wallet_screen.dart';
import 'package:ejari_mobile/screens/unified_home_screen.dart';
import 'package:ejari_mobile/screens/views/technician_home_view.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:ejari_mobile/providers/auth_provider.dart';
import 'package:ejari_mobile/providers/home_provider.dart';
import 'package:ejari_mobile/providers/property_provider.dart';
import 'package:ejari_mobile/widgets/ejari_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await MaintenanceService.initDemoRequests();
    await MaintenanceService.ensureTechnicianHomeDemo();
    await WalletService.init(userId: 'tech@ejari.app');
    await AuthService.login('tech@ejari.app', 'tech123');
    await AuthService.setUserRole('technician');
  });

  Widget shell({Widget? home}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider.value(value: LiveSyncService.instance),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home ?? const HomeScreen(),
      ),
    );
  }

  testWidgets('technician bottom nav has tech IA labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EjariNavigationBar(
          currentIndex: 0,
          role: 'technician',
          onTap: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المهام'), findsOneWidget);
    expect(find.text('الجدول'), findsOneWidget);
    expect(find.text('المحفظة'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('عقاراتي'), findsNothing);
    expect(find.text('استكشف'), findsNothing);
  });

  testWidgets('technician HomeScreen tabs wire to tech screens', (tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byType(UnifiedHomeScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProviderJobsScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProviderTimelineScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProviderWalletScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProfileScreen, skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('المهام').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('مهام الصيانة'), findsOneWidget);

    await tester.tap(find.text('الجدول').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('جدول المهام'), findsOneWidget);

    await tester.tap(find.text('المحفظة').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('المحفظة والأرباح'), findsOneWidget);

    await tester.tap(find.text('حسابي').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ProfileScreen), findsWidgets);

    await tester.tap(find.text('الرئيسية').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(UnifiedHomeScreen), findsOneWidget);
    expect(find.byType(TechnicianHomeView), findsOneWidget);
  });

  testWidgets('technician home shows active and new jobs without crash',
      (tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();
    // Role resolve + tech home local load (not the heavy HomeProvider fetch).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('لوحة الفني').evaluate().isNotEmpty) break;
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(TechnicianHomeView), findsOneWidget);
    expect(find.text('لوحة الفني'), findsOneWidget);
    expect(find.text('الطلبات الجارية'), findsOneWidget);
    expect(find.text('طلبات جديدة'), findsOneWidget);
    expect(
      find.textContaining('صيانة').evaluate().isNotEmpty ||
          find.textContaining('إصلاح').evaluate().isNotEmpty ||
          find.textContaining('فحص').evaluate().isNotEmpty ||
          find.textContaining('تكييف').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
