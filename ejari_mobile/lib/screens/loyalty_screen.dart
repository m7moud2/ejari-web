import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/loyalty_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _points = 0;
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    final points = await LoyaltyService.getPoints();
    if (mounted) {
      setState(() {
        _points = points;
        _balance = (points * 0.08).round();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مميزات إيجاري',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildBenefitCard(),
            const SizedBox(height: 40),
            _buildPointsStats(),
            const SizedBox(height: 30),
            _buildRewardsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF4F0E8), Color(0xFFE9F1EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [],
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.18), width: 1.2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ejari Premium',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                Icon(Icons.verified_rounded, color: AppTheme.primaryColor),
              ],
            ),
            Text('شفافية، أمان، ومتابعة أوضح',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('كل الامتيازات مرتبطة بخدمات حقيقية',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4)),
                Row(
                  children: [
                    Icon(Icons.star, color: AppTheme.primaryColor, size: 16),
                    SizedBox(width: 4),
                    Text('Active',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('نقاط الولاء',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text('$_points',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
              height: 40,
              width: 1,
              color: AppTheme.primaryColor.withOpacity(0.15)),
          Column(
            children: [
              const Text('الرصيد المتاح',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text('$_balance ج',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _redeemPoints(String title, int requiredPoints) {
    if (_points >= requiredPoints) {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.primaryColor, width: 0.5)),
          title: const Text('تأكيد الاستبدال',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Text('هل تريد استبدال $requiredPoints نقطة مقابل: \n$title؟',
              style: const TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء',
                    style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                final ok = await LoyaltyService.redeemPoints(
                  cost: requiredPoints,
                  rewardTitle: title,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (ok) {
                  await _loadLoyaltyData();
                  if (context.mounted) _showSuccessAnimation(title);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('عذراً، نقاطك لا تكفي لهذا الامتياز ⚠️')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عذراً، نقاطك لا تكفي لهذا الامتياز ⚠️')));
    }
  }

  void _showSuccessAnimation(String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded,
                  color: AppTheme.primaryColor, size: 80),
              const SizedBox(height: 24),
              const Text('مبروك!',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('تم تفعيل امتياز: \n$title',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white),
                child: const Text('رائع!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem(
      String title, String subtitle, IconData icon, int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _redeemPoints(title, points),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('استبدال',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('امتيازات إيجاري المتاحة',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRewardItem('ترقية مجانية لتنظيف فندقي', 'استبدل 3000 نقطة',
            Icons.cleaning_services, 3000),
        const SizedBox(height: 12),
        _buildRewardItem('خُصم 5% على التوثيق القانوني', 'استبدل 5000 نقطة',
            Icons.gavel, 5000),
        const SizedBox(height: 12),
        _buildRewardItem('توصيلة ليموزين للمطار مجانًا', 'استبدل 10000 نقطة',
            Icons.directions_car, 10000),
      ],
    );
  }
}
