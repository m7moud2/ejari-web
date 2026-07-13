import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/accommodation_type.dart';
import '../models/booking_status.dart';
import '../models/rental_duration_tier.dart';
import '../services/check_in_out_service.dart';
import '../services/data_service.dart';
import '../services/live_sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../utils/rental_rules.dart';
import '../utils/safe_parse.dart';
import '../widgets/booking_status_timeline.dart';
import '../widgets/ejari_section.dart';
import '../widgets/escrow_transparency_widget.dart';
import '../widgets/refund_calculator_dialog.dart';
import '../widgets/skeleton_list_loader.dart';
import 'booking_qr_screen.dart';
import 'chat_details_screen.dart';
import 'contract_view_screen.dart';
import 'owner_rating_screen.dart';
import 'payment_screen.dart';

/// شاشة «تابع حجزك» — مسار كامل + تفاصيل + الخطوة التالية.
class BookingTrackScreen extends StatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? booking;

  const BookingTrackScreen({
    super.key,
    this.bookingId,
    this.booking,
  }) : assert(bookingId != null || booking != null);

  @override
  State<BookingTrackScreen> createState() => _BookingTrackScreenState();
}

class _BookingTrackScreenState extends State<BookingTrackScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _notFound = false;
  bool _isSyncRefreshing = false;
  int _lastSyncGeneration = 0;
  LiveSyncService? _liveSync;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking != null
        ? Map<String, dynamic>.from(widget.booking!)
        : null;
    _load(initial: true);
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
    _load(showUpdatedSnack: showSnack);
  }

  String? get _resolvedId =>
      widget.bookingId ??
      _booking?['id']?.toString() ??
      _booking?['_id']?.toString();

  Future<void> _load({
    bool initial = false,
    bool showUpdatedSnack = false,
  }) async {
    if (_isSyncRefreshing && !initial) return;
    if (showUpdatedSnack) {
      setState(() => _isSyncRefreshing = true);
    }

    final id = _resolvedId;
    Map<String, dynamic>? found;
    if (id != null && id.isNotEmpty) {
      found = await DataService.findBookingById(id);
    }
    found ??= _booking;

    if (!mounted) return;
    setState(() {
      _booking = found != null ? Map<String, dynamic>.from(found) : null;
      _notFound = found == null;
      _isLoading = false;
      _isSyncRefreshing = false;
    });

    if (showUpdatedSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الحجز'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('تابع حجزك'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
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
        ],
      ),
      body: _isLoading
          ? const SkeletonListLoader(itemCount: 5, itemHeight: 100)
          : _notFound || _booking == null
              ? _buildNotFound()
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () => _load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenPadding,
                      AppTheme.spaceMd,
                      AppTheme.screenPadding,
                      AppTheme.spaceXl,
                    ),
                    children: [
                      _buildHeroCard(_booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildNextCta(_booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'مسار الحجز',
                              subtitle: 'كل خطوة من الطلب حتى التقييم',
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            BookingStatusTimeline(
                              booking: _booking!,
                              detailed: true,
                              title: 'المسار التفصيلي',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildDetailsPanel(_booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildPaymentBreakdown(_booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      EscrowTransparencyWidget(booking: _booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildRefundCountdown(_booking!),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildActionsPanel(_booking!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.screenPadding),
        child: EjariSurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text(
                'لم يتم العثور على الحجز',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'تحقق من الرابط أو افتح حجوزاتي من الشريط السفلي.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    final statusLabel = BookingStatus.arabicLabel(status);
    final title =
        booking['title']?.toString() ?? booking['service']?.toString() ?? 'حجز';
    final address = booking['address']?.toString() ??
        booking['location']?.toString() ??
        booking['governorate']?.toString() ??
        '';
    final image = booking['image']?.toString() ?? 'assets/images/home1.jpg';
    final acc = accommodationTypeFromProperty(booking);
    final roomHint = acc == AccommodationType.sharedRoom
        ? (booking['roomLabel']?.toString() ?? 'غرفة مشتركة')
        : acc == AccommodationType.bed
            ? (booking['bedLabel']?.toString() ?? 'سرير')
            : null;

    final checkIn = DateParsing.display(
      booking['checkInDate'] ?? booking['leaseStartDate'] ?? booking['startDate'],
      fallback: '—',
      pattern: 'dd/MM/yyyy',
    );
    final checkOut = DateParsing.display(
      booking['checkOutDate'] ?? booking['leaseEndDate'] ?? booking['endDate'],
      fallback: '—',
      pattern: 'dd/MM/yyyy',
    );
    final tierLabel = booking['rentalTierLabel']?.toString() ??
        _resolveTier(booking).arabicLabel;

    return EjariSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cardRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  child: const Icon(Icons.home_rounded,
                      size: 48, color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (roomHint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    roomHint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('دخول', checkIn),
                    _chip('خروج', checkOut),
                    _chip('المدة', tierLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNextCta(Map<String, dynamic> booking) {
    final next = BookingStatus.nextActionForBooking(booking);
    if (next == null) return const SizedBox.shrink();

    IconData icon;
    switch (next.$1) {
      case 'payments':
        icon = Icons.payments_rounded;
      case 'qr':
        icon = Icons.qr_code_2_rounded;
      case 'logout':
        icon = Icons.logout_rounded;
      case 'star':
        icon = Icons.star_rounded;
      default:
        icon = Icons.hourglass_top_rounded;
    }

    final actionable =
        next.$3 == 'pay' ||
        next.$3 == 'qr_checkin' ||
        next.$3 == 'checkout' ||
        next.$3 == 'rate';

    return SizedBox(
      width: double.infinity,
      height: AppTheme.ctaHeight + 4,
      child: ElevatedButton.icon(
        onPressed: actionable ? () => _runPrimaryAction(booking, next.$3) : null,
        icon: Icon(icon, size: 22),
        label: Text(
          next.$2,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.45),
          disabledForegroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _runPrimaryAction(
    Map<String, dynamic> booking,
    String key,
  ) async {
    switch (key) {
      case 'pay':
        await _openPayment(booking);
      case 'qr_checkin':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingQrScreen(booking: booking)),
        );
        if (mounted) _load();
      case 'checkout':
        final id = booking['id']?.toString() ?? '';
        if (id.isEmpty) return;
        final r = await CheckInOutService.checkOut(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message']?.toString() ?? '')),
        );
        _load();
      case 'rate':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerRatingScreen(
              ownerEmail: booking['ownerEmail']?.toString() ?? '',
              tenantEmail: booking['tenantEmail']?.toString() ?? '',
              bookingId: booking['id']?.toString(),
            ),
          ),
        );
    }
  }

  Widget _buildDetailsPanel(Map<String, dynamic> booking) {
    final paid = safeDouble(booking['amountPaid'] ?? booking['depositAmount']);
    final remaining = safeDouble(booking['remainingAmount']);
    final total = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? (paid + remaining),
    );

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'تفاصيل الحجز',
            subtitle: 'المبالغ والتواريخ',
          ),
          const SizedBox(height: 8),
          _row('المدفوع', '${paid.toStringAsFixed(0)} ج.م'),
          _row('المتبقي', '${remaining.toStringAsFixed(0)} ج.م'),
          _row('الإجمالي', '${total.toStringAsFixed(0)} ج.م'),
          if (booking['duration'] != null)
            _row('المدة', booking['duration'].toString()),
          if (booking['id'] != null) _row('رقم الحجز', booking['id'].toString()),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(Map<String, dynamic> booking) {
    final deposit = safeDouble(booking['depositAmount']);
    final remaining = safeDouble(booking['remainingAmount']);
    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);

    return EjariSurfaceCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'تفصيل الدفع',
            subtitle: 'عربون ومتبقي',
          ),
          const SizedBox(height: 8),
          _row('الإيجار الشهري', '${monthly.toStringAsFixed(0)} ج.م'),
          _row('العربون / المقدم', '${deposit.toStringAsFixed(0)} ج.م'),
          _row('المتبقي للاستكمال', '${remaining.toStringAsFixed(0)} ج.م'),
        ],
      ),
    );
  }

  Widget _buildRefundCountdown(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    if (status == BookingStatus.paid ||
        status == BookingStatus.active ||
        status == BookingStatus.completed ||
        status == BookingStatus.cancelled ||
        status == BookingStatus.rejected ||
        status == BookingStatus.depositRefunded) {
      return const SizedBox.shrink();
    }

    final checkIn = DateParsing.parse(
          booking['checkInDate'] ??
              booking['leaseStartDate'] ??
              booking['startDate'],
        ) ??
        DateTime.now().add(const Duration(days: 3));
    final now = DateTime.now();
    final hoursLeft = checkIn.difference(now).inHours;
    final refundable = RentalRules.isRefundable(
      checkInDate: checkIn,
      cancelDate: now,
    );
    final hoursUntilCutoff = hoursLeft - 48;

    return EjariSurfaceCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'أهلية الاسترداد',
            subtitle: RentalRules.refundPolicyShortArabic,
          ),
          const SizedBox(height: 8),
          Text(
            refundable
                ? hoursUntilCutoff > 0
                    ? 'متبقي حوالي $hoursUntilCutoff ساعة قبل انتهاء أهلية الاسترداد الكامل.'
                    : 'ما زال الإلغاء قابلاً للاسترداد (قبل الاستلام بـ ٤٨ ساعة).'
                : 'انتهت أهلية الاسترداد — الإلغاء خلال أقل من ٤٨ ساعة.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: refundable ? AppTheme.primaryColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsPanel(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    final id = booking['id']?.toString() ?? '';
    final checkedIn = booking['checkedInAt'] != null;
    final checkedOut = booking['checkedOutAt'] != null;

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'إجراءات سريعة',
            subtitle: 'عقد · QR · محادثة · دخول',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(
                icon: Icons.description_outlined,
                label: 'العقد',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ContractViewScreen(bookingDetails: booking),
                  ),
                ),
              ),
              _actionChip(
                icon: Icons.qr_code_2_rounded,
                label: 'QR',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingQrScreen(booking: booking),
                  ),
                ),
              ),
              _actionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'المالك',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatDetailsScreen(
                      userName: 'احمد محمد (المالك)',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (status == BookingStatus.approved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppTheme.ctaHeight,
              child: ElevatedButton.icon(
                onPressed: () => _openPayment(booking),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('ادفع المتبقي واصدر العقد'),
              ),
            ),
          ],
          if (status == BookingStatus.paid ||
              status == BookingStatus.confirmed ||
              status == BookingStatus.active) ...[
            const SizedBox(height: 12),
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
                              SnackBar(
                                content:
                                    Text(r['message']?.toString() ?? ''),
                              ),
                            );
                            _load();
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
                              SnackBar(
                                content:
                                    Text(r['message']?.toString() ?? ''),
                              ),
                            );
                            _load();
                          },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(checkedOut ? 'تم الخروج ✓' : 'تسجيل الخروج'),
                  ),
                ),
              ],
            ),
          ],
          if (status == BookingStatus.completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: AppTheme.ctaHeight,
              child: ElevatedButton.icon(
                onPressed: () => _runPrimaryAction(booking, 'rate'),
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text('قيّم المالك بعد الإقامة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ),
          ],
          if (_canCancel(status)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(booking),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('إلغاء الحجز'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canCancel(String status) {
    return status != BookingStatus.paid &&
        status != BookingStatus.active &&
        status != BookingStatus.completed &&
        status != BookingStatus.cancelled &&
        status != BookingStatus.rejected &&
        status != BookingStatus.depositRefunded;
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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

  Future<void> _openPayment(Map<String, dynamic> booking) async {
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'دفع الحجز وإصدار العقد',
    );
    if (!allowed || !mounted) return;

    final amount = safeDouble(booking['remainingAmount']);
    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);
    final deposit = safeDouble(booking['depositAmount']);
    final leaseTotal = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: amount > 0 ? amount : leaseTotal,
          paymentStage: 'remaining',
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: amount,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final deposit = safeDouble(booking['depositAmount']);
    final checkIn = DateParsing.parse(
          booking['checkInDate'] ??
              booking['leaseStartDate'] ??
              booking['startDate'],
        ) ??
        DateTime.now().add(const Duration(days: 3));

    final confirmed = await RefundCalculatorDialog.show(
      context,
      checkInDate: checkIn,
      depositAmount: deposit,
      bookingTitle: booking['title']?.toString() ?? 'الحجز',
    );
    if (confirmed != true || !mounted) return;

    final result = await DataService.cancelBookingWithRefund(
      bookingId: booking['id'].toString(),
      checkInDate: checkIn,
      depositAmount: deposit,
    );

    if (!mounted) return;
    _load();
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
