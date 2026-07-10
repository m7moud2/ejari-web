import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/models/rental_pricing_tier.dart';
import 'package:ejari_mobile/utils/booking_validator.dart';
import 'package:ejari_mobile/utils/rental_pricing.dart';

void main() {
  const monthlyRent = 10000.0;

  group('RentalPricing tiered rent', () {
    test('1 day uses premium daily rate (~500 not 333)', () {
      final result = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 1,
      );

      expect(result.tier, RentalPricingTier.daily);
      expect(result.totalRent, 500);
      expect(result.effectiveDailyRate, 500);
      expect(result.totalRent, greaterThan(monthlyRent / 30));
    });

    test('7 days uses weekly package (~2800 not 2333)', () {
      final result = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 7,
      );

      expect(result.tier, RentalPricingTier.weekly);
      expect(result.totalRent, 2800);
      expect(result.totalRent, greaterThan((monthlyRent / 30) * 7));
      expect(result.savingsVsPremiumDaily, greaterThan(0));
    });

    test('15 days short-term progressive discount', () {
      final result = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 15,
      );

      expect(result.tier, RentalPricingTier.shortTerm);
      expect(result.totalRent, closeTo(5237.5, 1));
      expect(result.totalRent, lessThan(monthlyRent));
      expect(result.totalRent, greaterThan(RentalPricing.rentForShortPeriod(monthlyRent, 7)));
    });

    test('30 days equals exact monthly rent', () {
      final byDays = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 30,
      );
      final byMonth = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'شهر',
        durationCount: 1,
      );

      expect(byDays.tier, RentalPricingTier.monthly);
      expect(byDays.totalRent, 10000);
      expect(byMonth.totalRent, 10000);
      expect(byDays.effectiveDailyRate, closeTo(10000 / 30, 0.01));
    });

    test('29 days close to but below monthly', () {
      final result = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 29,
      );

      expect(result.totalRent, 9700);
      expect(result.totalRent, lessThan(monthlyRent));
      expect(result.totalRent, greaterThan(monthlyRent * 0.9));
    });

    test('weekly duration type matches 7 day tier', () {
      final days = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 7,
      );
      final weeks = RentalPricing.calculate(
        monthlyRent: monthlyRent,
        durationType: 'أسبوع',
        durationCount: 1,
      );

      expect(days.totalRent, weeks.totalRent);
    });
  });

  group('BookingValidator.resolvePricing matches RentalPricing', () {
    test('server recalculation for 1 day', () {
      final resolved = BookingValidator.resolvePricing(
        baseMonthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 1,
      );
      expect(resolved['totalPrice'], 500);
      expect(resolved['pricingTier'], RentalPricingTier.daily.name);
    });

    test('server recalculation for 30 days', () {
      final resolved = BookingValidator.resolvePricing(
        baseMonthlyRent: monthlyRent,
        durationType: 'يوم',
        durationCount: 30,
      );
      expect(resolved['totalPrice'], 10000);
      expect(resolved['pricingTier'], RentalPricingTier.monthly.name);
    });
  });

  group('RentalPricing.tierTable', () {
    test('example amounts for 10k monthly', () {
      final table = RentalPricing.tierTable(monthlyRent);
      expect(table[0]['example'], 500);
      expect(table[1]['example'], 2800);
      expect(table[3]['example'], 10000);
    });
  });
}
