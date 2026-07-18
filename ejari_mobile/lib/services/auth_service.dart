import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/app_config.dart';
import '../utils/account_id_service.dart';
import '../utils/api_client.dart';
import 'wallet_service.dart';

/// AuthService — يدعم 3 أوضاع:
/// 1) Firebase Auth + Firestore إذا ما فيش API محلي
/// 2) Express + MongoDB إذا الـ API متاح
/// 3) Local demo fallback لنسخة التجربة
class AuthService {
  static FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

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
      'accountId': 'EJR-100003',
    },
    {
      'name': 'مستأجر تجريبي',
      'email': 'user@ejari.app',
      'password': 'user123',
      'role': 'tenant',
      'accountId': 'EJR-100002',
    },
    {
      'name': 'فني صيانة تجريبي',
      'email': 'tech@ejari.app',
      'password': 'tech123',
      'role': 'provider',
      'accountId': 'EJR-100004',
    },
    {
      'name': 'مدير تجريبي',
      'email': 'admin@ejari.app',
      'password': 'admin123',
      'role': 'admin',
      'accountId': 'EJR-100001',
    },
  ];

  static List<Map<String, String>> get demoAccounts =>
      List.unmodifiable(_demoAccounts);

  /// Local SharedPreferences auth — demo / debug only.
  static bool get _useLocalAuth => AppConfig.demoMode;
  /// Real Firebase Auth when not in demo and Firebase initialized.
  /// Prefer Firebase over optional Express API when no API_BASE_URL is set.
  static bool get _useFirebaseAuth =>
      !AppConfig.demoMode && Firebase.apps.isNotEmpty && _baseUrl == null;

  /// Firebase Auth codes that mean Email/Password (or Auth) is not configured.
  static const Set<String> _authConfigurationCodes = {
    'configuration-not-found',
    'operation-not-allowed',
    'admin-restricted-operation',
  };

  static bool _isAuthConfigurationError(Object e) {
    if (e is FirebaseAuthException) {
      return _authConfigurationCodes.contains(e.code);
    }
    final text = e.toString().toLowerCase();
    return text.contains('configuration-not-found') ||
        text.contains('operation-not-allowed') ||
        text.contains('auth/configuration-not-found');
  }

  /// Credential mismatches should not be remapped to "check connection".
  static bool _isCredentialAuthError(Object e) {
    if (e is FirebaseAuthException) {
      return const {
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'invalid-email',
        'weak-password',
        'email-already-in-use',
        'user-disabled',
      }.contains(e.code);
    }
    return false;
  }

  /// Public Arabic mapping for UI — never show raw Firebase codes to users.
  static String friendlyAuthError(Object e) => _arabicFirebaseAuthError(e);

  static String _arabicFirebaseAuthError(Object e) {
    if (e is TimeoutException) {
      return 'انتهت مهلة الاتصال. جرّب حساب التجربة أو تحقق من الإنترنت';
    }
    if (_isAuthConfigurationError(e)) {
      return 'خدمة Firebase غير مفعّلة بعد. استخدم حسابات التجربة أو سجّل محلياً.';
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'هذا البريد مسجّل مسبقاً. سجّل الدخول أو استخدم بريداً آخر';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح';
        case 'weak-password':
          return 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'بيانات الدخول غير صحيحة';
        case 'user-disabled':
          return 'تم تعطيل هذا الحساب';
        case 'too-many-requests':
          return 'محاولات كثيرة. انتظر قليلاً ثم حاول مرة أخرى';
        case 'network-request-failed':
        case 'unavailable':
        case 'internal-error':
          return 'تعذر الاتصال بالخادم. جرّب حسابات التجربة أو أعد المحاولة';
        case 'missing-email':
          return 'أدخل البريد الإلكتروني أولاً';
        default:
          return 'تعذر إتمام العملية. جرّب حسابات التجربة أو أعد المحاولة';
      }
    }
    final text = e.toString();
    if (text.contains('firebase_auth/') || text.contains('FirebaseAuthException')) {
      return 'تعذر إتمام العملية. جرّب حسابات التجربة أو أعد المحاولة';
    }
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('HandshakeException') ||
        text.contains('network')) {
      return 'تعذر الاتصال. جرّب حسابات التجربة أو تحقق من الإنترنت';
    }
    if (e is String && e.trim().isNotEmpty) {
      // Strip accidental Exception: / Error prefixes and raw Firebase codes.
      var cleaned = e.trim();
      cleaned = cleaned.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
      if (cleaned.contains('firebase_auth/') ||
          cleaned.contains('configuration-not-found')) {
        return 'خدمة Firebase غير مفعّلة بعد. استخدم حسابات التجربة أو سجّل محلياً.';
      }
      return cleaned;
    }
    return 'تعذر إتمام العملية. جرّب حسابات التجربة أو أعد المحاولة';
  }

  static String _accountIdFromUid(String uid) {
    final hash = uid.hashCode.abs() % 900000;
    return 'EJR-${(100000 + hash).toString()}';
  }

  static bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveAuthToken(
    String token, {
    SharedPreferences? prefs,
  }) async {
    await ApiClient.saveToken(token);
    final targetPrefs = prefs ?? await SharedPreferences.getInstance();
    await targetPrefs.setString(_userTokenKey, token);
  }

  static String? _readIdentityValue(Map<String, dynamic> userData, String key) {
    final value = userData[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Map<String, dynamic> _withCompatibleIdentity(
    Map<String, dynamic> userData,
  ) {
    final canonicalId = _readIdentityValue(userData, 'uid') ??
        _readIdentityValue(userData, 'id') ??
        _readIdentityValue(userData, '_id') ??
        _readIdentityValue(userData, 'email') ??
        'generated-${DateTime.now().microsecondsSinceEpoch}';

    return {
      ...userData,
      if (_readIdentityValue(userData, 'id') == null) 'id': canonicalId,
      if (_readIdentityValue(userData, '_id') == null) '_id': canonicalId,
      if (_readIdentityValue(userData, 'uid') == null) 'uid': canonicalId,
    };
  }

  static String _normalizeRoleForAccess(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'owner':
      case 'landlord':
        return 'owner';
      case 'technician':
      case 'tech':
      case 'provider':
      case 'service_provider':
        return 'technician';
      case 'admin':
        return 'admin';
      case 'tenant':
      default:
        return 'tenant';
    }
  }

  static const Set<String> _approvalRequiredRoles = {
    'owner',
    'technician',
    'company',
  };

  static String _normalizeRequestedRole(Object? role) {
    final normalized = role?.toString().trim().toLowerCase() ?? 'tenant';
    switch (normalized) {
      case 'owner':
      case 'landlord':
        return 'owner';
      case 'technician':
      case 'tech':
      case 'provider':
      case 'service_provider':
        return 'technician';
      case 'company':
        return 'company';
      case 'tenant':
      default:
        return 'tenant';
    }
  }

  static Map<String, dynamic> _publicRegistrationRoleFields(
    Object? selectedRole,
  ) {
    final requestedRole = _normalizeRequestedRole(selectedRole);
    return {
      'role': 'tenant',
      'type': 'tenant',
      'requestedRole': requestedRole,
      'verificationStatus': _approvalRequiredRoles.contains(requestedRole)
          ? 'pending'
          : 'approved',
    };
  }

  static Map<String, dynamic> _buildLocalUser({
    required String name,
    required String email,
    required String role,
    String? password,
    bool offlineSignup = false,
    String? accountId,
  }) {
    return _withCompatibleIdentity({
      'id': email,
      '_id': email,
      'name': name,
      'email': email,
      'role': role,
      'type': role,
      if (password != null) 'password': password,
      if (offlineSignup) 'offlineSignup': true,
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
    });
  }

  static Future<void> _storeLocalAccount(
    Map<String, dynamic> userData, {
    String token = 'local-demo-token',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final compatibleUserData = _withCompatibleIdentity(userData);
    final email =
        (compatibleUserData['email'] ?? '').toString().trim().toLowerCase();
    if (email.isEmpty) return;

    final storedUser = await AccountIdService.ensureUserHasAccountId(
      compatibleUserData,
    );

    await prefs.setString('user_$email', jsonEncode(storedUser));

    final users = prefs.getStringList(_usersListKey) ?? <String>[];
    if (!users.contains(email)) {
      users.add(email);
      await prefs.setStringList(_usersListKey, users);
    }

    await prefs.setString(
      _userRoleKey,
      storedUser['role'] ?? storedUser['type'] ?? 'tenant',
    );
    await prefs.setString(
      _userIdKey,
      storedUser['id']?.toString() ?? email,
    );
    await prefs.setString(_currentUserEmailKey, email);
    await prefs.setString(_userDataKey, jsonEncode(storedUser));
    await _saveAuthToken(token, prefs: prefs);
    await prefs.setBool(_guestModeKey, false);
    await WalletService.init(userId: email);
  }

  static Future<void> _storeFirebaseSession({
    required User firebaseUser,
    required Map<String, dynamic> profile,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email =
        (firebaseUser.email ?? profile['email'] ?? '').toString().trim().toLowerCase();
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

    final firebaseUserData = <String, dynamic>{...userData};
    if (_readIdentityValue(firebaseUserData, 'uid') == null) {
      firebaseUserData['uid'] = firebaseUser.uid;
    }
    final compatibleUserData = _withCompatibleIdentity(firebaseUserData);

    await prefs.setString(_userRoleKey, role);
    await prefs.setString(_userIdKey, firebaseUser.uid);
    await prefs.setString(_currentUserEmailKey, email);
    await prefs.setString(_userDataKey, jsonEncode(compatibleUserData));
    final authToken = token ?? await firebaseUser.getIdToken() ?? '';
    await _saveAuthToken(authToken, prefs: prefs);
    await prefs.setBool(_guestModeKey, false);
  }

  static Future<Map<String, dynamic>?> _getFirebaseProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final profile = <String, dynamic>{...data};
    if (_readIdentityValue(profile, 'uid') == null) {
      profile['uid'] = uid;
    }
    return _withCompatibleIdentity(profile);
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
  static Future<Map<String, dynamic>?> _completeLocalLogin(
    Map<String, dynamic> localAccount,
    String email,
    String password,
  ) async {
    if (localAccount['isBlocked'] == true) {
      final reason = localAccount['blockReason']?.toString();
      throw reason != null && reason.isNotEmpty
          ? 'تم حظر الحساب: $reason'
          : 'تم حظر هذا الحساب من قبل الإدارة';
    }
    if (localAccount['isSuspended'] == true) {
      final until = localAccount['suspendUntil']?.toString();
      throw until != null ? 'الحساب معلّق حتى $until' : 'الحساب معلّق مؤقتاً';
    }

    final role = localAccount['role'] ?? localAccount['type'] ?? 'tenant';
    final user = _withCompatibleIdentity({
      ...localAccount,
      'name': localAccount['name'] ?? 'مستخدم إيجاري',
      'email': localAccount['email'] ?? email,
      'role': role.toString(),
      'type': role.toString(),
      if (localAccount['password'] != null)
        'password': localAccount['password'] ?? password,
    });

    await _storeLocalAccount(
      user,
      token: 'local-demo-token',
    );
    return user;
  }

  static Future<Map<String, dynamic>?> _tryLocalLoginFallback(
    String email,
    String password, {
    bool force = true,
  }) async {
    // Early-stage reliability: always attempt local demo/offline accounts when
    // Firebase is down, misconfigured, timed out, or unavailable. Prefer a
    // working login over a misleading "check connection" error.
    if (!force && !AppConfig.demoMode) return null;
    try {
      await initDemoAccounts();
      final localAccount = await _findLocalAccount(email, password);
      if (localAccount == null) return null;
      return _completeLocalLogin(localAccount, email, password);
    } catch (e) {
      debugPrint('Local login fallback failed: $e');
      return null;
    }
  }

  static Future<bool> signUp(Map<String, dynamic> userData) async {
    final registrationRoleFields = _publicRegistrationRoleFields(
      userData['requestedRole'] ?? userData['type'] ?? userData['role'],
    );

    Future<bool> localSignUp() async {
      final email = (userData['email'] ?? '').toString().trim().toLowerCase();
      final accountId = await AccountIdService.assignAccountIdForEmail(email);
      final fallbackUser = _buildLocalUser(
        name: userData['name'] ?? '',
        email: email,
        role: registrationRoleFields['role'] as String,
        password: userData['password'] ?? '',
        offlineSignup: true,
        accountId: accountId,
      )..addAll(registrationRoleFields);
      await _storeLocalAccount(
        fallbackUser,
        token: 'local-demo-token',
      );
      return true;
    }

    if (_useLocalAuth) {
      return localSignUp();
    }

    if (_useFirebaseAuth) {
      try {
        final email = (userData['email'] ?? '').toString().trim();
        final password = (userData['password'] ?? '').toString();
        final credential = await _firebaseAuth
            .createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
            .timeout(AppConfig.authTimeout);
        final uid = credential.user!.uid;
        final accountId = _accountIdFromUid(uid);
        final profile = <String, dynamic>{
          'name': userData['name'] ?? '',
          'email': email.toLowerCase(),
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? 'العنوان غير محدد',
          'accountId': accountId,
          ...registrationRoleFields,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        };

        await _firestore
            .collection('users')
            .doc(uid)
            .set(
              profile,
              SetOptions(merge: true),
            )
            .timeout(AppConfig.authTimeout);
        if (userData['name'] != null) {
          await credential.user!
              .updateDisplayName(userData['name'].toString())
              .timeout(AppConfig.authTimeout);
        }
        await _storeFirebaseSession(
          firebaseUser: credential.user!,
          profile: profile,
        );
        return true;
      } catch (e) {
        debugPrint('Firebase SignUp Error: $e');
        // Prefer a working local account over a dead-end connection error.
        // Only rethrow hard credential conflicts (email already in use) if we
        // did not fall back — for early stage always create local account.
        if (_isCredentialAuthError(e) &&
            e is FirebaseAuthException &&
            e.code == 'email-already-in-use') {
          // Still allow local if the account only exists offline.
          try {
            return await localSignUp();
          } catch (_) {
            throw _arabicFirebaseAuthError(e);
          }
        }
        debugPrint('Firebase signup unavailable — falling back to local signup');
        return localSignUp();
      }
    }

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      // No Express API and Firebase not in use — always create local account.
      return localSignUp();
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
              'requestedRole': registrationRoleFields['requestedRole'],
              'address': userData['address'] ?? 'العنوان غير محدد',
            }),
          )
          .timeout(AppConfig.authTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = _withCompatibleIdentity(
          (data['user'] as Map<String, dynamic>?) ?? {},
        );
        final role = user['role'] ?? 'tenant';
        final token = data['token'] ?? '';
        final uid = user['_id'] ?? user['id'] ?? user['uid'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userRoleKey, role);
        await _saveAuthToken(token, prefs: prefs);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_userDataKey, jsonEncode(user));
        await prefs.setBool(_guestModeKey, false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw err['message'] ?? err['error'] ?? 'فشل التسجيل';
      }
    } catch (e) {
      debugPrint('SignUp Error: $e');
      // Always fall back to local signup so the app stays usable.
      try {
        return await localSignUp();
      } catch (_) {
        if (e is String) rethrow;
        throw _arabicFirebaseAuthError(e);
      }
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    if (_useLocalAuth) {
      await initDemoAccounts();
      final localAccount = await _findLocalAccount(email, password);
      if (localAccount == null) {
        throw 'بيانات الدخول غير صحيحة';
      }
      return _completeLocalLogin(localAccount, email, password);
    }

    if (_useFirebaseAuth) {
      try {
        final credential = await _firebaseAuth
            .signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(AppConfig.authTimeout);
        final firebaseUser = credential.user;
        if (firebaseUser == null) {
          throw 'تعذر تسجيل الدخول';
        }

        final profile = await _getFirebaseProfile(firebaseUser.uid)
                .timeout(AppConfig.authTimeout) ??
            <String, dynamic>{
              'name': firebaseUser.displayName ?? 'مستخدم إيجاري',
              'email': firebaseUser.email ?? email,
              'role': 'tenant',
              'type': 'tenant',
            };

        final role = (profile['role'] ?? profile['type'] ?? 'tenant').toString();
        final firebaseUserData = <String, dynamic>{...profile};
        if (_readIdentityValue(firebaseUserData, 'uid') == null) {
          firebaseUserData['uid'] = firebaseUser.uid;
        }
        final user = _withCompatibleIdentity({
          ...firebaseUserData,
          'role': role,
          'type': role,
        });
        await _storeFirebaseSession(
          firebaseUser: firebaseUser,
          profile: user,
        );
        return user;
      } catch (e) {
        debugPrint('Firebase Login Error: $e');
        // Always try local demo / offline accounts on ANY Firebase failure so
        // release APKs stay usable when Email/Password is disabled, network
        // is down, or Firebase init is incomplete.
        final local = await _tryLocalLoginFallback(email, password);
        if (local != null) return local;
        throw _arabicFirebaseAuthError(e);
      }
    }

    // Debug/demo-only admin shortcut; never available in production builds.
    if (kDebugMode &&
        AppConfig.demoMode &&
        email == 'admin@ejari.app' &&
        password == 'admin123') {
      final user = _withCompatibleIdentity({
        'name': 'Admin',
        'email': email,
        'role': 'admin',
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, 'admin');
      await prefs.setString(_currentUserEmailKey, email);
      await prefs.setString(_userDataKey, jsonEncode(user));
      await prefs.setBool(_guestModeKey, false);
      await WalletService.init(userId: email);
      return user;
    }

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      final local = await _tryLocalLoginFallback(email, password);
      if (local != null) return local;
      if (!AppConfig.demoMode && !_firebaseReady) {
        throw 'تعذر الاتصال بـ Firebase. استخدم حسابات التجربة أو فعّل Email/Password في Firebase Console.';
      }
      throw 'بيانات الدخول غير صحيحة';
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppConfig.authTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = _withCompatibleIdentity(
          data['user'] as Map<String, dynamic>? ?? {},
        );
        final role = user['role'] ?? 'tenant';
        final token = data['token'] ?? '';
        final uid = user['_id'] ?? user['id'] ?? user['uid'] ?? '';

        if (user['isBlocked'] == true) {
          throw 'تم حظر هذا الحساب من قبل الإدارة';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userRoleKey, role);
        await _saveAuthToken(token, prefs: prefs);
        await prefs.setString(_userIdKey, uid);
        await prefs.setString(_userDataKey, jsonEncode(user));
        await prefs.setBool(_guestModeKey, false);
        return user;
      } else {
        final err = jsonDecode(response.body);
        throw err['message'] ?? err['error'] ?? 'بيانات الدخول غير صحيحة';
      }
    } catch (e) {
      if (e is String) {
        final local = await _tryLocalLoginFallback(email, password);
        if (local != null) return local;
        rethrow;
      }
      debugPrint('Login Error: $e');
      final local = await _tryLocalLoginFallback(email, password);
      if (local != null) return local;
      if (e is TimeoutException) {
        throw 'انتهت مهلة الاتصال. جرّب حسابات التجربة أو تحقق من الإنترنت';
      }
      throw 'تعذر الاتصال بالسيرفر. جرّب حسابات التجربة أو تحقق من الإنترنت';
    }
  }

  // ─────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────
  /// Sends a Firebase password-reset email when Firebase auth is active.
  /// In demo/local mode, completes successfully so the UX can be tested.
  static Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw 'أدخل البريد الإلكتروني أولاً';
    }
    if (!trimmed.contains('@')) {
      throw 'أدخل بريداً إلكترونياً صالحاً لإعادة التعيين';
    }

    if (_useLocalAuth || AppConfig.demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return;
    }

    if (_useFirebaseAuth) {
      try {
        await _firebaseAuth
            .sendPasswordResetEmail(email: trimmed)
            .timeout(AppConfig.authTimeout);
        return;
      } catch (e) {
        debugPrint('Password reset error: $e');
        throw _arabicFirebaseAuthError(e);
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  static Future<void> logout() async {
    if (!_useLocalAuth &&
        _firebaseReady &&
        _firebaseAuth.currentUser != null) {
      try {
        await _firebaseAuth.signOut().timeout(AppConfig.authTimeout);
      } catch (e) {
        debugPrint('Firebase signOut skipped: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await ApiClient.clearToken();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_currentUserEmailKey);
    await prefs.remove(_guestModeKey);
  }

  // ─────────────────────────────────────────────
  // IS LOGGED IN
  // ─────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool(_guestModeKey) ?? false;
    if (isGuest) return false;

    if (_useLocalAuth || AppConfig.demoMode) {
      final token = await ApiClient.getToken() ?? '';
      final userData = prefs.getString(_userDataKey) ?? '';
      return token.isNotEmpty || userData.isNotEmpty;
    }

    try {
      if (_firebaseReady && _firebaseAuth.currentUser != null) return true;
    } catch (e) {
      debugPrint('isLoggedIn Firebase check skipped: $e');
    }

    final token = await ApiClient.getToken() ?? '';
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
      await ApiClient.clearToken();
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
        return _withCompatibleIdentity(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    if (_useLocalAuth || AppConfig.demoMode) {
      return null;
    }

    try {
      if (!_firebaseReady) return null;
      final current = _firebaseAuth.currentUser;
      if (current == null) return null;

      final profile = await _getFirebaseProfile(current.uid)
          .timeout(AppConfig.authTimeout);
      if (profile != null) {
        final role = (profile['role'] ?? profile['type'] ?? 'tenant').toString();
        final firebaseUserData = <String, dynamic>{...profile};
        if (_readIdentityValue(firebaseUserData, 'uid') == null) {
          firebaseUserData['uid'] = current.uid;
        }
        return _withCompatibleIdentity({
          ...firebaseUserData,
          'role': role,
          'type': role,
        });
      }
      return _withCompatibleIdentity({
        'id': current.uid,
        '_id': current.uid,
        'name': current.displayName ?? 'مستخدم إيجاري',
        'email': current.email ?? '',
        'role': 'tenant',
        'type': 'tenant',
      });
    } catch (e) {
      debugPrint('getCurrentUser Firebase skipped: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // GET USER ROLE
  // ─────────────────────────────────────────────
  static Future<String> getUserRole() async {
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      return _normalizeRoleForAccess(prefs.getString(_userRoleKey));
    }
    final prefs = await SharedPreferences.getInstance();
    return _normalizeRoleForAccess(prefs.getString(_userRoleKey));
  }

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  // ─────────────────────────────────────────────
  // GET TOKEN (for API calls)
  // ─────────────────────────────────────────────
  static Future<String> getToken() async {
    return await ApiClient.getToken() ?? '';
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
  // ADMIN: MODERATE USER (block / suspend with reason)
  // ─────────────────────────────────────────────
  static Future<bool> moderateUser({
    required String uid,
    required String action,
    String? reason,
    DateTime? suspendUntil,
  }) async {
    if (_useLocalAuth) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_$uid');
      if (raw == null || raw.isEmpty) return false;
      try {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        if (action == 'unblock') {
          user['isBlocked'] = false;
          user.remove('blockReason');
          user.remove('suspendUntil');
          user['isSuspended'] = false;
        } else if (action == 'block') {
          user['isBlocked'] = true;
          user['blockReason'] = reason ?? 'مخالفة سياسة المنصة';
          user['isSuspended'] = false;
          user.remove('suspendUntil');
        } else if (action == 'suspend') {
          user['isSuspended'] = true;
          user['isBlocked'] = false;
          user['blockReason'] = reason ?? 'تعليق مؤقت';
          user['suspendUntil'] =
              (suspendUntil ?? DateTime.now().add(const Duration(days: 7)))
                  .toIso8601String();
        }
        user['moderatedAt'] = DateTime.now().toIso8601String();
        await prefs.setString('user_$uid', jsonEncode(user));
        return true;
      } catch (_) {
        return false;
      }
    }
    return toggleUserBlock(uid);
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
      final email = account['email']!;
      Map<String, dynamic> merged = {};
      final existingRaw = prefs.getString('user_$email');
      if (existingRaw != null && existingRaw.isNotEmpty) {
        try {
          final parsed = jsonDecode(existingRaw);
          if (parsed is Map<String, dynamic>) {
            merged = Map<String, dynamic>.from(parsed);
          }
        } catch (_) {}
      }

      merged.addAll({
        'id': email,
        '_id': email,
        'uid': email,
        'name': account['name'],
        'email': email,
        'role': account['role'],
        'type': account['role'],
        'password': account['password'],
        'accountId': account['accountId'],
      });

      await prefs.setString('user_$email', jsonEncode(merged));
    }

    await _backfillMissingAccountIds();
    await AccountIdService.ensureCounterAtLeast(100005);
  }

  static Future<void> _backfillMissingAccountIds() async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_usersListKey) ?? <String>[];

    for (final email in emails) {
      final raw = prefs.getString('user_$email');
      if (raw == null || raw.isEmpty) continue;
      try {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        final existing = user['accountId']?.toString().trim();
        if (existing != null && existing.isNotEmpty) continue;

        final accountId = await AccountIdService.assignAccountIdForEmail(email);
        user['accountId'] = accountId;
        await prefs.setString('user_$email', jsonEncode(user));
      } catch (_) {}
    }
  }

  /// Sign In with Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (AppConfig.demoMode) {
      return {
        'id': 'demo_google_id',
        'name': 'مستخدم جوجل تجريبي',
        'email': 'social_user@ejari.app',
        'type': 'tenant',
        'role': 'tenant',
      };
    }

    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        throw Exception('تم إلغاء تسجيل الدخول بجوجل');
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> data;
        String role = 'tenant';

        if (doc.exists) {
          data = doc.data() as Map<String, dynamic>;
          role = data['type'] ?? data['role'] ?? 'tenant';
        } else {
          final String generatedId = await AccountIdService.generateNextAccountId();
          data = {
            'id': user.uid,
            'name': user.displayName ?? gUser.displayName ?? 'مستخدم جوجل',
            'email': user.email ?? gUser.email,
            'type': 'tenant',
            'role': 'tenant',
            'accountId': generatedId,
            'createdAt': FieldValue.serverTimestamp(),
          };
          await _firestore.collection('users').doc(user.uid).set(data);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userTokenKey, await user.getIdToken() ?? 'mock_firebase_token');
        await prefs.setString(_userRoleKey, role);
        await prefs.setString(_userIdKey, user.uid);
        await prefs.setString(_currentUserEmailKey, user.email ?? gUser.email ?? '');
        await prefs.setString(_userDataKey, jsonEncode(data));

        return data;
      }
      throw Exception('فشل تسجيل الدخول بجوجل');
    } catch (e) {
      if (kDebugMode) print('Google Sign-In Error: $e');
      throw Exception('خطأ في تسجيل الدخول بجوجل: $e');
    }
  }

  static Future<void> clearAllData() async => logout();
}
