import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Optional first-run coach marks — dismissible per screen.
class FirstRunTooltips {
  static const String _prefix = 'tooltip_seen_';

  static Future<bool> shouldShow(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$screenKey') != true;
  }

  static Future<void> dismiss(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$screenKey', true);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

class FirstRunTooltipBanner extends StatefulWidget {
  final String screenKey;
  final String message;
  final IconData icon;

  const FirstRunTooltipBanner({
    super.key,
    required this.screenKey,
    required this.message,
    this.icon = Icons.tips_and_updates_outlined,
  });

  @override
  State<FirstRunTooltipBanner> createState() => _FirstRunTooltipBannerState();
}

class _FirstRunTooltipBannerState extends State<FirstRunTooltipBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final show = await FirstRunTooltips.shouldShow(widget.screenKey);
    if (mounted) setState(() => _visible = show);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await FirstRunTooltips.dismiss(widget.screenKey);
              if (mounted) setState(() => _visible = false);
            },
            tooltip: 'إخفاء',
          ),
        ],
      ),
    );
  }
}
