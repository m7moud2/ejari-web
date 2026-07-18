import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../config/social_links.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfig.demoMode
                ? 'تم تسجيل الطلب (وضع العرض). في الإنتاج يُرسل رابط إعادة التعيين للبريد.'
                : 'تم إرسال رابط إعادة التعيين إن وُجد حساب بهذا البريد.',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyAuthError(e)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse(SocialLinks.whatsappUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'استعادة الدخول',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _sent
                      ? 'تحقق من بريدك واتبع الرابط لإعادة تعيين كلمة المرور. إن لم تصلك رسالة خلال دقائق، راجع مجلد الرسائل غير المرغوبة أو تواصل مع الدعم.'
                      : 'أدخل بريدك الإلكتروني المسجّل وسنرسل رابطاً آمناً لإعادة تعيين كلمة المرور.',
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.primaryColor, height: 1.5),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sent,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: const TextStyle(color: AppTheme.primaryColor),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppTheme.primaryColor, size: 22),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب إكمال هذا الحقل';
                    }
                    if (!value.contains('@')) {
                      return 'أدخل بريداً إلكترونياً صالحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_sent ? () => Navigator.pop(context) : _sendResetLink),
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
                        : Text(
                            _sent ? 'العودة لتسجيل الدخول' : 'إرسال رابط التعيين',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                if (_sent) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _sent = false);
                              _sendResetLink();
                            },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة الإرسال'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: _openSupport,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('مساعدة عبر واتساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
