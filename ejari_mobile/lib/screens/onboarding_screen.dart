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

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.body,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.chip,
    this.footnote,
  });

  final String title;
  final String body;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final String chip;
  final String? footnote;
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconPulse;

  static const List<_OnboardingSlide> _pages = [
    _OnboardingSlide(
      title: 'إيجار ذكي',
      body:
          'اكتشف وحدات قريبة وإقامات قصيرة بأسعار واضحة وموقع دقيق قبل ما تتحرك خطوة.',
      icon: Icons.travel_explore_rounded,
      gradient: [Color(0xFF0F3A30), Color(0xFF1B594B)],
      accent: Color(0xFFB58D3D),
      chip: 'قريب منك • إقامة قصيرة',
    ),
    _OnboardingSlide(
      title: 'معاينة وحجز',
      body:
          'احجز موعد معاينة، ثم أكمل الحجز بخطوات مرتبة من الاهتمام حتى التأكيد.',
      icon: Icons.event_available_rounded,
      gradient: [Color(0xFF143D34), Color(0xFF0F3A30)],
      accent: Color(0xFFD4AF6A),
      chip: 'معاينة → حجز → متابعة',
    ),
    _OnboardingSlide(
      title: 'دفع آمن',
      body:
          'ادفع عبر المحفظة بضمان واضح، واحصل على QR للدخول بعد إتمام العملية.',
      icon: Icons.account_balance_wallet_rounded,
      gradient: [Color(0xFF0A2E26), Color(0xFF1B594B)],
      accent: Color(0xFFB58D3D),
      chip: 'محفظة • ضمان • QR',
    ),
    _OnboardingSlide(
      title: 'صيانة وتتبع',
      body:
          'اطلب صيانة معتمدة وتابع الفني خطوة بخطوة حتى الإغلاق — كل شيء من نفس التطبيق.',
      icon: Icons.handyman_rounded,
      gradient: [Color(0xFF0F3A30), Color(0xFF143D34)],
      accent: Color(0xFFD4AF6A),
      chip: 'طلب • تتبع • إغلاق',
      footnote: 'إعلانات البيع للعرض فقط — بدون عمولة بيع',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  Future<void> _setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  Future<void> _goTo(Widget screen, {bool markSeen = true}) async {
    if (markSeen) await _setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    await AuthService.setGuestMode(true);
    await _goTo(const HomeScreen());
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 360;
    final short = size.height < 640;
    final isLast = _currentPage == _pages.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: page.gradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    narrow ? 14 : 20,
                    8,
                    narrow ? 14 : 20,
                    0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_pages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _goTo(const LoginScreen()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'تخطي',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _pages.length,
                        minHeight: 4,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        color: page.accent,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _SlideBody(
                        slide: _pages[index],
                        narrow: narrow,
                        short: short,
                        pulse: _iconPulse,
                        active: index == _currentPage,
                      );
                    },
                  ),
                ),
                _BottomPanel(
                  pageCount: _pages.length,
                  currentPage: _currentPage,
                  isLast: isLast,
                  narrow: narrow,
                  onNext: _next,
                  onStart: () => _goTo(const SignupScreen()),
                  onGuest: _continueAsGuest,
                  onLogin: () => _goTo(const LoginScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideBody extends StatelessWidget {
  const _SlideBody({
    required this.slide,
    required this.narrow,
    required this.short,
    required this.pulse,
    required this.active,
  });

  final _OnboardingSlide slide;
  final bool narrow;
  final bool short;
  final AnimationController pulse;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final iconBox = short ? 118.0 : (narrow ? 130.0 : 150.0);
    final halo = iconBox + (short ? 36 : 50);
    final titleSize = narrow ? 24.0 : (short ? 26.0 : 30.0);
    final bodySize = narrow ? 14.0 : 15.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final scale = active ? (0.98 + pulse.value * 0.04) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: halo,
                      height: halo,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: slide.accent.withOpacity(0.12),
                      ),
                    ),
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        slide.icon,
                        size: iconBox * 0.46,
                        color: slide.accent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: short ? 18 : 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: slide.accent.withOpacity(0.4)),
            ),
            child: Text(
              slide.chip,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: slide.accent,
                fontWeight: FontWeight.w800,
                fontSize: narrow ? 11 : 12,
              ),
            ),
          ),
          SizedBox(height: short ? 14 : 18),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              height: 1.6,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (slide.footnote != null) ...[
            const SizedBox(height: 12),
            Text(
              slide.footnote!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.pageCount,
    required this.currentPage,
    required this.isLast,
    required this.narrow,
    required this.onNext,
    required this.onStart,
    required this.onGuest,
    required this.onLogin,
  });

  final int pageCount;
  final int currentPage;
  final bool isLast;
  final bool narrow;
  final VoidCallback onNext;
  final VoidCallback onStart;
  final VoidCallback onGuest;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(narrow ? 12 : 16, 0, narrow ? 12 : 16, 14),
      padding: EdgeInsets.fromLTRB(
        narrow ? 16 : 22,
        18,
        narrow ? 16 : 22,
        14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: currentPage == index ? 28 : 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isLast)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.35),
                ),
                child: const Text('التالي'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.35),
                ),
                child: const Text('ابدأ'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onGuest,
                child: const Text('تصفح كزائر'),
              ),
            ),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('لدي حساب بالفعل'),
            ),
          ],
        ],
      ),
    );
  }
}
