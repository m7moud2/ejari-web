/// فئات تسعير الإيجار القصير — مبنية على عدد الأيام الفعلي.
enum RentalPricingTier {
  daily,
  weekly,
  shortTerm,
  monthly,
}

extension RentalPricingTierX on RentalPricingTier {
  String get arabicLabel {
    switch (this) {
      case RentalPricingTier.daily:
        return 'يومي (سعر مميز)';
      case RentalPricingTier.weekly:
        return 'باقة أسبوعية';
      case RentalPricingTier.shortTerm:
        return 'قصير المدى (تخفيض تدريجي)';
      case RentalPricingTier.monthly:
        return 'شهري';
    }
  }

  String get descriptionArabic {
    switch (this) {
      case RentalPricingTier.daily:
        return 'سعر يومي أعلى من الحصة العادلة — مناسب لإقامة قصيرة جداً';
      case RentalPricingTier.weekly:
        return 'باقة أسبوع بسعر أفضل من ٧ أيام منفصلة';
      case RentalPricingTier.shortTerm:
        return 'كلما زادت المدة اقترب السعر من الإيجار الشهري';
      case RentalPricingTier.monthly:
        return 'الإيجار الشهري الكامل للوحدة';
    }
  }
}
