import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../add_property_screen.dart';
import '../owner_collection_screen.dart';
import '../owner_bulk_pricing_screen.dart';
import '../owner_discount_scheduler_screen.dart';
import '../owner_tenant_lists_screen.dart';
import '../owner_occupancy_screen.dart';
import '../my_contracts_screen.dart';
import '../maintenance_requests_screen.dart';
import '../wallet_screen.dart';
import '../notifications_screen.dart';
import '../owner_property_performance_screen.dart';
import '../listing_plans_screen.dart';
import '../../widgets/owner_booking_requests_panel.dart';
import '../owner_booking_requests_screen.dart';
import '../owner_qr_verify_screen.dart';
import '../../widgets/bed_hierarchy_tree.dart';
import '../../widgets/smart_pricing_hint_widget.dart';
import '../../widgets/trust_score_badge.dart';

class OwnerHomeView extends StatelessWidget {
  const OwnerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.ownerStats;
    final smartHint = stats['smartPricingHint'] is Map
        ? Map<String, dynamic>.from(stats['smartPricingHint'] as Map)
        : null;
    final trustData = stats['trustData'] is Map
        ? Map<String, dynamic>.from(stats['trustData'] as Map)
        : null;

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
                  _buildOverviewSection(stats, trustData),
                  if (stats['contextualAction'] != null) ...[
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildContextualBanner(context, stats),
                  ],
                  const SizedBox(height: AppTheme.spaceLg),
                  _buildRevenueIntelligence(stats),
                  if (smartHint != null) ...[
                    const SizedBox(height: AppTheme.spaceMd),
                    SmartPricingHintWidget(
                      propertyId:
                          smartHint['propertyId']?.toString() ?? 'shared_egy1',
                      listedPrice:
                          (smartHint['price'] as num?)?.toDouble() ?? 2500,
                      location: smartHint['location']?.toString(),
                    ),
                  ],
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
                if ((stats['vacantBeds'] as List?)?.isNotEmpty == true) ...[
                  const EjariSectionHeader(
                    title: 'أماكن فاضية',
                    subtitle: 'أسرّة وغرف متاحة — اعرضها للمستأجرين',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildVacantBedsSection(context, stats),
                  const SizedBox(height: AppTheme.spaceLg),
                ],
                const EjariSectionHeader(
                  title: 'أداء العقارات',
                  subtitle: 'أفضل الوحدات ومشاهداتها',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                _buildPerformanceCard(context, stats),
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
                    builder: (_) => const NotificationsScreen(),
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
          if ((stats['accountId'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'رقم الحساب: ${stats['accountId']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
              if ((stats['pendingCollection'] ?? 0) > 0)
                _heroMetric('تحصيل معلّق', '${stats['pendingCollection']}'),
              _heroMetric('الباقة', _planBadgeLabel(stats)),
            ],
          ),
        ],
      ),
    );
  }

  String _planBadgeLabel(Map<String, dynamic> stats) {
    final name = stats['subscriptionPlan']?.toString() ?? 'مجاني';
    final id = stats['subscriptionPlanId']?.toString() ?? 'free';
    return id == 'gold' ? '$name ⭐' : name;
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

  Widget _buildOverviewSection(
    Map<String, dynamic> stats,
    Map<String, dynamic>? trustData,
  ) {
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
              mainAxisExtent: 100,
            ),
            children: [
              EjariStatTile(
                icon: Icons.verified,
                label: 'معتمد',
                value: '${stats['approvedProperties'] ?? 0}',
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.pie_chart_rounded,
                label: 'نسبة الإشغال',
                value: '${stats['occupancyRate'] ?? 0}%',
                accentColor: AppTheme.primaryColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.event_available_rounded,
                label: 'حجوزات الشهر',
                value: '${stats['bookingsThisMonth'] ?? 0}',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.nights_stay_rounded,
                label: 'متوسط الإقامة',
                value: '${stats['avgStayDuration'] ?? 0} يوم',
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'إيراد الشهر',
                value: '${stats['monthlyRevenue'] ?? 0} ج.م',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.star_rounded,
                label: 'أفضل عقار',
                value: (stats['topProperty'] ?? '—').toString().length > 14
                    ? '${(stats['topProperty'] ?? '—').toString().substring(0, 14)}…'
                    : '${stats['topProperty'] ?? '—'}',
                accentColor: const Color(0xFF2D6A5A),
                compact: true,
              ),
            ],
          ),
          if (trustData != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            TrustScoreCard(trustData: trustData),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueIntelligence(Map<String, dynamic> stats) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'ذكاء الإيرادات',
            subtitle: 'إشغال، مدفوعات معلقة، واستلام قادم',
          ),
          const SizedBox(height: AppTheme.spaceMd),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spaceXs,
              crossAxisSpacing: AppTheme.spaceXs,
              mainAxisExtent: 92,
            ),
            children: [
              EjariStatTile(
                icon: Icons.today_rounded,
                label: 'إيراد اليوم',
                value: '${stats['todayIncome'] ?? 0} ج.م',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.calendar_month_rounded,
                label: 'إيراد الشهر',
                value: '${stats['monthlyRevenue'] ?? 0} ج.م',
                accentColor: AppTheme.primaryColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.pie_chart_rounded,
                label: 'نسبة الإشغال',
                value: '${stats['occupancyRate'] ?? 0}%',
                accentColor: AppTheme.primaryColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.schedule_rounded,
                label: 'استلام قادم (٧ أيام)',
                value: '${stats['upcomingCheckIns'] ?? 0}',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.pending_actions_rounded,
                label: 'مدفوعات معلقة',
                value: '${stats['pendingPayouts'] ?? 0} ج.م',
                compact: true,
              ),
              EjariStatTile(
                icon: Icons.lock_rounded,
                label: 'في الضمان',
                value: '${stats['escrowBalance'] ?? 0} ج.م',
                accentColor: const Color(0xFF2D6A5A),
                compact: true,
              ),
            ],
          ),
          if (stats['revenueForecast'] != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    stats['revenueTrend'] == 'up'
                        ? Icons.trending_up_rounded
                        : Icons.trending_flat_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'توقع إيراد الشهر القادم: ${stats['revenueForecast']} ج.م',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (stats['nearSubscriptionLimit'] == true) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.errorColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تنبيه: اقتربت من حد باقة الإعلانات — رقِّ باقتك لإضافة عقارات جديدة.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextualBanner(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final action =
        Map<String, dynamic>.from(stats['contextualAction'] as Map? ?? {});
    final badge = action['badge'];
    final isRequests = action['icon'] == 'requests';

    return Material(
      color: AppTheme.accentColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: () {
          if (isRequests) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OwnerBookingRequestsScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListingPlansScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Icon(
                isRequests
                    ? Icons.inbox_rounded
                    : Icons.workspace_premium_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      action['subtitle']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(Map<String, dynamic> stats) {
    final features = List<String>.from(stats['subscriptionFeatures'] as List? ?? []);
    return EjariSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      radius: AppTheme.cardRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (features.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: features.take(3).map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    f,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        'تسعير جماعي',
        Icons.price_change_outlined,
        const OwnerBulkPricingScreen(),
      ),
      (
        'جدولة تخفيض',
        Icons.schedule_rounded,
        const OwnerDiscountSchedulerScreen(),
      ),
      (
        'قوائم المستأجرين',
        Icons.people_alt_outlined,
        const OwnerTenantListsScreen(),
      ),
      (
        'شجرة الأسرّة',
        Icons.account_tree_rounded,
        const BedHierarchyScreen(),
      ),
      (
        'تحقق QR',
        Icons.qr_code_scanner_rounded,
        const OwnerQrVerifyScreen(),
      ),
      (
        'الباقات',
        Icons.workspace_premium,
        const ListingPlansScreen(),
      ),
      (
        'إضافة عقار',
        Icons.add_home_work,
        const AddPropertyScreen(),
      ),
      (
        'إدارة الإشغال',
        Icons.bed_rounded,
        const OwnerOccupancyScreen(),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => action.$3),
              );
              if (context.mounted) {
                context.read<HomeProvider>().loadHomeData('owner');
              }
            },
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

  Widget _buildVacantBedsSection(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final vacant =
        List<Map<String, dynamic>>.from(stats['vacantBeds'] as List? ?? []);
    return EjariSurfaceCard(
      child: Column(
        children: vacant.take(6).map((v) {
          final price = double.tryParse(
                v['price']?.toString().replaceAll(',', '') ?? '0',
              ) ??
              0;
          final suggested = (price * 0.9).round();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bed_outlined, color: AppTheme.primaryColor),
            ),
            title: Text(
              v['bedLabel'] ?? v['roomLabel'] ?? 'سرير',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            subtitle: Text(
              '${v['propertyTitle'] ?? ''} — اقتراح: $suggested ج.م',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListingPlansScreen(),
                    ),
                  ),
                  child: const Text('ترويج', style: TextStyle(fontSize: 10)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'اقتراح تخفيض 10% → $suggested ج.م/شهر',
                        ),
                      ),
                    );
                  },
                  child: const Text('تخفيض', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final perfList = List<Map<String, dynamic>>.from(
      stats['propertyPerformance'] as List? ?? [],
    );
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EjariSectionHeader(
            title: stats['topProperty'] ?? 'أفضل عقار',
            subtitle:
                'العقار الأكثر مشاهدة: ${stats['topPropertyViews'] ?? 0} مشاهدة',
            actionLabel: 'عرض الكل',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OwnerPropertyPerformanceScreen(),
              ),
            ),
          ),
          if (perfList.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...perfList.take(3).map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['title']?.toString() ?? 'عقار',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${p['views'] ?? 0} 👁',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p['revenue'] ?? 0} ج.م',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

