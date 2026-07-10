import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';

/// مؤقت SLA لطلبات الصيانة.
class SlaTimerChip extends StatelessWidget {
  final Map<String, dynamic> request;

  const SlaTimerChip({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final overdue = MaintenanceStatus.isSlaOverdue(request);
    final label = MaintenanceStatus.slaRemainingLabelAr(request);
    final color = overdue ? AppTheme.errorColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: overdue ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.timer_off_rounded : Icons.timer_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
