import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../widgets/image_upload_widget.dart';
import 'enhanced_owner_home_screen.dart';
import 'provider_home_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? redirectToRole;
  const SignupScreen({super.key, this.redirectToRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;
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

  Future<void> _submit() async {
    if (_nationalIdImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى رفع صور الهوية لإتمام توثيق العضوية')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signUp({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'type': _userType,
        'isVerified': false,
        'documents': {
          'nationalId': _nationalIdImage,
          'selfie': _selfieImage,
          'proof': _proofImage,
        }
      });

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
              'أهلاً بك في كيو. يتم الآن مراجعة بياناتك لضمان الأمان والموثوقية قبل تفعيل الحساب.',
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
                  String roleToApply = widget.redirectToRole ?? _userType;
                  await AuthService.setUserRole(roleToApply);

                  if (roleToApply == 'owner') {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const EnhancedOwnerHomeScreen()),
                        (route) => false);
                  } else if (roleToApply == 'provider') {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ServiceProviderHomeScreen()),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            return Column(
              children: [
                _buildLinearProgress(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) =>
                            setState(() => _currentStep = index),
                        children: [
                          _buildStep1(),
                          _buildStep2(),
                          _buildStep3(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildLinearProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10, 30, 20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color:
                    isActive ? AppTheme.primaryColor : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContainer(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.primaryColor, height: 1.5)),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _buildStepContainer(
      title: 'بيانات حسابك',
      subtitle: 'أدخل معلوماتك الشخصية للبدء في تجهيز ملفك',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildMinimalTextField(
                controller: _nameController,
                label: 'الاسم الكامل',
                icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildMinimalTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                isEmail: true),
            const SizedBox(height: 20),
            _buildMinimalTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                isPhone: true),
            const SizedBox(height: 20),
            _buildMinimalTextField(
                controller: _passwordController,
                label: 'كلمة المرور الآمنة',
                icon: Icons.lock_outline,
                isPassword: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return _buildStepContainer(
      title: 'تحديد الهوية',
      subtitle: 'كيف تنوي استخدام كيو؟',
      child: Column(
        children: [
          _buildTypeCard('tenant', 'عميل (مستأجر)',
              'استأجر واستكشف أرقى العقارات', Icons.key_rounded),
          const SizedBox(height: 16),
          _buildTypeCard('owner', 'مستثمر (مالك)', 'أدر محفظتك العقارية بذكاء',
              Icons.domain_rounded),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildStepContainer(
      title: 'التوثيق القانوني',
      subtitle: 'حماية هويتك والحفاظ على مجتمع آمن وموثوق',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded,
                    color: AppTheme.primaryColor, size: 28),
                SizedBox(width: 16),
                Expanded(
                    child: Text(
                        'جميع البيانات والمستندات مشفرة بالكامل ولا يتم مشاركتها بموجب قانون السرية.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            height: 1.5))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ImageUploadWidget(
              label: 'بطاقة الهوية (الوجه الأمامي)',
              icon: Icons.badge_outlined,
              onImageSelected: (path) =>
                  setState(() => _nationalIdImage = path)),
          const SizedBox(height: 20),
          ImageUploadWidget(
              label: 'توثيق الحضور (سيلفي حي)',
              icon: Icons.face_rounded,
              onImageSelected: (path) => setState(() => _selfieImage = path)),
          const SizedBox(height: 20),
          ImageUploadWidget(
            label: _userType == 'owner'
                ? 'صك ملكية (اختياري لتوثيق الثقة)'
                : 'إثبات دخل (اختياري للإسراع)',
            icon: _userType == 'owner'
                ? Icons.description_outlined
                : Icons.account_balance_wallet_outlined,
            onImageSelected: (path) => setState(() => _proofImage = path),
          ),
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
          color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white.withOpacity(0.2) : Colors.white,
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
                              : AppTheme.primaryColor)),
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
        labelStyle: const TextStyle(color: AppTheme.primaryColor),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
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
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'مطلوب إكمال هذا الحقل' : null,
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: AppTheme.backgroundColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(
                  _currentStep == _totalSteps - 1
                      ? 'إتمام التسجيل وإرسال للمراجعة'
                      : 'المتابعة',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}
