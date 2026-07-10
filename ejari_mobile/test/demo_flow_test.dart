import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/services/mock_data_seeder.dart';
import 'package:ejari_mobile/utils/rental_rules.dart';

void main() {
  group('Demo catalog merge', () {
    test('Egyptian properties include multiple governorates', () {
      final props = MockDataSeeder.getEgyptianProperties();
      final governorates = props
          .map((p) => p['governorate']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toSet();
      expect(governorates.length, greaterThanOrEqualTo(4));
      expect(governorates, contains('القاهرة'));
      expect(governorates, contains('الجيزة'));
    });

    test('Sale listings are present in Egyptian demo data', () {
      final props = MockDataSeeder.getEgyptianProperties();
      expect(
        props.any((p) => p['listingMode'] == 'for_sale'),
        isTrue,
      );
    });
  });

  group('Cancel booking refund enforcement', () {
    test('refund amount is zero inside 48h window', () {
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final cancel = DateTime.now();
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        false,
      );
    });

    test('refund amount is full when cancel >= 2 days before', () {
      final checkIn = DateTime.now().add(const Duration(days: 5));
      final cancel = DateTime.now();
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        true,
      );
    });
  });
}
