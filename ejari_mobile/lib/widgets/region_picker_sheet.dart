import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_region.dart';
import '../providers/property_provider.dart';
import '../services/region_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Compact country picker used from onboarding and settings.
class RegionPickerSheet extends StatelessWidget {
  const RegionPickerSheet({super.key, this.onSelected});

  final ValueChanged<AppRegion>? onSelected;

  static Future<AppRegion?> show(BuildContext context) {
    return showModalBottomSheet<AppRegion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (_) => const RegionPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final current = RegionService.current;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space20,
          AppTheme.space16,
          AppTheme.space20,
          AppTheme.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('choose_region'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: AppTheme.weightHeavy,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              context.tr('choose_region_hint'),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            ...AppRegion.values.map((region) {
              final selected = region == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space8),
                child: Material(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.08)
                      : AppTheme.inputFillColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final propertyProvider = context.read<PropertyProvider>();
                      await RegionService.setRegion(region);
                      try {
                        await propertyProvider.fetchAllProperties();
                      } catch (_) {}
                      onSelected?.call(region);
                      navigator.pop(region);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region.displayName(arabic: ar),
                                  style: const TextStyle(
                                    fontWeight: AppTheme.weightBold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${region.currencyCode} · ${CurrencyFormatter.symbolOf(region)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            region.demoCitiesAr.take(2).join(' · '),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
