import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/loyalty_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _points = 0;
  int _availableRewards = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points = await LoyaltyService.getPoints();
    final redeemed = await LoyaltyService.getRedeemedRewards();
    if (mounted) {
      setState(() {
        _points = points;
        _availableRewards = (3 - redeemed.length).clamp(0, 3);
        _loading = false;
      });
    }
  }

  String get _tierLabel {
    if (_points >= 5000) return 'المستوى الذهبي 🏆';
    if (_points >= 2000) return 'المستوى الفضي 🥈';
    return 'المستوى البرونزي 🥉';
  }

  String get _tierShort {
    if (_points >= 5000) return 'ذهبي';
    if (_points >= 2000) return 'فضي';
    return 'برونزي';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقاط الولاء والمكافآت'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.1)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text('ملخص الولاء',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'استخدم نقاطك في خصومات وخدمات تساعدك داخل رحلة الإيجار نفسها.',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.star,
                            size: 48, color: AppTheme.borderColor),
                        const SizedBox(height: 16),
                        const Text(
                          'رصيد النقاط',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPoints(_points),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                Theme.of(context)
                                    .cardColor
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _tierLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatMini(
                              context, 'الخصومات المتاحة', '$_availableRewards'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatMini(
                              context, 'مستوى الولاء', _tierShort),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'استبدل نقاطك',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildRewardItem(
                          context,
                          'خصم 500 ج.م على الإيجار',
                          '5000 نقطة',
                          5000,
                          AppTheme.primaryColor,
                          Icons.home,
                        ),
                        _buildRewardItem(
                          context,
                          'خدمة تنظيف مجانية',
                          '3000 نقطة',
                          3000,
                          AppTheme.primaryColor,
                          Icons.cleaning_services,
                        ),
                        _buildRewardItem(
                          context,
                          'قسيمة شراء كارفور',
                          '2000 نقطة',
                          2000,
                          AppTheme.borderColor,
                          Icons.shopping_cart,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatPoints(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildRewardItem(BuildContext context, String title, String cost,
      int pointCost, Color color, IconData icon) {
    final canRedeem = _points >= pointCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(cost,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canRedeem
                ? () => _showRedeemDialog(context, title, cost, pointCost)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              foregroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('استبدال'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRedeemDialog(
      BuildContext context, String title, String cost, int pointCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد استبدال النقاط'),
        content: Text('هل تريد استبدال $cost مقابل $title؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await LoyaltyService.redeemPoints(
                cost: pointCost,
                rewardTitle: title,
              );
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('رصيد النقاط غير كافٍ')));
                return;
              }
              await _load();
              if (!mounted) return;
              final redeemed = await LoyaltyService.getRedeemedRewards();
              final code = redeemed.isNotEmpty
                  ? redeemed.last['code']?.toString() ?? ''
                  : '';
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تم الاستبدال بنجاح! 🎉'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.primaryColor, size: 60),
                      const SizedBox(height: 16),
                      Text('كود الخصم: $code'),
                      const SizedBox(height: 8),
                      const Text('تمت إضافة القسيمة إلى محفظتك.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primaryColor)),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ممتاز'))
                  ],
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
