import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../ejari_section.dart';

/// رأس مضغوط موحّد: ترحيب + رقم الحساب + جرس الإشعارات.
class HomeCompactHeader extends StatelessWidget {
  final String greeting;
  final String? accountId;
  final String? subtitle;
  final String? badgeLabel;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final List<Widget>? trailing;

  const HomeCompactHeader({
    super.key,
    required this.greeting,
    this.accountId,
    this.subtitle,
    this.badgeLabel,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spaceMd,
        AppTheme.screenPadding,
        44,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0A2E26),
            Color(0xFF0F3A30),
            Color(0xFF1B594B),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badgeLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              const Spacer(),
              if (onNotificationTap != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onNotificationTap,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_rounded,
                          color: Colors.white, size: 22),
                      if (notificationCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (trailing != null) ...trailing!,
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            greeting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if ((accountId ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'EJR-$accountId',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// بلاطة سريعة في صف واحد (حتى 4 عناصر).
class HomeQuickLookTile {
  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color color;

  const HomeQuickLookTile({
    required this.label,
    required this.value,
    this.hint,
    required this.icon,
    required this.color,
  });
}

class HomeQuickLookRow extends StatelessWidget {
  final List<HomeQuickLookTile> tiles;

  const HomeQuickLookRow({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final items = tiles.take(4).toList();
    return EjariSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: AppTheme.spaceSm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Row(
            children: items.map((tile) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: compact ? 32 : 36,
                        height: compact ? 32 : 36,
                        decoration: BoxDecoration(
                          color: tile.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tile.icon, color: tile.color, size: compact ? 16 : 18),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tile.value,
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tile.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 8 : 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (tile.hint != null && !compact)
                        Text(
                          tile.hint!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            color: tile.color.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// إجراء أساسي في الشريط العلوي.
class HomePrimaryAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HomePrimaryAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class HomePrimaryActionRow extends StatelessWidget {
  final List<HomePrimaryAction> actions;

  const HomePrimaryActionRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final items = actions.take(4).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Row(
          children: items.map((action) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
                      decoration: AppTheme.surfaceCardDecoration(
                        radius: 14,
                        elevated: true,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: compact ? 32 : 36,
                            height: compact ? 32 : 36,
                            decoration: BoxDecoration(
                              color: action.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(action.icon, color: action.color, size: compact ? 18 : 20),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            action.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// قسم قابل للطي مع عنوان موحّد.
class HomeExpandableSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  const HomeExpandableSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<HomeExpandableSection> createState() => _HomeExpandableSectionState();
}

class _HomeExpandableSectionState extends State<HomeExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return EjariSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceSm,
                AppTheme.spaceSm,
                AppTheme.spaceSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: EjariSectionHeader(
                      title: widget.title,
                      subtitle: widget.subtitle,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                0,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
              ),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// رابط ثانوي صغير داخل قسم الحساب.
class HomeSecondaryLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const HomeSecondaryLink({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شبكة إجراءات ثانوية (للمالك/الأدمن).
class HomeActionGrid extends StatelessWidget {
  final List<({String label, IconData icon, Widget page})> actions;
  final int maxVisible;
  final VoidCallback? onMore;

  const HomeActionGrid({
    super.key,
    required this.actions,
    this.maxVisible = 6,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final visible = actions.take(maxVisible).toList();
    final hasMore = actions.length > maxVisible || onMore != null;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length + (hasMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spaceXs,
        mainAxisSpacing: AppTheme.spaceXs,
        mainAxisExtent: 68,
      ),
      itemBuilder: (context, index) {
        if (hasMore && index == visible.length) {
          return _gridTile(
            context,
            label: 'المزيد',
            icon: Icons.apps_rounded,
            onTap: onMore ?? () {},
          );
        }
        final action = visible[index];
        return _gridTile(
          context,
          label: action.label,
          icon: action.icon,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => action.page),
          ),
        );
      },
    );
  }

  Widget _gridTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: AppTheme.surfaceCardDecoration(
            radius: 14,
            elevated: false,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ورقة سفلية لإجراءات "المزيد".
Future<void> showHomeMoreSheet(
  BuildContext context, {
  required String title,
  required List<({String label, IconData icon, VoidCallback onTap})> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    item.onTap();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
