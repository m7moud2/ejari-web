import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_status.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../utils/safe_parse.dart';
import '../widgets/ejari_section.dart';
import '../widgets/skeleton_list_loader.dart';
import '../widgets/empty_state_view.dart';
import 'payment_screen.dart';
import 'my_bookings_screen.dart';

/// قائمة تذكيرات الدفع للمستأجر — مستقلة عن المحفظة.
class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String _filter = 'الكل'; // الكل، متأخر، قادم

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final upcoming = await DataService.getTenantUpcomingPayments();
    if (!mounted) return;
    setState(() {
      _reminders = upcoming;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case 'متأخر':
        return _reminders.where((r) => r['isOverdue'] == true).toList();
      case 'قادم':
        return _reminders.where((r) => r['isOverdue'] != true).toList();
      default:
        return _reminders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdueCount =
        _reminders.where((r) => r['isOverdue'] == true).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'تذكيرات الدفع',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const SkeletonListLoader(itemCount: 5, itemHeight: 110)
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPadding,
                        AppTheme.spaceSm,
                        AppTheme.screenPadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EjariSurfaceCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: EjariStatTile(
                                    icon: Icons.notifications_active_outlined,
                                    label: 'الإجمالي',
                                    value: '${_reminders.length}',
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceXs),
                                Expanded(
                                  child: EjariStatTile(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'متأخر',
                                    value: '$overdueCount',
                                    accentColor: overdueCount > 0
                                        ? AppTheme.errorColor
                                        : AppTheme.accentColor,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['الكل', 'متأخر', 'قادم'].map((f) {
                                final selected = _filter == f;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: ChoiceChip(
                                    label: Text(f),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _filter = f),
                                    selectedColor:
                                        AppTheme.primaryColor.withOpacity(0.12),
                                    labelStyle: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                        ],
                      ),
                    ),
                  ),
                  if (_filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyReminders(filter: _filter),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPadding,
                        0,
                        AppTheme.screenPadding,
                        100,
                      ),
                      sliver: SliverList.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.spaceSm),
                        itemBuilder: (context, index) {
                          return _ReminderCard(
                            reminder: _filtered[index],
                            onPay: () => _openPayment(_filtered[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _openPayment(Map<String, dynamic> reminder) async {
    final bookingId = reminder['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty) return;
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null || !mounted) return;

    final amount = safeDouble(reminder['amount']);
    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);
    final deposit = safeDouble(booking['depositAmount']);
    final leaseTotal = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );
    final status = (booking['status'] ?? '').toString();
    final needsDeposit = status == BookingStatus.submitted ||
        status == BookingStatus.pending ||
        status == BookingStatus.approved ||
        status == BookingStatus.corporatePending;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: needsDeposit
              ? (deposit > 0 ? deposit : monthly * 0.2)
              : (amount > 0 ? amount : monthly),
          paymentStage: needsDeposit ? 'deposit' : 'remaining',
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: needsDeposit
              ? (deposit > 0 ? deposit : monthly * 0.2)
              : (amount > 0 ? amount : monthly),
        ),
      ),
    );
    await _load();
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onPay;

  const _ReminderCard({required this.reminder, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(reminder['dueDate']?.toString() ?? '');
    final dueText =
        due == null ? '—' : DateFormat('yyyy/MM/dd').format(due);
    final isOverdue = reminder['isOverdue'] == true;
    final amount = safeDouble(reminder['amount']);
    final property = reminder['property']?.toString().isNotEmpty == true
        ? reminder['property'].toString()
        : (reminder['title']?.toString() ?? 'عقار');
    final location = reminder['location']?.toString() ?? '';

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isOverdue
                          ? AppTheme.errorColor
                          : AppTheme.accentColor)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.event_available_rounded,
                  color: isOverdue
                      ? AppTheme.errorColor
                      : AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reminder['statusLabel']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isOverdue
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المبلغ المستحق',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,##0.00').format(amount)} ج.م',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isOverdue
                            ? AppTheme.errorColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تاريخ الاستحقاق',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            height: AppTheme.ctaHeight,
            child: ElevatedButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment_rounded, color: Colors.white),
              label: const Text(
                'ادفع الآن',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverdue
                    ? AppTheme.errorColor
                    : AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  final String filter;
  const _EmptyReminders({required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = filter == 'متأخر'
        ? 'لا توجد دفعات متأخرة — أحسنت!'
        : filter == 'قادم'
            ? 'لا توجد دفعات قادمة خلال الـ 60 يوماً القادمة'
            : 'لا توجد تذكيرات دفع حالياً';

    return EmptyStateView(
      icon: Icons.check_circle_outline_rounded,
      title: message,
      subtitle: 'ستظهر هنا أقساط الإيجار والعربون المستحقة من حجوزاتك.',
      actionLabel: 'عرض حجوزاتي',
      actionIcon: Icons.calendar_month_rounded,
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
      },
    );
  }
}
