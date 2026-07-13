import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent empty-state illustration used across list screens.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final bool compact;

  const EmptyStateView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 16.0 : 32.0;
    final iconSize = compact ? 36.0 : 56.0;
    final titleSize = compact ? 14.0 : 18.0;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 12 : 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: AppTheme.primaryColor),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: compact ? 11 : 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 12 : 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon, size: compact ? 16 : 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: compact
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
