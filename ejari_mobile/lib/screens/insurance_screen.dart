import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  String _selectedPlan = 'basic';

  final List<Map<String, dynamic>> _insurancePlans = [
    {
      'id': 'basic',
      'name': 'الباقة الأساسية',
      'price': '200',
      'period': 'شهرياً',
      'color': AppTheme.primaryColor,
      'features': [
        'تأمين ضد الأضرار حتى 10,000 ج.م',
        'صيانة طارئة مجانية',
        'تغطية الأجهزة المنزلية',
        'دعم فني 24/7',
      ],
    },
    {
      'id': 'premium',
      'name': 'الباقة المميزة',
      'price': '350',
      'period': 'شهرياً',
      'color': AppTheme.primaryColor,
      'features': [
        'تأمين ضد الأضرار حتى 25,000 ج.م',
        'صيانة دورية مجانية',
        'تغطية شاملة للمحتويات',
        'استبدال فوري للأجهزة',
        'خدمة كونسيرج',
        'دعم فني VIP',
      ],
    },
    {
      'id': 'gold',
      'name': 'الباقة الذهبية',
      'price': '500',
      'period': 'شهرياً',
      'color': AppTheme.borderColor,
      'features': [
        'تأمين ضد الأضرار حتى 50,000 ج.م',
        'صيانة شاملة مجانية',
        'تغطية كاملة ضد الكوارث',
        'تأمين ضد السرقة',
        'نقل وتخزين مجاني',
        'خدمة كونسيرج مخصصة',
        'دعم فني حصري',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التأمين والضمانات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'احمِ استثمارك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تأمين شامل لراحة بالك',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Why Insurance
            const Text(
              'لماذا التأمين؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBenefitCard(
              'حماية مالية',
              'تغطية شاملة ضد الأضرار والخسائر',
              Icons.account_balance_wallet,
              AppTheme.primaryColor,
            ),
            _buildBenefitCard(
              'راحة البال',
              'لا تقلق بشأن المفاجآت غير المتوقعة',
              Icons.spa,
              AppTheme.primaryColor,
            ),
            _buildBenefitCard(
              'خدمات إضافية',
              'صيانة مجانية ودعم فني متواصل',
              Icons.build_circle,
              AppTheme.borderColor,
            ),

            const SizedBox(height: 32),

            // Insurance Plans
            const Text(
              'اختر الباقة المناسبة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...List.generate(
              _insurancePlans.length,
              (index) => _buildPlanCard(_insurancePlans[index]),
            ),

            const SizedBox(height: 24),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showSubscribeDialog();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'اشترك الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            const Text(
              '* جميع الباقات تشمل فترة تجريبية مجانية لمدة 7 أيام',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan['id'];
    final color = plan['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.backgroundColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan['price'],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'ج.م/${plan['period']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المميزات:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    (plan['features'] as List).length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              plan['features'][index],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscribeDialog() {
    final selectedPlan =
        _insurancePlans.firstWhere((p) => p['id'] == _selectedPlan);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الباقة: ${selectedPlan['name']}'),
            const SizedBox(height: 8),
            Text(
                'السعر: ${selectedPlan['price']} ج.م/${selectedPlan['period']}'),
            const SizedBox(height: 16),
            const Text(
              'ستحصل على فترة تجريبية مجانية لمدة 7 أيام',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تفعيل الفترة التجريبية بنجاح!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
