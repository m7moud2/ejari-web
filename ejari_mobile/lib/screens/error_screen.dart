import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.errorColor.withOpacity(0.1),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.1)),
                          boxShadow: const [],
                        ),
                        child: const Icon(Icons.error_outline_rounded,
                            size: 64, color: AppTheme.errorColor),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'حدث خطأ غير متوقع',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage ??
                            'واجه النظام مشكلة أثناء معالجة طلبك.\nنحن نعمل على استقرار الخدمة فوراً.',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            height: 1.6,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      if (onRetry != null)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            label: const Text('إعادة المحاولة',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.borderColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('العودة للخلف',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
