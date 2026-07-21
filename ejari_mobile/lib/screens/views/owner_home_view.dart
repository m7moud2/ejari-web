import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../../widgets/home/home_ui_kit.dart';
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
import '../owner_viewings_screen.dart';
import '../owner_qr_verify_screen.dart';
import '../../widgets/bed_hierarchy_tree.dart';
import '../../widgets/smart_pricing_hint_widget.dart';
import '../../widgets/trust_score_badge.dart';
import '../subscriptions_screen.dart';
import '../manage_properties_screen.dart';
import '../sales_properties_screen.dart';
import '../changelog_screen.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/pdf_export_service.dart';

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
          HomeCompactHeader(
            greeting: 'مرحباً ${stats['userName'] ?? 'بك'}',
            accountId: stats['accountId']?.toString(),
            subtitle: stats['verificationStatus']?.toString(),
            badgeLabel: _planBadgeLabel(stats),
            onNotificationTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeQuickLookRow(tiles: [
                    HomeQuickLookTile(
                      label: 'إيراد اليوم',
                      value: '${stats['todayIncome'] ?? 0} ج.م',
                      icon: Icons.today_rounded,
                      color: AppTheme.accentColor,
                    ),
                    HomeQuickLookTile(
                      label: 'الإشغال',
                      value: '${stats['occupancyRate'] ?? 0}%',
                      icon: Icons.pie_chart_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    HomeQuickLookTile(
                      label: 'تحصيل معلّق',
                      value: '${stats['pendingCollection'] ?? 0}',
                      hint: (stats['lateInstallments'] as num?)?.toInt() != null &&
                              (stats['lateInstallments'] as num).toInt() > 0
                          ? '${stats['lateInstallments']} متأخر'
                          : 'افتح التحصيل',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFF2D6A5A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OwnerCollectionScreen(),
                        ),
                      ),
                    ),
                    HomeQuickLookTile(
                      label: 'معاينات',
                      value: '${stats['pendingViewings'] ?? 0}',
                      hint: ((stats['pendingViewings'] as num?)?.toInt() ?? 0) > 0
                          ? 'بانتظارك'
                          : 'لا جديد',
                      icon: Icons.visibility_rounded,
                      color: AppTheme.accentColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OwnerViewingsScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppTheme.spaceSm),
                  if (stats['contextualAction'] != null) ...[
                    _buildContextualBanner(context, stats),
                    const SizedBox(height: AppTheme.spaceSm),
                  ],
                  const EjariSectionHeader(
                    title: 'إجراءات اليوم',
                    subtitle: 'أهم مهام إدارة العقارات',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeActionGrid(
                    actions: _primaryActions(),
                    maxVisible: 6,
                    onMore: () => _showOwnerMoreSheet(context),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeExpandableSection(
                    title: 'ذكاء الأعمال',
                    subtitle: 'تسعير ذكي، ثقة، وتوقعات الإيراد',
                    child: _buildBusinessIntelligence(
                      context,
                      stats,
                      smartHint,
                      trustData,
                    ),
                  ),
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
                const EjariSectionHeader(
                  title: 'أداء العقارات',
                  subtitle: 'أفضل الوحدات ومشاهداتها',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                _buildPerformanceCard(context, stats),
                if ((stats['vacantBeds'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  const EjariSectionHeader(
                    title: 'أماكن فاضية',
                    subtitle: 'أسرّة وغرف متاحة للعرض',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildVacantBedsSection(context, stats),
                ],
                const SizedBox(height: AppTheme.spaceMd),
                const EjariSectionHeader(
                  title: 'الحجوزات الجديدة',
                  subtitle: 'طلبات تحتاج مراجعة',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const OwnerBookingRequestsPanel(),
                const SizedBox(height: AppTheme.spaceMd),
                const EjariSectionHeader(
                  title: 'طلبات المعاينة',
                  subtitle: 'موافقة / رفض / إعادة جدولة',
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const OwnerViewingsPanel(),
              ],
            ),
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

  List<({String label, IconData icon, Widget page})> _primaryActions() {
    return [
      (
        label: 'عقاراتي',
        icon: Icons.home_work_rounded,
        page: const ManagePropertiesScreen(),
      ),
      (
        label: 'حجوزات',
        icon: Icons.inbox_rounded,
        page: const OwnerBookingRequestsScreen(),
      ),
      (
        label: 'معاينة',
        icon: Icons.visibility_rounded,
        page: const OwnerViewingsScreen(),
      ),
      (
        label: 'تحقق QR',
        icon: Icons.qr_code_scanner_rounded,
        page: const OwnerQrVerifyScreen(),
      ),
      (
        label: 'تحصيل',
        icon: Icons.receipt_long_rounded,
        page: const OwnerCollectionScreen(),
      ),
      (
        label: 'شجرة الأسرّة',
        icon: Icons.account_tree_rounded,
        page: const BedHierarchyScreen(),
      ),
    ];
  }

  void _showOwnerMoreSheet(BuildContext context) {
    showHomeMoreSheet(
      context,
      title: 'المزيد من الأدوات',
      items: [
        (
          label: 'تحقق QR للاستلام',
          icon: Icons.qr_code_scanner_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OwnerQrVerifyScreen()),
          ),
        ),
        (
          label: 'إضافة عقار',
          icon: Icons.add_home_work_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          ),
        ),
        (
          label: 'تسعير جماعي',
          icon: Icons.price_change_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerBulkPricingScreen(),
            ),
          ),
        ),
        (
          label: 'جدولة تخفيض',
          icon: Icons.schedule_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerDiscountSchedulerScreen(),
            ),
          ),
        ),
        (
          label: 'قوائم المستأجرين',
          icon: Icons.people_alt_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerTenantListsScreen(),
            ),
          ),
        ),
        (
          label: 'إدارة الإشغال',
          icon: Icons.bed_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerOccupancyScreen(),
            ),
          ),
        ),
        (
          label: 'المحفظة',
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletScreen()),
          ),
        ),
        (
          label: 'العقود',
          icon: Icons.description_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyContractsScreen()),
          ),
        ),
        (
          label: 'متابعة الصيانة',
          icon: Icons.build_circle_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MaintenanceRequestsScreen(),
            ),
          ),
        ),
        (
          label: 'الباقات',
          icon: Icons.workspace_premium_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListingPlansScreen()),
          ),
        ),
        (
          label: 'اشتراكي',
          icon: Icons.card_membership_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
          ),
        ),
        (
          label: 'تقرير شهري PDF',
          icon: Icons.picture_as_pdf_rounded,
          onTap: () => _exportOwnerMonthlyReport(context),
        ),
        (
          label: 'ما الجديد',
          icon: Icons.new_releases_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangelogScreen()),
          ),
        ),
        (
          label: 'إعلانات البيع',
          icon: Icons.sell_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SalesPropertiesScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessIntelligence(
    BuildContext context,
    Map<String, dynamic> stats,
    Map<String, dynamic>? smartHint,
    Map<String, dynamic>? trustData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (smartHint != null)
          SmartPricingHintWidget(
            propertyId: smartHint['propertyId']?.toString() ?? 'shared_egy1',
            listedPrice:
                (smartHint['price'] as num?)?.toDouble() ?? 2500,
            location: smartHint['location']?.toString(),
          ),
        if (smartHint != null) const SizedBox(height: AppTheme.spaceSm),
        if (trustData != null) TrustScoreCard(trustData: trustData),
        if (trustData != null) const SizedBox(height: AppTheme.spaceSm),
        Row(
          children: [
            Expanded(
              child: EjariStatTile(
                icon: Icons.calendar_month_rounded,
                label: 'إيراد الشهر',
                value: '${stats['monthlyRevenue'] ?? 0} ج.م',
                accentColor: AppTheme.primaryColor,
                compact: true,
              ),
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Expanded(
              child: EjariStatTile(
                icon: Icons.schedule_rounded,
                label: 'استلام قادم',
                value: '${stats['upcomingCheckIns'] ?? 0}',
                accentColor: AppTheme.accentColor,
                compact: true,
              ),
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
        if (stats['subscriptionExpiringSoon'] == true) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه: باقتك تنتهي خلال ${stats['daysUntilSubscriptionExpiry'] ?? 7} أيام — جدّد الآن.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
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
                    'تنبيه: اقتربت من حد باقة الإعلانات.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (stats['banner'] != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            stats['banner']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spaceSm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _exportOwnerMonthlyReport(context),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('تصدير التقرير الشهري PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.35)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportOwnerMonthlyReport(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء التقرير الشهري...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final user = await AuthService.getCurrentUser();
      final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
      final report = await DataService.exportOwnerMonthlyReport(ownerId);
      await PdfExportService.shareOwnerMonthlyReportPdf(report);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تصدير التقرير الشهري كـ PDF'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تصدير التقرير: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildContextualBanner(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final action =
        Map<String, dynamic>.from(stats['contextualAction'] as Map? ?? {});
    final badge = action['badge'];
    final iconKey = action['icon']?.toString() ?? 'requests';

    IconData iconData;
    Widget page;
    switch (iconKey) {
      case 'viewings':
        iconData = Icons.visibility_rounded;
        page = const OwnerViewingsScreen();
      case 'collection':
        iconData = Icons.receipt_long_rounded;
        page = const OwnerCollectionScreen();
      case 'subscription':
        iconData = Icons.workspace_premium_rounded;
        page = const ListingPlansScreen();
      default:
        iconData = Icons.inbox_rounded;
        page = const OwnerBookingRequestsScreen();
    }

    return Material(
      color: AppTheme.accentColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Icon(iconData, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if ((action['subtitle']?.toString() ?? '').isNotEmpty)
                      Text(
                        action['subtitle'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'افتح',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bed_outlined,
                  color: AppTheme.primaryColor, size: 18),
            ),
            title: Text(
              v['bedLabel'] ?? v['roomLabel'] ?? 'سرير',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            subtitle: Text(
              '${v['propertyTitle'] ?? ''} — $suggested ج.م',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
            trailing: TextButton(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  stats['topProperty'] ?? 'أفضل عقار',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerPropertyPerformanceScreen(),
                  ),
                ),
                child: const Text('عرض الكل', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Text(
            '${stats['topPropertyViews'] ?? 0} مشاهدة',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          if (perfList.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...perfList.take(3).map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['title']?.toString() ?? 'عقار',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
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
