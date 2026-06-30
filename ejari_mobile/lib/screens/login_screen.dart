import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'admin_home_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_owner_home_screen.dart';
import 'provider_home_screen.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectToRole;
  const LoginScreen({super.key, this.redirectToRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _authenticate() async {
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
      _handleSocialSuccess('عضو كيو (بيومتري)');
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      final user = await AuthService.login(
          'user@keyo.app', 'user123'); // Using demo user
      if (mounted && user != null) {
        String role = widget.redirectToRole ?? user['type'] ?? 'tenant';
        await AuthService.setUserRole(role);

        Widget destination = const HomeScreen();
        if (role == 'provider') {
          destination = const ServiceProviderHomeScreen();
        } else if (role == 'owner') {
          destination = const EnhancedOwnerHomeScreen();
        }
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => destination));
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
      _handleSocialSuccess('مستخدم كيو (جوجل)');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
  }

  void _handleSocialSuccess(String name) async {
    final prefs = await SharedPreferences.getInstance();
    // Set a mock user for social login if not already set
    await prefs.setString('current_user_email', 'social_user@keyo.app');

    if (mounted) {
      String role = widget.redirectToRole ?? 'tenant';
      await AuthService.setUserRole(role);

      Widget destination = const HomeScreen();
      if (role == 'provider') {
        destination = const ServiceProviderHomeScreen();
      } else if (role == 'owner') {
        destination = const EnhancedOwnerHomeScreen();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => destination));
    }
  }

  Future<void> _loginAsVisitor() async {
    await AuthService.setGuestMode(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ابدأ رحلتك: بحث، حجز، عقد، وصيانة من مكان واحد',
                  style: TextStyle(
                      fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 50),

                // Minimalist Email Field
                _buildMinimalTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  isEmail: true,
                ),
                const SizedBox(height: 24),

                // Minimalist Password Field
                _buildMinimalTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('نسيت كلمة المرور؟',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);

                              try {
                                final user = await AuthService.login(
                                    _emailController.text,
                                    _passwordController.text);
                                if (!mounted) return;
                                setState(() => _isLoading = false);

                                if (user != null) {
                                  if (widget.redirectToRole != null) {
                                    await AuthService.setUserRole(
                                        widget.redirectToRole!);
                                  }

                                  if (!context.mounted) return;
                                  if (widget.redirectToRole == 'provider' ||
                                      user['type'] == 'provider' ||
                                      user['role'] == 'provider') {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ServiceProviderHomeScreen()));
                                  } else if (widget.redirectToRole == 'owner' ||
                                      user['type'] == 'owner' ||
                                      user['role'] == 'owner') {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const EnhancedOwnerHomeScreen()));
                                  } else if (user['type'] == 'admin' ||
                                      user['role'] == 'admin') {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminHomeScreen()));
                                  } else {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen()));
                                  }
                                }
                              } catch (e) {
                                setState(() => _isLoading = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppTheme.errorColor));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('دخول',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _loginAsVisitor,
                    child: const Text(
                      'الدخول كزائر',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Minimalist Social Login
                const Center(
                  child: Text('أو المتابعة باستخدام',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildSocialCircularButton(Icons.g_mobiledata_rounded,
                        onTap: _signInWithGoogle),
                    const SizedBox(width: 24),
                    _buildSocialCircularButton(Icons.apple),
                    const SizedBox(width: 24),
                    _buildSocialCircularButton(Icons.fingerprint_rounded,
                        onTap: _authenticate, isPrimary: true),
                  ],
                ),
                const SizedBox(height: 60),

                // Sign Up Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('مستخدم جديد؟',
                        style: TextStyle(color: AppTheme.primaryColor)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupScreen()));
                      },
                      child: const Text('أنشئ حسابك',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                if (AppConfig.demoMode)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.55),
                        ),
                      ),
                      child: const Text(
                        'للتجربة فقط: الحسابات الجاهزة تساعدك على استكشاف التطبيق بسرعة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                      ),
                    ),
                ),
                const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
        labelStyle: const TextStyle(color: AppTheme.primaryColor),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppTheme.primaryColor,
                    size: 20),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }

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
