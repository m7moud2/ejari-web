import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/booking_status.dart';
import '../services/wallet_service.dart';
import '../utils/safe_parse.dart';
import 'ejari_section.dart';

/// شفافية الضمان — يوضح أين المال (محجوز / مُفرج / مُسترد).
class EscrowTransparencyWidget extends StatelessWidget {
  final Map<String, dynamic> booking;

  const EscrowTransparencyWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final state = _resolveEscrowState(booking);
    final deposit = safeDouble(booking['depositAmount']);

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: state.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(state.icon, color: state.color, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'شفافية الضمان',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (deposit > 0)
                Text(
                  '${deposit.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: state.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _stepRow(
            label: 'المستأجر',
            value: state.tenantLabel,
            active: state.tenantActive,
            icon: Icons.person_outline_rounded,
          ),
          _connector(active: state.tenantActive && state.escrowActive),
          _stepRow(
            label: 'حساب الضمان',
            value: state.escrowLabel,
            active: state.escrowActive,
            icon: Icons.lock_rounded,
          ),
          _connector(active: state.escrowActive && state.ownerActive),
          _stepRow(
            label: 'المالك',
            value: state.ownerLabel,
            active: state.ownerActive,
            icon: Icons.home_work_outlined,
          ),
          if (state.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              state.note,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepRow({
    required String label,
    required String value,
    required bool active,
    required IconData icon,
  }) {
    final color = active ? AppTheme.primaryColor : AppTheme.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(active ? 1 : 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (active)
          Icon(Icons.check_circle_rounded, size: 14, color: color),
      ],
    );
  }

  Widget _connector({required bool active}) {
    return Padding(
      padding: const EdgeInsets.only(right: 7, top: 2, bottom: 2),
      child: Container(
        width: 2,
        height: 12,
        color: active
            ? AppTheme.primaryColor.withOpacity(0.35)
            : AppTheme.borderColor.withOpacity(0.3),
      ),
    );
  }

  _EscrowState _resolveEscrowState(Map<String, dynamic> booking) {
    final status =
        BookingStatus.normalize(booking['status']?.toString());
    final deposit = safeDouble(booking['depositAmount']);
    final feePercent = WalletService.platformFeePercent;

    switch (status) {
      case BookingStatus.submitted:
      case BookingStatus.pending:
      case BookingStatus.corporatePending:
        return const _EscrowState(
          icon: Icons.hourglass_empty_rounded,
          color: AppTheme.textSecondary,
          tenantLabel: 'لم يُدفع العربون بعد',
          tenantActive: false,
          escrowLabel: 'بانتظار الدفع',
          escrowActive: false,
          ownerLabel: 'بانتظار تأكيد الحجز',
          ownerActive: false,
          note: 'بعد الدفع يُحجز المبلغ في حساب ضمان آمن حتى تأكيد الصفقة.',
        );
      case BookingStatus.depositPaid:
      case BookingStatus.viewingScheduled:
        return _EscrowState(
          icon: Icons.lock_rounded,
          color: AppTheme.accentColor,
          tenantLabel: 'تم خصم العربون من محفظتك',
          tenantActive: true,
          escrowLabel: 'محجوز في الضمان — $deposit ج.م',
          escrowActive: true,
          ownerLabel: 'يُفرج بعد موافقتك على الحجز',
          ownerActive: false,
          note: RentalRulesNote.escrowHeld,
        );
      case BookingStatus.approved:
      case BookingStatus.confirmed:
      case BookingStatus.active:
      case BookingStatus.paid:
        final ownerNet = (deposit * (1 - feePercent)).toStringAsFixed(0);
        return _EscrowState(
          icon: Icons.sync_rounded,
          color: AppTheme.primaryColor,
          tenantLabel: 'العربون مؤكد — بانتظار الإفراج',
          tenantActive: true,
          escrowLabel: 'جاري الإفراج من الضمان',
          escrowActive: true,
          ownerLabel: 'سيستلم ~$ownerNet ج.م (بعد عمولة المنصة)',
          ownerActive: true,
          note: 'المنصة تحتفظ بـ ${(feePercent * 100).toInt()}% كعمولة خدمة.',
        );
      case BookingStatus.completed:
        return const _EscrowState(
          icon: Icons.verified_rounded,
          color: AppTheme.successColor,
          tenantLabel: 'اكتمل الحجز بنجاح',
          tenantActive: true,
          escrowLabel: 'تم الإفراج من الضمان',
          escrowActive: true,
          ownerLabel: 'استلم المبلغ في محفظته',
          ownerActive: true,
          note: 'جميع المدفوعات مُوثقة بإيصالات رسمية.',
        );
      case BookingStatus.depositRefunded:
      case BookingStatus.cancelled:
        return _EscrowState(
          icon: Icons.replay_rounded,
          color: AppTheme.successColor,
          tenantLabel: status == BookingStatus.depositRefunded
              ? 'تم استرداد العربون'
              : 'تم إلغاء الحجز',
          tenantActive: true,
          escrowLabel: 'لا مبالغ محجوزة',
          escrowActive: false,
          ownerLabel: 'لا مستحقات',
          ownerActive: false,
          note: 'تُطبَّق سياسة الاسترداد (٤٨ ساعة قبل الاستلام).',
        );
      case BookingStatus.disputed:
        return _EscrowState(
          icon: Icons.gavel_rounded,
          color: AppTheme.errorColor,
          tenantLabel: 'نزاع مفتوح — المبلغ مجمّد',
          tenantActive: true,
          escrowLabel: 'مجمّد في الضمان — $deposit ج.م',
          escrowActive: true,
          ownerLabel: 'بانتظار قرار الإدارة',
          ownerActive: false,
          note: 'فريق إيجاري يراجع النزاع — لا إفراج حتى الحسم.',
        );
      default:
        return _EscrowState(
          icon: Icons.info_outline_rounded,
          color: AppTheme.textSecondary,
          tenantLabel: BookingStatus.arabicLabel(status),
          tenantActive: false,
          escrowLabel: 'حالة غير محددة',
          escrowActive: false,
          ownerLabel: '—',
          ownerActive: false,
          note: '',
        );
    }
  }
}

class _EscrowState {
  final IconData icon;
  final Color color;
  final String tenantLabel;
  final bool tenantActive;
  final String escrowLabel;
  final bool escrowActive;
  final String ownerLabel;
  final bool ownerActive;
  final String note;

  const _EscrowState({
    required this.icon,
    required this.color,
    required this.tenantLabel,
    required this.tenantActive,
    required this.escrowLabel,
    required this.escrowActive,
    required this.ownerLabel,
    required this.ownerActive,
    required this.note,
  });
}

class RentalRulesNote {
  static const escrowHeld =
      'العربون محمي في حساب ضمان إيجاري — لا يُفرج للمالك إلا بعد تأكيدك.';
}
