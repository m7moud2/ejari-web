import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ErrorStateWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const ErrorStateWidget({
    super.key,
    required this.onRetry,
    this.errorMessage = 'حدث خطأ في الاتصال بالخادم',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 72, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                const Text(
                  'تعذر تحميل الصفحة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
