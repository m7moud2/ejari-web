import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';

class AuthGate {
  static Future<bool> requireLogin(BuildContext context,
      {String actionLabel = 'هذه العملية'}) async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) return true;

    if (!context.mounted) return false;

    final goToLogin = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'العملية دي تحتاج تسجيل دخول',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'عشان $actionLabel، لازم تدخل بحسابك أو تنشئ حساب جديد أولًا.',
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('تسجيل الدخول'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('إنشاء حساب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return false;

    final route = MaterialPageRoute(
      builder: (context) =>
          (goToLogin ?? true) ? const LoginScreen() : const SignupScreen(),
    );
    await Navigator.push(context, route);
    return false;
  }
}
