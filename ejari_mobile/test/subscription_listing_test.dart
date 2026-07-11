import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/models/listing_type.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/booking_qr_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/subscription_service.dart';
import 'package:ejari_mobile/widgets/sale_listing_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
  });

  test('ListingType detects sale vs rent', () {
    expect(isSaleListing({'listingMode': 'for_sale'}), true);
    expect(isSaleListing({'listingMode': 'rent'}), false);
    expect(listingTypeFromProperty({'listingMode': 'rent'}).arabicLabel, 'للإيجار');
    expect(listingTypeFromProperty({'listingMode': 'for_sale'}).arabicLabel, 'إعلان بيع');
    expect(ListingType.sale.saleAdBadge, kSaleAdBadgeLabel);
  });

  test('Sale listings are ad-only — no sale commission rate', () async {
    final ability = await SubscriptionService.checkListingAbility();
    expect(ability.containsKey('commission_rate_sale'), false);
    expect(SubscriptionService.saleAdPlans['sale_bronze']!['sale_ads_limit'], 2);
    expect(
      SubscriptionService.saleAdPlanFeatureLabels('sale_gold'),
      contains('بدون عمولة على سعر البيع'),
    );
  });

  test('SubscriptionService owner plans have limits', () {
    expect(SubscriptionService.ownerPlans['free']!['properties_limit'], 2);
    expect(SubscriptionService.ownerPlans['gold']!['featured'], true);
    expect(SubscriptionService.ownerPlans['bronze']!['properties_limit'], 5);
    expect(SubscriptionService.ownerPlans['bronze']!['price'], 99);
  });

  test('SubscriptionService tenant plus plan has booking limit', () {
    expect(SubscriptionService.tenantPlans['plus']!['bookings_limit'], 10);
    expect(SubscriptionService.normalizePlanId('basic', 'owner'), 'bronze');
    expect(SubscriptionService.normalizePlanId('pro', 'owner'), 'silver');
  });

  test('activatePlan persists bronze and enforces listing limit', () async {
    const email = 'owner@ejari.app';
    await SubscriptionService.activatePlan(email, 'bronze', userType: 'owner');

    final sub = await SubscriptionService.getCurrentSubscription();
    expect(sub['plan'], 'bronze');
    expect(sub['type'], 'owner');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('owner_subscription_$email'), isNotNull);

    final ability = await SubscriptionService.checkListingAbility(ownerId: email);
    expect(ability['plan_id'], 'bronze');
    expect(ability['limit'], 5);
  });

  test('QR verify demo_req_1 returns valid result with details', () async {
    final result = await BookingQrService.verifyByBookingId('demo_req_1');
    expect(result['valid'], isTrue);
    expect(result['bookingId'], 'demo_req_1');
    expect(result['tenantName'], isNotNull);
    expect(result['propertyTitle'], isNotNull);
    expect(result['paymentStatus'], isNotNull);
  });

  test('QR verify demo_bed_booking includes bed label', () async {
    final result = await BookingQrService.verifyByBookingId('demo_bed_booking');
    expect(result['valid'], isTrue);
    expect(result['bedLabel'], isNotNull);
  });
}
