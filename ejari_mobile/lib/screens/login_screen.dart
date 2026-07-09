import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../widgets/ejari_auth_header.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectToRole;
  final bool returnResult;
  const LoginScreen(
      {super.key, this.redirectToRole, this.returnResult = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showMoreOptions = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _authenticate() async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (!biometricEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('يرجى تفعيل المصادقة الحيوية من إعدادات النظام أولاً')),
        );
      }
      return;
    }

    bool authenticated = false;
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('المصادقة الحيوية غير متوفرة')));
        }
        return;
      }

      authenticated = await _localAuth.authenticate(
        localizedReason: 'الوصول الآمن إلى حسابك',
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } on PlatformException catch (e) {
      debugPrint("Biometric Error: $e");
      _handleSocialSuccess('عضو إيجاري (بيومتري)');
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      final user = await AuthService.login(
          'user@ejari.app', 'user123'); // Using demo user
      if (mounted && user != null) {
        String role = widget.redirectToRole ?? user['type'] ?? 'tenant';
        await AuthService.setUserRole(role);

        if (widget.returnResult) {
          navigator.pop(true);
          return;
        }

        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!AppConfig.demoMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تسجيل Google غير متاح حالياً')),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تسجيل Google متاح في نسخة التجربة')));
      }
      await Future.delayed(const Duration(milliseconds: 800));
      _handleSocialSuccess('مستخدم إيجاري (جوجل)');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
  }

  void _handleSocialSuccess(String name) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    // Set a mock user for social login if not already set
    await prefs.setString('current_user_email', 'social_user@ejari.app');

    if (mounted) {
      String role = widget.redirectToRole ?? 'tenant';
      await AuthService.setUserRole(role);

      if (widget.returnResult) {
        navigator.pop(true);
        return;
      }

      if (!mounted) return;
      navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  Future<void> _loginAsVisitor() async {
    final navigator = Navigator.of(context);
    await AuthService.setGuestMode(true);
    if (!mounted) return;
    if (widget.returnResult) {
      navigator.pop(false);
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: EjariAuthShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EjariAuthHeader(
                            title: 'مرحباً بعودتك',
                            subtitle:
                                'سجّل الدخول لمتابعة حجوزاتك وعقودك بأمان',
                          ),
                          const SizedBox(height: 28),
                          EjariAuthFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMinimalTextField(
                                  controller: _emailController,
                                  label: 'البريد الإلكتروني',
                                  icon: Icons.email_outlined,
                                  isEmail: true,
                                ),
                                const SizedBox(height: 20),
                                _buildMinimalTextField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text(
                                      'نسيت كلمة المرور؟',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            final navigator =
                                                Navigator.of(context);
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            if (_formKey.currentState!
                                                .validate()) {
                                              setState(() => _isLoading = true);
                                              try {
                                                final user =
                                                    await AuthService.login(
                                                  _emailController.text,
                                                  _passwordController.text,
                                                );
                                                if (!mounted) return;
                                                setState(
                                                    () => _isLoading = false);
                                                if (user != null) {
                                                  if (widget.redirectToRole !=
                                                      null) {
                                                    await AuthService.setUserRole(
                                                        widget.redirectToRole!);
                                                  }
                                                  if (widget.returnResult) {
                                                    if (!mounted) return;
                                                    navigator.pop(true);
                                                    return;
                                                  }
                                                  navigator.pushReplacement(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const HomeScreen(),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                setState(
                                                    () => _isLoading = false);
                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(e.toString()),
                                                    backgroundColor:
                                                        AppTheme.errorColor,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 3,
                                      shadowColor: AppTheme.primaryColor
                                          .withOpacity(0.35),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('دخول'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'مستخدم جديد؟',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'أنشئ حسابك',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          EjariAuthFormCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => setState(
                                    () => _showMoreOptions = !_showMoreOptions,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.tune_rounded,
                                          size: 18,
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _showMoreOptions
                                              ? 'إخفاء الخيارات'
                                              : 'خيارات إضافية',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Icon(
                                          _showMoreOptions
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_showMoreOptions) ...[
                                  const SizedBox(height: 8),
                                  _buildAltLoginTile(
                                    icon: Icons.g_mobiledata_rounded,
                                    label: 'تسجيل عبر Google',
                                    color: const Color(0xFF4285F4),
                                    onTap: _signInWithGoogle,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildAltLoginTile(
                                    icon: Icons.fingerprint_rounded,
                                    label: 'البصمة / الوجه',
                                    color: AppTheme.primaryColor,
                                    onTap: _authenticate,
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed:
                                        _isLoading ? null : _loginAsVisitor,
                                    child: const Text('الدخول كزائر'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (AppConfig.demoMode) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.accentColor.withOpacity(0.35),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: AppTheme.accentColor, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'وضع التجربة: استخدم الحسابات الجاهزة للاستكشاف.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAltLoginTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: color.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }

  // ignore: unused_element
  Widget _buildSocialCircularButton(IconData icon,
      {VoidCallback? onTap, bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryColor.withOpacity(0.5)
                  : AppTheme.backgroundColor,
              width: 1.5),
        ),
        child: Icon(icon,
            size: 28,
            color: isPrimary ? AppTheme.primaryColor : AppTheme.textPrimary),
      ),
    );
  }
}
