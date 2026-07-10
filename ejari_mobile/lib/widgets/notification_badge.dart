import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// شارة عدد الإشعارات غير المقروءة.
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final double top;
  final double right;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.top = 4,
    this.right = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final label = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
