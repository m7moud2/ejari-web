import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'NOT-01',
      'title': 'تذكير قسط إيجار',
      'body': 'يتبقى 3 أيام على موعد القسط القادم.',
      'type': 'Reminder',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      'action': 'Pay'
    },
    {
      'id': 'NOT-02',
      'title': 'تم استلام الدفعة',
      'body': 'تم تحديث حالة القسط وإصدار إيصال جديد.',
      'type': 'Payment',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'action': 'ViewReceipt'
    },
    {
      'id': 'NOT-03',
      'title': 'طلب صيانة جديد',
      'body': 'طلب سباكة جديد في العقار المرتبط بك.',
      'type': 'Maintenance',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'action': 'ViewRequest'
    },
    {
      'id': 'NOT-04',
      'title': 'تنبيه تأخير',
      'body': 'هناك تأخير متكرر يحتاج مراجعة من الأدمن.',
      'type': 'Alert',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'action': 'Contact'
    },
  ];

  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final items = _filter == 'all'
        ? _notifications
        : _notifications.where((n) => n['type'] == _filter).toList();

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
            onPressed: () => setState(() {
              for (final n in _notifications) {
                n['isRead'] = true;
              }
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _filters(),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('لا توجد إشعارات'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _card(items[index]),
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
    final isRead = notif['isRead'] == true;
    final type = notif['type'] as String;
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

    return Dismissible(
      key: ValueKey(notif['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      onDismissed: (_) => setState(() => _notifications.remove(notif)),
      child: Container(
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
          onTap: () => setState(() => notif['isRead'] = true),
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
                          child: Text(notif['title'],
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
                    Text(notif['body'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, height: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                        DateFormat('yyyy/MM/dd - hh:mm a')
                            .format(notif['createdAt'] as DateTime),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
