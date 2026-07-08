import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/app_config.dart';

/// AuthService — يدعم 3 أوضاع:
/// 1) Firebase Auth + Firestore إذا ما فيش API محلي
/// 2) Express + MongoDB إذا الـ API متاح
/// 3) Local demo fallback لنسخة التجربة
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get _baseUrl {
    final configured = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    return configured.isNotEmpty ? configured : null;
  }
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
      'email': 'owner@ejari.app',
      'password': 'owner123',
      'role': 'owner',
    },
    {
      'name': 'مستأجر تجريبي',
      'email': 'user@ejari.app',
      'password': 'user123',
      'role': 'tenant',
    },
    {
      'name': 'فني صيانة تجريبي',
      'email': 'tech@ejari.app',
      'password': 'tech123',
      'role': 'provider',
    },
    {
      'name': 'مدير تجريبي',
      'email': 'admin@ejari.app',
      'password': 'admin123',
      'role': 'admin',
    },
  ];

  static bool get _useLocalAuth => AppConfig.demoMode;
  static bool get _useFirebaseAuth =>
      !AppConfig.demoMode &&
      _baseUrl == null &&
      Firebase.apps.isNotEmpty;

  static Map<String, dynamic> _buildLocalUser({
    required String name,
    required String email,
    required String role,
    String? password,
    bool offlineSignup = false,
  }) {
    return {
      'id': email,
      '_id': email,
      'name': name,
      'email': email,
      'role': role,
      'type': role,
      if (password != null) 'password': password,
      if (offlineSignup) 'offlineSignup': true,
    };
  }

  static Future<void> _storeLocalAccount(
    Map<String, dynamic> userData, {
    String token = 'local-demo-token',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email = (userData['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) return;

    await prefs.setString('user_$email', jsonEncode(userData));

    final users = prefs.getStringList(_usersListKey) ?? <String>[];
    if (!users.contains(email)) {
      users.add(email);
      await prefs.setStringList(_usersListKey, users);
    }

    await prefs.setString(_userRoleKey, userData['role'] ?? userData['type'] ?? 'tenant');
    await prefs.setString(_userIdKey, userData['id']?.toString() ?? email);
    await prefs.setString(_currentUserEmailKey, email);
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await prefs.setString(_userTokenKey, token);
    await prefs.setBool(_guestModeKey, false);
  }

  static Future<void> _storeFirebaseSession({
    required User firebaseUser,
    required Map<String, dynamic> profile,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email = (firebaseUser.email ?? profile['email'] ?? '').toString().trim().toLowerCase();
    final role = (profile['role'] ?? profile['type'] ?? 'tenant').toString();
    final rawUserData = <String, dynamic>{
      'id': firebaseUser.uid,
      '_id': firebaseUser.uid,
      'name': profile['name'] ?? firebaseUser.displayName ?? '',
      'email': email,
      'role': role,
      'type': role,
      ...profile,
    };
    final userData = <String, dynamic>{};
    rawUserData.forEach((key, value) {
      if (value == null) return;
      if (value is FieldValue) return;
      if (value is Timestamp) {
        userData[key] = value.toDate().toIso8601String();
        return;
      }
      if (value is DateTime) {
        userData[key] = value.toIso8601String();
        return;
      }
      if (value is Map || value is List || value is String || value is num || value is bool) {
        userData[key] = value;
      } else {
        userData[key] = value.toString();
      }
    });

    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, firebaseUser.uid);
    await prefs.setString(_currentUserEmailKey, email);
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await prefs.setString(_userTokenKey, token ?? await firebaseUser.getIdToken() ?? '');
    await prefs.setBool(_guestModeKey, false);
  }

  static Future<Map<String, dynamic>?> _getFirebaseProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return {
      ...data,
      'id': uid,
      '_id': uid,
    };
  }

  static Future<Map<String, dynamic>?> _findLocalAccount(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = email.trim().toLowerCase();

    final candidates = <Map<String, dynamic>>[
      ..._demoAccounts.map((a) => {
            'id': a['email'],
            '_id': a['email'],
            'name': a['name'],
            'email': a['email'],
            'role': a['role'],
            'type': a['role'],
            'password': a['password'],
          }),
    ];

    final storedRaw = prefs.getString('user_$normalizedEmail');
    if (storedRaw != null && storedRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(storedRaw);
        if (parsed is Map<String, dynamic>) {
          candidates.add(parsed);
        }
      } catch (_) {}
    }

    final match = candidates.cast<Map<String, dynamic>?>().firstWhere(
          (user) =>
              user?['email']?.toString().toLowerCase() == normalizedEmail &&
              user?['password'] == password,
          orElse: () => null,
        );
    return match;
  }

  // ─────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────
  static Future<bool> signUp(Map<String, dynamic> userData) async {
    if (_useLocalAuth) {
      final role = userData['type'] ?? 'tenant';
      final fallbackUser = _buildLocalUser(
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: role,
        password: userData['password'] ?? '',
        offlineSignup: true,
      );
      await _storeLocalAccount(
        fallbackUser,
        token: 'local-demo-token',
      );
      return true;
    }

    if (_useFirebaseAuth) {
      try {
        final email = (userData['email'] ?? '').toString().trim();
        final password = (userData['password'] ?? '').toString();
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final role = (userData['type'] ?? 'tenant').toString();
        final profile = <String, dynamic>{
          'name': userData['name'] ?? '',
          'email': email.toLowerCase(),
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? 'العنوان غير محدد',
          'role': role,
          'type': role,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        };

        await _firestore.collection('users').doc(credential.user!.uid).set(
              profile,
              SetOptions(merge: true),
            );
        await _storeFirebaseSession(
          firebaseUser: credential.user!,
          profile: profile,
        );
        return true;
      } catch (e) {
        debugPrint('Firebase SignUp Error: $e');
        rethrow;
      }
    }

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

      if (AppConfig.demoMode || isNetworkError || _baseUrl == null) {
        final role = userData['type'] ?? 'tenant';
        final fallbackUser = _buildLocalUser(
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: role,
          password: userData['password'] ?? '',
          offlineSignup: true,
        )..['status'] = 'pending_review';

        await _storeLocalAccount(
          fallbackUser,
          token: 'local-demo-token',
        );
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
    if (_useLocalAuth) {
      final localAccount = await _findLocalAccount(email, password);
      if (localAccount == null) {
        throw 'بيانات الدخول غير صحيحة';
      }

      final role = localAccount['role'] ?? localAccount['type'] ?? 'tenant';
      final user = _buildLocalUser(
        name: localAccount['name'] ?? 'مستخدم إيجاري',
        email: localAccount['email'] ?? email,
        role: role.toString(),
        password: localAccount['password'] ?? password,
        offlineSignup: localAccount['offlineSignup'] == true,
      )..addAll({
          if (localAccount['status'] != null) 'status': localAccount['status'],
        });

      await _storeLocalAccount(
        user,
        token: 'local-demo-token',
      );
      return user;
    }

    if (_useFirebaseAuth) {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw 'تعذر تسجيل الدخول';
      }

      final profile = await _getFirebaseProfile(firebaseUser.uid) ?? <String, dynamic>{
        'name': firebaseUser.displayName ?? 'مستخدم إيجاري',
        'email': firebaseUser.email ?? email,
        'role': 'tenant',
        'type': 'tenant',
      };

      final role = (profile['role'] ?? profile['type'] ?? 'tenant').toString();
      final user = <String, dynamic>{
        ...profile,
        'id': firebaseUser.uid,
        '_id': firebaseUser.uid,
        'role': role,
        'type': role,
      };
      await _storeFirebaseSession(
        firebaseUser: firebaseUser,
        profile: user,
      );
      return user;
    }

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
    if (email == 'admin@ejari.app' && password == 'admin123') {
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
    if (_firebaseAuth.currentUser != null) {
      await _firebaseAuth.signOut();
    }
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
    if (_firebaseAuth.currentUser != null) return true;
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
    final current = _firebaseAuth.currentUser;
    if (current != null) {
      final profile = await _getFirebaseProfile(current.uid);
      if (profile != null) {
        final role = (profile['role'] ?? profile['type'] ?? 'tenant').toString();
        return {
          ...profile,
          'id': current.uid,
          '_id': current.uid,
          'role': role,
          'type': role,
        };
      }
      return {
        'id': current.uid,
        '_id': current.uid,
        'name': current.displayName ?? 'مستخدم إيجاري',
        'email': current.email ?? '',
        'role': 'tenant',
        'type': 'tenant',
      };
    }
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
    if (_useLocalAuth) {
      final current = await getCurrentUser();
      if (current == null) return false;
      final merged = <String, dynamic>{...current, ...updatedData};
      await _storeLocalAccount(merged, token: 'local-demo-token');
      return true;
    }
    if (_useFirebaseAuth) {
      final current = _firebaseAuth.currentUser;
      if (current == null) return false;
      try {
        await _firestore.collection('users').doc(current.uid).set(
              updatedData,
              SetOptions(merge: true),
            );
        if (updatedData['name'] != null) {
          await current.updateDisplayName(updatedData['name'].toString());
        }
        final profile = await _getFirebaseProfile(current.uid) ?? updatedData;
        await _storeFirebaseSession(firebaseUser: current, profile: profile);
        return true;
      } catch (e) {
        debugPrint('Firebase Update Profile Error: $e');
        return false;
      }
    }
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
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      final emails = prefs.getStringList(_usersListKey) ?? <String>[];
      final users = <Map<String, dynamic>>[];
      for (final email in emails) {
        final raw = prefs.getString('user_$email');
        if (raw == null || raw.isEmpty) continue;
        try {
          final parsed = jsonDecode(raw);
          if (parsed is Map<String, dynamic>) users.add(parsed);
        } catch (_) {}
      }
      return users;
    }
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
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_$uid');
      if (raw == null || raw.isEmpty) return false;
      try {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        user['role'] = newRole;
        user['type'] = newRole;
        await prefs.setString('user_$uid', jsonEncode(user));
        final currentEmail = prefs.getString(_currentUserEmailKey);
        if (currentEmail == uid) {
          await _storeLocalAccount(user, token: 'local-demo-token');
        }
        return true;
      } catch (_) {
        return false;
      }
    }
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
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_$uid');
      if (raw == null || raw.isEmpty) return false;
      try {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        user['isBlocked'] = !(user['isBlocked'] == true);
        await prefs.setString('user_$uid', jsonEncode(user));
        return true;
      } catch (_) {
        return false;
      }
    }
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
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_$uid');
      if (raw == null || raw.isEmpty) return false;
      await prefs.remove('user_$uid');
      final users = prefs.getStringList(_usersListKey) ?? <String>[];
      users.remove(uid);
      await prefs.setStringList(_usersListKey, users);
      await logout();
      return true;
    }
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
