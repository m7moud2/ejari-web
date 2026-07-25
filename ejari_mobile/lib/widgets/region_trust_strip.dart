import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/app_region.dart';
import '../services/region_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

/// Light, region-aware trust cues: verified, escrow, safety guide.
class RegionTrustStrip extends StatelessWidget {
  const RegionTrustStrip({
    super.key,
    this.verified = true,
    this.showEscrow = true,
    this.showSafetyLink = true,
    this.compact = false,
  });

  final bool verified;
  final bool showEscrow;
  final bool showSafetyLink;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppRegion>(
      valueListenable: RegionService.notifier,
      builder: (context, region, _) {
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        final chips = <Widget>[
          if (verified)
            _chip(
              icon: Icons.verified_rounded,
              label: ar ? 'موثّق' : 'Verified',
            ),
          if (showEscrow)
            _chip(
              icon: Icons.lock_rounded,
              label: ar
                  ? 'ضمان · ${CurrencyFormatter.symbolOf(region)}'
                  : 'Escrow · ${CurrencyFormatter.codeOf(region)}',
            ),
          if (showSafetyLink)
            InkWell(
              onTap: () async {
                final uri = Uri.parse(AppConfig.safetyUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: _chip(
                icon: Icons.shield_outlined,
                label: context.tr('safety_guide'),
                accent: true,
              ),
            ),
        ];

        return Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: 6,
          children: chips,
        );
      },
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    bool accent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.accentColor.withOpacity(0.12)
            : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: accent
              ? AppTheme.accentColor.withOpacity(0.35)
              : AppTheme.primaryColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 13 : 14,
            color: accent ? AppTheme.accentColor : AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
