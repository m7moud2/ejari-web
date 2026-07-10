import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tenant_score_service.dart';
import 'ejari_section.dart';

/// بطاقة درجة المستأجر متعددة الأبعاد — للمالك عند قبول الحجز.
class TenantScoreCard extends StatelessWidget {
  final Map<String, dynamic> scoreData;

  const TenantScoreCard({super.key, required this.scoreData});

  factory TenantScoreCard.fromEmail(String tenantEmail) {
    return TenantScoreCard(scoreData: {'tenantEmail': tenantEmail});
  }

  @override
  Widget build(BuildContext context) {
    final email = scoreData['tenantEmail']?.toString() ?? '';
    if (email.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: TenantScoreService.getTenantScore(email),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final s = snap.data!;
        return EjariSurfaceCard(
          elevated: false,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    s['badge']?.toString() ?? '●',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'درجة المستأجر',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          s['summary']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (s['hasEnoughStays'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s['displayScore']}/5',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (s['isFlagged'] == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppTheme.errorColor, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تحذير: ${(s['fraudFlags'] as List?)?.join(', ') ?? 'سجل مشبوه'}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (s['dimensions'] is Map &&
                  (s['dimensions'] as Map).isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: TenantScoreService.dimensions.map((d) {
                    final val =
                        (s['dimensions'] as Map)[d.$1] as double? ?? 0;
                    if (val <= 0) return const SizedBox.shrink();
                    return _dimChip(d.$2, val);
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dimChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
