import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/auth_gate.dart';
import 'my_service_requests_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceName;
  final String description;
  final IconData icon;
  final Color color;
  final int basePrice;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceName,
    required this.description,
    required this.icon,
    required this.color,
    this.basePrice = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(serviceName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border:
                    Border(bottom: BorderSide(color: color.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [],
                    ),
                    child: Icon(icon, color: color, size: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    serviceName,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('نظرة عامة',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        height: 1.8,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),

                  const Text('ضمان إيجاري للتميز',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _buildFeature('خضوع كافة الكوادر لاختبارات الدقة والأمان.'),
                  _buildFeature('تأمين شامل ضد الحوادث أو التلفيات.'),
                  _buildFeature('تقييم فوري للخدمة مع ضمان استرداد الأموال.'),
                  _buildFeature('تنفيذ دقيق بمعايير فندقية (Five Stars).'),
                  const SizedBox(height: 32),

                  // Pricing
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.2)),
                      boxShadow: const [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('التكلفة المبدئية',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${basePrice > 0 ? basePrice : '---'} ج.م',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: color),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.shield_rounded,
                              color: color, size: 30),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legal Disclaimer Wrapper
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.3))),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.gavel_rounded,
                            color: AppTheme.borderColor, size: 20),
                        SizedBox(width: 12),
                        ExtendedTextLegal(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          boxShadow: const [],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _showBookingDialog(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppTheme.borderColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('بدء إجراءات التعاقد',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.done_all_rounded, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طلب زيارة مبدئية لخدمة\n$serviceName',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, height: 1.3),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: 'التاريخ',
                          prefixIcon: const Icon(Icons.calendar_month_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: AppTheme.backgroundColor),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 60)),
                            builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                        ColorScheme.light(primary: color),
                                  ),
                                  child: child!,
                                ));
                        if (!context.mounted) return;
                        if (picked != null) {
                          dateController.text =
                              "${picked.year}-${picked.month}-${picked.day}";
                        }
                      },
                      validator: (v) =>
                          v!.isEmpty ? 'مطلوب تحديد التاريخ' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: 'الوقت المحبذ',
                          prefixIcon: const Icon(Icons.schedule_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: AppTheme.backgroundColor),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          timeController.text = picked.format(context);
                        }
                      },
                      validator: (v) => v!.isEmpty ? 'مطلوب تحديد الوقت' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'التعليمات الخاصة',
                  hintText:
                      'اذكر أي تفاصيل إضافية عن مساحة الوحدة للحصول على تقييم دقيق للمقايسة المبدئية...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final allowed = await AuthGate.requireLogin(
                      context,
                      actionLabel: 'توثيق الطلب',
                    );
                    if (!allowed || !context.mounted) return;
                    Navigator.pop(context); // Close sheet
                    _showSuccessDialog(
                        context, dateController.text, timeController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('توثيق الطلب',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String date, String time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded,
                  color: AppTheme.primaryColor, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('تم قيد طلبك بنجاح',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'تم تعيين موعد زيارة المعاينة لخدمة "$serviceName" في تاريخ $date الساعة $time.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                  height: 1.5,
                  fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to Home
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MyServiceRequestsScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.borderColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('لوحة متابعة الطلبات',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExtendedTextLegal extends StatelessWidget {
  const ExtendedTextLegal({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontFamily: 'Tajawal',
              height: 1.6),
          children: [
            TextSpan(
                text:
                    'بموجب اتفاقية الاستخدام، الأسعار المعروضة هي أسعار تقديرية مبدئية '),
            TextSpan(
                text: '(Base Prices)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text:
                    ' قابلة للزيادة أو النقصان بناءً على المعاينة الفعلية للعقار، وتشمل الضريبة المضافة لرسوم المنصة. إتمام الطلب يعتبر إقراراً بالموافقة المبدئية على دخول ممثلي إيجاري للمعاينات الدورية.'),
          ],
        ),
      ),
    );
  }
}
