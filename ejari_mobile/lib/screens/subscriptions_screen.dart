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
    final normalized =
        SubscriptionService.normalizePlanId(planId, _userType);
    final change = await SubscriptionService.canChangePlan(normalized, _userType);
    if (change['allowed'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(change['message']?.toString() ?? 'تغيير الباقة غير مسموح'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final planDetails = SubscriptionService.getPlanDetails(normalized, _userType);

    if (planDetails != null && planDetails['price'] > 0) {
      final navigator = Navigator.of(context);
      final allowed = await AuthGate.requireLogin(
        context,
        actionLabel: 'الاشتراك في باقة مدفوعة',
      );
      if (!allowed || !mounted) return;
      // Navigate to payment screen for paid plans
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentScreen(
            planId: normalized,
            userType: _userType,
            planDetails: planDetails,
          ),
        ),
      );
      if (!mounted) return;
      _loadUserData(); // Reload after payment
    } else {
      // Free plan - subscribe directly
      await SubscriptionService.subscribe(normalized, _userType);
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
          'عمولة على الإيجار',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'bronze',
        'برونزي',
        '299',
        [
          'حتى 5 عقارات',
          'بدون عمولة',
          'دعم فني أساسي',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'silver',
        'فضي',
        '599',
        [
          'حتى 15 عقار',
          'أولوية في الظهور',
          'Reels تسويقية',
        ],
        AppTheme.primaryColor,
        isPopular: true,
      ),
      _buildPlanCard(
        'gold',
        'ذهبي (Ejari)',
        '1299',
        [
          'عقارات غير محدودة',
          'تمييز الإعلانات',
          'أولوية كاملة',
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
          '3 طلبات حجز شهرياً',
          'بحث عادي',
          'دعم فني محدود',
        ],
        AppTheme.primaryColor,
      ),
      _buildPlanCard(
        'plus',
        'بلس',
        '99',
        [
          '10 طلبات حجز شهرياً',
          'إشعارات فورية',
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
          'حجوزات غير محدودة',
          'أولوية في الطلبات',
          'معاينات مجانية',
        ],
        AppTheme.primaryColor,
      ),
    ];
  }

  Widget _buildPlanCard(String planId, String name, String price,
      List<String> features, Color color,
      {bool isPopular = false}) {
  bool isCurrent = _currentPlan ==
      SubscriptionService.normalizePlanId(planId, _userType);

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
