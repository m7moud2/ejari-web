import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_receipt.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';

/// عرض إيصال دفع — من الحجوزات أو المحفظة أو الإشعارات.
class ReceiptScreen extends StatelessWidget {
  final PaymentReceipt receipt;

  const ReceiptScreen({super.key, required this.receipt});

  static Future<void> showDialogFor(
    BuildContext context,
    PaymentReceipt receipt,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              ReceiptScreen(receipt: receipt),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إيصال دفع إيجاري',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                    Text('إيصال ديجيتال موثق',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _row('رقم الإيصال', receipt.id),
          _row('المبلغ', '${receipt.amount.toStringAsFixed(0)} ج.م',
              bold: true),
          _row('التاريخ',
              DateFormat('yyyy/MM/dd - hh:mm a').format(receipt.date)),
          _row('مرجع الحجز', receipt.bookingRef),
          _row('الدافع', receipt.payer),
          _row('المستلم', receipt.payee),
          _row('وسيلة الدفع', receipt.methodLabelAr),
          if (receipt.title != null) _row('الوصف', receipt.title!),
          _row('الحالة', receipt.status == 'completed' ? 'مكتمل ✅' : receipt.status),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'هذا إيصال تجريبي للعرض. في الإنتاج يُربط ببوابة الدفع وقاعدة البيانات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  fontSize: bold ? 16 : 14,
                )),
          ),
        ],
      ),
    );
  }
}
