import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Generates and resolves human-readable Ejari account IDs (e.g. EJR-100001).
class AccountIdService {
  static const String prefix = 'EJR-';
  static const String _counterKey = 'account_id_counter';
  static const int _minCounter = 100005;

  static const Map<String, String> demoAccountIds = {
    'admin@ejari.app': 'EJR-100001',
    'user@ejari.app': 'EJR-100002',
    'owner@ejari.app': 'EJR-100003',
    'tech@ejari.app': 'EJR-100004',
  };

  static String formatAccountId(int sequence) {
    return '$prefix${sequence.toString().padLeft(6, '0')}';
  }

  static String? normalizeQuery(String query) {
    final trimmed = query.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith(prefix)) return trimmed;
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return trimmed;
    return formatAccountId(int.parse(digits));
  }

  static Future<void> ensureCounterAtLeast(int value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_counterKey) ?? _minCounter;
    if (current < value) {
      await prefs.setInt(_counterKey, value);
    }
  }

  static Future<bool> accountIdExists(String accountId) async {
    final normalized = accountId.trim().toUpperCase();
    final users = await _loadAllUsers();
    return users.any(
      (user) =>
          (user['accountId']?.toString().trim().toUpperCase() ?? '') ==
          normalized,
    );
  }

  static Future<String> generateNextAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    var counter = prefs.getInt(_counterKey) ?? _minCounter;

    while (await accountIdExists(formatAccountId(counter))) {
      counter++;
    }

    final accountId = formatAccountId(counter);
    await prefs.setInt(_counterKey, counter + 1);
    return accountId;
  }

  static Future<String> assignAccountIdForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final preset = demoAccountIds[normalizedEmail];
    if (preset != null) return preset;
    return generateNextAccountId();
  }

  static Future<Map<String, dynamic>> ensureUserHasAccountId(
    Map<String, dynamic> user, {
    bool persist = false,
  }) async {
    final existing = user['accountId']?.toString().trim();
    if (existing != null && existing.isNotEmpty) {
      return user;
    }

    final email = user['email']?.toString().trim().toLowerCase() ?? '';
    final accountId = email.isNotEmpty
        ? await assignAccountIdForEmail(email)
        : await generateNextAccountId();

    final updated = {...user, 'accountId': accountId};

    if (persist && email.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_$email', jsonEncode(updated));
    }

    return updated;
  }

  static Future<List<Map<String, dynamic>>> _loadAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList('users_list') ?? <String>[];
    final users = <Map<String, dynamic>>[];

    for (final email in emails) {
      final raw = prefs.getString('user_$email');
      if (raw == null || raw.isEmpty) continue;
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          users.add(parsed);
        }
      } catch (_) {}
    }

    return users;
  }

  static Future<Map<String, dynamic>?> findUserByAccountId(String query) async {
    final trimmed = query.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    final normalized = normalizeQuery(query) ?? trimmed;
    final users = await _loadAllUsers();

    for (final user in users) {
      final accountId =
          user['accountId']?.toString().trim().toUpperCase() ?? '';
      if (accountId == normalized || accountId == trimmed) {
        return user;
      }
    }

    if (normalized.length >= 8) {
      for (final user in users) {
        final accountId =
            user['accountId']?.toString().trim().toUpperCase() ?? '';
        if (accountId.contains(normalized)) {
          return user;
        }
      }
    }

    return null;
  }

  static Map<String, dynamic> toPublicProfile(Map<String, dynamic> user) {
    final role = user['role'] ?? user['type'] ?? 'tenant';
    final verified = user['isVerified'] == true ||
        user['verificationStatus']?.toString().toLowerCase() == 'approved';

    return {
      'accountId': user['accountId']?.toString() ?? '',
      'name': user['name']?.toString() ?? 'مستخدم',
      'role': role,
      'roleLabel': _roleLabel(role.toString()),
      'verified': verified,
      'verificationLabel': verified ? 'موثق' : 'غير موثق',
    };
  }

  static String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'مالك عقار';
      case 'admin':
        return 'مدير نظام';
      case 'technician':
      case 'provider':
        return 'فني صيانة';
      case 'tenant':
      default:
        return 'مستأجر';
    }
  }
}
