import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/rental_rules.dart';

/// حاسبة سياسة الاسترداد عند الإلغاء.
class RefundCalculatorDialog extends StatefulWidget {
  final DateTime checkInDate;
  final double depositAmount;
  final String bookingTitle;

  const RefundCalculatorDialog({
    super.key,
    required this.checkInDate,
    required this.depositAmount,
    required this.bookingTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DateTime checkInDate,
    required double depositAmount,
    required String bookingTitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RefundCalculatorDialog(
        checkInDate: checkInDate,
        depositAmount: depositAmount,
        bookingTitle: bookingTitle,
      ),
    );
  }

  @override
  State<RefundCalculatorDialog> createState() => _RefundCalculatorDialogState();
}

class _RefundCalculatorDialogState extends State<RefundCalculatorDialog> {
  late DateTime _cancelDate;

  @override
  void initState() {
    super.initState();
    _cancelDate = DateTime.now();
  }

  bool get _isRefundable =>
      RentalRules.isRefundable(checkInDate: widget.checkInDate, cancelDate: _cancelDate);

  int get _daysBefore => widget.checkInDate.difference(_cancelDate).inDays;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.calculate_rounded, color: AppTheme.primaryColor),
          SizedBox(width: 10),
          Expanded(child: Text('حاسبة الاسترداد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الحجز: ${widget.bookingTitle}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _infoRow('تاريخ الاستلام', _fmt(widget.checkInDate)),
            _infoRow('تاريخ الإلغاء', _fmt(_cancelDate)),
            _infoRow('الأيام قبل الاستلام', '$_daysBefore يوم'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isRefundable ? AppTheme.primaryColor : AppTheme.errorColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_isRefundable ? AppTheme.primaryColor : AppTheme.errorColor).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isRefundable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isRefundable ? AppTheme.primaryColor : AppTheme.errorColor,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRefundable ? 'قابل للاسترداد ✅' : 'غير قابل للاسترداد ❌',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isRefundable ? AppTheme.primaryColor : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRefundable
                        ? 'يحق لك استرداد ${widget.depositAmount.toStringAsFixed(0)} ج.م'
                        : 'الإلغاء خلال يومين أو بعد الاستلام — لا استرداد',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(RentalRules.refundPolicyShortArabic,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.5)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إغلاق')),
        if (_isRefundable)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد الاسترداد (${widget.depositAmount.toStringAsFixed(0)} ج.م)'),
          ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
