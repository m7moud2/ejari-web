class FinancialService {
  // نسب العمولات (يمكن تغييرها ديناميكياً)
  static const double rentCommissionPercent = 0.025; // 2.5% عمولة إيجار
  static const double serviceCommissionPercent = 0.15; // 15% عمولة خدمات/صيانة

  // رسوم ثابتة
  static const double transactionFee = 5.0; // 5 جنيه مصاريف تحويل

  /// حساب تفاصيل عملية دفع الإيجار
  static TransactionBreakdown calculateRentBreakdown(double rentAmount) {
    double appCommission = rentAmount * rentCommissionPercent;
    double ownerGets = rentAmount - appCommission;

    return TransactionBreakdown(
      totalAmount: rentAmount,
      appCommission: appCommission,
      providerAmount: ownerGets,
      details: 'إيجار وحدة سكنية (عمولة $rentCommissionPercent)',
    );
  }

  /// حساب تفاصيل عملية خدمة صيانة
  /// هذا يضمن حق الفني وحق التطبيق
  static TransactionBreakdown calculateServiceBreakdown(double servicePrice) {
    double appCommission = servicePrice * serviceCommissionPercent;
    double technicianGets = servicePrice - appCommission;

    return TransactionBreakdown(
      totalAmount: servicePrice,
      appCommission: appCommission,
      providerAmount: technicianGets,
      details:
          'خدمة صيانة (عمولة ${(serviceCommissionPercent * 100).toInt()}%)',
    );
  }

  /// محاكاة إنشاء عرض سعر من الفني
  /// في الواقع، الفني هو من يدخل هذا الرقم
  static double generateTechnicianQuote(String issueType) {
    switch (issueType) {
      case 'سباكة':
        return 250.0;
      case 'كهرباء':
        return 300.0;
      case 'تكييف':
        return 500.0;
      case 'نظافة':
        return 400.0;
      default:
        return 150.0;
    }
  }
}

class TransactionBreakdown {
  final double totalAmount; // المبلغ الذي يدفعه العميل
  final double appCommission; // ربح التطبيق
  final double providerAmount; // المبلغ الذي يصل للمالك/الفني
  final String details;

  TransactionBreakdown({
    required this.totalAmount,
    required this.appCommission,
    required this.providerAmount,
    required this.details,
  });
}
