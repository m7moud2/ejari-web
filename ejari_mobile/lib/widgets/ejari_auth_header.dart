import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft gradient backdrop for login / signup screens.
class EjariAuthShell extends StatelessWidget {
  final Widget child;

  const EjariAuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0A2E26),
            Color(0xFF0F3A30),
            Color(0xFF1B594B),
            Color(0xFFF0F4F2),
          ],
          stops: [0.0, 0.22, 0.48, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _glowOrb(220, AppTheme.accentColor.withOpacity(0.18)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _glowOrb(140, Colors.white.withOpacity(0.07)),
          ),
          Positioned(
            bottom: 180,
            left: -30,
            child: _glowOrb(100, AppTheme.primaryLight.withOpacity(0.25)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Premium branded header for auth screens.
class EjariAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool lightText;

  const EjariAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.lightText = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = lightText ? Colors.white : AppTheme.primaryColor;
    final subtitleColor =
        lightText ? Colors.white.withOpacity(0.82) : AppTheme.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إيجاري',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.45),
                    ),
                  ),
                  child: const Text(
                    'إيجار بثقة',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: titleColor,
            height: 1.15,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: subtitleColor,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentColor, Color(0xFFD4AF6A)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// Elevated white card wrapping auth form fields.
class EjariAuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const EjariAuthFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.surfaceCardDecoration(
        radius: 28,
        elevated: true,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.14),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
