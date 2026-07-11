import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../../widgets/home/home_ui_kit.dart';
import '../admin_users_screen.dart';
import '../admin_properties_screen.dart';
import '../admin_reports_screen.dart';
import '../admin_financials_screen.dart';
import '../admin_service_requests_screen.dart';
import '../admin_support_screen.dart';
import '../admin_reviews_screen.dart';
import '../admin_search_screen.dart';
import '../admin_feedback_screen.dart';
import '../admin_audit_log_screen.dart';
import '../settings_screen.dart';
import '../verification_screen.dart';
import '../../widgets/admin_operations_feed.dart';

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
          _buildHero(),
          const SizedBox(height: 12),
          HomeQuickLookRow(tiles: [
            HomeQuickLookTile(
              label: 'المستخدمين',
              value: '${stats['totalUsers'] ?? 0}',
              icon: Icons.people_alt_rounded,
              color: AppTheme.primaryColor,
            ),
            HomeQuickLookTile(
              label: 'الأرباح',
              value: '${stats['platformRevenue'] ?? 0}',
              hint: 'ج.م',
              icon: Icons.payments_rounded,
              color: AppTheme.accentColor,
            ),
            HomeQuickLookTile(
              label: 'نزاعات',
              value: '${stats['openDisputes'] ?? 0}',
              icon: Icons.gavel_rounded,
              color: AppTheme.errorColor,
            ),
            HomeQuickLookTile(
              label: 'توثيقات',
              value: '${stats['pendingVerifications'] ?? 0}',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF2D6A5A),
            ),
          ]),
          const SizedBox(height: 12),
          HomeExpandableSection(
            title: 'تفاصيل النظام',
            subtitle: 'إحصائيات إضافية',
            child: _buildDetailMetrics(stats),
          ),
          const SizedBox(height: 12),
          HomeExpandableSection(
            title: 'تنبيهات',
            subtitle: 'أحداث تحتاج مراجعة',
            child: _buildAlerts(context, stats),
          ),
          const SizedBox(height: 12),
          const EjariSectionHeader(
            title: 'النشاط المباشر',
            subtitle: 'آخر العمليات في المنصة',
          ),
          const SizedBox(height: 8),
          const AdminOperationsFeed(),
          const SizedBox(height: 12),
          const EjariSectionHeader(
            title: 'إجراءات سريعة',
            subtitle: 'الوصول لأدوات الإدارة',
          ),
          const SizedBox(height: 8),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لوحة تحكم الإدارة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ملخص سريع لكل شيء داخل النظام.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetrics(Map<String, dynamic> stats) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 72,
      ),
      children: [
        EjariStatTile(
          icon: Icons.person_search_rounded,
          label: 'مستأجرين',
          value: '${stats['tenantsCount'] ?? 0}',
          accentColor: AppTheme.accentColor,
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.home_work_rounded,
          label: 'ملاك',
          value: '${stats['ownersCount'] ?? 0}',
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.handyman_rounded,
          label: 'فنيين',
          value: '${stats['techniciansCount'] ?? 0}',
          accentColor: Colors.orange,
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.payments_rounded,
          label: 'مدفوعات معلقة',
          value: '${stats['pendingPayments'] ?? 0}',
          accentColor: AppTheme.errorColor,
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.lock_rounded,
          label: 'Escrow',
          value: '${stats['escrowBalance'] ?? 0} ج.م',
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.build_circle_rounded,
          label: 'صيانة جارية',
          value: '${stats['activeMaintenance'] ?? 0}',
          accentColor: Colors.blue,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      children: [
        _alert(
          context,
          '${stats['systemAlerts'] ?? 0} أحداث أمنية',
          AppTheme.errorColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminServiceRequestsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _alert(
          context,
          '${stats['openDisputes'] ?? 0} نزاعات مفتوحة',
          AppTheme.errorColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminServiceRequestsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _alert(
          context,
          '${stats['pendingVerifications'] ?? 0} حسابات بانتظار التوثيق',
          AppTheme.borderColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _alert(
    BuildContext context,
    String message,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(Icons.notification_important_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.chevron_left, color: color.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return HomeActionGrid(
      actions: const [
        (
          label: 'سجل النشاط',
          icon: Icons.history_rounded,
          page: AdminAuditLogScreen(),
        ),
        (
          label: 'توثيق الهوية',
          icon: Icons.verified_user_rounded,
          page: VerificationScreen(),
        ),
        (
          label: 'بحث شامل',
          icon: Icons.manage_search_rounded,
          page: AdminSearchScreen(),
        ),
        (
          label: 'المستخدمين',
          icon: Icons.people,
          page: AdminUsersScreen(),
        ),
        (
          label: 'العقارات',
          icon: Icons.home_work_rounded,
          page: AdminPropertiesScreen(),
        ),
        (
          label: 'المالية',
          icon: Icons.account_balance_wallet_rounded,
          page: AdminFinancialsScreen(),
        ),
      ],
      maxVisible: 5,
      onMore: () => showHomeMoreSheet(
        context,
        title: 'المزيد من الأدوات',
        items: [
          (
            label: 'صندوق الدعم',
            icon: Icons.support_agent_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminSupportScreen(),
              ),
            ),
          ),
          (
            label: 'التقييمات',
            icon: Icons.star_rate_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminReviewsScreen(),
              ),
            ),
          ),
          (
            label: 'طلبات الخدمة',
            icon: Icons.handyman_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminServiceRequestsScreen(),
              ),
            ),
          ),
          (
            label: 'التقارير',
            icon: Icons.analytics_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminReportsScreen(),
              ),
            ),
          ),
          (
            label: 'تقييم التطبيق',
            icon: Icons.feedback_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminFeedbackScreen(),
              ),
            ),
          ),
          (
            label: 'الإعدادات',
            icon: Icons.settings_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
