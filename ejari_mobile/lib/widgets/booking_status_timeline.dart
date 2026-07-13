import 'package:flutter/material.dart';
import '../models/booking_status.dart';
import '../theme/app_theme.dart';

/// Vertical timeline showing booking lifecycle progress.
class BookingStatusTimeline extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool detailed;
  final String title;

  const BookingStatusTimeline({
    super.key,
    required this.booking,
    this.detailed = false,
    this.title = 'مسار الحجز',
  });

  @override
  Widget build(BuildContext context) {
    final steps = BookingStatus.buildTimeline(booking, detailed: detailed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            final done = step['done'] == true;
            final active = step['active'] == true;
            final failed = step['failed'] == true;
            final isLast = idx == steps.length - 1;

            Color dotColor;
            if (failed) {
              dotColor = AppTheme.errorColor;
            } else if (active) {
              dotColor = AppTheme.primaryColor;
            } else if (done) {
              dotColor = AppTheme.accentColor;
            } else {
              dotColor = AppTheme.borderColor;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: active
                                ? Border.all(
                                    color: AppTheme.primaryColor, width: 2)
                                : null,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: done
                                  ? AppTheme.accentColor.withOpacity(0.5)
                                  : AppTheme.borderColor.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.w600,
                              color: failed
                                  ? AppTheme.errorColor
                                  : active
                                      ? AppTheme.primaryColor
                                      : done
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                            ),
                          ),
                          if (step['at'] != null)
                            Text(
                              _formatAt(step['at']),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (step['note'] != null)
                            Text(
                              step['note'].toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatAt(dynamic at) {
    final dt = DateTime.tryParse(at.toString());
    if (dt == null) return at.toString();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
