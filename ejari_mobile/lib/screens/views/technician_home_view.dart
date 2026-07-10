import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../notification_center_screen.dart';

class TechnicianHomeView extends StatelessWidget {
  const TechnicianHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.techStats;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => context.read<HomeProvider>().loadHomeData('technician'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHero(context, stats),
          const SizedBox(height: 14),
          _buildStats(stats),
          const SizedBox(height: 14),
          if ((stats['urgentRequests'] ?? 0) > 0) _buildUrgentBanner(stats),
          const SizedBox(height: 14),
          _buildSectionTitle('الطلبات الجارية'),
          _buildJobList(active: true),
          const SizedBox(height: 14),
          _buildSectionTitle('طلبات جديدة قريبة'),
          _buildJobList(active: false),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentColor,
                child:
                    Icon(Icons.handyman_rounded, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مرحباً أيها الفني',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'الحالة: ${stats['availability'] ?? 'متاح'} • ${stats['verificationStatus'] ?? 'موثق'}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen())),
                icon: const Icon(Icons.notifications_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _heroMetric(
                      'طلبات جديدة', '${stats['newRequests'] ?? 0}')),
              const SizedBox(width: 10),
              Expanded(
                  child: _heroMetric(
                      'أرباح اليوم', '${stats['todayEarnings'] ?? 0} ج.م')),
              const SizedBox(width: 10),
              Expanded(
                  child: _heroMetric('التقييم', '${stats['rating'] ?? 0}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 96,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      children: [
        _statCard('اليومي', '${stats['todayEarnings'] ?? 0} ج.م',
            Icons.payments_rounded, Colors.green),
        _statCard('الشهر', '${stats['monthlyEarnings'] ?? 0} ج.م',
            Icons.calendar_month_rounded, AppTheme.primaryColor),
        _statCard('المنجز', '${stats['completedJobs'] ?? 0}',
            Icons.task_alt_rounded, AppTheme.accentColor),
        _statCard('الرصيد', '${stats['availableBalance'] ?? 0} ج.م',
            Icons.account_balance_wallet_rounded, Colors.teal),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentBanner(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.errorColor,
            child: Icon(Icons.warning_amber_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'لديك ${stats['urgentRequests'] ?? 0} طلب عاجل يحتاج تدخل سريع الآن.',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildJobList({required bool active}) {
    return Column(
      children: List.generate(
        active ? 1 : 2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: (active ? AppTheme.primaryColor : AppTheme.accentColor)
                  .withOpacity(0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.build_circle_rounded,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب سباكة - الرحاب',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('شقة 102 • قريب من موقعك',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
