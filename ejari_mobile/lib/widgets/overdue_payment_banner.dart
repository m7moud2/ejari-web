import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../screens/payment_reminders_screen.dart';
import '../screens/notification_center_screen.dart';

/// بانر push-style عند تأخر الدفع.
class OverduePaymentBanner extends StatefulWidget {
  const OverduePaymentBanner({super.key});

  @override
  State<OverduePaymentBanner> createState() => _OverduePaymentBannerState();
}

class _OverduePaymentBannerState extends State<OverduePaymentBanner> {
  Map<String, dynamic>? _overdue;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final note = await DataService.getLatestOverduePaymentNotification();
    if (mounted) {
      setState(() => _overdue = note);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _overdue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: const Color(0xFF7A2E2E),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PaymentRemindersScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _overdue!['title']?.toString() ?? 'تأخر في الدفع',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _overdue!['body']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded,
                      color: Colors.white, size: 20),
                ),
                IconButton(
                  onPressed: () => setState(() => _dismissed = true),
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.8), size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
