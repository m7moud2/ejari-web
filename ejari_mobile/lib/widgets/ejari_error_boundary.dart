import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Friendly fallback instead of the default red error screen.
class EjariErrorFallback extends StatelessWidget {
  final FlutterErrorDetails? details;

  const EjariErrorFallback({super.key, this.details});

  static void install() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      return EjariErrorFallback(details: details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'نعمل على إصلاح المشكلة. حاول إعادة تحميل الصفحة.',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode && details?.exceptionAsString().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    details!.exceptionAsString(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
