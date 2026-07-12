import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'help_center_screen.dart';
import '../main.dart';
import 'about_app_screen.dart';
import 'feedback_screen.dart';
import 'changelog_screen.dart';
import 'app_update_screen.dart';
import '../services/app_version_service.dart';
import '../services/share_app_service.dart';
import '../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/social_links.dart';
import 'package:local_auth/local_auth.dart'; // Add import
import '../services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = true;
  bool _darkMode = false;
  String _language = 'ar';
  Map<PushNotificationCategory, bool> _categoryStates = {};

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _language = localeNotifier.value.languageCode;
    _darkMode = themeNotifier.value == ThemeMode.dark;
    _loadBiometricState();
    _loadNotificationState();
    _loadCategoryStates();
  }

  Future<void> _loadCategoryStates() async {
    final states = await PushNotificationService.getCategoryStates();
    if (mounted) {
      setState(() => _categoryStates = states);
    }
  }

  Future<void> _loadNotificationState() async {
    final enabled = await PushNotificationService.isEnabled();
    if (mounted) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  Future<void> _loadBiometricState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

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
        title: const Text('الإعدادات'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildSectionHeader('الحسابات والتحويلات'),
          _buildListTile(
            title: 'تفاصيل استلام الأرباح',
            subtitle: 'إدارة السحب والتحويل البنكي',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('العامة'),
          _buildListTile(
            title: 'اللغة / Language',
            subtitle: _language == 'ar' ? 'العربية' : 'English',
            icon: Icons.language,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() => _language = val);
                  final countryCode = val == 'ar' ? 'SA' : 'US';
                  localeNotifier.value = Locale(val, countryCode);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language_code', val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val == 'ar'
                              ? 'تم تغيير اللغة إلى العربية'
                              : 'Language changed to English',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          _buildSwitchTile(
            title: 'الوضع الداكن',
            subtitle: _darkMode ? 'مفعّل — مريح للعين ليلاً' : 'الوضع الفاتح الافتراضي',
            icon: Icons.dark_mode_outlined,
            value: _darkMode,
            onChanged: (val) async {
              setState(() => _darkMode = val);
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', val);
            },
          ),
          _buildListTile(
            title: 'المظهر',
            subtitle: _darkMode ? 'الوضع الداكن مفعّل' : 'ألوان إيجاري الهادئة مفعّلة',
            icon: Icons.palette_outlined,
          ),
          const Divider(height: 32),
          _buildSectionHeader('الإشعارات والأمان'),
          _buildSwitchTile(
            title: 'الإشعارات',
            subtitle: 'تلقي تحديثات الحجز والعروض',
            icon: Icons.notifications,
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              await PushNotificationService.setEnabled(val);
              if (val) await _loadCategoryStates();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات',
                    ),
                  ),
                );
              }
            },
          ),
          if (_notificationsEnabled) ...[
            const Padding(
              padding: EdgeInsets.only(right: 4, bottom: 6, top: 4),
              child: Text(
                'فئات الإشعارات',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            ...PushNotificationCategory.values.map((cat) {
              final enabled = _categoryStates[cat] ?? true;
              return _buildSwitchTile(
                title: cat.labelAr,
                icon: Icons.notifications_active_outlined,
                value: enabled,
                onChanged: (val) async {
                  setState(() => _categoryStates[cat] = val);
                  await PushNotificationService.setCategoryEnabled(cat, val);
                },
              );
            }),
          ],
          _buildSwitchTile(
            title: 'تفعيل البصمة',
            subtitle: 'تسجيل الدخول باستخدام الوجه/البصمة',
            icon: Icons.fingerprint,
            value: _biometricsEnabled,
            onChanged: (val) async {
              if (val) {
                // Try to authenticate before enabling
                bool authenticated = false;
                try {
                  final canCheck = await auth.canCheckBiometrics;
                  if (canCheck) {
                    authenticated = await auth.authenticate(
                      localizedReason: 'يرجى تأكيد هويتك لتفعيل الدخول بالبصمة',
                      options: const AuthenticationOptions(stickyAuth: true),
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('جهازك لا يدعم البصمة أو غير مفعلة')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Biometric Error: $e');
                }

                if (authenticated) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('biometric_enabled', true);
                  setState(() => _biometricsEnabled = true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم تفعيل الدخول بالبصمة بنجاح ✅')),
                    );
                  }
                }
              } else {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('biometric_enabled', false);
                setState(() => _biometricsEnabled = false);
              }
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('الدعم'),
          _buildListTile(
            title: 'مركز المساعدة',
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen()));
            },
          ),
          _buildListTile(
            title: 'سياسة الخصوصية',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('سياسة الخصوصية'),
                  content: const Text(
                      'نحن نلتزم بحفظ بياناتك وخصوصيتك بأعلى معايير الأمان العالمية في إيجاري.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'))
                  ],
                ),
              );
            },
          ),
          _buildListTile(
            title: 'شاركنا رأيك',
            subtitle: 'تقييم التطبيق ومقترحاتك',
            icon: Icons.rate_review_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              );
            },
          ),
          _buildListTile(
            title: 'ما الجديد',
            subtitle: 'الإصدار ${AppConfig.versionLabel}',
            icon: Icons.new_releases_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangelogScreen()),
              );
            },
          ),
          _buildListTile(
            title: 'شارك التطبيق',
            subtitle: 'ادعُ أصدقاءك لتجربة إيجاري',
            icon: Icons.share_rounded,
            onTap: ShareAppService.shareInvite,
          ),
          _buildListTile(
            title: 'التحقق من التحديثات',
            subtitle: 'الإصدار ${AppConfig.versionLabel}',
            icon: Icons.system_update_alt_rounded,
            onTap: _checkForUpdates,
          ),
          _buildListTile(
            title: 'عن تطبيق إيجاري',
            subtitle: 'نسخة ${AppConfig.versionLabel}',
            icon: Icons.info_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('تابعنا'),
          _buildListTile(
            title: 'Facebook',
            subtitle: 'صفحة إيجاري الرسمية',
            icon: Icons.facebook_rounded,
            onTap: () => _launchUrl(SocialLinks.facebook),
          ),
          _buildListTile(
            title: 'LinkedIn',
            subtitle: 'ملف الشركة والفرص',
            icon: Icons.business_center_rounded,
            onTap: () => _launchUrl(SocialLinks.linkedin),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final latest = await AppVersionService.checkForUpdates();
    if (!mounted) return;
    if (latest == null || latest == AppVersionService.currentVersion) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أنت تستخدم أحدث إصدار (${AppVersionService.fullVersion})',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppUpdateScreen(
          currentVersion: AppVersionService.currentVersion,
          latestVersion: latest,
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.38)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/promo/hero_reviews.jpg',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryColor.withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'إعدادات إيجاري',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اضبط التجربة على ذوقك',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اللغة، الأمان، والإشعارات كلها تحت تحكمك من هنا.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final langLabel = _language == 'ar' ? 'العربية' : 'English';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_suggest_rounded,
                  color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'ملخص الإعدادات',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile('اللغة', langLabel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryTile(
                  'الأمان',
                  _biometricsEnabled ? 'البصمة مفعلة' : 'البصمة متوقفة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'الإشعارات',
                  _notificationsEnabled ? 'مفعلة' : 'متوقفة',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryTile(
                  'المظهر',
                  _darkMode ? 'داكن' : 'فاتح',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.28)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppTheme.primaryColor)
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.28)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: value ? AppTheme.primaryColor : AppTheme.textPrimary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
