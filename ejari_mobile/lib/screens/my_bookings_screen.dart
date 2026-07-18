import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/data_service.dart';
import 'contract_view_screen.dart';
import 'payment_screen.dart';
import 'chat_details_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../utils/rental_schedule_utils.dart';
import '../models/booking_status.dart';
import '../models/rental_duration_tier.dart';
import '../models/tenant_type.dart';
import '../widgets/booking_status_timeline.dart';
import '../widgets/rental_booking_widgets.dart';
import '../widgets/skeleton_list_loader.dart';
import '../widgets/refund_calculator_dialog.dart';
import 'refund_tracker_screen.dart';
import '../widgets/corporate_bookings_strip.dart';
import '../widgets/escrow_transparency_widget.dart';
import '../utils/safe_parse.dart';
import '../services/check_in_out_service.dart';
import '../services/live_sync_service.dart';
import 'booking_qr_screen.dart';
import 'booking_track_screen.dart';
import 'owner_rating_screen.dart';
import '../widgets/empty_state_view.dart';
import 'properties_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  bool _isSyncRefreshing = false;
  int _lastSyncGeneration = 0;
  LiveSyncService? _liveSync;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _liveSync = context.read<LiveSyncService>();
      _liveSync?.addListener(_onLiveSync);
    });
  }

  @override
  void dispose() {
    _liveSync?.removeListener(_onLiveSync);
    super.dispose();
  }

  void _onLiveSync() {
    final sync = _liveSync;
    if (sync == null || !mounted) return;
    final gen = sync.syncGeneration;
    if (gen == _lastSyncGeneration) return;
    final showSnack = _lastSyncGeneration > 0 && !_isLoading;
    _lastSyncGeneration = gen;
    _loadBookings(showUpdatedSnack: showSnack);
  }

  Future<void> _loadBookings({bool showUpdatedSnack = false}) async {
    if (_isSyncRefreshing) return;
    if (showUpdatedSnack) {
      setState(() => _isSyncRefreshing = true);
    }
    try {
      final bookings = await DataService.getBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
        _isSyncRefreshing = false;
        _loadError = null;
      });
      if (showUpdatedSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التحديث'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSyncRefreshing = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('حجوزاتي'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          if (_isSyncRefreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'متابعة الاسترداد',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RefundTrackerScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const SkeletonListLoader(itemCount: 4, itemHeight: 120)
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _loadError = null;
                            });
                            _loadBookings();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
          : RefreshIndicator(
              onRefresh: () => _loadBookings(),
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPadding,
                  AppTheme.spaceMd,
                  AppTheme.screenPadding,
                  AppTheme.spaceXl,
                ),
                children: [
                  _buildOverviewCard(),
                  const CorporateBookingsStrip(),
                  const SizedBox(height: AppTheme.spaceSm),
                  const EjariSurfaceCard(
                    elevated: false,
                    padding: EdgeInsets.all(AppTheme.spaceMd),
                    child: Text(
                      'هنا ستجد حالة كل عملية: عربون، استكمال، أو استرداد. كل خطوة مالية واضحة ومربوطة بصفقة محددة.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  if (_bookings.isEmpty)
                    _buildEmptyState()
                  else
                    ..._bookings.map(_buildBookingCard),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final total = _bookings.length;
    final depositPaid = _bookings
        .where((b) =>
            BookingStatus.normalize(b['status']?.toString()) ==
                BookingStatus.depositPaid ||
            BookingStatus.normalize(b['status']?.toString()) ==
                BookingStatus.viewingScheduled)
        .length;
    final approved = _bookings
        .where((b) =>
            BookingStatus.normalize(b['status']?.toString()) ==
            BookingStatus.approved)
        .length;
    final refunded =
        _bookings.where((b) => b['status'] == 'deposit_refunded').length;

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'ملخص الحجوزات المالية',
            subtitle: 'نظرة سريعة على حالات الدفع والموافقات',
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: EjariStatTile(
                  icon: Icons.list_alt_rounded,
                  label: 'الإجمالي',
                  value: '$total',
                  compact: true,
                ),
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: EjariStatTile(
                  icon: Icons.payments_rounded,
                  label: 'عربون مدفوع',
                  value: '$depositPaid',
                  accentColor: AppTheme.accentColor,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              Expanded(
                child: EjariStatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'موافقات',
                  value: '$approved',
                  compact: true,
                ),
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: EjariStatTile(
                  icon: Icons.replay_rounded,
                  label: 'استرداد',
                  value: '$refunded',
                  accentColor: AppTheme.textSecondary,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EjariSurfaceCard(
      child: EmptyStateView(
        icon: Icons.calendar_today_outlined,
        title: 'لا توجد حجوزات حالياً',
        subtitle:
            'أول ما تعمل حجز أو تدفع عربون، هتظهر الحالة هنا بشكل واضح، ومعها المتبقي أو الاسترداد لو حصل تغيير.',
        actionLabel: 'استكشف العقارات',
        actionIcon: Icons.search_rounded,
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertiesScreen()),
          );
        },
      ),
    );
  }

  Widget _buildRentalTransparencyCard(Map<String, dynamic> booking) {
    final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
    final totalUnits = safeInt(snapshot['totalUnits'],
        safeInt(snapshot['leaseMonths']));
    final remainingUnits = safeInt(snapshot['remainingUnits']);
    final elapsedUnits = safeInt(snapshot['elapsedUnits']);
    final unitLabel = snapshot['durationUnit']?.toString() ?? 'شهر';
    final progress = safeDouble(snapshot['progress']).clamp(0.0, 1.0);
    final monthlyRent = safeDouble(snapshot['monthlyRent']);
    final nextDueAmount = safeDouble(snapshot['nextDueAmount']);
    final remainingAmount = safeDouble(snapshot['remainingAmount']);
    final nextDueDate = DateParsing.display(
      snapshot['nextDueDate'],
      fallback: 'قريباً',
      pattern: 'dd/MM/yyyy',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'شفافية السداد الشهري',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أنقضى $elapsedUnits من $totalUnits $unitLabel • المتبقي $remainingUnits $unitLabel',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTinyStat(
                  'القسط الشهري', '${monthlyRent.toStringAsFixed(0)} ج.م'),
              _buildTinyStat(
                  'أقرب قسط', '${nextDueAmount.toStringAsFixed(0)} ج.م'),
              _buildTinyStat('موعد القسط', nextDueDate),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المبلغ المتبقي الحالي: ${remainingAmount.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    final statusColor = _statusColor(status);
    final statusText = BookingStatus.arabicLabel(status);
    final nextAction = _nextActionForStatus(status, booking);

    // Format date
    String dateStr = '';
    if (booking['startDate'] != null) {
      dateStr = DateParsing.display(booking['startDate'],
          fallback: booking['startDate'].toString());
    } else if (booking['requestDate'] != null) {
      dateStr = DateParsing.display(booking['requestDate'], fallback: 'اليوم');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: EjariSurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
        children: [
          // Header — tap opens full track screen
          InkWell(
            onTap: () {
              final id = booking['id']?.toString();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingTrackScreen(
                    bookingId: id,
                    booking: booking,
                  ),
                ),
              ).then((_) => _loadBookings());
            },
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bookmark, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_left_rounded,
                              size: 18, color: AppTheme.textSecondary),
                        ],
                      ),
                    ],
                  ),
                  if (nextAction != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Icon(nextAction.$1,
                              size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الخطوة التالية: ${nextAction.$2}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const Text(
                            'تابع حجزك',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        booking['image'] ?? 'assets/images/home1.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.backgroundColor,
                            child: const Icon(Icons.home,
                                color: AppTheme.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['title'] ??
                                booking['service'] ??
                                'طلب خدمة',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (booking['duration'] != null)
                            Text('المدة: ${booking['duration']}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                              '${booking['monthlyRent'] ?? booking['price']} ج.م${booking['itemType'] == 'car' ? '' : ' / شهر'}',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold)),
                          if (booking['leaseTotal'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'إجمالي مدة التعاقد: ${booking['leaseTotal']} ج.م',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                          if (booking['depositAmount'] != null ||
                              booking['remainingAmount'] != null) ...[
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                booking['itemType'] == 'car'
                                    ? 'عربون: ${booking['depositAmount'] ?? '0'} ج.م • متبقي: ${booking['remainingAmount'] ?? '0'} ج.م'
                                    : 'عربون: ${booking['depositAmount'] ?? '0'} ج.م • متبقي الشهر الأول: ${booking['remainingAmount'] ?? '0'} ج.م',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ),
                          ],
                          if (booking['itemType'] != 'car' &&
                              !(booking['duration']?.toString() ?? '')
                                  .contains('مرة واحدة')) ...[
                            const SizedBox(height: 12),
                            BookingStatusTimeline(booking: booking),
                            const SizedBox(height: 12),
                            EscrowTransparencyWidget(booking: booking),
                            const SizedBox(height: 12),
                            _buildRentalTransparencyCard(booking),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                if (status == BookingStatus.submitted ||
                    status == BookingStatus.pending ||
                    status == BookingStatus.corporatePending) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  const EjariSurfaceCard(
                    elevated: false,
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'طلبك قيد المراجعة. سيتم إبلاغك عند موافقة المالك.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCancelButton(booking, status),
                ],

                if (status == BookingStatus.approved) ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  BookingSummaryCard(
                    tier: _resolveTier(booking),
                    tenantType: _resolveTenantType(booking),
                    depositAmount: _parseAmount(booking['depositAmount']),
                    totalPrice: _parseAmount(
                        booking['leaseTotal'] ?? booking['currentAmount']),
                    showInstallments: booking['showInstallments'] == true,
                    checkInDate: _checkInDate(booking),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.ctaHeight,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPayment(
                        booking,
                        stage: 'remaining',
                        amount: _parseAmount(booking['remainingAmount']),
                      ),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('ادفع المتبقي واصدر العقد'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCancelButton(booking, status),
                ],

                if (status == BookingStatus.depositPaid ||
                    status == BookingStatus.viewingScheduled) ...[
                  const SizedBox(height: 16),
                  const EjariSurfaceCard(
                    elevated: false,
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'تم دفع العربون. بانتظار موافقة المالك قبل استكمال الدفع.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCancelButton(booking, status),
                ],

                if (status == BookingStatus.paid ||
                    status == BookingStatus.confirmed ||
                    status == BookingStatus.active) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            color: AppTheme.primaryColor, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'اعرض QR للدخول عند الوصول — المالك يمسحه للتحقق',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckInOutRow(booking),
                ],

                if (status == BookingStatus.paid ||
                    status == BookingStatus.confirmed ||
                    status == BookingStatus.active ||
                    status == BookingStatus.completed) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ContractViewScreen(bookingDetails: booking),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.description_outlined, size: 18),
                          label: const Text('عقدي الإلكتروني'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatDetailsScreen(
                                    userName: 'احمد محمد (المالك)'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('محادثة المالك'),
                        ),
                      ),
                    ],
                  ),
                  if (status == BookingStatus.completed) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.ctaHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerRatingScreen(
                                ownerEmail:
                                    booking['ownerEmail']?.toString() ?? '',
                                tenantEmail:
                                    booking['tenantEmail']?.toString() ?? '',
                                bookingId: booking['id']?.toString(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: const Text('قيّم المالك بعد الإقامة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ]
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Clear next step for the tenant per booking status.
  (IconData, String)? _nextActionForStatus(
    String status,
    Map<String, dynamic> booking,
  ) {
    switch (status) {
      case BookingStatus.submitted:
      case BookingStatus.pending:
      case BookingStatus.corporatePending:
        return (Icons.hourglass_top_rounded, 'انتظر موافقة المالك');
      case BookingStatus.approved:
        return (Icons.payments_rounded, 'ادفع المتبقي');
      case BookingStatus.depositPaid:
      case BookingStatus.viewingScheduled:
        return (Icons.hourglass_top_rounded, 'بانتظار موافقة المالك');
      case BookingStatus.paid:
      case BookingStatus.confirmed:
      case BookingStatus.active:
        if (booking['checkedInAt'] == null) {
          return (Icons.qr_code_rounded, 'اعرض QR أو سجّل الدخول');
        }
        if (booking['checkedOutAt'] == null) {
          return (Icons.logout_rounded, 'سجّل الخروج عند المغادرة');
        }
        return (Icons.star_rounded, 'قيّم الإقامة');
      case BookingStatus.completed:
        return (Icons.star_rounded, 'قيّم المالك');
      default:
        return null;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.disputed:
        return AppTheme.errorColor;
      case BookingStatus.submitted:
      case BookingStatus.pending:
      case BookingStatus.corporatePending:
      case BookingStatus.depositRefunded:
        return AppTheme.borderColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  double _parseAmount(dynamic raw) {
    return double.tryParse(
          raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
        ) ??
        0;
  }

  DateTime? _checkInDate(Map<String, dynamic> booking) {
    return DateParsing.parse(
      booking['checkInDate'] ??
          booking['leaseStartDate'] ??
          booking['startDate'],
    );
  }

  Widget _buildCheckInOutRow(Map<String, dynamic> booking) {
    final id = booking['id']?.toString() ?? '';
    final checkedIn = booking['checkedInAt'] != null;
    final checkedOut = booking['checkedOutAt'] != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: checkedIn || id.isEmpty
                    ? null
                    : () async {
                        final r = await CheckInOutService.checkIn(id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(r['message']?.toString() ?? '')),
                        );
                        _loadBookings();
                      },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(checkedIn ? 'تم الدخول ✓' : 'تسجيل الدخول'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: !checkedIn || checkedOut || id.isEmpty
                    ? null
                    : () async {
                        final r = await CheckInOutService.checkOut(id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(r['message']?.toString() ?? '')),
                        );
                        _loadBookings();
                      },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(checkedOut ? 'تم الخروج ✓' : 'تسجيل الخروج'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: AppTheme.ctaHeight,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingQrScreen(booking: booking),
              ),
            ),
            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
            label: const Text('عرض QR للدخول'),
          ),
        ),
      ],
    );
  }

  RentalDurationTier _resolveTier(Map<String, dynamic> booking) {
    final name = booking['rentalTier']?.toString();
    if (name != null) {
      try {
        return RentalDurationTier.values.firstWhere((t) => t.name == name);
      } catch (_) {}
    }
    return RentalDurationTier.shortTerm;
  }

  TenantType _resolveTenantType(Map<String, dynamic> booking) {
    return tenantTypeFromValue(booking['tenantType']?.toString());
  }

  Future<void> _openPayment(
    Map<String, dynamic> booking, {
    required String stage,
    required double amount,
  }) async {
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'دفع الحجز وإصدار العقد',
    );
    if (!allowed || !mounted) return;

    final monthly = _parseAmount(booking['monthlyRent'] ?? booking['price']);
    final deposit = _parseAmount(booking['depositAmount']);
    final leaseTotal = _parseAmount(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: amount,
          paymentStage: stage,
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: amount,
        ),
      ),
    );

    if (result == true) {
      _loadBookings();
    }
  }

  Widget _buildCancelButton(Map<String, dynamic> booking, String status) {
    if (status == BookingStatus.paid ||
        status == BookingStatus.active ||
        status == BookingStatus.completed ||
        status == BookingStatus.cancelled ||
        status == BookingStatus.rejected ||
        status == BookingStatus.depositRefunded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelBooking(booking),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('إلغاء الحجز'),
      ),
    );
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final deposit = _parseAmount(booking['depositAmount']);
    final checkIn = _checkInDate(booking) ??
        DateTime.now().add(const Duration(days: 3));

    final confirmed = await RefundCalculatorDialog.show(
      context,
      checkInDate: checkIn,
      depositAmount: deposit,
      bookingTitle: booking['title'] ?? 'الحجز',
    );
    if (confirmed != true || !mounted) return;

    final result = await DataService.cancelBookingWithRefund(
      bookingId: booking['id'].toString(),
      checkInDate: checkIn,
      depositAmount: deposit,
    );

    if (!mounted) return;
    _loadBookings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] != true
              ? result['message']?.toString() ?? 'تعذر الإلغاء'
              : result['refundable'] == true
                  ? 'تم استرداد عربون بقيمة ${deposit.toStringAsFixed(0)} ج.م بنجاح'
                  : 'تم الإلغاء بدون استرداد — أقل من ٤٨ ساعة قبل الاستلام',
        ),
        backgroundColor: result['refundable'] == true
            ? AppTheme.primaryColor
            : AppTheme.errorColor,
      ),
    );
  }
}
