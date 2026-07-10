import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../my_contracts_screen.dart';
import '../my_bookings_screen.dart';
import '../tenant_installments_screen.dart';
import '../search_results_screen.dart';
import '../payment_screen.dart';
import '../notifications_screen.dart';
import '../my_service_requests_screen.dart';
import '../property_details_screen.dart';
import '../corporate_command_center_screen.dart';
import '../request_verification_screen.dart';
import '../../models/accommodation_type.dart';
import '../../widgets/trust_score_badge.dart';

class TenantHomeView extends StatelessWidget {
  const TenantHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.tenantStats;
    final recommended = List<Map<String, dynamic>>.from(
      stats['recommendedProperties'] ?? const [],
    );
    final featured = List<Map<String, dynamic>>.from(
      stats['featuredProperties'] ?? const [],
    );

    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: () => context.read<HomeProvider>().loadHomeData('tenant'),
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
                  _buildSearchCard(context),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildAccommodationFilters(context),
                  const SizedBox(height: AppTheme.spaceMd),
                  if (stats['contextualAction'] != null) ...[
                    _buildContextualAction(context, stats),
                    const SizedBox(height: AppTheme.spaceMd),
                  ],
                  _buildOverviewSection(context, stats),
                  const SizedBox(height: AppTheme.spaceLg),
                  const EjariSectionHeader(
                    title: 'إجراءات سريعة',
                    subtitle: 'الوصول المباشر لأهم مهام الإيجار',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildQuickActions(context, stats),
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
                if (stats['activeBooking'] == true ||
                    (stats['nextInstallmentDays'] ?? 99) <= 7) ...[
                  const EjariSectionHeader(
                    title: 'تنبيهاتك',
                    subtitle: 'متابعة الالتزامات القادمة',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildBookingAlert(context, stats),
                  const SizedBox(height: AppTheme.spaceLg),
                ],
                EjariSectionHeader(
                  title: 'عقارات مقترحة لك',
                  subtitle: 'مختارة حسب تفضيلاتك وموقعك',
                  actionLabel: 'عرض الكل',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(query: ''),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                _buildPropertyStrip(context, recommended, showBadge: true),
                const SizedBox(height: AppTheme.spaceLg),
                EjariSectionHeader(
                  title: 'العقارات المميزة',
                  subtitle: 'وحدات مختارة بعناية من فريق إيجاري',
                  actionLabel: 'استكشف',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SearchResultsScreen(query: 'مميز'),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                _buildPropertyStrip(context, featured, showBadge: false),
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
                    Icon(Icons.verified_rounded,
                        color: AppTheme.accentColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'إيجاري',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
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
              if (stats['activeBooking'] == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'حجز نشط',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text(
            'مرحباً ${stats['userName'] ?? 'بك'} 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
            stats['verificationStatus'] ?? 'ابحث عن وحدتك القادمة بثقة',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      color: AppTheme.surfaceColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchResultsScreen(query: ''),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: AppTheme.surfaceCardDecoration(elevated: true),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.12),
                      AppTheme.accentColor.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const Expanded(
                child: Text(
                  'ابحث عن شقة، فيلا، مكتب...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'بحث',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccommodationFilters(BuildContext context) {
    final filters = [
      (null, 'الكل'),
      (AccommodationType.fullUnit.value, AccommodationType.fullUnit.filterLabel),
      (AccommodationType.sharedRoom.value, AccommodationType.sharedRoom.filterLabel),
      (AccommodationType.bed.value, AccommodationType.bed.filterLabel),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ActionChip(
              label: Text(f.$2),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsScreen(
                    query: '',
                    filters: f.$1 != null
                        ? {'accommodationType': f.$1}
                        : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, Map<String, dynamic> stats) {
    final nextDays = stats['nextInstallmentDays'] ?? 0;
    final nextAmount = stats['nextInstallmentAmount'] ?? 0;
    final contracts = stats['tenantBookingsCount'] ?? 0;
    final saved = stats['savedCount'] ?? 0;
    final isVerified = (stats['verificationStatus'] ?? '')
        .toString()
        .contains('موثق');

    final tiles = [
      (
        label: 'القسط القادم',
        value: nextAmount > 0 ? '$nextAmount ج.م' : 'لا يوجد',
        hint: nextDays > 0 ? 'بعد $nextDays يوم' : 'محدّث',
        icon: Icons.payments_rounded,
        color: AppTheme.accentColor,
      ),
      (
        label: 'العقود النشطة',
        value: '$contracts',
        hint: contracts > 0 ? 'قيد المتابعة' : 'ابدأ البحث',
        icon: Icons.description_outlined,
        color: AppTheme.primaryColor,
      ),
      (
        label: 'المحفوظات',
        value: '$saved',
        hint: isVerified ? 'حساب موثق' : 'أكمل التوثيق',
        icon: isVerified ? Icons.verified_rounded : Icons.bookmark_outline,
        color: const Color(0xFF1B594B),
      ),
    ];

    return Column(
      children: [
        if (stats['trustData'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
            child: TrustScoreCard(
              trustData: Map<String, dynamic>.from(stats['trustData'] as Map),
            ),
          ),
        EjariSurfaceCard(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          child: Row(
            children: tiles.map((tile) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tile.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(tile.icon, color: tile.color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tile.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tile.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        tile.hint,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: tile.color.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        EjariSurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: EjariListTile(
            icon: Icons.corporate_fare_rounded,
            title: 'مركز قيادة الشركات',
            subtitle: 'إدارة إسكان الموظفين عبر المحافظات',
            iconColor: AppTheme.accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CorporateCommandCenterScreen(),
              ),
            ),
            isLast: true,
          ),
        ),
      ],
    );
  }

  Widget _buildContextualAction(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final action =
        Map<String, dynamic>.from(stats['contextualAction'] as Map? ?? {});
    final icon = action['icon']?.toString() ?? 'info';
    final badge = action['badge'];

    IconData iconData;
    VoidCallback onTap;
    switch (icon) {
      case 'booking':
        iconData = Icons.event_available_rounded;
        onTap = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            );
        break;
      case 'kyc':
        iconData = Icons.verified_user_rounded;
        onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestVerificationScreen(),
              ),
            );
        break;
      default:
        iconData = Icons.touch_app_rounded;
        onTap = () {};
    }

    return Material(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['title']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      action['subtitle']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null && (badge as num) > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
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
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> stats) {
    final hasActiveBooking = stats['activeBooking'] == true;
    final quickActions = [
      if (hasActiveBooking)
        (
          title: 'تابع حجزك',
          subtitle: stats['bookingTitle']?.toString() ?? 'حجز نشط',
          icon: Icons.event_available_rounded,
          color: AppTheme.accentColor,
          onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              ),
        ),
      (
        title: 'ابحث',
        subtitle: 'وحدات جديدة',
        icon: Icons.search_rounded,
        color: const Color(0xFF0F3A30),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchResultsScreen(query: 'شقة'),
              ),
            ),
      ),
      (
        title: 'حجوزاتي',
        subtitle: 'متابعة الطلبات',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF1B594B),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
      ),
      (
        title: 'سدد',
        subtitle: 'القسط القادم',
        icon: Icons.payments_rounded,
        color: const Color(0xFFB58D3D),
        onTap: () => _openRentPayment(context, stats),
      ),
      (
        title: 'عقودي',
        subtitle: 'متابعة العقود',
        icon: Icons.description_outlined,
        color: const Color(0xFF2D6A5A),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyContractsScreen()),
            ),
      ),
      (
        title: 'صيانة',
        subtitle: 'طلب ومتابعة',
        icon: Icons.build_circle_outlined,
        color: const Color(0xFF3D5A80),
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyServiceRequestsScreen(),
              ),
            ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spaceSm,
          crossAxisSpacing: AppTheme.spaceSm,
          childAspectRatio: narrow ? 1.05 : 1.25,
          children: quickActions.map((action) {
            return Material(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                onTap: action.onTap,
                child: Container(
                  padding: EdgeInsets.all(narrow ? 10 : 12),
                  decoration: AppTheme.surfaceCardDecoration(
                    elevated: true,
                    radius: AppTheme.cardRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: narrow ? 34 : 40,
                        height: narrow ? 34 : 40,
                        decoration: BoxDecoration(
                          color: action.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon,
                            color: action.color, size: narrow ? 18 : 22),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: narrow ? 12 : 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            action.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: narrow ? 10 : 11,
                              color: AppTheme.textSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookingAlert(BuildContext context, Map<String, dynamic> stats) {
    final nextAmount = stats['nextInstallmentAmount'] ?? 0;
    final nextDays = stats['nextInstallmentDays'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.22),
            AppTheme.accentColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.payments_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أقرب قسط مستحق',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'متبقي $nextDays أيام • $nextAmount ج.م',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: AppTheme.ctaHeight - 10,
            child: ElevatedButton(
              onPressed: () => _openRentPayment(context, stats),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 3,
              ),
              child: const Text('ادفع'),
            ),
          ),
        ],
      ),
    );
  }

  void _openRentPayment(BuildContext context, Map<String, dynamic> stats) {
    final bookingId = stats['bookingId']?.toString() ?? '';
    final bookingTitle = stats['bookingTitle']?.toString() ?? 'حجز الإيجار';
    final monthlyRent = (stats['monthlyRent'] as num?)?.toDouble() ?? 0.0;
    final depositAmount =
        (stats['depositAmount'] as num?)?.toDouble() ?? monthlyRent * 0.1;
    final remainingAmount = (stats['remainingAmount'] as num?)?.toDouble() ??
        (monthlyRent - depositAmount);
    final bookingStatus = stats['bookingStatus']?.toString() ?? 'deposit_paid';
    final paymentStage =
        bookingStatus == 'deposit_paid' ? 'remaining' : 'deposit';

    if (bookingId.isEmpty || monthlyRent <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TenantInstallmentsScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: {
            'id': bookingId,
            'title': bookingTitle,
            'monthlyRent': monthlyRent,
            'price': monthlyRent,
            'status': bookingStatus,
            'ownerId': stats['ownerId']?.toString() ?? 'owner',
          },
          amount: paymentStage == 'remaining' ? remainingAmount : depositAmount,
          paymentStage: paymentStage,
          totalAmount: monthlyRent,
          depositAmount: depositAmount,
          remainingAmount: remainingAmount,
        ),
      ),
    );
  }

  Widget _buildPropertyStrip(
    BuildContext context,
    List<Map<String, dynamic>> items, {
    required bool showBadge,
  }) {
    return SizedBox(
      height: 252,
      child: items.isEmpty
          ? const EjariSurfaceCard(
              elevated: false,
              child: Center(
                child: Text(
                  'لا توجد بيانات حالياً',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
                  color: AppTheme.surfaceColor,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailsScreen(property: item),
                      ),
                    ),
                    child: Container(
                      width: 220,
                      decoration: AppTheme.surfaceCardDecoration(
                        radius: AppTheme.cardRadiusLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppTheme.cardRadiusLg),
                                ),
                                child: _propertyImage(
                                  item['image'] ?? 'assets/images/home1.jpg',
                                  height: 120,
                                ),
                              ),
                              if (showBadge && index == 0)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'مقترح',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item['location'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${item['price'] ?? ''} ج.م / شهر',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _propertyImage(String imagePath, {required double height}) {
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/home1.jpg',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      imagePath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/home1.jpg',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
