import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../utils/date_utils.dart';
import 'receipt_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await DataService.getNotifications();
    setState(() {
      _notifications = notes;
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
    if (title.contains('قسط') || title.contains('دفع') || title.contains('عربون')) {
      return 'Payment';
    }
    if (title.contains('صيانة') || title.contains('فني')) return 'Maintenance';
    if (title.contains('تأخير') || title.contains('رفض') || title.contains('إلغاء')) {
      return 'Alert';
    }
    if (title.contains('تذكير') || title.contains('موعد')) return 'Reminder';
    return 'General';
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
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('لا توجد إشعارات حالياً')),
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
    const filters = [
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
          return ChoiceChip(
            selected: selected,
            label: Text(item.$2),
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
