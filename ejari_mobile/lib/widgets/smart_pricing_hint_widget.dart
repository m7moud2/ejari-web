import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/smart_pricing_service.dart';
import 'ejari_section.dart';

/// تلميح تسعير ذكي — مقارنة منطقة، تعديل مقترح، موسمي، وتوقع إيراد.
class SmartPricingHintWidget extends StatelessWidget {
  final String propertyId;
  final double listedPrice;
  final String? location;
  final VoidCallback? onApplySuggestion;

  const SmartPricingHintWidget({
    super.key,
    required this.propertyId,
    required this.listedPrice,
    this.location,
    this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SmartPricingService.analyzePrice(
        propertyId: propertyId,
        listedPrice: listedPrice,
        location: location,
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final a = snap.data!;
        final color = _colorForVerdict(a['color']?.toString() ?? 'blue');
        final trends = List<Map<String, dynamic>>.from(a['trends'] as List? ?? []);
        final forecast = (listedPrice * 1.06).round();

        return EjariSurfaceCard(
          elevated: false,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.insights_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['verdictAr']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          'متوسط ${a['location']}: ${a['areaAverage']} ج.م',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onApplySuggestion != null && a['verdict'] != 'fair')
                    TextButton(
                      onPressed: onApplySuggestion,
                      child: Text(
                        '${a['suggestedPrice']} ج.م',
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chip('تعديل مقترح', '${a['suggestedPrice']} ج.م', color),
                  _chip('توقع الشهر', '$forecast ج.م', AppTheme.primaryColor),
                  _chip('موسم الصيف', '+8%', AppTheme.accentColor),
                ],
              ),
              if (trends.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'اتجاه المنطقة: ${_trendLabel(trends)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  String _trendLabel(List<Map<String, dynamic>> trends) {
    if (trends.length < 2) return 'مستقر';
    final first = (trends.first['value'] as num?)?.toDouble() ?? 0;
    final last = (trends.last['value'] as num?)?.toDouble() ?? 0;
    if (last > first * 1.05) return 'صاعد ↑';
    if (last < first * 0.95) return 'هابط ↓';
    return 'مستقر →';
  }

  Color _colorForVerdict(String c) {
    switch (c) {
      case 'red':
      case 'orange':
        return AppTheme.errorColor;
      case 'green':
      case 'teal':
        return const Color(0xFF2D6A5A);
      default:
        return AppTheme.primaryColor;
    }
  }
}
