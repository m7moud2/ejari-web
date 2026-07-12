import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import 'booking_qr_screen.dart';
import 'contract_view_screen.dart';
import 'my_bookings_screen.dart';
import 'receipt_screen.dart';
import '../models/payment_receipt.dart';

/// شاشة تأكيد الحجز مع الخطوات التالية: QR، العقد، مواعيد الدخول.
class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final double amount;
  final String transactionId;
  final String paymentMethod;
  final PaymentReceipt? receipt;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
    this.receipt,
  });

  DateTime? get _checkIn {
    final raw = booking['checkInDate']?.toString() ??
        booking['leaseStartDate']?.toString() ??
        booking['startDate']?.toString();
    return DateTime.tryParse(raw ?? '');
  }

  DateTime? get _checkOut {
    final raw = booking['checkOutDate']?.toString() ??
        booking['leaseEndDate']?.toString() ??
        booking['endDate']?.toString();
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed != null) return parsed;
    final checkIn = _checkIn;
    if (checkIn == null) return null;
    final months = int.tryParse(booking['leaseMonths']?.toString() ?? '1') ?? 1;
    return DateTime(checkIn.year, checkIn.month + months, checkIn.day);
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'wallet':
        return 'محفظة إيجاري';
      case 'card':
        return 'بطاقة بنكية';
      case 'fawry':
        return 'فوري';
      case 'valu':
        return 'تقسيط';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = booking['title']?.toString() ?? 'حجز جديد';
    final checkIn = _checkIn;
    final checkOut = _checkOut;
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم تأكيد حجزك!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              EjariSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EjariSectionHeader(
                      title: 'ملخص الدفع',
                      subtitle: 'تم استلام العربون بنجاح',
                    ),
                    const SizedBox(height: 8),
                    _row('المبلغ', '${amount.toStringAsFixed(0)} ج.م'),
                    _row('رقم العملية', transactionId),
                    _row('وسيلة الدفع', _methodLabel(paymentMethod)),
                    if (checkIn != null)
                      _row('تاريخ الدخول', dateFmt.format(checkIn)),
                    if (checkOut != null)
                      _row('تاريخ الخروج', dateFmt.format(checkOut)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const EjariSectionHeader(
                title: 'الخطوات التالية',
                subtitle: 'أكمل رحلتك من هنا',
              ),
              const SizedBox(height: 10),
              _nextStepTile(
                context,
                icon: Icons.qr_code_2_rounded,
                title: 'رمز QR للدخول',
                subtitle: 'اعرض الرمز للمالك عند استلام الوحدة',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingQrScreen(booking: booking),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _nextStepTile(
                context,
                icon: Icons.description_outlined,
                title: 'مراجعة العقد',
                subtitle: 'اقرأ ووقّع عقد الإيجار الإلكتروني',
                color: const Color(0xFF2D6A5A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContractViewScreen(
                      bookingDetails: {
                        'title': title,
                        'price': amount,
                        'tenantName':
                            booking['tenantName']?.toString() ?? 'مستأجر',
                        'ownerName':
                            booking['ownerName']?.toString() ?? 'المالك',
                        'startDate': checkIn?.toIso8601String() ??
                            DateTime.now().toIso8601String(),
                        'endDate': checkOut?.toIso8601String() ??
                            DateTime.now()
                                .add(const Duration(days: 365))
                                .toIso8601String(),
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _nextStepTile(
                context,
                icon: Icons.calendar_month_rounded,
                title: 'متابعة الحجز',
                subtitle: 'حالة الطلب، الدفعات، والتذكيرات',
                color: AppTheme.accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                ),
              ),
              if (receipt != null) ...[
                const SizedBox(height: 8),
                _nextStepTile(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'إيصال الدفع',
                  subtitle: 'تحميل أو مشاركة الإيصال',
                  color: const Color(0xFFB58D3D),
                  onTap: () => ReceiptScreen.showDialogFor(context, receipt!),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.surfaceCardDecoration(radius: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
