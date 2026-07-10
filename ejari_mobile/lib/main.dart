import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/firebase_service.dart';
import 'services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/maintenance_service.dart';
import 'services/wallet_service.dart';
import 'services/operations_feed_service.dart';

import 'screens/splash_screen.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/home_provider.dart';

// Global Notifiers
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> localeNotifier =
    ValueNotifier(const Locale('ar', 'SA'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe Firebase Initialization
  if (!AppConfig.demoMode) {
    try {
      await FirebaseService.initialize();
    } catch (e) {
      debugPrint('Firebase init skipped/failed safely: $e');
    }
  } else {
    debugPrint('Firebase initialization skipped in demo mode.');
  }

  // Initialize Push Notifications
  if (!AppConfig.demoMode) {
    try {
      await PushNotificationService.initialize();
    } catch (e) {
      debugPrint('Push notifications skipped/failed safely: $e');
    }
  }

  if (AppConfig.demoMode) {
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await DataService.initDemoReceipts();
    await MaintenanceService.initDemoRequests();
    await WalletService.init(userId: 'user@ejari.app');
    await WalletService.init(userId: 'owner@ejari.app');
    await WalletService.init(userId: 'tech@ejari.app');
    await DataService.initDemoJoinRequests();
    await OperationsFeedService.initDemoFeed();
  }

  // Load Saved Language Preference
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code');
    if (savedLang != null && (savedLang == 'ar' || savedLang == 'en')) {
      final countryCode = savedLang == 'ar' ? 'SA' : 'US';
      localeNotifier.value = Locale(savedLang, countryCode);
    }
  } catch (e) {
    debugPrint('Error loading language: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => PropertyProvider()..fetchAllProperties()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const EjariApp(),
    ),
  );
}

class EjariApp extends StatefulWidget {
  const EjariApp({super.key});

  @override
  State<EjariApp> createState() => _EjariAppState();
}

class _EjariAppState extends State<EjariApp> {
  Widget _startScreen = const SplashScreen();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() => _startScreen = const SplashScreen());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              title: 'إيجاري',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              locale: currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate, // <-- Custom Translation Engine
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar', 'SA'),
                Locale('en', 'US'),
              ],
              home: _startScreen,
            );
          },
        );
      },
    );
  }
}
