import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../providers/home_provider.dart';
import '../utils/auth_gate.dart';
import '../widgets/ejari_section.dart';
import 'subscription_payment_screen.dart';

class ListingPlansScreen extends StatefulWidget {
  final bool isFromWizard;
  const ListingPlansScreen({super.key, this.isFromWizard = false});

  @override
  State<ListingPlansScreen> createState() => _ListingPlansScreenState();
}

class _ListingPlansScreenState extends State<ListingPlansScreen> {
  String _currentPlan = 'free';
  Map<String, dynamic>? _summary;
  bool _loading = true;

  static const _comparisonRows = [
    ('مجاني', '2', '✗', '✗', '0'),
    ('برونزي', '5', '✗', 'أساسية', '99'),
    ('فضي', '15', '✓', '✓', '249'),
    ('ذهبي', '∞', '✓ أولوية', '✓ كاملة', '499'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final sub = await SubscriptionService.getCurrentSubscription();
    final summary = await SubscriptionService.getSubscriptionSummary();
    if (mounted) {
      setState(() {
        _currentPlan = sub['plan']?.toString() ?? 'free';
        _summary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('خطط النشر'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCurrent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentPlanBanner(),
                    const SizedBox(height: 20),
                    const EjariSectionHeader(
                      title: 'مقارنة الباقات',
                      subtitle: 'اختر الخطة المناسبة لنشاطك العقاري',
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonTable(),
                    const SizedBox(height: 24),
                    ..._buildPlanCards(),
                    const SizedBox(height: 16),
                    _buildCommissionCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    final planName = _summary?['plan_name']?.toString() ?? 'مجاني';
    final used = _summary?['properties_used'] ?? 0;
    final limit = _summary?['properties_limit'] ?? 2;
    final isGold = _currentPlan == 'gold';

    return EjariSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isGold ? Icons.star_rounded : Icons.workspace_premium_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'باقتك الحالية',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  '$planName${isGold ? ' ⭐' : ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'الإعلانات: $used / ${limit == -1 ? '∞' : limit}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'نشط',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return EjariSurfaceCard(
      elevated: false,
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 2, child: Text('الخطة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
              Expanded(child: Text('إعلانات', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
              Expanded(child: Text('تمييز', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
              Expanded(child: Text('تحليلات', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
              Expanded(child: Text('السعر', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 16),
          ..._comparisonRows.map((row) {
            final planKey = switch (row.$1) {
              'مجاني' => 'free',
              'برونزي' => 'bronze',
              'فضي' => 'silver',
              _ => 'gold',
            };
            final isCurrent = _currentPlan == planKey;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: isCurrent
                  ? const EdgeInsets.symmetric(vertical: 6, horizontal: 4)
                  : EdgeInsets.zero,
              decoration: isCurrent
                  ? BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(row.$1, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600)),
                        if (isCurrent) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('أنت هنا', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(child: Text(row.$2, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(child: Text(row.$3, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(child: Text(row.$4, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(child: Text('${row.$5}/ش', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildPlanCards() {
    const plans = [
      ('free', 'مجاني', 0, AppTheme.borderColor),
      ('bronze', 'برونزي', 99, Color(0xFF8B6914)),
      ('silver', 'فضي', 249, AppTheme.primaryColor),
      ('gold', 'ذهبي', 499, AppTheme.accentColor),
    ];

    return plans.map((p) {
      final id = p.$1;
      final name = p.$2;
      final price = p.$3;
      final color = p.$4;
      final isCurrent = _currentPlan == id;
      final features = SubscriptionService.planFeatureLabels(id);
      final isPopular = id == 'silver';

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: EjariSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (isPopular)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Text(
                    '⭐ الأكثر طلباً',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('الباقة الحالية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price == 0 ? 'مجاناً' : '$price ج.م/شهر',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: color, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isCurrent ? null : () => _handleSelection(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent ? AppTheme.borderColor : color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isCurrent ? 'الباقة الحالية' : 'اشترك الآن',
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
    }).toList();
  }

  Widget _buildCommissionCard() {
    return EjariSurfaceCard(
      elevated: false,
      child: Column(
        children: [
          const Text(
            'لا ترغب في الاشتراك؟',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'انشر مجاناً بنظام العمولة — تدفع فقط عند إتمام الصفقة',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _currentPlan == 'commission'
                ? null
                : () => _handleSelection('commission'),
            child: const Text('اختيار نظام العمولة'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelection(String planId) async {
    if (planId != 'free' && planId != 'commission') {
      final allowed = await AuthGate.requireLogin(
        context,
        actionLabel: 'الاشتراك في الباقات المدفوعة',
      );
      if (!allowed || !mounted) return;
    }

    if (planId == 'free' || planId == 'commission') {
      final user = await AuthService.getCurrentUser();
      final email = user?['email']?.toString() ?? '';
      await SubscriptionService.activatePlan(email, planId, userType: 'owner');
    } else {
      final planDetails = SubscriptionService.getPlanDetails(planId, 'owner');
      if (planDetails == null) return;

      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionPaymentScreen(
            planId: planId,
            userType: 'owner',
            planDetails: planDetails,
          ),
        ),
      );
      if (paid != true || !mounted) return;
    }

    await _loadCurrent();
    if (!mounted) return;

    try {
      context.read<HomeProvider>().loadHomeData('owner');
    } catch (_) {}

    if (widget.isFromWizard) {
      Navigator.pop(context, planId);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تفعيل الخطة بنجاح! ✅'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
