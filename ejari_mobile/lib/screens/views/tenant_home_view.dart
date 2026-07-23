import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/home/home_ui_kit.dart';
import '../my_contracts_screen.dart';
import '../my_bookings_screen.dart';
import '../booking_track_screen.dart';
import '../tenant_installments_screen.dart';
import '../search_results_screen.dart';
import '../payment_screen.dart';
import '../my_service_requests_screen.dart';
import '../property_details_screen.dart';
import '../request_verification_screen.dart';
import '../../models/accommodation_type.dart';
import '../../widgets/trust_score_badge.dart';
import '../../widgets/overdue_payment_banner.dart';
import '../demo_flow_guide_screen.dart';
import '../notification_center_screen.dart';
import '../rental_statement_screen.dart';
import '../favorites_screen.dart';
import '../my_viewings_screen.dart';
import '../advanced_filters_screen.dart';
import '../payment_reminders_screen.dart';
import '../../services/demo_flow_service.dart';
import '../../services/data_service.dart';
import '../../services/location_service.dart';

class TenantHomeView extends StatefulWidget {
  const TenantHomeView({super.key});

  @override
  State<TenantHomeView> createState() => _TenantHomeViewState();
}

class _TenantHomeViewState extends State<TenantHomeView> {
  bool _showDemoLink = false;
  int _unreadNotifications = 0;
  String _locationLabel = 'تحديد موقعك';
  bool _locationPromptChecked = false;

  @override
  void initState() {
    super.initState();
    _loadExtras();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLocation());
  }

  Future<void> _loadExtras() async {
    final dismissed = await DemoFlowService.isBannerDismissed();
    final complete = await DemoFlowService.isFlowComplete();
    final unread = await DataService.getUnreadNotificationCount();
    final loc = await LocationService.loadSaved();
    if (mounted) {
      setState(() {
        _showDemoLink = !dismissed && !complete;
        _unreadNotifications = unread;
        _locationLabel = loc.hasArea || loc.hasCoords ? loc.label : 'تحديد موقعك';
      });
    }
  }

  Future<void> _ensureLocation() async {
    if (_locationPromptChecked) return;
    _locationPromptChecked = true;
    final should = await LocationService.shouldPromptForLocation();
    if (!should || !mounted) {
      await _loadExtras();
      return;
    }
    final snap = await LocationService.showEnableLocationDialog(context);
    if (snap != null && mounted) {
      setState(() => _locationLabel = snap.label);
      await context.read<HomeProvider>().loadHomeData('tenant');
    } else {
      await _loadExtras();
    }
  }

  Future<void> _changeLocation() async {
    final snap = await LocationService.showManualPicker(context);
    if (snap != null && mounted) {
      setState(() => _locationLabel = snap.label);
      await context.read<HomeProvider>().loadHomeData('tenant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.tenantStats;
    final recommended = List<Map<String, dynamic>>.from(
      stats['recommendedProperties'] ?? const [],
    );
    final featured = List<Map<String, dynamic>>.from(
      stats['featuredProperties'] ?? const [],
    );
    final nearby = List<Map<String, dynamic>>.from(
      stats['nearbyProperties'] ?? const [],
    );
    final hotOffers = List<Map<String, dynamic>>.from(
      stats['hotOffers'] ?? const [],
    );
    final shortStays = List<Map<String, dynamic>>.from(
      stats['shortStayProperties'] ?? const [],
    );
    final locLabel =
        stats['userLocationLabel']?.toString() ?? _locationLabel;
    final pendingViewings = (stats['pendingViewings'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      color: AppTheme.accentColor,
      onRefresh: () async {
        await context.read<HomeProvider>().loadHomeData('tenant');
        await _loadExtras();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          HomeCompactHeader(
            greeting: 'مرحباً ${stats['userName'] ?? 'بك'} 👋',
            accountId: stats['accountId']?.toString(),
            subtitle: stats['verificationStatus']?.toString(),
            badgeLabel: 'إيجاري',
            notificationCount: _unreadNotifications,
            onNotificationTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
              _loadExtras();
            },
          ),
          const OverduePaymentBanner(),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationBar(locLabel),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildSearchCard(context),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildViewingCta(context, pendingViewings),
                  const SizedBox(height: AppTheme.spaceSm),
                  if (stats['contextualAction'] != null) ...[
                    _buildContextualAction(context, stats),
                    const SizedBox(height: AppTheme.spaceSm),
                  ],
                  HomeQuickLookRow(tiles: _quickLookTiles(context, stats)),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomePrimaryActionRow(actions: _primaryActions(context, stats)),
                  const SizedBox(height: AppTheme.spaceMd),
                  HomeExpandableSection(
                    title: 'قربك الآن',
                    subtitle: 'وحدات مرتّبة حسب موقعك',
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyStrip(
                          context,
                          nearby.isNotEmpty ? nearby : recommended,
                          showBadge: true,
                          showProximity: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeExpandableSection(
                    title: 'عروض ساخنة',
                    subtitle: 'باقات وأسعار خاصة لمدة محددة',
                    initiallyExpanded: true,
                    child: _buildPropertyStrip(
                      context,
                      hotOffers,
                      showBadge: false,
                      offerAccent: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeExpandableSection(
                    title: 'إقامات قصيرة',
                    subtitle: 'يومي · أسبوعي · نصف أسبوع',
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccommodationFilters(context),
                        const SizedBox(height: AppTheme.spaceSm),
                        _buildPropertyStrip(context, shortStays, showBadge: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeExpandableSection(
                    title: 'استكشف',
                    subtitle: 'عقارات مميزة ومقترحة',
                    initiallyExpanded: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stats['activeBooking'] == true ||
                            (stats['nextInstallmentDays'] ?? 99) <= 7) ...[
                          _buildBookingAlert(context, stats),
                          const SizedBox(height: AppTheme.spaceSm),
                        ],
                        EjariSectionHeader(
                          title: 'عقارات مقترحة',
                          subtitle: 'مختارة حسب موقعك وتفضيلاتك',
                          actionLabel: 'عرض الكل',
                          onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SearchResultsScreen(query: ''),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        _buildPropertyStrip(context, recommended, showBadge: true),
                        const SizedBox(height: AppTheme.spaceMd),
                        EjariSectionHeader(
                          title: 'العقارات المميزة',
                          subtitle: 'وحدات مختارة بعناية',
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
                  const SizedBox(height: AppTheme.spaceSm),
                  HomeExpandableSection(
                    title: 'حسابك',
                    subtitle: 'درجة الثقة وخدماتك كمستأجر',
                    child: _buildAccountSection(context, stats),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.homeBottomClearance),
        ],
      ),
    );
  }

  Widget _buildLocationBar(String label) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _changeLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'موقعك للبحث',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _changeLocation,
                child: const Text(
                  'تغيير',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
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

  Widget _buildViewingCta(BuildContext context, int count) {
    final urgent = count > 0;
    return Material(
      color: urgent
          ? AppTheme.accentColor.withOpacity(0.12)
          : AppTheme.primaryColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyViewingsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                color: urgent ? AppTheme.accentColor : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      urgent
                          ? (count == 1
                              ? 'موعد معاينة بانتظار المتابعة'
                              : '$count مواعيد معاينة')
                          : 'معاينة العقار',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      urgent
                          ? 'افتح المواعيد للتأكيد أو الإلغاء'
                          : 'اطلب موعداً من صفحة العقار أو تابع مواعيدك هنا',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }

  List<HomeQuickLookTile> _quickLookTiles(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final hasBooking = stats['activeBooking'] == true;
    final trust = (stats['trustScore'] as num?)?.toInt() ?? 0;
    final nextAmount = (stats['nextInstallmentAmount'] as num?)?.toInt() ?? 0;
    final bookingId = stats['bookingId']?.toString() ?? '';

    return [
      HomeQuickLookTile(
        label: 'الحجز',
        value: hasBooking ? 'نشط' : 'لا يوجد',
        hint: hasBooking
            ? (stats['nextActionLabel']?.toString() ?? 'قيد المتابعة')
            : 'افتح حجوزاتي',
        icon: Icons.event_available_rounded,
        color: AppTheme.accentColor,
        onTap: () {
          if (hasBooking && bookingId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingTrackScreen(bookingId: bookingId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            );
          }
        },
      ),
      HomeQuickLookTile(
        label: 'الدفع',
        value: nextAmount > 0 ? '$nextAmount ج.م' : 'محدّث',
        hint: nextAmount > 0 ? 'قسط قادم — تذكيرات' : 'تذكيرات الدفع',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFFB58D3D),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentRemindersScreen()),
        ),
      ),
      HomeQuickLookTile(
        label: 'الثقة',
        value: trust > 0 ? '$trust' : '—',
        hint: stats['trustLevel']?.toString() ?? 'درجتك',
        icon: Icons.verified_rounded,
        color: AppTheme.primaryColor,
      ),
      HomeQuickLookTile(
        label: 'تنبيهات',
        value: '$_unreadNotifications',
        hint: _unreadNotifications > 0 ? 'جديد' : 'لا جديد',
        icon: Icons.notifications_rounded,
        color: const Color(0xFF2D6A5A),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationCenterScreen(),
            ),
          );
          _loadExtras();
        },
      ),
    ];
  }

  List<HomePrimaryAction> _primaryActions(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    // Avoid duplicating bottom-nav primaries (استكشف / حجوزاتي / المحفظة).
    // معاينة is not in the tab bar — keep it on the home surface.
    return [
      HomePrimaryAction(
        label: 'معاينة',
        icon: Icons.visibility_rounded,
        color: const Color(0xFF0F3A30),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyViewingsScreen()),
        ),
      ),
      HomePrimaryAction(
        label: 'صيانة',
        icon: Icons.build_circle_outlined,
        color: const Color(0xFF1B594B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
        ),
      ),
      HomePrimaryAction(
        label: 'ادفع',
        icon: Icons.payments_rounded,
        color: const Color(0xFFB58D3D),
        onTap: () => _openRentPayment(context, stats),
      ),
      HomePrimaryAction(
        label: 'المزيد',
        icon: Icons.apps_rounded,
        color: AppTheme.primaryColor,
        onTap: () => _showMoreSheet(context, stats),
      ),
    ];
  }

  void _showMoreSheet(BuildContext context, Map<String, dynamic> stats) {
    // Tenant shortcuts only — no bottom-nav duplicates, no owner tools.
    showHomeMoreSheet(
      context,
      title: 'اختصارات المستأجر',
      items: [
        (
          label: 'عقودي',
          icon: Icons.description_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyContractsScreen()),
          ),
        ),
        (
          label: 'المفضلة',
          icon: Icons.favorite_border_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        (
          label: 'تذكيرات الدفع',
          icon: Icons.notifications_active_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentRemindersScreen()),
          ),
        ),
        (
          label: 'أقساطي',
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TenantInstallmentsScreen(),
            ),
          ),
        ),
        (
          label: 'إيصالاتي',
          icon: Icons.receipt_long_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RentalStatementScreen(),
            ),
          ),
        ),
        (
          label: 'توثيق الهوية',
          icon: Icons.verified_user_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RequestVerificationScreen(),
            ),
          ),
        ),
        if (_showDemoLink)
          (
            label: 'جرب التدفق الكامل',
            icon: Icons.play_circle_outline_rounded,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DemoFlowGuideScreen(),
                ),
              );
              _loadExtras();
            },
          ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats['trustData'] != null)
          TrustScoreCard(
            trustData: Map<String, dynamic>.from(stats['trustData'] as Map),
          ),
        if (stats['trustData'] != null) const SizedBox(height: AppTheme.spaceSm),
        if (_showDemoLink)
          HomeSecondaryLink(
            icon: Icons.play_circle_outline_rounded,
            title: 'جرب التدفق الكامل',
            subtitle: 'حجز → دفع → QR → تقييم',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DemoFlowGuideScreen(),
                ),
              );
              _loadExtras();
            },
            trailing: IconButton(
              tooltip: 'إخفاء',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await DemoFlowService.dismissBanner();
                setState(() => _showDemoLink = false);
              },
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          )
        else if (stats['trustData'] == null)
          const Text(
            'درجة الثقة تظهر بعد نشاط الحجوزات والدفع.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
      ],
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
            builder: (_) => const AdvancedFiltersScreen(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: AppTheme.surfaceCardDecoration(elevated: true),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.12),
                      AppTheme.accentColor.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const Expanded(
                child: Text(
                  'فلاتر احترافية · محافظة · سعر · مدة',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'فلتر',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

  Widget _buildAccommodationFilters(BuildContext context) {
    final filters = [
      (null as String?, 'الكل', null as Map<String, dynamic>?),
      (
        AccommodationType.fullUnit.value,
        AccommodationType.fullUnit.filterLabel,
        null,
      ),
      (
        AccommodationType.sharedRoom.value,
        AccommodationType.sharedRoom.filterLabel,
        null,
      ),
      (
        AccommodationType.bed.value,
        AccommodationType.bed.filterLabel,
        null,
      ),
      (
        'short_stay',
        'إقامة قصيرة',
        {'shortStayOnly': true},
      ),
      (
        'coastal',
        'ساحل / مطروح',
        {'coastalOnly': true, 'shortStayOnly': true},
      ),
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
                fontSize: 11,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                final Map<String, dynamic>? filtersMap;
                if (f.$3 != null) {
                  filtersMap = Map<String, dynamic>.from(f.$3!);
                } else if (f.$1 != null && f.$1 != 'short_stay' && f.$1 != 'coastal') {
                  filtersMap = {'accommodationType': f.$1};
                } else {
                  filtersMap = null;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchResultsScreen(
                      query: '',
                      filters: filtersMap,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
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
    final actionKey = action['actionKey']?.toString() ??
        stats['nextActionKey']?.toString() ??
        '';

    IconData iconData;
    VoidCallback onTap;
    switch (icon) {
      case 'booking':
        iconData = Icons.event_available_rounded;
        onTap = () => _openNextBookingAction(context, stats, actionKey);
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Icon(iconData, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['title']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      action['subtitle']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null && (badge as num) > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
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
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'افتح',
                  style: TextStyle(
                    color: Colors.white,
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

  void _openNextBookingAction(
    BuildContext context,
    Map<String, dynamic> stats,
    String actionKey,
  ) {
    final bookingId = stats['bookingId']?.toString() ?? '';
    if (actionKey == 'pay') {
      _openRentPayment(context, stats);
      return;
    }
    if (actionKey == 'viewing') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyViewingsScreen()),
      );
      return;
    }
    if (bookingId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingTrackScreen(bookingId: bookingId),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  Widget _buildBookingAlert(BuildContext context, Map<String, dynamic> stats) {
    final nextAmount = stats['nextInstallmentAmount'] ?? 0;
    final nextDays = stats['nextInstallmentDays'] ?? 0;
    final nextLabel = stats['nextActionLabel']?.toString();
    final bookingId = stats['bookingId']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nextLabel != null && nextLabel.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.flag_rounded,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'التالي: $nextLabel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (bookingId.isEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingTrackScreen(bookingId: bookingId),
                      ),
                    );
                  },
                  child: const Text('تابع', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              const Icon(Icons.payments_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'قسط مستحق خلال $nextDays يوم • $nextAmount ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openRentPayment(context, stats),
                child: const Text('ادفع', style: TextStyle(fontSize: 11)),
              ),
            ],
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
    bool showProximity = false,
    bool offerAccent = false,
  }) {
    return SizedBox(
      height: 240,
      child: items.isEmpty
          ? EmptyStateView(
              compact: true,
              icon: Icons.home_work_outlined,
              title: 'لا عقارات هنا حالياً',
              subtitle: 'افتح الاستكشاف وابحث بالمنطقة أو نوع الوحدة.',
              actionLabel: 'استكشف العقارات',
              actionIcon: Icons.search_rounded,
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: ''),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSale = item['listingMode'] == 'for_sale';
                final proximity = item['proximityLabel']?.toString();
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
                      width: 200,
                      clipBehavior: Clip.antiAlias,
                      decoration: AppTheme.surfaceCardDecoration(
                        radius: AppTheme.cardRadiusLg,
                      ).copyWith(
                        border: offerAccent
                            ? Border.all(
                                color: AppTheme.accentColor.withOpacity(0.4))
                            : null,
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
                                  height: 110,
                                ),
                              ),
                              if ((showBadge && index == 0) ||
                                  (showProximity &&
                                      proximity != null &&
                                      proximity.isNotEmpty))
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  right: 8,
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: [
                                      if (showProximity &&
                                          proximity != null &&
                                          proximity.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            proximity,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      if (showBadge && index == 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'مقترح',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['location'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isSale
                                        ? '${item['price'] ?? ''} ج.م'
                                        : (item['dailyPrice'] != null
                                            ? '${item['dailyPrice']} ج.م / يوم'
                                            : '${item['price'] ?? ''} ج.م / شهر'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
