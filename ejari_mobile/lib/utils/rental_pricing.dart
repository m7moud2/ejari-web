import '../models/rental_pricing_tier.dart';

/// نتيجة حساب الإيجار المتدرج.
class RentalPricingResult {
  final double monthlyRent;
  final int totalDays;
  final String durationType;
  final int durationCount;
  final RentalPricingTier tier;
  final double totalRent;
  final double effectiveDailyRate;
  final double premiumDailyRate;
  final double naivePremiumTotal;
  final double savingsVsPremiumDaily;

  const RentalPricingResult({
    required this.monthlyRent,
    required this.totalDays,
    required this.durationType,
    required this.durationCount,
    required this.tier,
    required this.totalRent,
    required this.effectiveDailyRate,
    required this.premiumDailyRate,
    required this.naivePremiumTotal,
    required this.savingsVsPremiumDaily,
  });
}

/// تسعير الإيجار المتدرج — لا يُقسّم الإيجار الشهري على ٣٠ للحجوزات القصيرة.
///
/// المعادلات (monthlyRent = M):
/// - يومي (١–٦ أيام): `M × 0.05 × أيام` — ≈٥٪ من الشهر لكل يوم
/// - أسبوعي (٧–١٣): `M × 0.28` للأسبوع الأول + `M × 0.03` لكل يوم إضافي
/// - قصير (١٤–٢٩): استيفاء خطي بين سعر ١٣ يوماً و`M × 0.97` عند ٢٩ يوماً
/// - شهري (٣٠+): `M` لكل ٣٠ يوماً بالضبط
class RentalPricing {
  RentalPricing._();

  /// نسبة السعر اليومي المميز (٥٪ من الشهر لكل يوم).
  static const double dailyRateFactor = 0.05;

  /// نسبة باقة الأسبوع (٢٨٪ من الشهر).
  static const double weeklyRateFactor = 0.28;

  /// نسبة كل يوم إضافي داخل شريحة الأسبوع (٣٪ من الشهر).
  static const double weeklyExtraDayFactor = 0.03;

  /// عند ٢٩ يوماً يقترب السعر من الشهر الكامل (٩٧٪).
  static const double monthlyApproachFactor = 0.97;

  static int totalDays(String durationType, int count) {
    if (count <= 0) return 0;
    switch (durationType) {
      case 'يوم':
        return count;
      case 'أسبوع':
        return count * 7;
      case 'شهر':
        return count * 30;
      case 'سنة':
        return count * 365;
      default:
        return count;
    }
  }

  static RentalPricingTier tierForDays(int days) {
    if (days <= 6) return RentalPricingTier.daily;
    if (days <= 13) return RentalPricingTier.weekly;
    if (days <= 29) return RentalPricingTier.shortTerm;
    return RentalPricingTier.monthly;
  }

  /// السعر اليومي المميز المرجعي (للمقارنة فقط — أعلى من M/30).
  static double premiumDailyRate(double monthlyRent) =>
      monthlyRent * dailyRateFactor;

  /// إجمالي لو حُسبت كل الأيام بالسعر اليومي المميز.
  static double naivePremiumTotal(double monthlyRent, int days) {
    if (days <= 0) return 0;
    return premiumDailyRate(monthlyRent) * days;
  }

  /// حساب إيجار فترة قصيرة (< ٣٠ يوماً) حسب الشرائح.
  static double rentForShortPeriod(double monthlyRent, int days) {
    if (days <= 0) return 0;
    if (days <= 6) {
      return monthlyRent * dailyRateFactor * days;
    }
    if (days <= 13) {
      final base = monthlyRent * weeklyRateFactor;
      final extraDays = days - 7;
      if (extraDays <= 0) return base;
      return base + extraDays * monthlyRent * weeklyExtraDayFactor;
    }
    if (days <= 29) {
      final at13 = rentForShortPeriod(monthlyRent, 13);
      final at29 = monthlyRent * monthlyApproachFactor;
      final progress = (days - 13) / (29 - 13);
      return at13 + (at29 - at13) * progress;
    }
    return monthlyRent;
  }

  /// إجمالي الإيجار لأي عدد أيام — يجمع أشهر كاملة + باقي الأيام.
  static double rentForDays(double monthlyRent, int days) {
    if (days <= 0) return 0;
    if (days >= 30) {
      final fullMonths = days ~/ 30;
      final remainder = days % 30;
      var total = fullMonths * monthlyRent;
      if (remainder > 0) {
        total += rentForShortPeriod(monthlyRent, remainder);
      }
      return total;
    }
    return rentForShortPeriod(monthlyRent, days);
  }

  /// الحساب الرئيسي حسب نوع المدة وعددها.
  static RentalPricingResult calculate({
    required double monthlyRent,
    required String durationType,
    required int durationCount,
  }) {
    final count = durationCount < 1 ? 1 : durationCount;
    double totalRent;
    int days;
    RentalPricingTier tier;

    if (durationType == 'شهر') {
      totalRent = monthlyRent * count;
      days = count * 30;
      tier = RentalPricingTier.monthly;
    } else if (durationType == 'سنة') {
      totalRent = monthlyRent * 12 * count;
      days = count * 365;
      tier = RentalPricingTier.monthly;
    } else {
      days = totalDays(durationType, count);
      totalRent = rentForDays(monthlyRent, days);
      if (days >= 30 && days % 30 == 0) {
        tier = RentalPricingTier.monthly;
      } else if (days >= 30) {
        tier = RentalPricingTier.shortTerm;
      } else {
        tier = tierForDays(days);
      }
    }

    final effectiveDaily =
        days > 0 ? totalRent / days : premiumDailyRate(monthlyRent);
    final premiumDaily = premiumDailyRate(monthlyRent);
    final naive = naivePremiumTotal(monthlyRent, days);
    final savings =
        ((naive - totalRent).clamp(0.0, double.infinity) as double);

    return RentalPricingResult(
      monthlyRent: monthlyRent,
      totalDays: days,
      durationType: durationType,
      durationCount: count,
      tier: tier,
      totalRent: totalRent.roundToDouble(),
      effectiveDailyRate: effectiveDaily,
      premiumDailyRate: premiumDaily,
      naivePremiumTotal: naive.roundToDouble(),
      savingsVsPremiumDaily: savings,
    );
  }

  /// جدول الشرائح للعرض في الواجهة.
  static List<Map<String, dynamic>> tierTable(double monthlyRent) {
    return [
      {
        'tier': RentalPricingTier.daily,
        'range': '١–٦ أيام',
        'formula': '${(dailyRateFactor * 100).toStringAsFixed(0)}٪ × أيام',
        'example': rentForShortPeriod(monthlyRent, 1),
      },
      {
        'tier': RentalPricingTier.weekly,
        'range': '٧–١٣ يوماً',
        'formula':
            '${(weeklyRateFactor * 100).toStringAsFixed(0)}٪ + ${(weeklyExtraDayFactor * 100).toStringAsFixed(0)}٪/يوم إضافي',
        'example': rentForShortPeriod(monthlyRent, 7),
      },
      {
        'tier': RentalPricingTier.shortTerm,
        'range': '١٤–٢٩ يوماً',
        'formula': 'تخفيض تدريجي نحو الشهر',
        'example': rentForShortPeriod(monthlyRent, 15),
      },
      {
        'tier': RentalPricingTier.monthly,
        'range': '٣٠+ يوماً',
        'formula': 'الإيجار الشهري الكامل',
        'example': monthlyRent,
      },
    ];
  }
}
