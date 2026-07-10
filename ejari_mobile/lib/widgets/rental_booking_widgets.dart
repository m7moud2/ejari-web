import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/rental_duration_tier.dart';
import '../models/tenant_type.dart';
import '../utils/rental_rules.dart';
import 'ejari_section.dart';

/// شارات الثقة على شاشات الحجز والدفع والعقار.
class EjariTrustBadges extends StatelessWidget {
  final bool showTenant;
  final bool showOwner;

  const EjariTrustBadges({
    super.key,
    this.showTenant = true,
    this.showOwner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTenant) _badge(Icons.verified_user_rounded, RentalRules.tenantTrustArabic),
        if (showTenant && showOwner) const SizedBox(height: 8),
        if (showOwner) _badge(Icons.shield_rounded, RentalRules.ownerTrustArabic),
      ],
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11, height: 1.45, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// شارات الثقة على تفاصيل العقار.
class PropertyTrustBadges extends StatelessWidget {
  const PropertyTrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('موثّق', Icons.verified_rounded, AppTheme.primaryColor),
        _chip('عقد محمي', Icons.gavel_rounded, AppTheme.borderColor),
        _chip('استرداد واضح', Icons.replay_rounded, AppTheme.accentColor),
      ],
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// تلميح قاعدة الاسترداد (٤٨ ساعة).
class RefundRuleTooltip extends StatelessWidget {
  const RefundRuleTooltip({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: RentalRules.refundPolicyLegalArabic,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.borderColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.borderColor),
            SizedBox(width: 6),
            Text('قاعدة الاسترداد (٤٨ ساعة)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.borderColor)),
          ],
        ),
      ),
    );
  }
}

/// تلميح تكلفة المدة مقارنة باليومي.
class DurationCostHint extends StatelessWidget {
  final RentalDurationTier tier;
  final double totalPrice;
  final double monthlyRent;
  final int duration;
  final String durationType;

  const DurationCostHint({
    super.key,
    required this.tier,
    required this.totalPrice,
    required this.monthlyRent,
    required this.duration,
    required this.durationType,
  });

  @override
  Widget build(BuildContext context) {
    final dailyEquiv = monthlyRent / 30;
    String hint;
    if (tier == RentalDurationTier.daily) {
      hint = 'الإجمالي: ${totalPrice.toStringAsFixed(0)} ج.م لـ $duration $durationType';
    } else if (tier == RentalDurationTier.weekly) {
      final perDay = totalPrice / (duration * 7);
      hint = 'متوسط ${perDay.toStringAsFixed(0)} ج.م/يوم — مقابل ${dailyEquiv.toStringAsFixed(0)} ج.م يوميًا';
    } else {
      final perDay = totalPrice / (duration * 30);
      hint = 'متوسط ${perDay.toStringAsFixed(0)} ج.م/يوم — مقابل ${dailyEquiv.toStringAsFixed(0)} ج.م يوميًا';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: AppTheme.accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(hint, style: const TextStyle(fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}

/// قائمة تحقق المستندات للإيجار طويل المدى.
class DocumentChecklistStep extends StatelessWidget {
  final bool hasId;
  final bool hasIncome;
  final bool hasEmployment;
  final ValueChanged<String> onTapItem;

  const DocumentChecklistStep({
    super.key,
    required this.hasId,
    required this.hasIncome,
    required this.hasEmployment,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'قائمة المستندات المطلوبة',
            subtitle: 'للإيجار ٦ شهور فأكثر — أكمل القائمة لتسريع الموافقة',
          ),
          const SizedBox(height: 12),
          _item('الهوية الوطنية (وجهان)', hasId, 'id'),
          _item('إثبات دخل / كشف حساب', hasIncome, 'income'),
          _item('عقد عمل أو خطاب جهة العمل', hasEmployment, 'employment'),
        ],
      ),
    );
  }

  Widget _item(String label, bool done, String key) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? AppTheme.primaryColor : AppTheme.textSecondary),
      title: Text(label, style: TextStyle(fontWeight: done ? FontWeight.bold : FontWeight.normal)),
      trailing: done ? null : const Icon(Icons.upload_file_rounded, size: 18, color: AppTheme.primaryColor),
      onTap: () => onTapItem(key),
    );
  }
}

/// بطاقة ملخص الحجز قبل الدفع.
class BookingSummaryCard extends StatelessWidget {
  final RentalDurationTier tier;
  final TenantType tenantType;
  final double depositAmount;
  final double totalPrice;
  final bool showInstallments;
  final DateTime? checkInDate;

  const BookingSummaryCard({
    super.key,
    required this.tier,
    required this.tenantType,
    required this.depositAmount,
    required this.totalPrice,
    required this.showInstallments,
    this.checkInDate,
  });

  @override
  Widget build(BuildContext context) {
    final needsDocs = RentalRules.requiresIncomeProof(tier);
    final needsAdvance = RentalRules.requiresAdvanceDeposit(tier);

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'ملخص الحجز قبل الدفع',
            subtitle: 'راجع الفئة والشروط قبل التأكيد',
          ),
          const SizedBox(height: 12),
          _row('فئة المدة', tier.arabicLabel),
          _row('نوع المستأجر', tenantType.arabicLabel),
          _row('نموذج الدفع', tier.paymentModelArabic),
          _row('المطلوب الآن', '${depositAmount.toStringAsFixed(0)} ج.م'),
          _row('إجمالي التعاقد', '${totalPrice.toStringAsFixed(0)} ج.م'),
          _row('المستندات', needsDocs ? 'مستندات + إثبات دخل' : 'بدون حزمة كاملة'),
          if (needsAdvance)
            _row('الدفع المقدم', RentalRules.advanceDepositLabel(tier)),
          _row('الأقساط الشهرية', showInstallments ? 'متاحة' : 'غير متاحة'),
          const Divider(),
          Row(
            children: [
              const RefundRuleTooltip(),
              const Spacer(),
              if (checkInDate != null)
                Text(
                  RentalRules.refundStatusArabic(
                    checkInDate: checkInDate!,
                    cancelDate: DateTime.now(),
                  ),
                  style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(RentalRules.refundPolicyShortArabic,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// اختيار نوع المستأجر.
class TenantTypeSelector extends StatelessWidget {
  final TenantType selected;
  final ValueChanged<TenantType> onChanged;

  const TenantTypeSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نوع المستأجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: TenantType.values.map((t) {
            final isSel = selected == t;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? AppTheme.primaryColor : AppTheme.borderColor.withOpacity(0.3)),
                  ),
                  child: Text(t.arabicLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isSel ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
