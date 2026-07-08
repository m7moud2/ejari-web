import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../widgets/ejari_auth_header.dart';
import '../widgets/image_upload_widget.dart';

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
      await AuthService.signUp(payload);

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
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
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
                  String roleToApply = widget.redirectToRole ?? _userType;
                  await AuthService.setUserRole(roleToApply);

                  if (roleToApply == 'owner') {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false);
                  } else if (roleToApply == 'provider') {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false);
                  } else {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('البدء في الاستكشاف',
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: _previousStep,
        ),
        title: const Text('إنشاء حساب',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EjariAuthHeader(
                          title: _currentStep == 0
                              ? 'إنشاء حساب'
                              : 'توثيق الهوية',
                          subtitle: _currentStep == 0
                              ? 'أدخل بياناتك واختر نوع الحساب'
                              : 'ارفع المستندات الآن أو أكملها لاحقاً',
                        ),
                        const SizedBox(height: 20),
                        _buildLinearProgress(),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: constraints.maxHeight * 0.62,
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildLinearProgress() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLastStep)
              TextButton(
                onPressed: _isLoading ? null : () => _submit(skipVerification: true),
                child: const Text('تخطي الآن — أكمل التوثيق لاحقاً'),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
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
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isLastStep ? 'إنشاء الحساب' : 'متابعة',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
