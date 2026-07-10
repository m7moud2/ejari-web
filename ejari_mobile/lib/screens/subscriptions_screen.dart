import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../utils/auth_gate.dart';
import '../widgets/ejari_section.dart';
import 'subscription_payment_screen.dart';
import 'listing_plans_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _userType = 'tenant';
  String _currentPlan = 'free';
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final role = await AuthService.getUserRole();
    final subscription = await SubscriptionService.getCurrentSubscription();
    final summary = await SubscriptionService.getSubscriptionSummary();

    setState(() {
      _userType = role == 'tenant' ? 'tenant' : 'owner';
      _currentPlan = subscription['plan'] ?? 'free';
      _summary = summary;
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
      if (!mounted) return;
      final allowed = await AuthGate.requireLogin(
        context,
        actionLabel: 'الاشتراك في باقة مدفوعة',
      );
      if (!allowed || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentScreen(
            planId: normalized,
            userType: _userType,
            planDetails: planDetails,
          ),
        ),
      );
      if (!mounted) return;
      await _loadUserData();
    } else {
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('ترقية الباقة'),
      ),
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
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر الباقة المناسبة لاستثماراتك',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _buildCurrentPlanCard(),
                  if (_userType == 'owner') ...[
                    const SizedBox(height: 20),
                    _buildComparisonTable(),
                  ],
                  const SizedBox(height: 24),
                  const EjariSectionHeader(
                    title: 'الباقات المتاحة',
                    subtitle: 'ترقِّ للحصول على مزايا إضافية',
                  ),
                  const SizedBox(height: 12),
                  if (_userType == 'owner') ..._buildOwnerPlans(),
                  if (_userType == 'tenant') ..._buildTenantPlans(),
                  if (_userType == 'owner') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListingPlansScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('خطط النشر الإيجاري'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final planName = SubscriptionService.getPlanDetails(
          _currentPlan, _userType,
        )?['name'] ??
        'مجاني';
    final used = _summary?['properties_used'] ?? 0;
    final limit = _summary?['properties_limit'] ?? 1;

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_membership,
                  color: AppTheme.primaryColor, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('باقتك الحالية',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Text(planName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('نشط',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ),
            ],
          ),
          if (_userType == 'owner') ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: limit == -1
                  ? 0.2
                  : (used / (limit == 0 ? 1 : limit)).clamp(0.0, 1.0),
              backgroundColor: AppTheme.borderColor.withOpacity(0.3),
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 6),
            Text(
              'العقارات: $used / ${limit == -1 ? '∞' : limit}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    const rows = [
      ('مجاني', '2', '—', '—'),
      ('برونزي', '5', '—', '—'),
      ('فضي', '15', '✓', '—'),
      ('ذهبي', '∞', '✓', '✓'),
    ];
    return EjariSurfaceCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مقارنة المزايا',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Text('الباقة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('عقارات', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('أولوية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('تمييز', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
            ],
          ),
          const Divider(height: 16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 11))),
                    Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 11))),
                    Expanded(child: Text(r.$3, style: const TextStyle(fontSize: 11))),
                    Expanded(child: Text(r.$4, style: const TextStyle(fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<Widget> _buildOwnerPlans() {
    return [
      _buildPlanCard('free', 'مجاني', '0', [
        'حتى 2 عقارات',
        '5 طلبات شهرياً',
        'عمولة على الإيجار',
      ], AppTheme.borderColor),
      _buildPlanCard('bronze', 'برونزي', '99', [
        'حتى 5 عقارات',
        'تحليلات أساسية',
        'بدون عمولة',
      ], AppTheme.primaryColor),
      _buildPlanCard('silver', 'فضي', '249', [
        'حتى 15 عقار',
        'تمييز الإعلانات',
        'تحليلات متقدمة',
      ], AppTheme.primaryColor, isPopular: true),
      _buildPlanCard('gold', 'ذهبي', '499', [
        'عقارات غير محدودة',
        'تمييز أولوية',
        'تحليلات كاملة',
      ], AppTheme.accentColor),
    ];
  }

  List<Widget> _buildTenantPlans() {
    return [
      _buildPlanCard('free', 'مجاني', '0', [
        '3 طلبات حجز شهرياً',
        'بحث عادي',
      ], AppTheme.primaryColor),
      _buildPlanCard('plus', 'بلس', '99', [
        '10 طلبات حجز',
        'إشعارات فورية',
      ], AppTheme.primaryColor, isPopular: true),
      _buildPlanCard('premium', 'بريميوم', '199', [
        'حجوزات غير محدودة',
        'أولوية في الطلبات',
      ], AppTheme.primaryColor),
    ];
  }

  Widget _buildPlanCard(String planId, String name, String price,
      List<String> features, Color color,
      {bool isPopular = false}) {
    final isCurrent = _currentPlan ==
        SubscriptionService.normalizePlanId(planId, _userType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.surfaceCardDecoration(radius: 20).copyWith(
        border: Border.all(
          color: isCurrent ? color : AppTheme.borderColor.withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Text(
                '⭐ الأكثر شعبية',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const SizedBox(height: 8),
                Text('$price ج.م/شهر',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const SizedBox(height: 16),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _subscribe(planId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? AppTheme.borderColor : color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isCurrent ? 'الباقة الحالية' : 'ترقية الآن',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
