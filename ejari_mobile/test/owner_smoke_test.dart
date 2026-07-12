import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ejari_mobile/providers/home_provider.dart';
import 'package:ejari_mobile/providers/property_provider.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/maintenance_service.dart';
import 'package:ejari_mobile/services/wallet_service.dart';
import 'package:ejari_mobile/services/operations_feed_service.dart';
import 'package:ejari_mobile/services/tenant_score_service.dart';
import 'package:ejari_mobile/services/anti_fraud_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';

import 'package:ejari_mobile/screens/owner_occupancy_screen.dart';
import 'package:ejari_mobile/screens/owner_collection_screen.dart';
import 'package:ejari_mobile/screens/owner_qr_verify_screen.dart';
import 'package:ejari_mobile/screens/owner_booking_requests_screen.dart';
import 'package:ejari_mobile/screens/wallet_screen.dart';
import 'package:ejari_mobile/screens/subscriptions_screen.dart';
import 'package:ejari_mobile/screens/manage_properties_screen.dart';
import 'package:ejari_mobile/screens/add_property_screen.dart';
import 'package:ejari_mobile/screens/profile_screen.dart';
import 'package:ejari_mobile/screens/owner_property_performance_screen.dart';
import 'package:ejari_mobile/screens/damage_claim_screen.dart';
import 'package:ejari_mobile/widgets/bed_hierarchy_tree.dart';
import 'package:ejari_mobile/widgets/owner_booking_requests_panel.dart';

Future<void> _initDemo() async {
  await initializeDateFormatting('ar');
  SharedPreferences.setMockInitialValues({});
  await AuthService.initDemoAccounts();
  await DataService.initProperties();
  await DataService.initDemoBookings();
  await DataService.initDemoReceipts();
  await MaintenanceService.initDemoRequests();
  await WalletService.init(userId: 'owner@ejari.app');
  await OperationsFeedService.initDemoFeed();
  await TenantScoreService.seedDemoScores();
  await AntiFraudService.seedDemoProfiles();
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeProvider()),
      ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ChangeNotifierProvider.value(value: LiveSyncService.instance),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> _loginOwner() async {
  await AuthService.login('owner@ejari.app', 'owner123');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Owner comprehensive smoke tests', () {
    setUp(_initDemo);

    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      await tester.pumpWidget(_wrap(screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
    }

    Future<void> expectNoCrash(WidgetTester tester, Widget screen) async {
      await pumpScreen(tester, screen);
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} crashed',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    testWidgets('owner operations screens', (tester) async {
      await _loginOwner();
      for (final screen in const [
        OwnerOccupancyScreen(),
        OwnerCollectionScreen(),
        OwnerQrVerifyScreen(),
        OwnerBookingRequestsScreen(),
        BedHierarchyScreen(),
        OwnerBookingRequestsPanel(),
      ]) {
        await expectNoCrash(tester, screen);
      }
    });

    testWidgets('owner finance and property screens', (tester) async {
      await _loginOwner();
      for (final screen in const [
        WalletScreen(),
        SubscriptionsScreen(),
        ManagePropertiesScreen(),
        AddPropertyScreen(),
        OwnerPropertyPerformanceScreen(),
        ProfileScreen(),
      ]) {
        await expectNoCrash(tester, screen);
      }
    });

    testWidgets('owner damage claim screen', (tester) async {
      await _loginOwner();
      await expectNoCrash(
        tester,
        const DamageClaimScreen(
          bookingId: 'demo_active_checkin',
          ownerEmail: 'owner@ejari.app',
        ),
      );
    });
  });
}
