import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // No Internet Icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 90,
                    color: AppTheme.borderColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'يبدو أن اتصالك بالإنترنت غير متاح.\nتحقق من اتصالك وحاول مرة أخرى.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onRetry ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.borderColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نصائح:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• تأكد من تفعيل Wi-Fi أو البيانات',
                          style: TextStyle(fontSize: 13)),
                      Text('• جرب الاتصال بشبكة أخرى',
                          style: TextStyle(fontSize: 13)),
                      Text('• أعد تشغيل جهازك', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
