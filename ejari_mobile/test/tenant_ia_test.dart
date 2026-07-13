import 'package:ejari_mobile/screens/home_screen.dart';
import 'package:ejari_mobile/screens/my_bookings_screen.dart';
import 'package:ejari_mobile/screens/profile_screen.dart';
import 'package:ejari_mobile/screens/properties_screen.dart';
import 'package:ejari_mobile/screens/tenant_wallet_screen.dart';
import 'package:ejari_mobile/screens/unified_home_screen.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:ejari_mobile/widgets/ejari_navigation_bar.dart';
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
    await WalletService.init(userId: 'user@ejari.app');
    await AuthService.login('user@ejari.app', 'user123');
    await AuthService.setUserRole('tenant');
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

  testWidgets('tenant bottom nav has focused IA labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EjariNavigationBar(
          currentIndex: 0,
          role: 'tenant',
          onTap: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('استكشف'), findsOneWidget);
    expect(find.text('حجوزاتي'), findsOneWidget);
    expect(find.text('المحفظة'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('مميز'), findsNothing);
    expect(find.text('بحث'), findsNothing);
    expect(find.text('تحصيل'), findsNothing);
  });

  testWidgets('tenant HomeScreen tabs wire to renter screens', (tester) async {
    await tester.pumpWidget(shell(const HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byType(UnifiedHomeScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(PropertiesScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(MyBookingsScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(TenantWalletScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProfileScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('حجوزاتي'), findsWidgets);
    expect(find.text('المحفظة'), findsWidgets);
    expect(find.text('استكشف'), findsWidgets);
    expect(find.text('تحصيل'), findsNothing);
    expect(find.text('إضافة'), findsNothing);
  });

  testWidgets('tenant profile has role-appropriate sections only', (tester) async {
    await tester.pumpWidget(shell(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('حسابي'), findsWidgets);
    expect(find.text('حجوزاتي'), findsWidgets);
    expect(find.text('مالية'), findsOneWidget);
    expect(find.text('خدمات'), findsOneWidget);
    expect(find.text('عام'), findsOneWidget);
    expect(find.text('شات الدعم الفني'), findsOneWidget);
    expect(find.text('مركز المساعدة'), findsNothing);
    expect(find.text('خطط النشر'), findsNothing);
    expect(find.text('تحصيل الإيجارات'), findsNothing);
    expect(find.text('باقتي'), findsNothing);
    expect(find.text('عقاراتي'), findsNothing);
  });
}
