import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';
import '../utils/auth_gate.dart';
import 'payment_screen.dart';

class ListingPlansScreen extends StatefulWidget {
  final bool isFromWizard;
  const ListingPlansScreen({super.key, this.isFromWizard = false});

  @override
  State<ListingPlansScreen> createState() => _ListingPlansScreenState();
}

class _ListingPlansScreenState extends State<ListingPlansScreen> {
  bool _isAnnual = true;
  String _currentPlan = 'free';

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final sub = await SubscriptionService.getCurrentSubscription();
    if (mounted) {
      setState(() => _currentPlan = sub['plan']?.toString() ?? 'free');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('خطط النشر الإيجاري ✨'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'اختر الباقة التي تناسب استثماراتك',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'وفر أكثر مع الخطط السنوية واحصل على عمولة 0%',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Toggle Switch
            _buildPeriodToggle(),
            const SizedBox(height: 24),
            _buildFreeTierCard(),
            const SizedBox(height: 20),
            _buildFeatureTable(),
            const SizedBox(height: 32),

            // Package Cards
            _buildPackageCard(
              id: 'bronze',
              title: 'الباقة البرونزية',
              price: _isAnnual ? '2,990' : '299',
              features: ['حتى 5 عقارات', 'دعم فني أساسي', 'عمولة 0%'],
              color: AppTheme.borderColor,
            ),
            const SizedBox(height: 20),
            _buildPackageCard(
              id: 'silver',
              title: 'الباقة الفضية',
              price: _isAnnual ? '5,990' : '599',
              features: [
                'حتى 15 عقار',
                'ظهور في الـ Reels',
                'الأولوية في البحث',
                'عمولة 0%'
              ],
              color: AppTheme.borderColor,
              isPopular: true,
            ),
            const SizedBox(height: 20),
            _buildPackageCard(
              id: 'gold',
              title: 'الباقة الذهبية (Ejari)',
              price: _isAnnual ? '12,990' : '1,299',
              features: [
                'عقارات غير محدودة',
                'تمييز الإعلانات (Featured)',
                'تصوير احترافي مجاني',
                'عمولة 0%'
              ],
              color: AppTheme.primaryColor,
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // Commission Option
            _buildCommissionCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTierCard() {
    final isCurrent = _currentPlan == 'free';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryColor : AppTheme.borderColor.withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('الباقة المجانية',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('عقار واحد • عمولة 10% • بدون تمييز',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isCurrent ? null : () => _handleSelection('free'),
              child: Text(isCurrent ? 'الباقة الحالية' : 'اختيار مجاني'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTable() {
    const rows = [
      ('مجاني', '1', '—', '—'),
      ('برونزي', '5', '—', '—'),
      ('فضي', '15', '✓', '—'),
      ('ذهبي', '∞', '✓', '✓'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مقارنة خطط النشر',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Text('الخطة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('إعلانات', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('تمييز', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
              Expanded(child: Text('تحليلات', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
            ],
          ),
          const Divider(height: 14),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
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

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('شهري', !_isAnnual),
          _buildToggleButton('سنوي (وفر 20%)', _isAnnual),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = text.contains('سنوي')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: active ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required String id,
    required String title,
    required String price,
    required List<String> features,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isPopular ? Border.all(color: color, width: 2) : null,
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12))),
                child: const Text('الأكثر طلباً',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Icon(Icons.workspace_premium, color: color),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Text('ج.م',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    Text(_isAnnual ? '/سنة' : '/شهر',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: color.withOpacity(0.5), size: 18),
                          const SizedBox(width: 10),
                          Text(f, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleSelection(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('اشترك الآن',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'لا ترغب في الاشتراك؟ انشر مجاناً!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'ادفع فقط عند إتمام الصفقة (نظام العمولة)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCommissionBadge('بيع', '2.5%'),
              _buildCommissionBadge('إيجار', '10%'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleSelection('commission'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
              child: const Text('اختيار نظام العمولة',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionBadge(String title, String value) {
    return Column(
      children: [
        Text(title,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
      ],
    );
  }

  void _handleSelection(String planId) async {
    final navigator = Navigator.of(context);
    if (planId != 'free') {
      final allowed = await AuthGate.requireLogin(
        context,
        actionLabel: 'الاشتراك في الباقات المدفوعة',
      );
      if (!allowed || !mounted) return;
    }

    if (planId == 'free') {
      await SubscriptionService.subscribe('free', 'owner');
    } else if (planId != 'commission') {
      double amount = 0;
      if (planId == 'bronze') {
        amount = _isAnnual ? 2990 : 299;
      } else if (planId == 'silver') {
        amount = _isAnnual ? 5990 : 599;
      } else if (planId == 'gold') {
        amount = _isAnnual ? 12990 : 1299;
      }

      final result = await navigator.push(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            itemType: 'subscription',
            itemData: {
              'id': planId,
              'name': planId == 'bronze'
                  ? 'الباقة البرونزية'
                  : (planId == 'silver' ? 'الباقة الفضية' : 'الباقة الذهبية'),
              'period': _isAnnual ? 'annual' : 'monthly',
            },
            amount: amount,
          ),
        ),
      );

      if (result != true) return;
      await SubscriptionService.subscribe(planId, 'owner');
    }

    if (mounted) {
      if (widget.isFromWizard) {
        Navigator.pop(context, planId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تفعيل الخطة بنجاح! ✅'),
              backgroundColor: AppTheme.primaryColor),
        );
        Navigator.pop(context);
      }
    }
  }
}
