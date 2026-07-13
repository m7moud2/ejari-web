import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/ejari_auth_header.dart';
import '../widgets/ejari_section.dart';
import '../widgets/image_upload_widget.dart';
import '../config/app_config.dart';
import 'role_picker_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? redirectToRole;
  final bool returnResult;
  const SignupScreen(
      {super.key, this.redirectToRole, this.returnResult = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isPasswordVisible = false;
  String _userType = 'tenant';
  bool _isLoading = false;

  // Documents
  String? _nationalIdImage;
  String? _selfieImage;
  String? _proofImage;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit({bool skipVerification = false}) async {
    if (!skipVerification &&
        (_nationalIdImage == null || _selfieImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى رفع صور الهوية أو اضغط تخطي الآن')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'type': _userType,
        'isVerified': false,
      };
      if (!skipVerification) {
        payload['documents'] = {
          'nationalId': _nationalIdImage,
          'selfie': _selfieImage,
          'proof': _proofImage,
        };
      }
      await AuthService.signUp(payload).timeout(
        AppConfig.authTimeout,
        onTimeout: () =>
            throw 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyAuthError(e)),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'إعادة',
            textColor: Colors.white,
            onPressed: () => _submit(skipVerification: skipVerification),
          ),
        ),
      );
    }
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                color: AppTheme.primaryColor, size: 80),
            const SizedBox(height: 24),
            const Text('طلبك قيد المراجعة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userType == 'owner'
                    ? '💡 نصيحة: كمالك يمكنك إضافة عقاراتك ومتابعة الحجوزات من لوحة التحكم.'
                    : '💡 نصيحة: كمستأجر ابحث عن عقار، احجز، وادفع بأمان من التطبيق.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'أهلاً بك في إيجاري. يتم الآن مراجعة بياناتك لضمان الأمان والموثوقية قبل تفعيل الحساب.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.primaryColor, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (widget.returnResult) {
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                    return;
                  }
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RolePickerScreen(
                        initialRole: widget.redirectToRole ?? _userType,
                        userEmail: _emailController.text,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('اختر دورك وابدأ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
          onPressed: _previousStep,
        ),
      ),
      body: EjariAuthShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EjariAuthHeader(
                            title: _currentStep == 0
                                ? 'إنشاء حساب'
                                : 'توثيق الهوية',
                            subtitle: _currentStep == 0
                                ? 'أدخل بياناتك واختر نوع الحساب المناسب'
                                : 'ارفع المستندات الآن أو أكملها لاحقاً',
                          ),
                          const SizedBox(height: 22),
                          EjariStepIndicator(
                            labels: const ['البيانات', 'التوثيق'],
                            activeIndex: _currentStep,
                            light: true,
                          ),
                          const SizedBox(height: 20),
                          EjariAuthFormCard(
                            child: SizedBox(
                              height: constraints.maxHeight * 0.58,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) =>
                                    setState(() => _currentStep = index),
                                children: [
                                  _buildStep1(),
                                  _buildStep2(),
                                ],
                              ),
                            ),
                          ),
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
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildStepContainer(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _buildStepContainer(
      title: 'بيانات الحساب',
      subtitle: 'معلوماتك الأساسية ونوع الاستخدام',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildMinimalTextField(
                controller: _nameController,
                label: 'الاسم الكامل',
                icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildMinimalTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                isEmail: true),
            const SizedBox(height: 16),
            _buildMinimalTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                isPhone: true),
            const SizedBox(height: 16),
            _buildMinimalTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                icon: Icons.lock_outline,
                isPassword: true),
            const SizedBox(height: 24),
            _buildTypeCard('tenant', 'مستأجر',
                'ابحث واحجز وادفع بأمان', Icons.key_rounded),
            const SizedBox(height: 12),
            _buildTypeCard('owner', 'مالك عقار',
                'انشر وتابع حجوزاتك', Icons.domain_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return _buildStepContainer(
      title: 'التوثيق',
      subtitle: 'اختياري — يمكنك إكماله من الملف الشخصي',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: AppTheme.primaryColor, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المستندات مشفرة ولا تُشارك إلا للتحقق من الهوية.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ImageUploadWidget(
              label: 'بطاقة الهوية (الوجه الأمامي)',
              icon: Icons.badge_outlined,
              onImageSelected: (path) =>
                  setState(() => _nationalIdImage = path)),
          const SizedBox(height: 16),
          ImageUploadWidget(
              label: 'صورة سيلفي',
              icon: Icons.face_rounded,
              onImageSelected: (path) => setState(() => _selfieImage = path)),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
      String type, String title, String subtitle, IconData icon) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white70
                              : AppTheme.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 24),
          ],
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
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'مطلوب إكمال هذا الحقل' : null,
    );
  }

  Widget _buildBottomAction() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLastStep)
                TextButton(
                  onPressed:
                      _isLoading ? null : () => _submit(skipVerification: true),
                  child: const Text('تخطي الآن — أكمل التوثيق لاحقاً'),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (isLastStep) {
                            _submit();
                          } else {
                            _nextStep();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isLastStep ? 'إنشاء الحساب' : 'متابعة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
