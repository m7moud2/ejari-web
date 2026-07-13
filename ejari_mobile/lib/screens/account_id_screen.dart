import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import 'account_id_search_screen.dart';

/// عرض رقم حساب المستخدم مع نسخ وبحث.
class AccountIdScreen extends StatefulWidget {
  const AccountIdScreen({super.key});

  @override
  State<AccountIdScreen> createState() => _AccountIdScreenState();
}

class _AccountIdScreenState extends State<AccountIdScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountId = _user?['accountId']?.toString() ?? '—';
    final name = _user?['name']?.toString() ?? 'مستخدم إيجاري';
    final email = _user?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('رقم الحساب',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              children: [
                EjariSurfaceCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppTheme.primaryColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spaceLg),
                      const Text(
                        'رقم حسابك في إيجاري',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        accountId,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      SizedBox(
                        width: double.infinity,
                        height: AppTheme.ctaHeight,
                        child: ElevatedButton.icon(
                          onPressed: accountId == '—'
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: accountId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ رقم الحساب'),
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy_rounded,
                              color: Colors.white),
                          label: const Text(
                            'نسخ رقم الحساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                EjariSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: EjariListTile(
                    title: 'البحث برقم حساب',
                    subtitle: 'ابحث عن مستخدم أو عقار برقم الحساب',
                    icon: Icons.search_rounded,
                    iconColor: AppTheme.accentColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountIdSearchScreen(),
                        ),
                      );
                    },
                    isLast: true,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                const Text(
                  'شارك الحساب يُستخدم للمشاركة مع المالك أو الدعم الفني للتحقق من هويتك بسرعة.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}
