import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'help_center_screen.dart';
import '../main.dart';
import 'about_app_screen.dart';
import 'feedback_screen.dart';
import 'package:local_auth/local_auth.dart'; // Add import
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = true;
  String _language = 'ar';

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _language = localeNotifier.value.languageCode;
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildSectionHeader('الحسابات والتحويلات'),
          _buildListTile(
            title: 'تفاصيل استلام الأرباح',
            subtitle: '01069813210 - InstaPay',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الحساب معتمد ومؤمن ✅')));
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
          _buildListTile(
            title: 'المظهر',
            subtitle: 'ألوان كيو الهادئة مفعّلة على التطبيق كله',
            icon: Icons.palette_outlined,
          ),
          const Divider(height: 32),
          _buildSectionHeader('الإشعارات والأمان'),
          _buildSwitchTile(
            title: 'الإشعارات',
            subtitle: 'تلقي تحديثات الحجز والعروض',
            icon: Icons.notifications,
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
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
                      'نحن نلتزم بحفظ بياناتك وخصوصيتك بأعلى معايير الأمان العالمية في كيو.'),
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
            title: 'عن تطبيق إيجاري',
            subtitle: 'نسخة 1.1.0',
            icon: Icons.info_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
            },
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
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
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
                child: _buildSummaryTile('النسخة', 'جاهزة'),
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
        color: AppTheme.backgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.only(bottom: 16),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.textPrimary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.primaryColor)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
    );
  }
}
