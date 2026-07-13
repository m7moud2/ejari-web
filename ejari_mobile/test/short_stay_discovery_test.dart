import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/utils/short_stay_discovery.dart';
import 'package:ejari_mobile/services/mock_data_seeder.dart';

void main() {
  group('ShortStayDiscovery duration intents', () {
    test('includes FB-style stay lengths', () {
      final labels =
          ShortStayDiscovery.durationIntents.map((e) => e.label).toList();
      expect(labels, containsAll(['ليلة', 'يومين', '٣ أيام', 'نصف أسبوع', 'أسبوع', 'شهر']));
    });

    test('half week maps to 7 days', () {
      final half = ShortStayDiscovery.intentById('half_week');
      expect(half, isNotNull);
      expect(half!.days, 7);
      expect(half.durationType, 'يوم');
      expect(half.durationCount, 7);
    });
  });

  group('ShortStayDiscovery filters', () {
    late Map<String, dynamic> matrouhHouse;

    setUp(() {
      matrouhHouse = MockDataSeeder.getEgyptianProperties()
          .firstWhere((p) => p['id'] == 'vac_matrouh_1');
    });

    test('matches Matrouh coastal family house like FB post', () {
      expect(ShortStayDiscovery.isCoastal(matrouhHouse), isTrue);
      expect(ShortStayDiscovery.isShortStayListing(matrouhHouse), isTrue);
      expect(ShortStayDiscovery.nearbyBeachMinutes(matrouhHouse), 8);
      expect(ShortStayDiscovery.flagTrue(matrouhHouse, 'carAvailable'), isTrue);
      expect(
          ShortStayDiscovery.flagTrue(matrouhHouse, 'familyFriendly'), isTrue);
      expect(
          ShortStayDiscovery.flagTrue(matrouhHouse, 'independentHouse'),
          isTrue);
      expect(ShortStayDiscovery.dailyRate(matrouhHouse), 550);
    });

    test('amenity filters mirror vacation discovery chips', () {
      expect(
        ShortStayDiscovery.matchesAmenityFilter(matrouhHouse, 'قريب من البحر'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(matrouhHouse, 'سيارة متاحة'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(matrouhHouse, 'مطبخ'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(matrouhHouse, 'مناسب للعائلات'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(matrouhHouse, 'بيت مستقل'),
        isTrue,
      );
    });

    test('offer badges include 3-day and half-week', () {
      final badges = ShortStayDiscovery.offerBadges(matrouhHouse);
      expect(badges.any((b) => b.contains('٣') || b.contains('3')), isTrue);
      expect(badges.any((b) => b.contains('نصف')), isTrue);
      expect(
        ShortStayDiscovery.matchesOfferFilter(matrouhHouse, 'عرض ٣ أيام'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesOfferFilter(matrouhHouse, 'نصف أسبوع'),
        isTrue,
      );
    });

    test('duration + governorate + daily price filter combo', () {
      final ok = ShortStayDiscovery.matchesFilters(matrouhHouse, {
        'durationates': ['مطروح'],
        'durationIntent': 'three_days',
        'minDailyPrice': 400,
        'maxDailyPrice': 700,
        'amenities': ['قريب من البحر', 'مناسب للعائلات'],
        'offerFilters': ['عرض ٣ أيام'],
      });
      expect(ok, isTrue);

      final tooCheap = ShortStayDiscovery.matchesFilters(matrouhHouse, {
        'minDailyPrice': 800,
        'maxDailyPrice': 1200,
      });
      expect(tooCheap, isFalse);
    });

    test('multi-unit deal badge for north coast twin apartments', () {
      final twin = MockDataSeeder.getEgyptianProperties()
          .firstWhere((p) => p['id'] == 'vac_matrouh_2');
      expect(
        ShortStayDiscovery.matchesOfferFilter(twin, 'شقتين بسعر خاص'),
        isTrue,
      );
      expect(ShortStayDiscovery.offerBadges(twin), contains('شقتين بسعر خاص'));
    });

    test('tapping offer preselects booking duration', () {
      final offer = ShortStayDiscovery.specialOffers(matrouhHouse).firstWhere(
            (o) => (o['days'] as num?)?.toInt() == 3,
          );
      final prefill = ShortStayDiscovery.bookingPrefillFromOffer(offer);
      expect(prefill, isNotNull);
      expect(prefill!['durationType'], 'يوم');
      expect(prefill['durationCount'], 3);
      expect(prefill['durationIntent'], 'three_days');
    });

    test('coastal seed catalog has at least 4 vacation listings', () {
      final coastal = MockDataSeeder.getEgyptianProperties()
          .where(ShortStayDiscovery.isShortStayListing)
          .where(ShortStayDiscovery.isCoastal)
          .toList();
      expect(coastal.length, greaterThanOrEqualTo(4));
      expect(
        coastal.any((p) => (p['title']?.toString() ?? '').contains('مطروح')),
        isTrue,
      );
    });
  });
}
