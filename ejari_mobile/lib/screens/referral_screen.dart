import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/loyalty_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String _referralCode = '';
  int _referralCount = 0;
  int _earnedPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final user = await AuthService.getCurrentUser();
    final accountId = user?['accountId']?.toString();
    final email = user?['email']?.toString() ?? '';
    final referrals = await LoyaltyService.getReferralCount(email);
    final earned = await LoyaltyService.getEarnedFromReferrals(email);
    setState(() {
      _referralCode = accountId?.isNotEmpty == true
          ? accountId!
          : (email.length >= 8
              ? email.substring(0, 8).toUpperCase()
              : 'EJARI123');
      _referralCount = referrals;
      _earnedPoints = earned;
    });
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كود الإحالة'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _shareReferral() {
    final message =
        'دعوة إيجاري الحصرية 🏠\n\nاستخدم كود الإحالة الخاص بي: $_referralCode\nواحصل على 100 نقطة فورية عند التسجيل!\n\nحمل تطبيق إيجاري من المتجر';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مشاركة كود الإحالة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.chat, color: Colors.white)),
              title: const Text('واتس آب (WhatsApp)'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم نسخ الرسالة - افتح واتس آب والصق')));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.sms, color: Colors.white)),
              title: const Text('رسالة نصية (SMS)'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم نسخ الرسالة - افتح الرسائل والصق')));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.copy, color: Colors.white)),
              title: const Text('نسخ الرسالة كاملة'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم نسخ الرسالة بالكامل ✅'),
                    backgroundColor: AppTheme.primaryColor));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('برنامج الإحالة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [],
              ),
              child: const Column(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.white, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'احصل على مكافآت عند دعوة أصدقائك!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اكسب 100 نقطة لكل صديق يسجل باستخدام كودك',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'عدد الإحالات',
                    '$_referralCount',
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'النقاط المكتسبة',
                    '$_earnedPoints',
                    Icons.stars,
                    AppTheme.borderColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Referral Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                boxShadow: const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'كود الإحالة الخاص بك',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _referralCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyReferralCode,
                          icon: const Icon(Icons.copy,
                              color: AppTheme.primaryColor),
                          tooltip: 'نسخ الكود',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareReferral,
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة الكود'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // How it works
            const Text(
              'كيف يعمل البرنامج؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStep(
              '1',
              'شارك كود الإحالة',
              'أرسل كودك لأصدقائك وعائلتك',
              Icons.share,
              AppTheme.primaryColor,
            ),
            _buildStep(
              '2',
              'يسجل صديقك',
              'عندما يسجل صديقك باستخدام كودك',
              Icons.person_add,
              AppTheme.primaryColor,
            ),
            _buildStep(
              '3',
              'احصل على المكافأة',
              'تحصل أنت وصديقك على 100 نقطة',
              Icons.card_giftcard,
              AppTheme.borderColor,
            ),

            const SizedBox(height: 24),

            // Rewards
            const Text(
              'استبدل نقاطك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRewardCard(
              'خصم 10%',
              '500 نقطة',
              'على أي حجز',
              Icons.discount,
              AppTheme.primaryColor,
            ),
            _buildRewardCard(
              'خصم 20%',
              '1000 نقطة',
              'على أي حجز',
              Icons.local_offer,
              AppTheme.errorColor,
            ),
            _buildRewardCard(
              'شهر مجاني',
              '2000 نقطة',
              'اشتراك باقة الملاك',
              Icons.workspace_premium,
              AppTheme.borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
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
                    fontSize: 16,
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
          Icon(icon, color: color),
        ],
      ),
    );
  }

  Widget _buildRewardCard(String title, String points, String description,
      IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              points,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
