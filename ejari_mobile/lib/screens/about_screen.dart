import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/social_links.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('من نحن'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'إيجاري (Ejari)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'منصتك الموثوقة للإيجارات الفاخرة',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vision
                  _buildSection(
                    'رؤيتنا',
                    'أن نكون المنصة الموثوقة في مصر لتسهيل الإيجار والحجز والدفع بين المستأجر والمالك.',
                    Icons.visibility,
                    AppTheme.primaryColor,
                  ),

                  // Mission
                  _buildSection(
                    'رسالتنا',
                    'نسعى لتوفير تجربة إيجار سلسة وآمنة من خلال منصة رقمية متكاملة تربط بين الملاك والمستأجرين، مع ضمان الشفافية والمصداقية في جميع المعاملات.',
                    Icons.flag,
                    AppTheme.primaryColor,
                  ),

                  // Values
                  const Text(
                    'قيمنا',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildValueCard(
                      'الثقة',
                      'نبني الثقة من خلال الشفافية والمصداقية',
                      Icons.verified_user),
                  _buildValueCard('الابتكار',
                      'نستخدم أحدث التقنيات لتحسين الخدمة', Icons.lightbulb),
                  _buildValueCard(
                      'الأمان', 'نضمن حماية بياناتك ومعاملاتك', Icons.security),
                  _buildValueCard(
                      'التميز', 'نسعى دائماً لتقديم أفضل تجربة', Icons.star),

                  const SizedBox(height: 32),

                  const Text(
                    'تابعنا',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          'Facebook',
                          Icons.facebook_rounded,
                          () => _launchUrl(SocialLinks.facebook),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          'LinkedIn',
                          Icons.business_center_rounded,
                          () => _launchUrl(SocialLinks.linkedin),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Statistics
                  const Text(
                    'إنجازاتنا',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard('10,000+', 'عقار', Icons.home)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              '50,000+', 'مستخدم', Icons.people)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              '5,000+', 'سيارة', Icons.directions_car)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildStatCard(
                              '98%', 'رضا العملاء', Icons.thumb_up)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Contact
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'تواصل معنا',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildContactRow(Icons.email, 'info@ejari.app'),
                        _buildContactRow(Icons.phone, '+20 123 456 7890'),
                        _buildContactRow(Icons.location_on, 'القاهرة، مصر'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
