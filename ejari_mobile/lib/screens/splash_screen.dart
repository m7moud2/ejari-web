import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_image.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _exitController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _taglineFade;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 36.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _mainController.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    final bool isGuest = await AuthService.isGuestMode();
    final bool loggedIn = await AuthService.isLoggedIn();
    Widget destination = const OnboardingScreen();

    if (loggedIn || isGuest) {
      destination = const HomeScreen();
    } else if (hasSeenOnboarding) {
      destination = const LoginScreen();
    }

    await _exitController.forward();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = shortest < 340 ? 96.0 : 112.0;
    final titleSize = shortest < 340 ? 34.0 : 42.0;

    return Scaffold(
      body: FadeTransition(
        opacity: _exitFade,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A2E26),
                Color(0xFF0F3A30),
                Color(0xFF143D34),
                Color(0xFF1B594B),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -80,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 0.95 + (_pulseAnimation.value - 1) * 2,
                    child: _orb(280, AppTheme.accentColor.withOpacity(0.14)),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: _orb(240, Colors.white.withOpacity(0.05)),
              ),
              Positioned(
                top: MediaQuery.sizeOf(context).height * 0.32,
                left: -20,
                child: _orb(80, AppTheme.accentColor.withOpacity(0.2)),
              ),
              // Soft diagonal brand sheen
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.04),
                          Colors.transparent,
                          Colors.black.withOpacity(0.12),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_mainController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: logoSize + 28,
                                        height: logoSize + 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.accentColor
                                                .withOpacity(0.35),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: logoSize + 10,
                                        height: logoSize + 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.accentColor
                                                .withOpacity(0.18),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: logoSize,
                                        height: logoSize,
                                        padding: EdgeInsets.all(
                                            logoSize < 100 ? 18 : 22),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accentColor
                                                  .withOpacity(0.35),
                                              blurRadius: 32,
                                              spreadRadius: -4,
                                            ),
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: const EjariImage(
                                          path: 'assets/images/app_icon.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'إيجاري',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Opacity(
                                  opacity: _taglineFade.value,
                                  child: Column(
                                    children: [
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor
                                              .withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: AppTheme.accentColor
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: const Text(
                                          'إيجار أوضح • عقود أسهل • ثقة أكبر',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'من البحث حتى المعاينة والحجز والدفع',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Colors.white.withOpacity(0.72),
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
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
              Positioned(
                bottom: 48,
                left: 24,
                right: 24,
                child: AnimatedBuilder(
                  animation: _taglineFade,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _taglineFade.value * 0.95,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTheme.accentColor.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'جاهزون لتجربة إيجار أوضح',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
