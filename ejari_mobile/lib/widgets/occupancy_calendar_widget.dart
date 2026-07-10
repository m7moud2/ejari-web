import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// شبكة شهرية بسيطة لعرض إشغال الأسرّة/الغرف.
class OccupancyCalendarWidget extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, List<String>> occupiedByDate;
  final List<String> vacantBedLabels;
  final void Function(DateTime day)? onDayTap;

  const OccupancyCalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.occupiedByDate,
    this.vacantBedLabels = const [],
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = first.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('ح', style: _wdStyle),
            Text('ن', style: _wdStyle),
            Text('ث', style: _wdStyle),
            Text('ر', style: _wdStyle),
            Text('خ', style: _wdStyle),
            Text('ج', style: _wdStyle),
            Text('س', style: _wdStyle),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) return const SizedBox.shrink();
            final day = index - startWeekday + 1;
            final date = DateTime(year, month, day);
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final occupied = occupiedByDate[key] ?? [];
            final isFull = occupied.isNotEmpty;
            final isPartial = occupied.length >= 3;

            return Material(
              color: isFull
                  ? (isPartial
                      ? AppTheme.errorColor.withOpacity(0.15)
                      : AppTheme.primaryColor.withOpacity(0.12))
                  : AppTheme.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onDayTap == null ? null : () => onDayTap!(date),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isFull
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (occupied.isNotEmpty)
                      Text(
                        '${occupied.length}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (vacantBedLabels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vacantBedLabels
                .map(
                  (l) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'فاضي: $l',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  static const _wdStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppTheme.textSecondary,
  );
}
