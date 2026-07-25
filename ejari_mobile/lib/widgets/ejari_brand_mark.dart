import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact in-app brand mark (green field + gold accent bar).
///
/// Reuses brand colors without regenerating binary launcher icons.
class EjariBrandMark extends StatelessWidget {
  const EjariBrandMark({
    super.key,
    this.size = 36,
    this.showWordmark = false,
    this.wordmarkColor,
    this.compact = false,
  });

  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EjariMarkPainter()),
    );

    if (!showWordmark) return mark;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: compact ? AppTheme.spaceXs : AppTheme.spaceSm),
        Text(
          isAr ? 'إيجاري' : 'Ejari',
          style: TextStyle(
            color: wordmarkColor ?? AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 16 : 20,
            letterSpacing: isAr ? 0 : 0.2,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _EjariMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(r, Paint()..color = AppTheme.primaryColor);

    final accent = Paint()
      ..color = AppTheme.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.28,
        size.width * 0.55,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.68,
        size.width * 0.78,
        size.height * 0.38,
      );
    canvas.drawPath(path, accent);

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.32),
      size.width * 0.06,
      Paint()..color = AppTheme.accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
