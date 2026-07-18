import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/deep_link_service.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state_view.dart';
import 'receipt_screen.dart';
import 'my_service_requests_screen.dart';
import 'my_bookings_screen.dart';
import 'property_details_screen.dart';
import 'subscriptions_screen.dart';
import 'payment_screen.dart';
import 'tech_job_screen.dart';
import '../services/auth_service.dart';
import '../utils/safe_parse.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<Map<String, dynamic>> _notifications = [];
  Map<String, int> _categoryCounts = {};
  bool _loading = true;
  String _filter = 'all';

  String _userRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await DataService.getNotifications();
    final counts = await DataService.getUnreadCountByCategory();
    final role = await AuthService.getUserRole();
    setState(() {
      _notifications = notes;
      _categoryCounts = counts;
      _userRole = role;
      _loading = false;
    });
  }

  Future<void> _openReceiptIfPayment(Map<String, dynamic> note) async {
    final refId = note['refId']?.toString();
    if (refId == null || !refId.startsWith('RCP-')) return;
    final receipt = await DataService.getReceiptById(refId);
    if (receipt != null && mounted) {
      await ReceiptScreen.showDialogFor(context, receipt);
    }
  }

  String _inferType(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? '';
    final type = note['type']?.toString() ?? '';
    if (type == 'booking' || title.contains('حجز') || title.contains('طلب')) {
      return 'Booking';
    }
    if (type == 'subscription' ||
        title.contains('باقة') ||
        title.contains('اشتراك')) {
      return 'Subscription';
    }
    if (type == 'kyc' || title.contains('توثيق') || title.contains('KYC')) {
      return 'KYC';
    }
    if (title.contains('فاض') ||
        title.contains('شاغر') ||
        title.contains('سرير')) {
      return 'Vacant';
    }
    if (type == 'payment_reminder' ||
        title.contains('قسط') ||
        title.contains('دفع') ||
        title.contains('عربون')) {
      return 'Payment';
    }
    if (title.contains('صيانة') || title.contains('فني')) return 'Maintenance';
    if (title.contains('تأخير') || title.contains('رفض') || title.contains('إلغاء')) {
      return 'Alert';
    }
    if (title.contains('تذكير') || title.contains('موعد')) return 'Reminder';
    return 'General';
  }

  Future<void> _openBooking(Map<String, dynamic> note) async {
    if (!mounted) return;
    final refId = note['refId']?.toString();
    if (refId != null && refId.isNotEmpty) {
      final target = DeepLinkTarget(type: DeepLinkType.booking, id: refId);
      await DeepLinkService.navigate(target);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  Future<void> _openSubscription() async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
    );
  }

  Future<void> _openProperty(String propertyId) async {
    final property = await DataService.findPropertyById(propertyId);
    if (property == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  Future<void> _openPaymentBooking(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null || !mounted) return;
    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);
    final deposit = safeDouble(booking['depositAmount']);
    final leaseTotal = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: deposit > 0 ? deposit : monthly * 0.2,
          paymentStage: 'deposit',
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: deposit > 0 ? deposit : monthly * 0.2,
        ),
      ),
    );
  }

  Future<void> _openMaintenance(Map<String, dynamic> note) async {
    final refId = note['refId']?.toString();
    final role = await AuthService.getUserRole();
    if (!mounted) return;
    if (role == 'technician' && refId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TechJobScreen(requestId: refId),
        ),
      );
      return;
    }
    if (role == 'admin') {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filter == 'all'
        ? _notifications
        : _notifications.where((n) => _inferType(n) == _filter).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('مركز الإشعارات'),
        titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              await DataService.markAllNotificationsAsRead();
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: _filters(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primaryColor,
                    child: items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              EmptyStateView(
                                icon: Icons.notifications_none_rounded,
                                title: 'لا توجد إشعارات حالياً',
                                subtitle:
                                    'ستظهر هنا تنبيهات الحجز والدفع والصيانة والتوثيق.',
                                actionLabel: 'تحديث',
                                actionIcon: Icons.refresh_rounded,
                                onAction: () {
                                  setState(() => _loading = true);
                                  _load();
                                },
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: items.length,
                            itemBuilder: (context, index) => _card(items[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _filters() {
    final isOwner = _userRole == 'owner';
    final filters = isOwner
        ? const [
            ('all', 'الكل'),
            ('Booking', 'حجوزات'),
            ('Payment', 'مدفوعات'),
            ('Vacant', 'أماكن فاضية'),
            ('KYC', 'توثيق'),
            ('Subscription', 'الباقة'),
            ('Alert', 'تنبيهات'),
          ]
        : const [
            ('all', 'الكل'),
            ('Reminder', 'تذكيرات'),
            ('Payment', 'مدفوعات'),
            ('Maintenance', 'صيانة'),
            ('Alert', 'تنبيهات'),
          ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = _filter == item.$1;
          final unread = item.$1 == 'all'
              ? (_categoryCounts['all'] ?? 0)
              : (_categoryCounts[item.$1] ?? 0);
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.$2),
                if (unread > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: selected ? AppTheme.primaryColor : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onSelected: (_) => setState(() => _filter = item.$1),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800),
            backgroundColor: AppTheme.surfaceColor,
            side: BorderSide(color: AppTheme.borderColor.withOpacity(0.18)),
          );
        },
      ),
    );
  }

  Widget _card(Map<String, dynamic> notif) {
    final isRead = notif['read'] == true;
    final type = _inferType(notif);
    final (icon, color) = switch (type) {
      'Reminder' => (Icons.calendar_today_rounded, Colors.orange),
      'Payment' => (
          Icons.account_balance_wallet_rounded,
          AppTheme.primaryColor
        ),
      'Maintenance' => (Icons.build_circle_rounded, Colors.blue),
      'Alert' => (Icons.warning_rounded, AppTheme.errorColor),
      _ => (Icons.notifications_rounded, AppTheme.primaryColor),
    };
    final date = DateParsing.parse(notif['date']?.toString()) ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? AppTheme.surfaceColor
            : AppTheme.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: InkWell(
        onTap: () async {
          final index = _notifications.indexOf(notif);
          if (index >= 0) {
            await DataService.markNotificationAsRead(index);
            await _load();
          }
          if (type == 'Payment') {
            await _openReceiptIfPayment(notif);
            final refId = notif['refId']?.toString();
            if (refId != null &&
                !refId.startsWith('RCP-') &&
                mounted) {
              await _openPaymentBooking(refId);
            }
          } else if (type == 'Booking' || type == 'Reminder') {
            await _openBooking(notif);
          } else if (type == 'Subscription') {
            await _openSubscription();
          } else if (type == 'Vacant') {
            final refId = notif['refId']?.toString();
            if (refId != null) await _openProperty(refId);
          } else if (type == 'Maintenance') {
            await _openMaintenance(notif);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.10), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif['title']?.toString() ?? 'إشعار',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w700
                                    : FontWeight.w900,
                                fontSize: 15)),
                      ),
                      if (!isRead)
                        Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notif['body']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                      DateFormat('yyyy/MM/dd - hh:mm a').format(date),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
