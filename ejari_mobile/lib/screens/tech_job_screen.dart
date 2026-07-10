import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'provider_wallet_screen.dart';

class TechJobScreen extends StatefulWidget {
  const TechJobScreen({super.key});

  @override
  State<TechJobScreen> createState() => _TechJobScreenState();
}

class _TechJobScreenState extends State<TechJobScreen> {
  // Mock Data for Technician Job Flow
  String jobStatus =
      'Accepted'; // 'Created', 'Accepted', 'Scheduled', 'In Progress', 'Waiting For Confirmation', 'Paid', 'Disputed'

  final Map<String, dynamic> _jobDetails = {
    'id': 'MAINT-7821',
    'type': 'سباكة',
    'property': 'شقة 102 - مجمع الرحاب',
    'payer': 'المالك', // Owner pays
    'description': 'تسريب مياه في الحمام الرئيسي',
    'initialCost': 150.0,
    'finalCost': 0.0,
    'customerName': 'أحمد محمود',
    'customerPhone': '010XXXXXXX',
  };

  void _updateStatus(String newStatus) {
    setState(() {
      jobStatus = newStatus;
    });

    // Simulate Backend Ledger Integration
    if (newStatus == 'Waiting For Confirmation') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'تم إرسال طلب التأكيد للعميل. (الأموال الآن في محفظة Escrow)')));
    } else if (newStatus == 'Paid') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'تم تأكيد العميل! تم تحويل الصافي لمحفظتك وتم خصم عمولة المنصة.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('مهمة ${_jobDetails['id']}'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusBar(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobDetailsCard(),
                  const SizedBox(height: 24),
                  _buildActionArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;

    switch (jobStatus) {
      case 'Accepted':
        statusColor = Colors.blue;
        statusText = 'تم القبول (بانتظار البدء)';
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        statusText = 'قيد التنفيذ الميداني';
        break;
      case 'Waiting For Confirmation':
        statusColor = Colors.purple;
        statusText = 'بانتظار تأكيد العميل للتحويل';
        break;
      case 'Paid':
        statusColor = Colors.green;
        statusText = 'تم الدفع بنجاح';
        break;
      case 'Disputed':
        statusColor = AppTheme.errorColor;
        statusText = 'يوجد نزاع - قيد مراجعة الإدارة';
        break;
      default:
        statusColor = Colors.grey;
        statusText = jobStatus;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: statusColor,
      child: Center(
        child: Text(statusText,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle,
                    color: AppTheme.primaryColor, size: 30),
                const SizedBox(width: 12),
                Text('${_jobDetails['type']}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('العقار', '${_jobDetails['property']}'),
            const SizedBox(height: 8),
            _buildDetailRow('العميل', '${_jobDetails['customerName']}'),
            const SizedBox(height: 8),
            _buildDetailRow('المسؤول عن الدفع', '${_jobDetails['payer']}'),
            const SizedBox(height: 8),
            _buildDetailRow('الوصف', '${_jobDetails['description']}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تكلفة المعاينة / المبدئية',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Text('${_jobDetails['initialCost']} ج.م',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14))),
      ],
    );
  }

  Widget _buildActionArea() {
    if (jobStatus == 'Accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus('In Progress'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('بدء المهمة وتسجيل الوقت',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ),
      );
    } else if (jobStatus == 'In Progress') {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'تم إرفاق ٢ صورة (قبل/بعد) — محاكاة وضع تجريبي'),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('إرفاق صور (قبل وبعد الإصلاح)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _updateStatus('Waiting For Confirmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إنهاء المهمة وطلب التأكيد',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (jobStatus == 'Waiting For Confirmation') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top, color: Colors.purple, size: 40),
            const SizedBox(height: 12),
            const Text('نحن بانتظار تأكيد العميل لإتمام الخدمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('Paid'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('محاكاة: تأكيد العميل',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('Disputed'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor),
                    child: const Text('محاكاة: رفض العميل',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    } else if (jobStatus == 'Disputed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: const Column(
          children: [
            Icon(Icons.gavel, color: AppTheme.errorColor, size: 40),
            SizedBox(height: 12),
            Text(
                'تم فتح نزاع من قبل العميل. الأموال مجمدة حالياً في الـ Escrow الإدارة تقوم بمراجعة الصور والمحادثات لاتخاذ قرار.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      // Paid
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 12),
            const Text('تم إضافة الصافي لمحفظتك بنجاح!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderWalletScreen(),
                  ),
                );
              },
              child: const Text('عرض الإيصال وسجل المحفظة'),
            )
          ],
        ),
      );
    }
  }
}
