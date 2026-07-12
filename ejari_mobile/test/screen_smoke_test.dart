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
import 'package:ejari_mobile/services/live_sync_service.dart';

import 'package:ejari_mobile/screens/admin_service_requests_screen.dart';
import 'package:ejari_mobile/screens/admin_search_screen.dart';
import 'package:ejari_mobile/screens/admin_financials_screen.dart';
import 'package:ejari_mobile/screens/admin_properties_screen.dart';
import 'package:ejari_mobile/screens/admin_support_screen.dart';
import 'package:ejari_mobile/screens/admin_users_screen.dart';
import 'package:ejari_mobile/screens/admin_audit_log_screen.dart';
import 'package:ejari_mobile/screens/my_contracts_screen.dart';
import 'package:ejari_mobile/screens/tenant_wallet_screen.dart';
import 'package:ejari_mobile/screens/wallet_screen.dart';
import 'package:ejari_mobile/screens/provider_wallet_screen.dart';
import 'package:ejari_mobile/screens/provider_jobs_screen.dart';
import 'package:ejari_mobile/screens/provider_timeline_screen.dart';
import 'package:ejari_mobile/screens/professional_services_screen.dart';
import 'package:ejari_mobile/screens/corporate_command_center_screen.dart';
import 'package:ejari_mobile/screens/payment_methods_screen.dart';
import 'package:ejari_mobile/screens/subscriptions_screen.dart';
import 'package:ejari_mobile/screens/my_bookings_screen.dart';
import 'package:ejari_mobile/screens/refund_tracker_screen.dart';
import 'package:ejari_mobile/screens/my_service_requests_screen.dart';
import 'package:ejari_mobile/screens/verification_screen.dart';
import 'package:ejari_mobile/screens/unified_home_screen.dart';
import 'package:ejari_mobile/screens/owner_occupancy_screen.dart';
import 'package:ejari_mobile/screens/owner_collection_screen.dart';
import 'package:ejari_mobile/screens/owner_qr_verify_screen.dart';
import 'package:ejari_mobile/screens/owner_booking_requests_screen.dart';
import 'package:ejari_mobile/screens/manage_properties_screen.dart';
import 'package:ejari_mobile/screens/owner_bulk_pricing_screen.dart';
import 'package:ejari_mobile/screens/owner_discount_scheduler_screen.dart';
import 'package:ejari_mobile/screens/owner_tenant_lists_screen.dart';
import 'package:ejari_mobile/screens/add_property_screen.dart';
import 'package:ejari_mobile/screens/profile_screen.dart';
import 'package:ejari_mobile/widgets/bed_hierarchy_tree.dart';

Future<void> _initDemo() async {
  await initializeDateFormatting('ar');
  SharedPreferences.setMockInitialValues({});
  await AuthService.initDemoAccounts();
  await DataService.initProperties();
  await DataService.initDemoBookings();
  await DataService.initDemoReceipts();
  await MaintenanceService.initDemoRequests();
  await WalletService.init(userId: 'user@ejari.app');
  await WalletService.init(userId: 'owner@ejari.app');
  await WalletService.init(userId: 'tech@ejari.app');
  await OperationsFeedService.initDemoFeed();
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

Future<void> _loginAs(String email, String password) async {
  await AuthService.login(email, password);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen smoke tests — no red screens', () {
    setUp(_initDemo);

    Future<void> pumpScreen(
      WidgetTester tester,
      Widget screen, {
      Duration settle = const Duration(seconds: 3),
    }) async {
      await tester.pumpWidget(_wrap(screen));
      await tester.pump();
      await tester.pump(settle);
    }

    testWidgets('admin screens', (tester) async {
      await _loginAs('admin@ejari.app', 'admin123');
      final adminScreens = <Widget>[
        const UnifiedHomeScreen(),
        const AdminSearchScreen(),
        const AdminSupportScreen(),
        const AdminUsersScreen(),
        const AdminServiceRequestsScreen(),
        const AdminFinancialsScreen(),
        const AdminAuditLogScreen(),
        const AdminPropertiesScreen(),
        const VerificationScreen(),
      ];
      for (final screen in adminScreens) {
        await pumpScreen(tester, screen);
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} crashed');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('tenant screens', (tester) async {
      await _loginAs('user@ejari.app', 'user123');
      final tenantScreens = <Widget>[
        const UnifiedHomeScreen(),
        const MyBookingsScreen(),
        const RefundTrackerScreen(),
        const MyContractsScreen(),
        const TenantWalletScreen(),
        const MyServiceRequestsScreen(),
        const PaymentMethodsScreen(),
        const SubscriptionsScreen(),
        const CorporateCommandCenterScreen(),
      ];
      for (final screen in tenantScreens) {
        await pumpScreen(tester, screen);
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} crashed');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('owner screens', (tester) async {
      await _loginAs('owner@ejari.app', 'owner123');
      final ownerScreens = <Widget>[
        const UnifiedHomeScreen(),
        const WalletScreen(),
        const MyContractsScreen(),
        const SubscriptionsScreen(),
        const OwnerOccupancyScreen(),
        const OwnerCollectionScreen(),
        const OwnerQrVerifyScreen(),
        const OwnerBookingRequestsScreen(),
        const ManagePropertiesScreen(),
        const OwnerBulkPricingScreen(),
        const OwnerDiscountSchedulerScreen(),
        const OwnerTenantListsScreen(),
        const AddPropertyScreen(),
        const ProfileScreen(),
        const BedHierarchyScreen(),
      ];
      for (final screen in ownerScreens) {
        await pumpScreen(tester, screen);
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} crashed');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('technician screens', (tester) async {
      await _loginAs('tech@ejari.app', 'tech123');
      final techScreens = <Widget>[
        const UnifiedHomeScreen(),
        const ProviderJobsScreen(),
        const ProviderTimelineScreen(),
        const ProviderWalletScreen(),
      ];
      for (final screen in techScreens) {
        await pumpScreen(tester, screen);
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} crashed');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('professional services screen', (tester) async {
      await _loginAs('user@ejari.app', 'user123');
      await pumpScreen(
        tester,
        const ProfessionalServicesScreen(),
        settle: const Duration(seconds: 2),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
