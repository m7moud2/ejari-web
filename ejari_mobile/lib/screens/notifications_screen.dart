import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../utils/date_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notes = await DataService.getNotifications();
    setState(() {
      _notifications = notes;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await DataService.markAllNotificationsAsRead();
    await _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديد الكل كمقروء')),
      );
    }
  }

  String _formatDate(String isoString) {
    final date = DateParsing.parse(isoString);
    if (date == null) return isoString;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return DateFormat('yyyy/MM/dd hh:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_notifications.any((n) => (n['read'] ?? false) == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'تحديد الكل كمقروء',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _buildNotificationItem(item, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, int index) {
    final title = item['title'] ?? '';
    final isRead = item['read'] ?? false;

    // Determine icon and color based on title
    IconData icon = Icons.notifications;
    Color color = AppTheme.primaryColor;

    if (title.contains('حجز') || title.contains('طلب')) {
      icon = Icons.book_online;
      color = AppTheme.primaryColor;
    } else if (title.contains('دفع') || title.contains('بنجاح')) {
      icon = Icons.check_circle_outline;
      color = AppTheme.primaryColor;
    } else if (title.contains('رفض')) {
      icon = Icons.cancel_outlined;
      color = AppTheme.errorColor;
    } else if (title.contains('رسالة')) {
      icon = Icons.chat_bubble_outline;
      color = AppTheme.borderColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? AppTheme.backgroundColor : color.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['body'] ?? '',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            if (item['date'] != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(item['date']),
                style:
                    const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
              ),
            ],
          ],
        ),
        onTap: () async {
          if (!isRead) {
            await DataService.markNotificationAsRead(index);
            _loadNotifications();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد تنبيهات جديدة',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
