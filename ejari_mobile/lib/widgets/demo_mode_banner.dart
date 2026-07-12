import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// Subtle badge shown in demo builds so users know data is illustrative.
class DemoModeBanner extends StatelessWidget {
  final Widget child;

  const DemoModeBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return child;

    return Stack(
      children: [
        child,
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, top: 4),
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    AppConfig.environmentLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
