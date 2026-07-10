import 'package:flutter/material.dart';
import '../utils/rental_pricing.dart';
import '../models/rental_pricing_tier.dart';
import '../theme/app_theme.dart';
import '../utils/rental_rules.dart';
import '../models/rental_duration_tier.dart';
import '../models/tenant_type.dart';
import 'ejari_section.dart';

/// مساعد الحجز الذكي — يقترح المدة، يعرض الاسترداد، وقائمة المستندات.
class SmartBookingAssistant extends StatelessWidget {
  final RentalDurationTier tier;
  final TenantType tenantType;
  final String durationType;
  final int duration;
  final DateTime checkInDate;
  final bool hasSelfie;
  final bool hasIdFront;
  final bool hasIdBack;
  final bool hasIncomeProof;
  final VoidCallback? onApplySuggestion;
  final RentalPricingResult? pricingResult;
  final double? monthlyRent;

  const SmartBookingAssistant({
    super.key,
    required this.tier,
    required this.tenantType,
    required this.durationType,
    required this.duration,
    required this.checkInDate,
    this.hasSelfie = false,
    this.hasIdFront = false,
    this.hasIdBack = false,
    this.hasIncomeProof = false,
    this.onApplySuggestion,
    this.pricingResult,
    this.monthlyRent,
  });

  String? get _durationSuggestion {
    if (pricingResult != null && monthlyRent != null && monthlyRent! > 0) {
      if (pricingResult!.tier == RentalPricingTier.daily && duration >= 3) {
        final weekly = RentalPricing.calculate(
          monthlyRent: monthlyRent!,
          durationType: 'أسبوع',
          durationCount: 1,
        );
        final saving = pricingResult!.naivePremiumTotal - weekly.totalRent;
        if (saving > 0) {
          return 'باقة أسبوع واحد (${weekly.totalRent.toStringAsFixed(0)} ج.م) '
              'أوفر من $duration أيام يومية — وفّر حتى ${saving.toStringAsFixed(0)} ج.م.';
        }
      }
      if (pricingResult!.savingsVsPremiumDaily > 100) {
        return 'وفّرت ${pricingResult!.savingsVsPremiumDaily.toStringAsFixed(0)} ج.م '
            'مقارنة بالسعر اليومي المميز — ${pricingResult!.tier.arabicLabel}.';
      }
    }
    if (durationType == 'يوم' && duration > 3) {
      return 'لإقامة $duration أيام، جرّب «أسبوع» — قد يوفر عليك تكلفة يومية أعلى.';
    }
    if (durationType == 'شهر' && duration >= 4 && duration < 6) {
      return 'قربت من ٦ شهور — عندها تُفعَّل الأقساط الشهرية بدل الدفع المقدم الكامل.';
    }
    if (durationType == 'شهر' && duration >= 6) {
      return 'مدة ممتازة — ستُطلب مستندات وإثبات دخل مع خطة أقساط شهرية.';
    }
    return null;
  }

  Duration get _refundWindow {
    final deadline = checkInDate.subtract(const Duration(hours: 48));
    return deadline.difference(DateTime.now());
  }

  bool get _isRefundableNow =>
      RentalRules.isRefundable(checkInDate: checkInDate, cancelDate: DateTime.now());

  List<({String label, bool done, bool required})> get _docChecklist {
    final docs = <({String label, bool done, bool required})>[
      (label: 'صورة شخصية (سيلفي)', done: hasSelfie, required: true),
      (label: 'بطاقة الهوية — الوجه', done: hasIdFront, required: true),
      (label: 'بطاقة الهوية — الظهر', done: hasIdBack, required: true),
    ];
    if (RentalRules.requiresIncomeProof(tier)) {
      docs.add((
        label: 'إثبات دخل / خطاب عمل',
        done: hasIncomeProof,
        required: true,
      ));
    }
    if (tenantType == TenantType.multiplePersons) {
      docs.add((
        label: 'خطاب الشركة / تفويض حجز',
        done: false,
        required: true,
      ));
    }
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final refundWindow = _refundWindow;
    final suggestion = _durationSuggestion;
    final docs = _docChecklist;
    final doneCount = docs.where((d) => d.done).length;

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'مساعد الحجز الذكي',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tier.arabicLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            tier.paymentModelArabic,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _infoRow(
            icon: Icons.timer_outlined,
            title: _isRefundableNow
                ? 'مؤهل للاسترداد الكامل'
                : 'انتهت مهلة الاسترداد',
            subtitle: _isRefundableNow
                ? refundWindow.inHours > 0
                    ? 'متبقي ${refundWindow.inHours} ساعة قبل موعد الاستلام'
                    : 'أقل من ٤٨ ساعة — الاسترداد غير متاح'
                : RentalRules.refundPolicyShortArabic,
            color: _isRefundableNow
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
          if (suggestion != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            _infoRow(
              icon: Icons.lightbulb_outline_rounded,
              title: 'اقتراح ذكي',
              subtitle: suggestion,
              color: AppTheme.accentColor,
              action: onApplySuggestion != null
                  ? TextButton(
                      onPressed: onApplySuggestion,
                      child: const Text('تطبيق', style: TextStyle(fontSize: 11)),
                    )
                  : null,
            ),
          ],
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              const Text(
                'قائمة المستندات',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/${docs.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...docs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      doc.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: doc.done
                          ? AppTheme.successColor
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: doc.done
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight:
                              doc.required ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
