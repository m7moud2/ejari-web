import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/app_config.dart';

/// AuthService — يتصل مباشرة بالباكند (Express + MongoDB)
/// لا يحتاج Firebase على الإطلاق
class AuthService {
  static String get _baseUrl => AppConfig.resolvedApiBaseUrl;
  static const String _userRoleKey = 'current_user_role';
  static const String _userTokenKey = 'user_token';
  static const String _userDataKey = 'user_data';
  static const String _userIdKey = 'user_id';
  static const String _currentUserEmailKey = 'current_user_email';
  static const String _usersListKey = 'users_list';
  static const String _guestModeKey = 'guest_mode';

  static const List<Map<String, String>> _demoAccounts = [
    {
      'name': 'مالك تجريبي',
      'email': 'owner@keyo.app',
      'password': 'owner123',
      'role': 'owner',
    },
    {
      'name': 'مستأجر تجريبي',
      'email': 'user@keyo.app',
      'password': 'user123',
      'role': 'tenant',
    },
    {
      'name': 'فني صيانة تجريبي',
      'email': 'tech@keyo.app',
      'password': 'tech123',
      'role': 'provider',
    },
    {
      'name': 'مدير تجريبي',
      'email': 'admin@keyo.app',
      'password': 'admin123',
      'role': 'admin',
    },
  ];

  // ─────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────
  static Future<bool> signUp(Map<String, dynamic> userData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': userData['name'] ?? '',
              'email': userData['email'] ?? '',
              'password': userData['password'] ?? '',
              'phone': userData['phone'] ?? '',
              'role': userData['type'] ?? 'tenant',
              'address': userData['address'] ?? 'العنوان غير محدد',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['user']?['role'] ?? userData['type'] ?? 'tenant';
        final token = data['token'] ?? '';
        final uid = data['user']?['_id'] ?? data['user']?['id'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userRoleKey, role);
        await prefs.setString(_userTokenKey, token);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_userDataKey, jsonEncode(data['user'] ?? {}));
        await prefs.setBool(_guestModeKey, false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw err['message'] ?? err['error'] ?? 'فشل التسجيل';
      }
    } catch (e) {
      debugPrint('SignUp Error: $e');
      final isNetworkError = e is TimeoutException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('HandshakeException');

      if (AppConfig.demoMode || isNetworkError) {
        final prefs = await SharedPreferences.getInstance();
        final role = userData['type'] ?? 'tenant';
        final uid = userData['email'] ?? 'local-user';
        final fallbackUser = {
          'id': uid,
          '_id': uid,
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'role': role,
          'type': role,
          'status': 'pending_review',
          'offlineSignup': true,
        };

        await prefs.setString(_userRoleKey, role);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_currentUserEmailKey, userData['email'] ?? '');
        await prefs.setString(_userDataKey, jsonEncode(fallbackUser));
        await prefs.setString(_userTokenKey, 'local-demo-token');
        await prefs.setBool(_guestModeKey, false);
        return true;
      }

      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    if (AppConfig.demoMode) {
      await initDemoAccounts();
      final normalizedEmail = email.trim().toLowerCase();
      final account = _demoAccounts.cast<Map<String, String>?>().firstWhere(
            (user) =>
                user?['email'] == normalizedEmail &&
                user?['password'] == password,
            orElse: () => null,
          );

      if (account == null) {
        throw 'بيانات الدخول غير صحيحة';
      }

      final user = <String, dynamic>{
        'id': account['email'],
        '_id': account['email'],
        'name': account['name'],
        'email': account['email'],
        'role': account['role'],
        'type': account['role'],
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, account['role']!);
      await prefs.setString(_userIdKey, account['email']!);
      await prefs.setString(_currentUserEmailKey, account['email']!);
      await prefs.setString(_userDataKey, jsonEncode(user));
      await prefs.setBool(_guestModeKey, false);
      return user;
    }

    // Admin shortcut — يدخل بدون اتصال بالشبكة
    if (email == 'admin@keyo.app' && password == 'admin123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, 'admin');
      await prefs.setString(_userDataKey,
          jsonEncode({'name': 'Admin', 'email': email, 'role': 'admin'}));
      await prefs.setBool(_guestModeKey, false);
      return {'name': 'Admin', 'email': email, 'role': 'admin'};
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>? ?? {};
        final role = user['role'] ?? 'tenant';
        final token = data['token'] ?? '';
        final uid = user['_id'] ?? user['id'] ?? '';

        if (user['isBlocked'] == true) {
          throw 'تم حظر هذا الحساب من قبل الإدارة';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userRoleKey, role);
        await prefs.setString(_userTokenKey, token);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_userDataKey, jsonEncode(user));
        await prefs.setBool(_guestModeKey, false);
        return user;
      } else {
        final err = jsonDecode(response.body);
        throw err['message'] ?? err['error'] ?? 'بيانات الدخول غير صحيحة';
      }
    } catch (e) {
      if (e is String) rethrow;
      debugPrint('Login Error: $e');
      throw 'تعذر الاتصال بالسيرفر، تحقق من الإنترنت';
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_guestModeKey);
  }

  // ─────────────────────────────────────────────
  // IS LOGGED IN
  // ─────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool(_guestModeKey) ?? false;
    if (isGuest) return false;
    final token = prefs.getString(_userTokenKey) ?? '';
    final userData = prefs.getString(_userDataKey) ?? '';
    return token.isNotEmpty || userData.isNotEmpty;
  }

  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  static Future<void> setGuestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, enabled);
    if (enabled) {
      await prefs.remove(_userTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userDataKey);
    }
  }

  // ─────────────────────────────────────────────
  // GET CURRENT USER
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userDataKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // GET USER ROLE
  // ─────────────────────────────────────────────
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey) ?? 'tenant';
  }

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  // ─────────────────────────────────────────────
  // GET TOKEN (for API calls)
  // ─────────────────────────────────────────────
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey) ?? '';
  }

  // ─────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────
  static Future<bool> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_userIdKey) ?? '';
      if (uid.isEmpty) return false;

      final response = await http
          .put(
            Uri.parse('$_baseUrl/users/$uid'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updatedData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString(_userDataKey, jsonEncode(data['user'] ?? data));
        return true;
      }
    } catch (e) {
      debugPrint('Update Profile Error: $e');
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // ADMIN: GET ALL USERS
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['users'] ?? data ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('Get All Users Error: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────
  // ADMIN: UPDATE USER ROLE
  // ─────────────────────────────────────────────
  static Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      final token = await getToken();
      final response = await http
          .put(
            Uri.parse('$_baseUrl/users/$uid'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'role': newRole}),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // ADMIN: TOGGLE BLOCK
  // ─────────────────────────────────────────────
  static Future<bool> toggleUserBlock(String uid) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$uid/block'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // DELETE ACCOUNT
  // ─────────────────────────────────────────────
  static Future<bool> deleteAccount(String uid) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$uid'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await logout();
        return true;
      }
    } catch (e) {
      debugPrint('Delete Account Error: $e');
    }
    return false;
  }

  static Future<void> initDemoAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_usersListKey) ?? <String>[];
    final users = {...existing, ..._demoAccounts.map((user) => user['email']!)};
    await prefs.setStringList(_usersListKey, users.toList()..sort());

    for (final account in _demoAccounts) {
      await prefs.setString(
        'user_${account['email']}',
        jsonEncode({
          'id': account['email'],
          '_id': account['email'],
          'name': account['name'],
          'email': account['email'],
          'role': account['role'],
          'type': account['role'],
        }),
      );
    }
  }

  static Future<void> clearAllData() async => logout();
}
