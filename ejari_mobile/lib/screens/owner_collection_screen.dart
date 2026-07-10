import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class OwnerCollectionScreen extends StatefulWidget {
  const OwnerCollectionScreen({super.key});

  @override
  State<OwnerCollectionScreen> createState() => _OwnerCollectionScreenState();
}

class _OwnerCollectionScreenState extends State<OwnerCollectionScreen> {
  final double expectedThisMonth = 35000.0;
  final double collectedThisMonth = 25000.0;
  final double lateAmount = 10000.0;

  final List<Map<String, dynamic>> _tenants = [
    {
      'name': 'أحمد محمود',
      'property': 'شقة 102 - مجمع الرحاب',
      'status': 'Late',
      'lateAmount': 10000.0,
      'nextDueDate': DateTime.now().subtract(const Duration(days: 5)),
      'lastPayment': DateTime.now().subtract(const Duration(days: 35))
    },
    {
      'name': 'محمد عبدالله',
      'property': 'فيلا 5 - التجمع',
      'status': 'Paid',
      'lateAmount': 0.0,
      'nextDueDate': DateTime.now().add(const Duration(days: 20)),
      'lastPayment': DateTime.now().subtract(const Duration(days: 10))
    },
    {
      'name': 'سارة أحمد',
      'property': 'مكتب 4 - مول العرب',
      'status': 'Upcoming',
      'lateAmount': 0.0,
      'nextDueDate': DateTime.now().add(const Duration(days: 10)),
      'lastPayment': DateTime.now().subtract(const Duration(days: 28))
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('تحصيل الإيجارات'),
        titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _summary(),
          const SizedBox(height: 14),
          _overview(),
          const SizedBox(height: 14),
          const Text('حالة المستأجرين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ..._tenants.map(_tenantCard),
        ],
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجمالي المتوقع تحصيله هذا الشهر',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${expectedThisMonth.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _smallMetric('المحصّل',
                      '${collectedThisMonth.toStringAsFixed(0)} ج.م')),
              const SizedBox(width: 10),
              Expanded(
                  child: _smallMetric(
                      'المتأخرات', '${lateAmount.toStringAsFixed(0)} ج.م')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _overview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الشفافية المالية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'كل مستأجر يظهر لك حالته بوضوح: مدفوع، قريب الاستحقاق، متأخر، مع سجل دفع وإيصال لكل عملية.',
              style: TextStyle(height: 1.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _tenantCard(Map<String, dynamic> tenant) {
    final status = tenant['status'] as String;
    final isLate = status == 'Late';
    final isPaid = status == 'Paid';
    final color = isLate
        ? AppTheme.errorColor
        : (isPaid ? AppTheme.primaryColor : Colors.orange);
    final text = isLate ? 'متأخر' : (isPaid ? 'مدفوع' : 'قريب الاستحقاق');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(tenant['property'],
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                    'القسط القادم',
                    DateFormat('yyyy/MM/dd')
                        .format(tenant['nextDueDate'] as DateTime)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfo(
                    'آخر دفع',
                    DateFormat('yyyy/MM/dd')
                        .format(tenant['lastPayment'] as DateTime)),
              ),
            ],
          ),
          if (isLate) ...[
            const SizedBox(height: 10),
            _miniInfo('المبلغ المتأخر', '${tenant['lateAmount']} ج.م'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('سجل الدفعات'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon:
                      const Icon(Icons.notifications_active_rounded, size: 16),
                  label: const Text('إشعار'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
