import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/operations_feed_service.dart';
import '../screens/verification_screen.dart';
import '../screens/admin_search_screen.dart';
import '../screens/admin_service_requests_screen.dart';
import 'ejari_section.dart';

/// بث العمليات الحي — لوحة تحكم الإدارة.
class AdminOperationsFeed extends StatefulWidget {
  const AdminOperationsFeed({super.key});

  @override
  State<AdminOperationsFeed> createState() => _AdminOperationsFeedState();
}

class _AdminOperationsFeedState extends State<AdminOperationsFeed> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await OperationsFeedService.getLiveFeed(limit: 12);
    if (mounted) {
      setState(() {
        _events = events;
        _loading = false;
      });
    }
  }

  void _openEvent(Map<String, dynamic> event) {
    OperationsFeedService.markRead(event['id']?.toString() ?? '');
    final type = event['type']?.toString() ?? '';
    Widget screen;
    switch (type) {
      case 'kyc':
        screen = const VerificationScreen();
        break;
      case 'dispute':
      case 'maintenance':
        screen = const AdminServiceRequestsScreen();
        break;
      case 'booking':
      case 'corporate':
      case 'payment':
        screen = const AdminSearchScreen();
        break;
      default:
        screen = const AdminSearchScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EjariSectionHeader(
            title: 'بث العمليات الحي',
            subtitle: 'آخر الأحداث — حجوزات، مدفوعات، توثيق، نزاعات',
            actionLabel: 'تحديث',
            onAction: () {
              setState(() => _loading = true);
              _load();
            },
          ),
          const SizedBox(height: AppTheme.spaceSm),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'لا أحداث حديثة — النظام هادئ حالياً.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ..._events.take(8).map((event) => _feedTile(event)),
        ],
      ),
    );
  }

  Widget _feedTile(Map<String, dynamic> event) {
    final color = _colorFor(event['colorKey']?.toString() ?? '');
    final icon = _iconFor(event['iconKey']?.toString() ?? '');
    final isUnread = event['read'] != true;
    final priority = event['priority']?.toString() ?? 'normal';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEvent(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priority == 'critical'
                              ? AppTheme.errorColor
                              : AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['detail']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                event['timeAgo']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'accent':
        return AppTheme.accentColor;
      case 'success':
        return AppTheme.successColor;
      case 'error':
        return AppTheme.errorColor;
      case 'info':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'event_available':
        return Icons.event_available_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'build':
        return Icons.build_circle_outlined;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'groups':
        return Icons.groups_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
