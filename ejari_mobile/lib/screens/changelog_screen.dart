import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<({String version, String date, List<String> items})>
      releases = [
    (
      version: '1.1.8',
      date: 'يوليو 2026',
      items: [
        'إصلاح تسجيل الدخول وإنشاء الحساب على أندرويد (وضع العرض)',
        'شات الدعم يعمل بدون إنترنت في النسخة التجريبية',
        'مهلة اتصال مع رسالة عربية وزر إعادة المحاولة',
        'عدم تعليق الواجهة عند فشل Firebase',
      ],
    ),
    (
      version: '1.1.7',
      date: 'يوليو 2026',
      items: [
        'تقرير شهري PDF للمالك',
        'تذكيرات الدفعات القادمة في محفظة المستأجر',
        'شاشة «ما الجديد» بالعربية',
        'مشاركة التطبيق برابط دعوة',
        'شارة «وضع العرض» في النسخة التجريبية',
        'تحضير Google Play وتوقيع الإصدار',
      ],
    ),
    (
      version: '1.1.6',
      date: 'يونيو 2026',
      items: [
        'مزامنة حية وروابط عميقة للإشعارات',
        'تصدير تقارير PDF يومية للإدارة',
        'تخزين مؤقت للعمل بدون اتصال',
        'إعلانات البيع — رسوم نشر فقط بدون عمولة',
        'تنظيم الشاشات الرئيسية حسب الدور',
      ],
    ),
    (
      version: '1.1.5',
      date: 'مايو 2026',
      items: [
        'محفظة المستأجر وكشوف الإيجار',
        'تذكيرات الدفع الجماعية للمالك',
        'مزامنة المفضلة عند تسجيل الدخول',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('ما الجديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.12),
                  AppTheme.accentColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.new_releases_rounded,
                      color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإصدار الحالي ${AppConfig.versionLabel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'آخر التحديثات والتحسينات في إيجاري',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...releases.map(_buildReleaseCard),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(
      ({String version, String date, List<String> items}) release) {
    final isCurrent = release.version == AppConfig.appVersion;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primaryColor.withOpacity(0.35)
              : AppTheme.borderColor.withOpacity(0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'الإصدار ${release.version}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'حالي',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  release.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...release.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
