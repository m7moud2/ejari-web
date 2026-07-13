import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/data/egypt_locations.dart';
import 'package:ejari_mobile/utils/location_ranking.dart';
import 'package:ejari_mobile/utils/short_stay_discovery.dart';
import 'package:ejari_mobile/services/mock_data_seeder.dart';

void main() {
  group('EgyptLocations', () {
    test('covers all 27 governorates with cities', () {
      expect(EgyptLocations.allGovernorates.length, greaterThanOrEqualTo(27));
      for (final g in EgyptLocations.allGovernorates) {
        expect(EgyptLocations.citiesFor(g), isNotEmpty, reason: g);
      }
    });

    test('normalizes coastal aliases', () {
      expect(EgyptLocations.normalizeGovernorate('الغردقة'), 'البحر الأحمر');
      expect(EgyptLocations.normalizeGovernorate('شرم الشيخ'), 'جنوب سيناء');
      expect(EgyptLocations.normalizeGovernorate('الساحل الشمالي'), 'مطروح');
    });
  });

  group('LocationRanking', () {
    late List<Map<String, dynamic>> props;

    setUp(() {
      props = MockDataSeeder.getEgyptianProperties();
    });

    test('haversine nearby Maadi properties rank first around Maadi coords', () {
      // Near Maadi / Nile apartment coords
      const userLat = 29.9600;
      const userLng = 31.2700;
      final ranked = LocationRanking.rankProperties(
        props.where((p) => p['listingMode'] != 'for_sale').toList(),
        userLat: userLat,
        userLng: userLng,
        userGovernorate: 'القاهرة',
        userCity: 'المعادي',
      );

      expect(ranked, isNotEmpty);
      expect(ranked.first.band, LocationProximityBand.nearby);
      expect(
        ranked.first.property['location']?.toString() ?? '',
        contains('المعادي'),
      );
      expect(ranked.first.arabicDistanceLabel, contains('كم'));
    });

    test('same governorate before elsewhere when no coords', () {
      final ranked = LocationRanking.rankProperties(
        [
          {
            'id': 'a',
            'title': 'أسيوط',
            'governorate': 'أسيوط',
            'location': 'أسيوط',
            'price': '3000',
          },
          {
            'id': 'b',
            'title': 'قاهرة',
            'governorate': 'القاهرة',
            'location': 'مدينة نصر، القاهرة',
            'price': '8000',
          },
          {
            'id': 'c',
            'title': 'جيزة',
            'governorate': 'الجيزة',
            'location': 'الهرم',
            'price': '7000',
          },
        ],
        userGovernorate: 'القاهرة',
        userCity: 'مدينة نصر',
      );
      expect(ranked.first.property['id'], 'b');
      expect(ranked.first.band, LocationProximityBand.sameCity);
    });

    test('cheapest sort mode overrides proximity for price order', () {
      final ranked = LocationRanking.rankProperties(
        props.take(8).toList(),
        userLat: 30.0,
        userLng: 31.0,
        userGovernorate: 'القاهرة',
        sortMode: 'cheapest',
      );
      for (var i = 1; i < ranked.length; i++) {
        final prev = double.tryParse(
              (ranked[i - 1].property['price'] ?? '0')
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        final curr = double.tryParse(
              (ranked[i].property['price'] ?? '0')
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0;
        expect(curr >= prev, isTrue);
      }
    });
  });

  group('Professional filters', () {
    test('offerType daily + specialOffersOnly + audience filters', () {
      final matrouh = MockDataSeeder.getEgyptianProperties()
          .firstWhere((p) => p['id'] == 'vac_matrouh_1');

      expect(
        ShortStayDiscovery.matchesFilters(matrouh, {
          'offerType': 'إيجار يومي',
          'specialOffersOnly': true,
          'suitableFor': 'عائلات',
          'finishStatus': 'مفروش',
          'governorate': 'مطروح',
        }),
        isTrue,
      );

      expect(
        ShortStayDiscovery.matchesFilters(matrouh, {
          'offerType': 'إعلان بيع',
        }),
        isFalse,
      );

      expect(
        ShortStayDiscovery.matchesFilters(matrouh, {
          'city': 'مرسى مطروح',
        }),
        isTrue,
      );
    });

    test('elevator parking gas amenity filters', () {
      final tanta = MockDataSeeder.getEgyptianProperties()
          .firstWhere((p) => p['id'] == 'egy_tanta_1');
      expect(
        ShortStayDiscovery.matchesAmenityFilter(tanta, 'مصعد'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(tanta, 'موقف'),
        isTrue,
      );
      expect(
        ShortStayDiscovery.matchesAmenityFilter(tanta, 'غاز'),
        isTrue,
      );
    });

    test('seed spans many governorates with lat/lng', () {
      final props = MockDataSeeder.getEgyptianProperties();
      final govs = props
          .map((p) => EgyptLocations.normalizeGovernorate(
                p['governorate']?.toString(),
              ))
          .where((g) => g.isNotEmpty)
          .toSet();
      expect(govs.length, greaterThanOrEqualTo(10));
      final withCoords = props.where((p) => p['lat'] != null && p['lng'] != null);
      expect(withCoords.length, equals(props.length));
    });
  });
}
