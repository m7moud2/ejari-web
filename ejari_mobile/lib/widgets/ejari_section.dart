import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// عنوان قسم موحّد مع وصف اختياري وزر إجراء.
class EjariSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool light;

  const EjariSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppTheme.textPrimary;
    final subtitleColor =
        light ? Colors.white.withOpacity(0.72) : AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ),
            if (actionLabel != null)
              Material(
                color: light
                    ? Colors.white.withOpacity(0.14)
                    : AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: light ? Colors.white : AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

/// بطاقة سطحية موحّدة للمحتوى المنظم.
class EjariSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool elevated;

  const EjariSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceMd),
    this.radius = AppTheme.cardRadius,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.surfaceCardDecoration(
        radius: radius,
        elevated: elevated,
      ),
      child: child,
    );
  }
}

/// بلاطة إحصائية موحّدة للأرقام والمؤشرات.
class EjariStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;
  final bool compact;

  const EjariStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryColor;

    return Container(
      padding: EdgeInsets.all(compact ? 8 : AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius - 4),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: compact ? 16 : 20),
            SizedBox(height: compact ? 4 : 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: compact ? 12 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنصر قائمة موحّد داخل بطاقة سطحية.
class EjariListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool isLast;

  const EjariListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر خطوات للتدفقات متعددة المراحل (دفع، تسجيل، إلخ).
class EjariStepIndicator extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final bool light;

  const EjariStepIndicator({
    super.key,
    required this.labels,
    required this.activeIndex,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index <= activeIndex;
        final isDone = index < activeIndex;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (light
                                ? Colors.white
                                : AppTheme.primaryColor)
                            : (light
                                ? Colors.white.withOpacity(0.2)
                                : AppTheme.borderColor.withOpacity(0.5)),
                        shape: BoxShape.circle,
                        border: isActive && light
                            ? Border.all(
                                color: AppTheme.accentColor,
                                width: 2,
                              )
                            : null,
                        boxShadow: isActive && !light
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: light
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? (light
                                          ? AppTheme.primaryColor
                                          : Colors.white)
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.15,
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive
                            ? (light
                                ? Colors.white
                                : AppTheme.primaryColor)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: isDone
                          ? (light
                              ? AppTheme.accentColor.withOpacity(0.6)
                              : AppTheme.primaryColor.withOpacity(0.35))
                          : (light
                              ? Colors.white.withOpacity(0.2)
                              : AppTheme.borderColor.withOpacity(0.4)),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
