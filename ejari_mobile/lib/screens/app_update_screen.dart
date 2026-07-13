import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../theme/app_theme.dart';

class AppUpdateScreen extends StatelessWidget {
  final bool isForceUpdate; // true = must update, false = optional
  final String currentVersion;
  final String latestVersion;
  final String updateMessage;

  const AppUpdateScreen({
    super.key,
    this.isForceUpdate = false,
    this.currentVersion = '1.0.0',
    this.latestVersion = '1.1.0',
    this.updateMessage = 'إصدار جديد متاح مع تحسينات وميزات جديدة!',
  });

  Future<void> _openDownload() async {
    await AppVersionService.openUpdateDownload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Update Icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt,
                    size: 90,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  isForceUpdate ? 'تحديث مطلوب' : 'تحديث متاح',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Version Info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الإصدار الحالي: $currentVersion → الإصدار الجديد: $latestVersion',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Message
                Text(
                  updateMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openDownload,
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'تحديث الآن',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                // Skip Button (only if not force update)
                if (!isForceUpdate) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'تخطي الآن',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],

                // Force Update Warning
                if (isForceUpdate) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.borderColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'هذا التحديث إلزامي لمواصلة استخدام التطبيق',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.borderColor),
                          ),
                        ),
                      ],
                    ),
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
