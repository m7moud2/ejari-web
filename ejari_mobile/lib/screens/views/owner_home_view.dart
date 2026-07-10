import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../manage_properties_screen.dart';
import '../owner_collection_screen.dart';
import '../my_contracts_screen.dart';
import '../maintenance_requests_screen.dart';
import '../wallet_screen.dart';
import '../notification_center_screen.dart';
import '../listing_plans_screen.dart';
import '../../widgets/owner_booking_requests_panel.dart';
import '../../services/subscription_service.dart';

class OwnerHomeView extends StatelessWidget {
  const OwnerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.ownerStats;

    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: () => context.read<HomeProvider>().loadHomeData('owner'),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildBrandedHeader(context, stats),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(stats),
                  const SizedBox(height: AppTheme.spaceLg),
                  const EjariSectionHeader(
                    title: 'إجراءات سريعة',
                    subtitle: 'إدارة العقارات والتحصيل والمتابعة',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              0,
              AppTheme.spaceMd,
              AppTheme.spaceXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats['banner'] != null) ...[
                  _buildBanner(stats),
                  const SizedBox(height: AppTheme.spaceLg),
                ],
                const EjariSectionHeader(
                  title: 'الحجوزات الجديدة',
                  subtitle: 'طلبات تحتاج مراجعة أو استكمال',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const OwnerBookingRequestsPanel(),
                const SizedBox(height: AppTheme.spaceLg),
                const EjariSectionHeader(
                  title: 'أداء العقارات',
                  subtitle: 'أفضل الوحدات ومشاهداتها',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                _buildPerformanceCard(stats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandedHeader(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spaceMd,
        AppTheme.screenPadding,
        56,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0A2E26),
            Color(0xFF0F3A30),
            Color(0xFF1B594B),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_work_rounded,
                        color: AppTheme.accentColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'لوحة المالك',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(),
                  ),
                ),
                icon: const Icon(Icons.notifications_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text(
            'مرحباً بك أيها المالك',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stats['verificationStatus'] ?? 'قيد المراجعة',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Wrap(
            spacing: AppTheme.spaceXs,
            runSpacing: AppTheme.spaceXs,
            children: [
              _heroMetric('عقارات', '${stats['propertiesCount'] ?? 0}'),
              _heroMetric('حجوزات جديدة', '${stats['pendingBookings'] ?? 0}'),
              _heroMetric('الباقة', stats['subscriptionPlan']?.toString() ?? 'مجاني'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> stats) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'ملخص الأداء',
            subtitle: 'أرقامك الأساسية في لمحة واحدة',
          ),
          const SizedBox(height: AppTheme.spaceMd),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spaceXs,
              crossAxisSpacing: AppTheme.spaceXs,
              mainAxisExtent: 96,
            ),
            children: [
              EjariStatTile(
                icon: Icons.verified,
                label: 'معتمد',
                value: '${stats['approvedProperties'] ?? 0}',
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.hourglass_bottom,
                label: 'تحت المراجعة',
                value: '${stats['pendingProperties'] ?? 0}',
                accentColor: AppTheme.borderColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'متاح للسحب',
                value: '${stats['availableToWithdraw'] ?? 0} ج.م',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.warning_amber_rounded,
                label: 'متأخرات',
                value: '${stats['lateInstallments'] ?? 0}',
                accentColor: AppTheme.errorColor,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(Map<String, dynamic> stats) {
    return EjariSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      radius: AppTheme.cardRadiusLg,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              stats['banner'] ??
                  'وثّق حسابك أو ارفع إعلانًا مميزًا لتصل لعملاء أكثر.',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        'الباقات',
        Icons.workspace_premium,
        const ListingPlansScreen(),
      ),
      (
        'إضافة عقار',
        Icons.add_home_work,
        const ManagePropertiesScreen(),
      ),
      (
        'تحصيل الإيجارات',
        Icons.receipt_long,
        const OwnerCollectionScreen(),
      ),
      (
        'المحفظة',
        Icons.account_balance_wallet,
        const WalletScreen(),
      ),
      (
        'العقود',
        Icons.description_outlined,
        const MyContractsScreen(),
      ),
      (
        'متابعة الصيانة',
        Icons.build_circle,
        const MaintenanceRequestsScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spaceXs,
        mainAxisSpacing: AppTheme.spaceXs,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => action.$3),
            ),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius - 4),
            child: Ink(
              decoration: AppTheme.surfaceCardDecoration(
                radius: AppTheme.cardRadius - 4,
                elevated: false,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceSm,
                vertical: AppTheme.spaceXs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.$2,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spaceXs),
                  Expanded(
                    child: Text(
                      action.$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniList() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
          child: EjariSurfaceCard(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            elevated: false,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.home_work_rounded,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('طلب حجز جديد',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('المستأجر يطلب استكمال الخطوة التالية.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> stats) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats['topProperty'] ?? 'أفضل عقار هذا الأسبوع',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'العقار الأكثر مشاهدة: ${stats['topPropertyViews'] ?? 0} مشاهدة',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
