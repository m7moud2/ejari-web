import 'package:ejari_mobile/screens/add_property_screen.dart';
import 'package:ejari_mobile/screens/home_screen.dart';
import 'package:ejari_mobile/screens/manage_properties_screen.dart';
import 'package:ejari_mobile/screens/owner_collection_screen.dart';
import 'package:ejari_mobile/screens/profile_screen.dart';
import 'package:ejari_mobile/screens/unified_home_screen.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
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
    await WalletService.init(userId: 'owner@ejari.app');
    await AuthService.login('owner@ejari.app', 'owner123');
    await AuthService.setUserRole('owner');
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

  testWidgets('owner bottom nav has owner IA labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EjariNavigationBar(
          currentIndex: 0,
          role: 'owner',
          onTap: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('عقاراتي'), findsOneWidget);
    expect(find.text('إضافة'), findsOneWidget);
    expect(find.text('تحصيل'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('استكشف'), findsNothing);
    expect(find.text('حجوزاتي'), findsNothing);
  });

  testWidgets('owner HomeScreen tabs wire to owner screens', (tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.byType(UnifiedHomeScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ManagePropertiesScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(AddPropertyScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(OwnerCollectionScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(ProfileScreen, skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('عقاراتي').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('عقاراتي'), findsWidgets);

    await tester.tap(find.text('إضافة').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('نشر إعلان'), findsOneWidget);

    await tester.tap(find.text('تحصيل').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('تحصيل الإيجارات'), findsOneWidget);

    await tester.tap(find.text('حسابي').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ProfileScreen), findsWidgets);

    await tester.tap(find.text('الرئيسية').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(UnifiedHomeScreen), findsOneWidget);
  });
}
