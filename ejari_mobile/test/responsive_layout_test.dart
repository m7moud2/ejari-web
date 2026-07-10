import 'package:ejari_mobile/screens/home_screen.dart';
import 'package:ejari_mobile/screens/login_screen.dart';
import 'package:ejari_mobile/screens/unified_home_screen.dart';
import 'package:ejari_mobile/screens/properties_screen.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/theme/app_theme.dart';
import 'package:ejari_mobile/widgets/offers_slider.dart';
import 'package:ejari_mobile/widgets/property_card.dart';
import 'package:ejari_mobile/providers/auth_provider.dart';
import 'package:ejari_mobile/providers/home_provider.dart';
import 'package:ejari_mobile/providers/property_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _narrowSize = Size(320, 640);
const _mobileSize = Size(390, 844);

Future<void> _initDemo() async {
  SharedPreferences.setMockInitialValues({});
  await AuthService.initDemoAccounts();
  await DataService.initProperties();
}

Widget _homeShell(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ChangeNotifierProvider(create: (_) => HomeProvider()),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: home),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('login fits 320px width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('offers slider content fits 320px card', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OffersSlider())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('simplified home fits 320px viewport', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _initDemo();

    await tester.pumpWidget(_homeShell(const HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('owner unified home fits 320px viewport', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _initDemo();
    await AuthService.login('owner@ejari.app', 'owner123');

    await tester.pumpWidget(_homeShell(const UnifiedHomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
  });

  testWidgets('property card fits 320px width', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyCard(
            id: 'test',
            title: 'شقة فاخرة على النيل — المعادي',
            price: '15,000',
            location: 'المعادي، القاهرة',
            image: 'assets/images/properties/apartment.jpg',
            beds: '3',
            baths: '2',
            area: '200',
            listingMode: 'rent',
            supportedDurations: const ['يوم', 'أسبوع', 'شهر', 'سنة'],
            onTap: () {},
            onBook: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('properties screen fits 320px viewport', (tester) async {
    await tester.binding.setSurfaceSize(_narrowSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _initDemo();

    await tester.pumpWidget(_homeShell(const PropertiesScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  testWidgets('simplified home fits a common mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(_mobileSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _initDemo();

    await tester.pumpWidget(_homeShell(const HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
