/// فئات مدة الإيجار — كل فئة لها معاملة مختلفة في الدفع والمستندات.
enum RentalDurationTier {
  daily,
  weekly,
  shortTerm,
  medium,
  longTerm,
}

extension RentalDurationTierX on RentalDurationTier {
  String get arabicLabel {
    switch (this) {
      case RentalDurationTier.daily:
        return 'يومي';
      case RentalDurationTier.weekly:
        return 'أسبوعي';
      case RentalDurationTier.shortTerm:
        return 'قصير المدى (أقل من ٦ شهور)';
      case RentalDurationTier.medium:
        return 'متوسط المدى (٦ شهور – أقل من سنة)';
      case RentalDurationTier.longTerm:
        return 'طويل المدى (سنة فأكثر)';
    }
  }

  String get paymentModelArabic {
    switch (this) {
      case RentalDurationTier.daily:
        return 'دفع يومي مقدم + عربون';
      case RentalDurationTier.weekly:
        return 'دفع أسبوعي مقدم + عربون';
      case RentalDurationTier.shortTerm:
        return 'دفع مقدم (عربون) بدون حزمة مستندات كاملة';
      case RentalDurationTier.medium:
        return 'أقساط شهرية + مستندات وإثبات دخل';
      case RentalDurationTier.longTerm:
        return 'أقساط شهرية طويلة + مستندات وإثبات دخل';
    }
  }
}
