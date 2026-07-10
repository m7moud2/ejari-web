import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../utils/date_utils.dart';
import 'receipt_screen.dart';
import 'my_bookings_screen.dart';
import 'my_service_requests_screen.dart';
import 'tenant_wallet_screen.dart';
import 'tech_job_screen.dart';
import 'admin_service_requests_screen.dart';

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

  String _inferType(Map<String, dynamic> note) {
    final title = note['title']?.toString() ?? '';
    if (title.contains('قسط') || title.contains('دفع') || title.contains('عربون')) {
      return 'Payment';
    }
    if (title.contains('صيانة') || title.contains('فني')) return 'Maintenance';
    if (title.contains('حجز') || title.contains('عقد')) return 'Booking';
    return 'General';
  }

  Future<void> _handleDeepLink(Map<String, dynamic> note) async {
    final type = _inferType(note);
    final role = await AuthService.getUserRole();
    if (!mounted) return;

    if (type == 'Payment') {
      final refId = note['refId']?.toString();
      if (refId != null && refId.startsWith('RCP-')) {
        final receipt = await DataService.getReceiptById(refId);
        if (receipt != null && mounted) {
          await ReceiptScreen.showDialogFor(context, receipt);
        }
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TenantWalletScreen()),
      );
      return;
    }

    if (type == 'Maintenance') {
      final refId = note['refId']?.toString();
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminServiceRequestsScreen(),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
      );
      return;
    }

    if (type == 'Booking') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
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
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                      ),
                    ),
                    child: const Text(
                      'هنا ستجد تحديثات الحجوزات، المدفوعات، والعقود. اقرأها لتعرف كل خطوة حصلت داخل الحساب.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_notifications.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(_notifications.length, (index) {
                      final item = _notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNotificationItem(item, index),
                      );
                    }),
                ],
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
          await _handleDeepLink(item);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.notifications_none,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد تنبيهات جديدة',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'أول ما يحصل حجز، دفع، أو تحديث مهم، هتظهر التفاصيل هنا.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
