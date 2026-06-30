import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'provider_home_screen.dart';
import 'enhanced_owner_home_screen.dart';
import 'admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    final bool isGuest = await AuthService.isGuestMode();
    final bool loggedIn = await AuthService.isLoggedIn();
    Widget destination = const OnboardingScreen();

    if (loggedIn) {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final role = await AuthService.getUserRole();
        if (role == 'provider') {
          destination = const ServiceProviderHomeScreen();
        } else if (role == 'owner') {
          destination = const EnhancedOwnerHomeScreen();
        } else if (role == 'admin') {
          destination = const AdminHomeScreen();
        } else {
          destination = const HomeScreen();
        }
      }
    } else if (isGuest) {
      destination = const HomeScreen();
    } else if (hasSeenOnboarding) {
      destination = const LoginScreen();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'كـــيـــو',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 40,
                          height: 2,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'إيجار أوضح • عقود أسهل • صيانة أسرع',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary.withOpacity(0.72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  'نسخة أولى للتجربة',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
