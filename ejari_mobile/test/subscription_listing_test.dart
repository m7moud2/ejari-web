import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/models/listing_type.dart';
import 'package:ejari_mobile/services/subscription_service.dart';

void main() {
  test('ListingType detects sale vs rent', () {
    expect(isSaleListing({'listingMode': 'for_sale'}), true);
    expect(isSaleListing({'listingMode': 'rent'}), false);
    expect(listingTypeFromProperty({'listingMode': 'rent'}).arabicLabel, 'للإيجار');
    expect(listingTypeFromProperty({'listingMode': 'for_sale'}).arabicLabel, 'للبيع');
  });

  test('SubscriptionService owner plans have limits', () {
    expect(SubscriptionService.ownerPlans['free']!['properties_limit'], 1);
    expect(SubscriptionService.ownerPlans['gold']!['featured'], true);
    expect(SubscriptionService.ownerPlans['bronze']!['properties_limit'], 5);
  });

  test('SubscriptionService tenant plus plan has booking limit', () {
    expect(SubscriptionService.tenantPlans['plus']!['bookings_limit'], 10);
    expect(SubscriptionService.normalizePlanId('basic', 'owner'), 'bronze');
    expect(SubscriptionService.normalizePlanId('pro', 'owner'), 'silver');
  });
}
