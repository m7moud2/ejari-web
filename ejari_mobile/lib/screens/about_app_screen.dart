import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/social_links.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('عن تطبيق إيجاري',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo and Version
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.real_estate_agent_rounded,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'إيجاري - Ejari',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الإصدار ${AppConfig.versionLabel}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Mission Statement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppTheme.primaryColor, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'رؤيتنا',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تسهيل رحلة الإيجار من أول البحث والحجز لحد العقد والصيانة. إيجاري يجمع المستأجر والمالك ومقدّم الخدمة في تجربة واحدة أوضح وأسرع.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trust List
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ماذا يضمن لك إيجاري؟',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.verified_outlined,
              'وضوح قبل القرار',
              'تفاصيل العقار والصور والخريطة في مكان واحد.',
            ),
            _buildFeatureItem(
              Icons.verified_user_outlined,
              'إجراءات مفهومة',
              'خطوات الحجز والعقد والصيانة كلها منظمة.',
            ),
            _buildFeatureItem(
              Icons.support_agent_rounded,
              'دعم عند الحاجة',
              'سهولة الوصول للمساعدة والمتابعة بدون تعقيد.',
            ),
            const SizedBox(height: 32),

            // Contact & Social
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'تواصل معنا',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                      Icons.email_outlined, 'البريد الإلكتروني', () {
                    _launchUrl(SocialLinks.mailtoSupport);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialButton(
                      Icons.language_rounded, 'الموقع الإلكتروني', () {
                    _launchUrl('https://ejari.app');
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                      Icons.facebook_rounded, 'Facebook', () {
                    _launchUrl(SocialLinks.facebook);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialButton(
                      Icons.business_center_rounded, 'LinkedIn', () {
                    _launchUrl(SocialLinks.linkedin);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Footer
            const Text(
              'صُنع لتسهيل رحلة السكن',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
