import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_utils.dart';
import 'financial_service.dart';

/// مصدر الحقيقة الوحيد لأرصدة المحفظة — لكل مستخدم على حدة.
class WalletService {
  static const String _balancesKey = 'wallet_balances_v2';
  static const String _escrowKey = 'wallet_escrow_v2';
  static const String _pendingKey = 'wallet_pending_v2';
  static const String _transactionsPrefix = 'wallet_tx_v2_';
  static const String _currentUserKey = 'current_user_email';
  static const double _platformFeePercent = 0.05;

  static String? _activeUserId;
  static double _balance = 0.0;
  static double _pendingBalance = 0.0;
  static double _escrowBalance = 0.0;
  static List<Map<String, dynamic>> _transactions = [];

  static double get currentBalance => _balance;
  static double get pendingBalance => _pendingBalance;
  static double get escrowBalance => _escrowBalance;
  static double get platformFeePercent => _platformFeePercent;

  static Future<String?> _resolveUserId([String? userId]) async {
    if (userId != null && userId.isNotEmpty) return userId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  static Future<Map<String, double>> _loadBalancesMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveBalancesMap(
      String key, Map<String, double> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<void> init({String? userId}) async {
    _activeUserId = await _resolveUserId(userId);
    if (_activeUserId == null || _activeUserId!.isEmpty) {
      _balance = 0;
      _pendingBalance = 0;
      _escrowBalance = 0;
      _transactions = [];
      return;
    }

    final balances = await _loadBalancesMap(_balancesKey);
    final escrow = await _loadBalancesMap(_escrowKey);
    final pending = await _loadBalancesMap(_pendingKey);

    _balance = balances[_activeUserId] ?? _defaultBalanceFor(_activeUserId!);
    _escrowBalance = escrow[_activeUserId] ?? 0;
    _pendingBalance = pending[_activeUserId] ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final txRaw = prefs.getString('$_transactionsPrefix$_activeUserId');
    if (txRaw != null) {
      try {
        _transactions =
            (jsonDecode(txRaw) as List).cast<Map<String, dynamic>>();
      } catch (_) {
        _transactions = [];
      }
    } else {
      _transactions = [];
    }
  }

  static double _defaultBalanceFor(String userId) {
    if (userId == 'user@ejari.app') return 15000;
    if (userId == 'owner@ejari.app') return 8500;
    if (userId == 'tech@ejari.app') return 2500;
    if (userId == 'admin@ejari.app') return 0;
    return 5000;
  }

  static Future<void> _persistUserState() async {
    if (_activeUserId == null || _activeUserId!.isEmpty) return;

    final balances = await _loadBalancesMap(_balancesKey);
    final escrow = await _loadBalancesMap(_escrowKey);
    final pending = await _loadBalancesMap(_pendingKey);

    balances[_activeUserId!] = _balance;
    escrow[_activeUserId!] = _escrowBalance;
    pending[_activeUserId!] = _pendingBalance;

    await _saveBalancesMap(_balancesKey, balances);
    await _saveBalancesMap(_escrowKey, escrow);
    await _saveBalancesMap(_pendingKey, pending);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_transactionsPrefix$_activeUserId',
      jsonEncode(_transactions),
    );
  }

  static Future<double> getBalance({String? userId}) async {
    await init(userId: userId);
    return _balance;
  }

  static Future<Map<String, dynamic>> getWalletSummary({String? userId}) async {
    await init(userId: userId);
    return {
      'balance': _balance,
      'available': _balance,
      'pending': _pendingBalance,
      'escrow': _escrowBalance,
      'currency': 'ج.م',
    };
  }

  static Future<List<Map<String, dynamic>>> getTransactions({String? userId}) async {
    await init(userId: userId);
    _transactions.sort((a, b) {
      final dateA =
          DateParsing.parse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateParsing.parse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return List<Map<String, dynamic>>.from(_transactions);
  }

  static Future<bool> payFromWallet({
    required String title,
    required double amount,
    required String category,
    required String bookingId,
    String? userId,
  }) async {
    await init(userId: userId);
    if (_balance < amount) {
      debugPrint('⛔ رصيد غير كافٍ: $_balance < $amount');
      return false;
    }
    _balance -= amount;
    _transactions.insert(0, {
      'id': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'expense',
      'method': 'wallet',
      'category': category,
      'bookingId': bookingId,
      'status': 'completed',
    });
    await _persistUserState();
    return true;
  }

  static Future<void> recordExternalPayment({
    required String title,
    required double amount,
    required String method,
    required String bookingId,
    String? userId,
    String category = 'rent',
  }) async {
    await init(userId: userId);
    _transactions.insert(0, {
      'id': 'EXT-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'expense',
      'method': method,
      'category': category,
      'bookingId': bookingId,
      'status': 'completed',
    });
    await _persistUserState();
  }

  /// خصم من مستأجر + إيداع للمالك (بعد عمولة ٥٪) + عربون escrow.
  static Future<bool> processBookingPayment({
    required String tenantId,
    required String ownerId,
    required double amount,
    required String bookingId,
    required String title,
    required String method,
    bool useWallet = false,
    bool isDeposit = true,
  }) async {
    if (useWallet) {
      final ok = await payFromWallet(
        title: title,
        amount: amount,
        category: isDeposit ? 'booking_deposit' : 'rent',
        bookingId: bookingId,
        userId: tenantId,
      );
      if (!ok) return false;
    } else {
      await recordExternalPayment(
        title: title,
        amount: amount,
        method: method,
        bookingId: bookingId,
        userId: tenantId,
      );
    }

    if (isDeposit) {
      await holdBookingDeposit(
        title: title,
        amount: amount,
        bookingId: bookingId,
        method: method,
        userId: tenantId,
      );
    } else {
      await creditOwnerFromPayment(
        ownerId: ownerId,
        totalAmount: amount,
        bookingId: bookingId,
        title: title,
      );
    }
    return true;
  }

  static Future<void> creditOwnerFromPayment({
    required String ownerId,
    required double totalAmount,
    required String bookingId,
    required String title,
  }) async {
    final breakdown = FinancialService.calculateRentBreakdown(totalAmount);
    final ownerNet = totalAmount - (totalAmount * _platformFeePercent);

    await init(userId: ownerId);
    _pendingBalance += ownerNet;
    _transactions.insert(0, {
      'id': 'INC-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': ownerNet,
      'date': DateTime.now().toIso8601String(),
      'type': 'income',
      'method': 'system',
      'category': 'rent',
      'bookingId': bookingId,
      'status': 'pending_settlement',
      'platformFee': totalAmount * _platformFeePercent,
      'breakdown': breakdown.details,
    });
    await _persistUserState();

    await init(userId: 'admin@ejari.app');
    final adminFee = totalAmount * _platformFeePercent;
    _balance += adminFee;
    _transactions.insert(0, {
      'id': 'ADM-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'عمولة منصة — $title',
      'amount': adminFee,
      'date': DateTime.now().toIso8601String(),
      'type': 'commission',
      'method': 'system',
      'category': 'platform',
      'bookingId': bookingId,
      'status': 'completed',
    });
    await _persistUserState();
  }

  static Future<void> holdBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
    String method = 'deposit',
    String? userId,
  }) async {
    await init(userId: userId);
    _escrowBalance += amount;
    _transactions.insert(0, {
      'id': 'ESC-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'escrow',
      'method': method,
      'category': 'booking_deposit',
      'bookingId': bookingId,
      'status': 'held',
    });
    await _persistUserState();
  }

  static Future<void> refundBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
    String? userId,
  }) async {
    await init(userId: userId);
    _escrowBalance = (_escrowBalance - amount).clamp(0.0, double.infinity);
    _balance += amount;
    _transactions.insert(0, {
      'id': 'REF-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'refund',
      'method': 'refund',
      'category': 'booking_deposit',
      'bookingId': bookingId,
      'status': 'completed',
    });
    await _persistUserState();
  }

  static Future<void> releaseBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
    required String ownerId,
    String? tenantId,
  }) async {
    if (tenantId != null) {
      await init(userId: tenantId);
      _escrowBalance = (_escrowBalance - amount).clamp(0.0, double.infinity);
      await _persistUserState();
    }
    await creditOwnerFromPayment(
      ownerId: ownerId,
      totalAmount: amount,
      bookingId: bookingId,
      title: title,
    );
  }

  static Future<void> depositToOwner({
    required String ownerId,
    required double totalAmount,
  }) async {
    await creditOwnerFromPayment(
      ownerId: ownerId,
      totalAmount: totalAmount,
      bookingId: 'legacy',
      title: 'إيداع إيجار',
    );
  }

  static Future<void> topUpWallet(double amount, {String? userId}) async {
    await init(userId: userId);
    _balance += amount;
    _transactions.insert(0, {
      'id': 'TOP-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'شحن رصيد',
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'income',
      'method': 'card',
      'category': 'topup',
      'status': 'completed',
    });
    await _persistUserState();
  }

  static Future<List<Map<String, dynamic>>> getAllTransactionsForAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_transactionsPrefix));
    final all = <Map<String, dynamic>>[];
    for (final key in keys) {
      final userId = key.replaceFirst(_transactionsPrefix, '');
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (final tx in list) {
          all.add({...tx, 'userId': userId});
        }
      } catch (_) {}
    }
    all.sort((a, b) {
      final dateA =
          DateParsing.parse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateParsing.parse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return all;
  }

  /// خصم مستأجر وتوزيع مبلغ الصيانة: فني + عمولة منصة.
  static Future<bool> processServicePayment({
    required String tenantId,
    required String technicianId,
    required double amount,
    required String requestId,
    required String title,
    required double technicianShare,
    required double platformFee,
    bool useWallet = true,
    String method = 'wallet',
  }) async {
    if (useWallet) {
      final ok = await payFromWallet(
        title: title,
        amount: amount,
        category: 'maintenance',
        bookingId: requestId,
        userId: tenantId,
      );
      if (!ok) return false;
    } else {
      await recordExternalPayment(
        title: title,
        amount: amount,
        method: method,
        bookingId: requestId,
        userId: tenantId,
        category: 'maintenance',
      );
    }

    await init(userId: technicianId);
    _balance += technicianShare;
    _transactions.insert(0, {
      'id': 'SVC-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'أجر صيانة — $title',
      'amount': technicianShare,
      'date': DateTime.now().toIso8601String(),
      'type': 'income',
      'method': 'system',
      'category': 'maintenance',
      'bookingId': requestId,
      'status': 'completed',
    });
    await _persistUserState();

    await init(userId: 'admin@ejari.app');
    _balance += platformFee;
    _transactions.insert(0, {
      'id': 'ADM-SVC-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'عمولة صيانة — $title',
      'amount': platformFee,
      'date': DateTime.now().toIso8601String(),
      'type': 'commission',
      'method': 'system',
      'category': 'maintenance',
      'bookingId': requestId,
      'status': 'completed',
    });
    await _persistUserState();

    return true;
  }
}
