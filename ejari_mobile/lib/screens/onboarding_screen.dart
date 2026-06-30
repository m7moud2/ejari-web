import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'اختار مكانك بثقة',
      'body':
          'شوف التفاصيل المهمة، الصور، السعر، والموقع، وحالة التوفر قبل ما تضيع وقتك في زيارات غير مناسبة.',
      'icon': Icons.home_work_outlined,
    },
    {
      'title': 'اعرف العربون قبل ما تدفع',
      'body':
          'المعاينة أو الحجز يتم بعربون واضح، واستكمال المبلغ أو استرداده يكون مفهومًا ومعلنًا من البداية.',
      'icon': Icons.event_available_outlined,
    },
    {
      'title': 'عقد وصيانة في مكان واحد',
      'body':
          'بعد السكن، تقدر تتابع العقود والمدفوعات وطلبات الصيانة من نفس التطبيق من غير لف ودوران.',
      'icon': Icons.verified_user_outlined,
    },
  ];

  Future<void> _setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  Future<void> _goTo(Widget screen, {bool markSeen = true}) async {
    if (markSeen) {
      await _setOnboardingSeen();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    await AuthService.setGuestMode(true);
    await _goTo(const HomeScreen());
  }

  Future<void> _goToLogin() async => _goTo(const LoginScreen());

  Future<void> _goToSignup() async => _goTo(const SignupScreen());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _goToLogin,
            child: const Text('تخطي',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const BouncingScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentColor.withOpacity(0.6),
                                ),
                              ),
                              child: Icon(
                                _pages[index]['icon'] as IconData,
                                size: 44,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              _pages[index]['title'] as String,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _pages[index]['body'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.8,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
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

          // Custom Elegant Bottom Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(left: 6),
                      height: 4,
                      width: _currentPage == index ? 24 : 4,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.borderColor
                            : AppTheme.primaryColor.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentPage != _pages.length - 1)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('التالي',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 16)
                        ],
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _continueAsGuest,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('تصفح كزائر',
                              style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goToSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('إنشاء حساب',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text('لدي حساب بالفعل',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
