import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/smart_pricing_service.dart';
import 'ejari_section.dart';

/// تلميح "السعر ده قليل/عالي" — مقارنة بمتوسط المنطقة.
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

        return EjariSurfaceCard(
          elevated: false,
          padding: const EdgeInsets.all(12),
          child: Row(
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
                      'متوسط المنطقة: ${a['areaAverage']} ج.م',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onApplySuggestion != null &&
                  a['verdict'] != 'fair')
                TextButton(
                  onPressed: onApplySuggestion,
                  child: Text(
                    '${a['suggestedPrice']} ج.م',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
