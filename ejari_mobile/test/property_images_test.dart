import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/mock_data_seeder.dart';
import 'package:ejari_mobile/utils/property_image_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Property images', () {
    test('every seeded property resolves to a non-empty asset path', () async {
      await DataService.initProperties();
      final properties = await DataService.getAllProperties(approvedOnly: false);

      expect(properties, isNotEmpty);

      for (final property in properties) {
        final image = PropertyImageResolver.resolve(property);
        expect(image, isNotEmpty);
        expect(image.startsWith('assets/'), isTrue,
            reason: 'Property ${property['id']} missing valid image');
      }
    });

    test('Egyptian demo catalog has images for all entries', () {
      for (final property in MockDataSeeder.getEgyptianProperties()) {
        final image = PropertyImageResolver.resolve(property);
        expect(image, isNotEmpty);
      }
    });

    test('shared accommodation uses bed placeholder', () {
      final shared = MockDataSeeder.getSharedAccommodationProperty();
      expect(
        PropertyImageResolver.resolve(shared),
        PropertyImageResolver.sharedBed,
      );
    });

    test('sale listings use sale placeholder when image missing', () {
      final image = PropertyImageResolver.resolve({
        'listingMode': 'for_sale',
        'type': 'شقق',
        'image': '',
      });
      expect(image, PropertyImageResolver.sale);
    });
  });
}
