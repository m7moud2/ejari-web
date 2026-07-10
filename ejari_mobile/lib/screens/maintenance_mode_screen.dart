import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MaintenanceModeScreen extends StatelessWidget {
  final String? estimatedTime;
  final String? message;

  const MaintenanceModeScreen({
    super.key,
    this.estimatedTime,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textPrimary,
      body: Stack(
        children: [
          // Luxury background effects
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.borderColor.withOpacity(0.1),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ejari Engineering Icon
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 4),
                      builder: (context, double value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ??
                                  Theme.of(context).cardColor.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.borderColor.withOpacity(0.3)),
                              boxShadow: const [],
                            ),
                            child: const Icon(Icons.settings_suggest_rounded,
                                size: 70, color: AppTheme.borderColor),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),

                    const Text(
                      'ترقية النظام',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      message ??
                          'نقوم حالياً بتحديث خوادم إيجاري لتوفير سرعة وأمان لا يضاهيان لاستثماراتك.',
                      style: const TextStyle(
                          fontSize: 15, color: Colors.white70, height: 1.6),
                      textAlign: TextAlign.center,
                    ),

                    if (estimatedTime != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: AppTheme.borderColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'العودة المتوقعة: $estimatedTime',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 64),

                    // Luxury progress
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                          color: AppTheme.borderColor, strokeWidth: 2),
                    ),
                    const SizedBox(height: 64),

                    // Premium Support
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ??
                              Theme.of(context).cardColor.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24)),
                      child: const Column(
                        children: [
                          Text('للاستفسارات العاجلة:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white54)),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.support_agent_rounded,
                                  size: 20, color: AppTheme.borderColor),
                              SizedBox(width: 8),
                              Text('19999 (VIP Line)',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
