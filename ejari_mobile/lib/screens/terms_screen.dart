import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشروط والأحكام'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'شروط وأحكام استخدام منصة إيجاري',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'آخر تحديث: ديسمبر 2024',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '0. حالة الإصدار الحالي',
              '''هذه النسخة من منصة إيجاري مخصصة للإطلاق والتشغيل التدريجي. يتم تحديث الخدمات والميزات بشكل مستمر لتحسين التجربة.
بناءً عليه:
• قد تختلف بعض التفاصيل التشغيلية حسب نوع الخدمة.
• جميع العروض والخدمات المقدمة تخضع لسياسات المنصة المعتمدة.
• يحق للمنصة تعديل أو إيقاف أي خدمة عند الحاجة مع الحفاظ على سلامة المستخدمين.''',
            ),
            _buildSection(
              '1. القبول بالشروط',
              'باستخدامك لمنصة إيجاري، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام المنصة.',
            ),
            _buildSection(
              '2. التسجيل والحساب',
              '''• يجب أن تكون بالغاً (18 عاماً أو أكثر) لاستخدام المنصة
• يجب تقديم معلومات صحيحة ودقيقة عند التسجيل
• أنت مسؤول عن الحفاظ على سرية حسابك وكلمة المرور
• يجب إخطارنا فوراً بأي استخدام غير مصرح به لحسابك''',
            ),
            _buildSection(
              '3. الخدمات المقدمة',
              '''تقدم منصة إيجاري الخدمات التالية:
• إيجار العقارات السكنية والتجارية
• تأجير السيارات
• خدمات الصيانة والنظافة
• خدمات النقل والتخزين
• إدارة العقود والمدفوعات''',
            ),
            _buildSection(
              '4. المسؤوليات',
              '''• الملاك مسؤولون عن دقة المعلومات المقدمة عن عقاراتهم
• المستأجرون مسؤولون عن الالتزام بشروط العقد
• المنصة ليست طرفاً في العقود بين الملاك والمستأجرين
• المنصة تعمل كوسيط لتسهيل المعاملات''',
            ),
            _buildSection(
              '5. الدفع والرسوم',
              '''• جميع الأسعار معروضة بالجنيه المصري
• يتم خصم عمولة من كل معاملة ناجحة
• المدفوعات آمنة ومشفرة
• سياسة الاسترجاع تطبق حسب نوع الخدمة''',
            ),
            _buildSection(
              '6. الإلغاء والاسترجاع',
              '''• يمكن إلغاء الحجوزات قبل 48 ساعة من الموعد
• رسوم الإلغاء تطبق حسب وقت الإلغاء
• استرجاع الأموال يتم خلال 7-14 يوم عمل
• بعض الخدمات غير قابلة للاسترجاع''',
            ),
            _buildSection(
              '7. الخصوصية وحماية البيانات',
              '''• نحن ملتزمون بحماية خصوصيتك
• البيانات الشخصية تُستخدم فقط لتقديم الخدمة
• لا نشارك بياناتك مع أطراف ثالثة بدون إذنك
• يمكنك طلب حذف بياناتك في أي وقت''',
            ),
            _buildSection(
              '8. السلوك المقبول',
              '''يُمنع استخدام المنصة في:
• نشر محتوى مخالف أو غير قانوني
• الاحتيال أو التضليل
• انتحال الشخصية
• إزعاج المستخدمين الآخرين
• أي نشاط يضر بالمنصة أو مستخدميها''',
            ),
            _buildSection(
              '9. حقوق الملكية الفكرية',
              '''• جميع المحتويات على المنصة محمية بحقوق النشر
• لا يجوز نسخ أو توزيع المحتوى بدون إذن
• الشعارات والعلامات التجارية ملك لإيجاري''',
            ),
            _buildSection(
              '10. إنهاء الخدمة',
              '''• يحق لنا تعليق أو إنهاء حسابك عند مخالفة الشروط
• يمكنك حذف حسابك في أي وقت
• بعض الالتزامات تستمر حتى بعد إنهاء الحساب''',
            ),
            _buildSection(
              '11. تحديد المسؤولية',
              '''• المنصة تُقدم "كما هي" بدون ضمانات
• لا نتحمل مسؤولية الأضرار غير المباشرة
• مسؤوليتنا محدودة بقيمة الخدمة المدفوعة''',
            ),
            _buildSection(
              '12. التعديلات',
              '''• نحتفظ بالحق في تعديل هذه الشروط في أي وقت
• سيتم إخطارك بالتغييرات الجوهرية
• استمرارك في استخدام المنصة يعني قبولك للتعديلات''',
            ),
            _buildSection(
              '13. القانون الحاكم',
              'تخضع هذه الشروط لقوانين جمهورية مصر العربية. أي نزاع يُحل من خلال المحاكم المصرية المختصة.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.contact_support,
                      color: AppTheme.primaryColor, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'لديك استفسار؟',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تواصل معنا على: support@ejari.app',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
