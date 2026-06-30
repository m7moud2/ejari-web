import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_gate.dart';
import 'subscription_payment_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _userType = 'tenant';
  String _currentPlan = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    final subscription = await SubscriptionService.getCurrentSubscription();

    setState(() {
      _userType = user?['type'] ?? 'tenant';
      _currentPlan = subscription['plan'] ?? 'free';
      _isLoading = false;
    });
  }

  Future<void> _subscribe(String planId) async {
    final planDetails = SubscriptionService.getPlanDetails(planId, _userType);

    if (planDetails != null && planDetails['price'] > 0) {
      final allowed = await AuthGate.requireLogin(
        context,
        actionLabel: 'الاشتراك في باقة مدفوعة',
      );
      if (!allowed || !mounted) return;
      // Navigate to payment screen for paid plans
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentScreen(
            planId: planId,
            userType: _userType,
            planDetails: planDetails,
          ),
        ),
      );
      _loadUserData(); // Reload after payment
    } else {
      // Free plan - subscribe directly
      await SubscriptionService.subscribe(planId, _userType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم الاشتراك في الباقة المجانية! ✅'),
              backgroundColor: AppTheme.primaryColor),
        );
        _loadUserData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('باقات الاشتراك')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userType == 'owner' ? 'باقات الملاك' : 'باقات المستأجرين',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الباقة المناسبة لك',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Current Subscription Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.card_membership,
                            color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اشتراكك الحالي',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                SubscriptionService.getPlanDetails(
                                        _currentPlan, _userType)?['name'] ??
                                    'مجاني',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                Theme.of(context).cardColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('نشط',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('الباقات المتاحة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  if (_userType == 'owner') ..._buildOwnerPlans(),
                  if (_userType == 'tenant') ..._buildTenantPlans(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildOwnerPlans() {
    return [
      _buildPlanCard(
        'free',
        'مجاني',
        '0',
        [
          'عقار واحد فقط',
          '5 طلبات شهرياً',
          'دعم فني محدود',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'basic',
        'أساسي',
        '299',
        [
          'حتى 5 عقارات',
          'طلبات غير محدودة',
          'دعم فني عادي',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'pro',
        'احترافي',
        '599',
        [
          'عقارات غير محدودة',
          'أولوية في الظهور',
          'إحصائيات متقدمة',
          'دعم فني سريع',
        ],
        AppTheme.primaryColor,
        isPopular: true,
      ),
      _buildPlanCard(
        'premium',
        'مميز',
        '999',
        [
          'كل مزايا الباقة الاحترافية',
          'دعم فني مخصص 24/7',
          'تسويق للعقارات',
          'تقارير شهرية',
        ],
        AppTheme.primaryColor,
      ),
    ];
  }

  List<Widget> _buildTenantPlans() {
    return [
      _buildPlanCard(
        'free',
        'مجاني',
        '0',
        [
          'بحث عادي',
          '3 طلبات حجز شهرياً',
          'دعم فني محدود',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'plus',
        'بلس',
        '99',
        [
          'طلبات غير محدودة',
          'إشعارات فورية',
          'حفظ عمليات البحث',
          'دعم فني سريع',
        ],
        AppTheme.primaryColor,
        isPopular: true,
      ),
      _buildPlanCard(
        'premium',
        'بريميوم',
        '199',
        [
          'كل مزايا باقة بلس',
          'أولوية في الطلبات',
          'معاينات مجانية',
          'استشارات عقارية',
        ],
        AppTheme.primaryColor,
      ),
    ];
  }

  Widget _buildPlanCard(String planId, String name, String price,
      List<String> features, Color color,
      {bool isPopular = false}) {
    bool isCurrent = _currentPlan == planId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? color : AppTheme.backgroundColor,
          width: isCurrent ? 3 : 1,
        ),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          // Header
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Text(
                  '⭐ الأكثر شعبية',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Plan Name
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ج.م',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (price != '0')
                            const Text('/شهر',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Features
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _subscribe(planId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCurrent ? AppTheme.primaryColor : color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isCurrent ? 'الباقة الحالية' : 'اشترك الآن',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
