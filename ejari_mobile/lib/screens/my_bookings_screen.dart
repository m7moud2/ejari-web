import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import 'contract_view_screen.dart';
import 'payment_screen.dart';
import 'chat_details_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../utils/rental_schedule_utils.dart';
import '../widgets/refund_calculator_dialog.dart';
import '../widgets/corporate_bookings_strip.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await DataService.getBookings();
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
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
      ),
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBookings,
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
    final depositPaid =
        _bookings.where((b) => b['status'] == 'deposit_paid').length;
    final approved = _bookings.where((b) => b['status'] == 'approved').length;
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
    return const EjariSurfaceCard(
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: AppTheme.spaceMd),
          Text(
            'لا توجد حجوزات حالياً',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceXs),
          Text(
            'أول ما تعمل حجز أو تدفع عربون، هتظهر الحالة هنا بشكل واضح، ومعها المتبقي أو الاسترداد لو حصل تغيير.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalTransparencyCard(Map<String, dynamic> booking) {
    final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
    final totalUnits = (snapshot['totalUnits'] as num?)?.toInt() ??
        (snapshot['leaseMonths'] as num?)?.toInt() ??
        0;
    final remainingUnits = (snapshot['remainingUnits'] as num?)?.toInt() ?? 0;
    final elapsedUnits = (snapshot['elapsedUnits'] as num?)?.toInt() ?? 0;
    final unitLabel = snapshot['durationUnit']?.toString() ?? 'شهر';
    final progress =
        ((snapshot['progress'] as num?) ?? 0.0).toDouble().clamp(0.0, 1.0);
    final monthlyRent = (snapshot['monthlyRent'] as num).toDouble();
    final nextDueAmount = (snapshot['nextDueAmount'] as num).toDouble();
    final remainingAmount = (snapshot['remainingAmount'] as num).toDouble();
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
    String status = booking['status'] ?? 'pending';
    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.borderColor;
        statusText = 'قيد الانتظار';
        break;
      case 'viewing_scheduled':
      case 'deposit_paid':
        statusColor = AppTheme.primaryColor;
        statusText = 'عربون المعاينة';
        break;
      case 'deposit_refunded':
        statusColor = AppTheme.borderColor;
        statusText = 'تم استرداد العربون';
        break;
      case 'approved': // Was accepted
        statusColor = AppTheme.primaryColor;
        statusText = 'تمت الموافقة';
        break;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusText = 'مرفوض';
        break;
      case 'active':
      case 'paid':
        statusColor = AppTheme.primaryColor;
        statusText = 'نشط / مدفوع';
        break;
      case 'completed':
        statusColor = AppTheme.primaryColor;
        statusText = 'مكتمل';
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = status;
    }

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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
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
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
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
                            _buildRentalTransparencyCard(booking),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                if (status == 'approved') ...[
                  const SizedBox(height: AppTheme.spaceMd),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.ctaHeight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final allowed = await AuthGate.requireLogin(
                          context,
                          actionLabel: 'دفع الحجز وإصدار العقد',
                        );
                        if (!allowed || !mounted) return;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              itemType: 'booking',
                              itemData: booking,
                              amount: double.tryParse((booking['monthlyRent'] ??
                                          booking['price'] ??
                                          0)
                                      .toString()) ??
                                  0.0,
                            ),
                          ),
                        );

                        if (result == true) {
                          _loadBookings();
                        }
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('ادفع الآن واصدر العقد'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بعد الدفع، سيظهر لك العقد الإلكتروني وتتبع العملية من نفس الصفحة.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],

                if (status == 'viewing_scheduled' ||
                    status == 'deposit_paid') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final allowed = await AuthGate.requireLogin(
                              context,
                              actionLabel: 'استكمال دفعة الشهر الأول',
                            );
                            if (!allowed || !mounted) return;
                            final monthly = double.tryParse(
                                    (booking['monthlyRent'] ??
                                            booking['price'] ??
                                            0)
                                        .toString()) ??
                                0.0;
                            final deposit = double.tryParse(
                                    booking['depositAmount']?.toString() ??
                                        (monthly * 0.10).toString()) ??
                                (monthly * 0.10);
                            final remaining = double.tryParse(
                                    booking['remainingAmount']?.toString() ??
                                        (monthly - deposit).toString()) ??
                                (monthly - deposit);

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  itemType: 'booking',
                                  itemData: booking,
                                  amount: remaining,
                                  paymentStage: 'remaining',
                                  totalAmount: monthly,
                                  depositAmount: deposit,
                                  remainingAmount: remaining,
                                ),
                              ),
                            );

                            if (result == true) {
                              _loadBookings();
                            }
                          },
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('استكمال دفعة الشهر الأول'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final monthly = double.tryParse(
                                    (booking['monthlyRent'] ??
                                            booking['price'] ??
                                            0)
                                        .toString()) ??
                                0.0;
                            final deposit = double.tryParse(
                                    booking['depositAmount']?.toString() ??
                                        (monthly * 0.10).toString()) ??
                                (monthly * 0.10);
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
                              bookingTitle: booking['title'] ?? 'الحجز',
                            );
                            if (confirmed != true || !mounted) return;

                            await WalletService.refundBookingDeposit(
                              title:
                                  'استرداد عربون ${booking['title'] ?? 'الحجز'}',
                              amount: deposit,
                              bookingId: booking['id'].toString(),
                            );
                            await DataService.refundBookingDeposit(
                                booking['id'].toString());
                            if (!mounted) return;
                            _loadBookings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'تم طلب استرداد عربون بقيمة ${deposit.toStringAsFixed(0)} ج.م بنجاح'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.keyboard_return_rounded,
                              size: 18),
                          label: const Text('استرداد العربون'),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status == 'paid' ||
                    status == 'active' ||
                    status == 'completed') ...[
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
                  )
                ]
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
