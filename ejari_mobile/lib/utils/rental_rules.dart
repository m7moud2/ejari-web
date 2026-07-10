import '../models/rental_duration_tier.dart';
import '../models/tenant_type.dart';

/// قواعد الإيجار المركزية: المدة، المستندات، الاسترداد، والأقساط.
class RentalRules {
  RentalRules._();

  static RentalDurationTier resolveTier(String durationType, int count) {
    switch (durationType) {
      case 'يوم':
        return RentalDurationTier.daily;
      case 'أسبوع':
        return RentalDurationTier.weekly;
      case 'شهر':
        if (count < 6) return RentalDurationTier.shortTerm;
        if (count < 12) return RentalDurationTier.medium;
        return RentalDurationTier.longTerm;
      case 'سنة':
        return count >= 1
            ? RentalDurationTier.longTerm
            : RentalDurationTier.medium;
      default:
        return RentalDurationTier.shortTerm;
    }
  }

  /// مدة ≥ ٦ شهور أو ≥ سنة — مستندات + إثبات دخل.
  static bool requiresIncomeProof(RentalDurationTier tier) {
    return tier == RentalDurationTier.medium ||
        tier == RentalDurationTier.longTerm;
  }

  /// مدة < ٦ شهور — دفع مقدم بدل حزمة المستندات الكاملة.
  static bool requiresAdvanceDeposit(RentalDurationTier tier) {
    return tier == RentalDurationTier.daily ||
        tier == RentalDurationTier.weekly ||
        tier == RentalDurationTier.shortTerm;
  }

  /// إظهار خطة الأقساط الشهرية فقط عند المدة ≥ ٦ شهور.
  static bool showMonthlyInstallments(RentalDurationTier tier) {
    return tier == RentalDurationTier.medium ||
        tier == RentalDurationTier.longTerm;
  }

  /// نسبة الدفع المقدم حسب الفئة.
  static double advanceDepositRate(RentalDurationTier tier) {
    switch (tier) {
      case RentalDurationTier.daily:
        return 0.30;
      case RentalDurationTier.weekly:
        return 0.25;
      case RentalDurationTier.shortTerm:
        return 0.20;
      case RentalDurationTier.medium:
      case RentalDurationTier.longTerm:
        return 0.10;
    }
  }

  static String advanceDepositLabel(RentalDurationTier tier) {
    switch (tier) {
      case RentalDurationTier.daily:
        return 'دفع مقدم يومي';
      case RentalDurationTier.weekly:
        return 'دفع مقدم أسبوعي';
      case RentalDurationTier.shortTerm:
        return 'دفع مقدم (عربون)';
      case RentalDurationTier.medium:
      case RentalDurationTier.longTerm:
        return 'عربون الشهر الأول';
    }
  }

  /// قابل للاسترداد فقط إذا الإلغاء ≥ يومين قبل تاريخ الاستلام.
  static bool isRefundable({
    required DateTime checkInDate,
    required DateTime cancelDate,
  }) {
    final daysBefore = checkInDate.difference(cancelDate).inDays;
    return daysBefore >= 2;
  }

  static String refundStatusArabic({
    required DateTime checkInDate,
    required DateTime cancelDate,
  }) {
    return isRefundable(checkInDate: checkInDate, cancelDate: cancelDate)
        ? 'قابل للاسترداد الكامل'
        : 'غير قابل للاسترداد';
  }

  static const String refundPolicyLegalArabic =
      'سياسة الاسترداد: يحق للمستأجر استرداد العربون/الدفع المقدم بالكامل '
      'فقط في حالة الإلغاء قبل موعد الاستلام بيومين (٤٨ ساعة) على الأقل. '
      'في حالة الإلغاء خلال يومين أو بعد تاريخ الاستلام، لا يحق أي استرداد '
      'وفقًا لشروط منصة إيجاري وعقد الإيجار المعتمد.';

  static const String refundPolicyShortArabic =
      'الاسترداد متاح فقط قبل الاستلام بـ ٤٨ ساعة على الأقل.';

  static const String tenantTrustArabic =
      'حقوقك محمية: العربون يُحجز في حساب ضمان حتى تأكيد الصفقة، '
      'والعقد الإلكتروني موثق من إيجاري.';

  static const String ownerTrustArabic =
      'حقوق المالك محمية: التحقق من الهوية والملاءة المالية، '
      'وسند لأمر إلكتروني عند الحاجة، مع متابعة إدارية لكل حجز.';

  static Map<String, dynamic> bookingTierPayload({
    required RentalDurationTier tier,
    required TenantType tenantType,
    required String durationType,
    required int durationCount,
    DateTime? checkInDate,
  }) {
    return {
      'rentalTier': tier.name,
      'rentalTierLabel': tier.arabicLabel,
      'tenantType': tenantType.value,
      'tenantTypeLabel': tenantType.arabicLabel,
      'durationType': durationType,
      'durationCount': durationCount,
      'requiresIncomeProof': requiresIncomeProof(tier),
      'requiresAdvanceDeposit': requiresAdvanceDeposit(tier),
      'showInstallments': showMonthlyInstallments(tier),
      'refundPolicy': refundPolicyLegalArabic,
      if (checkInDate != null)
        'checkInDate': checkInDate.toIso8601String(),
    };
  }
}
