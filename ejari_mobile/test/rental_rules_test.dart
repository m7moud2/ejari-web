import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/models/rental_duration_tier.dart';
import 'package:ejari_mobile/models/tenant_type.dart';
import 'package:ejari_mobile/utils/rental_rules.dart';

void main() {
  group('RentalRules tier resolution', () {
    test('daily tier', () {
      expect(RentalRules.resolveTier('يوم', 3), RentalDurationTier.daily);
    });

    test('weekly tier', () {
      expect(RentalRules.resolveTier('أسبوع', 2), RentalDurationTier.weekly);
    });

    test('short-term < 6 months', () {
      expect(RentalRules.resolveTier('شهر', 3), RentalDurationTier.shortTerm);
      expect(RentalRules.resolveTier('شهر', 5), RentalDurationTier.shortTerm);
    });

    test('medium 6-11 months', () {
      expect(RentalRules.resolveTier('شهر', 6), RentalDurationTier.medium);
      expect(RentalRules.resolveTier('شهر', 11), RentalDurationTier.medium);
    });

    test('long-term >= 1 year', () {
      expect(RentalRules.resolveTier('شهر', 12), RentalDurationTier.longTerm);
      expect(RentalRules.resolveTier('سنة', 1), RentalDurationTier.longTerm);
      expect(RentalRules.resolveTier('سنة', 2), RentalDurationTier.longTerm);
    });
  });

  group('RentalRules requirements', () {
    test('income proof only for medium and long', () {
      expect(RentalRules.requiresIncomeProof(RentalDurationTier.daily), false);
      expect(RentalRules.requiresIncomeProof(RentalDurationTier.shortTerm), false);
      expect(RentalRules.requiresIncomeProof(RentalDurationTier.medium), true);
      expect(RentalRules.requiresIncomeProof(RentalDurationTier.longTerm), true);
    });

    test('advance deposit for short durations', () {
      expect(RentalRules.requiresAdvanceDeposit(RentalDurationTier.daily), true);
      expect(RentalRules.requiresAdvanceDeposit(RentalDurationTier.medium), false);
    });

    test('installments only >= 6 months', () {
      expect(RentalRules.showMonthlyInstallments(RentalDurationTier.weekly), false);
      expect(RentalRules.showMonthlyInstallments(RentalDurationTier.shortTerm), false);
      expect(RentalRules.showMonthlyInstallments(RentalDurationTier.medium), true);
      expect(RentalRules.showMonthlyInstallments(RentalDurationTier.longTerm), true);
    });
  });

  group('RentalRules refund policy', () {
    final checkIn = DateTime(2026, 8, 10);

    test('refundable when cancel >= 2 days before', () {
      final cancel = DateTime(2026, 8, 7);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        true,
      );
    });

    test('not refundable within 2 days', () {
      final cancel = DateTime(2026, 8, 9);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        false,
      );
    });

    test('not refundable after check-in', () {
      final cancel = DateTime(2026, 8, 11);
      expect(
        RentalRules.isRefundable(checkInDate: checkIn, cancelDate: cancel),
        false,
      );
    });
  });

  group('TenantType', () {
    test('arabic labels', () {
      expect(TenantType.individual.arabicLabel, 'فرد');
      expect(TenantType.family.arabicLabel, 'أسرة');
      expect(TenantType.multiplePersons.arabicLabel, 'أكثر من فرد');
    });

    test('round-trip value', () {
      expect(tenantTypeFromValue('family'), TenantType.family);
      expect(tenantTypeFromValue(null), TenantType.individual);
    });
  });
}
