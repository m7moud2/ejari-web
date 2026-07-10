import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/trust_score_service.dart';

/// شارة درجة الثقة — تعرض المستوى والنقاط بشكل مختصر.
class TrustScoreBadge extends StatelessWidget {
  final Map<String, dynamic>? trustData;
  final bool compact;
  final bool light;
  final VoidCallback? onTap;

  const TrustScoreBadge({
    super.key,
    this.trustData,
    this.compact = false,
    this.light = false,
    this.onTap,
  });

  factory TrustScoreBadge.fromFuture({
    required Future<Map<String, dynamic>> future,
    bool compact = false,
    bool light = false,
    VoidCallback? onTap,
  }) {
    return TrustScoreBadge(
      trustData: null,
      compact: compact,
      light: light,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (trustData != null) {
      return _buildBadge(context, trustData!);
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: TrustScoreService.computeForCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return _buildBadge(context, snapshot.data!);
      },
    );
  }

  Widget _buildBadge(BuildContext context, Map<String, dynamic> data) {
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final level = data['level']?.toString() ?? 'مبتدئ';
    final badge = data['badge']?.toString() ?? '○';
    final color = _scoreColor(score);

    final child = compact
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: TextStyle(
                  color: light ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(light ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: light ? Colors.white : color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'درجة الثقة — $level',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: light ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      data['summary']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: light
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: child,
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.accentColor;
    if (score >= 60) return AppTheme.primaryColor;
    if (score >= 40) return const Color(0xFF2D6A5A);
    return AppTheme.textSecondary;
  }
}

/// بطاقة تفصيلية لدرجة الثقة في الملف الشخصي أو الرئيسية.
class TrustScoreCard extends StatelessWidget {
  final Map<String, dynamic> trustData;

  const TrustScoreCard({super.key, required this.trustData});

  @override
  Widget build(BuildContext context) {
    final score = (trustData['score'] as num?)?.toInt() ?? 0;
    final breakdown = List<Map<String, dynamic>>.from(
      trustData['breakdown'] ?? const [],
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: AppTheme.surfaceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TrustScoreBadge(trustData: trustData),
              ),
              const SizedBox(width: 8),
              Text(
                '$score/100',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSm),
            ...breakdown.map((item) {
              final pts = (item['points'] as num?)?.toInt() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['factor']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      pts >= 0 ? '+$pts' : '$pts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: pts >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
