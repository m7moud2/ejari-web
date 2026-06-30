import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'contract_view_screen.dart';
import 'package:intl/intl.dart';

class SuccessPaymentScreen extends StatefulWidget {
  final double amount;
  final String transactionId;
  final String paymentMethod; // New parameter
  final String successTitle;
  final String successMessage;

  const SuccessPaymentScreen({
    super.key,
    required this.amount,
    required this.transactionId,
    required this.paymentMethod,
    this.successTitle = 'تم الدفع بنجاح!',
    this.successMessage =
        'تم تأكيد عملية الدفع وحجز الوحدة بنجاح.\nشكراً لاستخدامك كيو.',
  });

  @override
  State<SuccessPaymentScreen> createState() => _SuccessPaymentScreenState();
}

class _SuccessPaymentScreenState extends State<SuccessPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                widget.successTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.successMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.backgroundColor),
                  boxShadow: const [],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: AppTheme.primaryColor, size: 16),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'إيصال ديجيتال موثق - كيو',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _buildDetailRow('المبلغ الإجمالي',
                        '${widget.amount.toStringAsFixed(0)} ج.م',
                        isBold: true),
                    const SizedBox(height: 14),
                    _buildDetailRow('رقم العملية', widget.transactionId),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'التاريخ والوقت',
                        DateFormat('yyyy/MM/dd - hh:mm a')
                            .format(DateTime.now())),
                    const SizedBox(height: 12),
                    _buildDetailRow('وسيلة الدفع',
                        _getPaymentMethodName(widget.paymentMethod)),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'الحساب الوجهة', '01069813210 (محفظة/InstaPay)'),
                    const Divider(height: 28),
                    const Text(
                      'سيصلك إشعار فور مراجعة المالك للطلب. يمكنك متابعة حالة الحجز من "حجوزاتي".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final mockBooking = {
                          'title': 'حجز عقار - معاملة ${widget.transactionId}',
                          'price': widget.amount,
                          'tenantName': 'مستخدم كيو',
                          'ownerName': 'المالك المعتمد',
                          'startDate': DateTime.now().toIso8601String(),
                          'endDate': DateTime.now()
                              .add(const Duration(days: 365))
                              .toIso8601String(),
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ContractViewScreen(bookingDetails: mockBooking),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('عرض العقد'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('الرئيسية',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              color: isBold ? AppTheme.textPrimary : AppTheme.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'wallet':
        return 'محفظة كيو';
      case 'card':
        return 'بطاقة ائتمان / خصم';
      case 'fawry':
        return 'فوري (Fawry)';
      case 'valu':
        return 'تقسيط (Valu)';
      default:
        return method;
    }
  }
}
