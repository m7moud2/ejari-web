import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../financial_ledger_screen.dart';
import '../admin_users_screen.dart';
import '../admin_properties_screen.dart';
import '../admin_reports_screen.dart';
import '../admin_financials_screen.dart';
import '../chat_list_screen.dart';
import '../admin_service_requests_screen.dart';
import '../rewards_screen.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.adminStats;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => context.read<HomeProvider>().loadHomeData('admin'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHero(stats),
          const SizedBox(height: 14),
          _buildMetrics(stats),
          const SizedBox(height: 14),
          _buildAlerts(stats),
          const SizedBox(height: 14),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHero(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة تحكم الإدارة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ملخص سريع لكل شيء داخل النظام بشكل واضح ومباشر.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroMetric('المستخدمين', '${stats['totalUsers'] ?? 0}'),
              _heroMetric('الأرباح', '${stats['platformRevenue'] ?? 0} ج.م'),
              _heroMetric('نزاعات', '${stats['openDisputes'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 90, maxWidth: 135),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(Map<String, dynamic> stats) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 90,
      ),
      children: [
        _metric('مستخدمين', '${stats['totalUsers'] ?? 0}',
            Icons.people_alt_rounded, AppTheme.primaryColor),
        _metric('مستأجرين', '${stats['tenantsCount'] ?? 0}',
            Icons.person_search_rounded, AppTheme.accentColor),
        _metric('ملاك', '${stats['ownersCount'] ?? 0}', Icons.home_work_rounded,
            Colors.teal),
        _metric('فنيين', '${stats['techniciansCount'] ?? 0}',
            Icons.handyman_rounded, Colors.orange),
        _metric('توثيقات', '${stats['pendingVerifications'] ?? 0}',
            Icons.verified_user_rounded, AppTheme.borderColor),
        _metric('مدفوعات معلقة', '${stats['pendingPayments'] ?? 0}',
            Icons.payments_rounded, AppTheme.errorColor),
        _metric('Escrow', '${stats['escrowBalance'] ?? 0} ج.م',
            Icons.lock_rounded, AppTheme.primaryColor),
        _metric('صيانة جارية', '${stats['activeMaintenance'] ?? 0}',
            Icons.build_circle_rounded, Colors.blue),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(Map<String, dynamic> stats) {
    return Column(
      children: [
        _alert('تنبيه أمني: ${stats['systemAlerts'] ?? 0} أحداث تحتاج مراجعة',
            AppTheme.errorColor),
        const SizedBox(height: 10),
        _alert(
            'يوجد ${stats['pendingVerifications'] ?? 0} حسابات في انتظار التوثيق',
            AppTheme.borderColor),
      ],
    );
  }

  Widget _alert(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.notification_important_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجراءات سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _action(context, 'مراجعة المستخدمين', Icons.people,
                  const AdminUsersScreen()),
              _action(context, 'إدارة العقارات', Icons.home_work_rounded,
                  const AdminPropertiesScreen()),
              _action(
                  context,
                  'إدارة المدفوعات',
                  Icons.account_balance_wallet_rounded,
                  const FinancialLedgerScreen(role: 'admin')),
              _action(context, 'إدارة النزاعات', Icons.gavel_rounded,
                  const AdminReportsScreen()),
              _action(context, 'المكافآت والعروض', Icons.local_offer_rounded,
                  const RewardsScreen()),
              _action(context, 'طلبات الخدمة', Icons.handyman_rounded,
                  const AdminServiceRequestsScreen()),
              _action(context, 'شات الدعم', Icons.chat_bubble_rounded,
                  const ChatListScreen()),
              _action(context, 'تقارير سريعة', Icons.analytics_rounded,
                  const AdminFinancialsScreen()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
      BuildContext context, String title, IconData icon, Widget page) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
