import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/date_utils.dart';

class WalletService {
  static const String _balanceKey = 'wallet_balance';
  static const String _pendingBalanceKey = 'owner_pending_balance'; // للمالك
  static const String _escrowBalanceKey =
      'booking_escrow_balance'; // عربون محجوز
  static const String _transactionsKey = 'wallet_transactions';

  // الأرصدة الحالية (Demo State)
  static double _balance = 0.0; // رصيد المستأجر أو الرصيد القابل للسحب للمالك
  static double _pendingBalance = 0.0; // رصيد معلق للمالك (تحت التسوية)
  static double _escrowBalance = 0.0; // عربون حجوزات تحت الحجز إلى حين الحسم
  static List<Map<String, dynamic>> _transactions = [];

  // تهيئة الخدمة
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble(_balanceKey) ?? 0.0; // Start with 0
    _pendingBalance = prefs.getDouble(_pendingBalanceKey) ?? 0.0;
    _escrowBalance = prefs.getDouble(_escrowBalanceKey) ?? 0.0;

    final String? transString = prefs.getString(_transactionsKey);
    if (transString != null) {
      final List<dynamic> decoded = jsonDecode(transString);
      _transactions = decoded.cast<Map<String, dynamic>>();
    }
  }

  static double get currentBalance => _balance;
  static double get pendingBalance => _pendingBalance;
  static double get escrowBalance => _escrowBalance;

  static Future<double> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _balance;
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    _transactions.sort((a, b) {
      DateTime dateA = DateParsing.parse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB = DateParsing.parse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return _transactions;
  }

  /// -------------------------------------------------------------
  /// عملية الدفع عبر المحفظة (خصم فعلي)
  /// -------------------------------------------------------------
  static Future<bool> payFromWallet({
    required String title,
    required double amount,
    required String category, // rent, service
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // محاكاة الاتصال بالسيرفر

    // 1. التحقق الصارم من الرصيد
    if (_balance < amount) {
      debugPrint(
          '⛔ فشل الدفع: الرصيد ($_balance) أقل من المبلغ المطلوب ($amount)');
      return false;
    }

    // 2. الخصم
    _balance -= amount;

    // 3. تسجيل المعاملة
    final transaction = {
      'id': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount, // بالسالب لأنه خصم
      'date': DateTime.now().toIso8601String(),
      'type': 'expense',
      'method': 'wallet', // وسيلة الدفع
      'category': category,
      'bookingId': bookingId,
      'status': 'completed',
    };
    _transactions.insert(0, transaction);

    await _saveData();
    return true;
  }

  /// -------------------------------------------------------------
  /// عملية الدفع الخارجي (فيزا، فوري، إلخ)
  /// لا تخصم من المحفظة، لكن تسجل في السجل
  /// -------------------------------------------------------------
  static Future<void> recordExternalPayment({
    required String title,
    required double amount,
    required String method, // card, fawry, valu
    required String bookingId,
  }) async {
    // هنا لا نتحقق من الرصيد لأن الدفع تم خارجياً
    // فقط نسجل العملية للأرشيف لإصدار الإيصال

    final transaction = {
      'id': 'EXT-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount, // بالسالب لأنه دفع
      'date': DateTime.now().toIso8601String(),
      'type': 'expense',
      'method': method,
      'category': 'rent',
      'bookingId': bookingId,
      'status': 'completed',
    };
    _transactions.insert(0, transaction);
    await _saveData();
  }

  /// -------------------------------------------------------------
  /// توريد المبلغ للمالك (Backend Logic Simulation)
  /// -------------------------------------------------------------
  static Future<void> depositToOwner({
    required String ownerId,
    required double totalAmount,
  }) async {
    // حساب النسبة (مثلاً التطبيق يأخذ 10%)
    double platformFee = totalAmount * 0.10;
    double ownerNet = totalAmount - platformFee;

    // إضافة للمالك في "الرصيد المعلق"
    // في الواقع يجب أن يكون هناك WalletService منفصل لكل مستخدم
    // هنا سنحاكي أننا نضيف الرصيد للمالك الحالي (لو كنا فاتحين حسابه)
    // أو نسجله في قاعدة البيانات

    // محاكاة: إضافة للمتغير المحلي لغرض العرض في شاشة المالك
    _pendingBalance += ownerNet;
    await _saveData();

    debugPrint('💰 تم إيداع $ownerNet للمالك (بعد خصم $platformFee رسوم)');
  }

  /// -------------------------------------------------------------
  /// حجز عربون المعاينة في رصيد مؤقت قابل للاسترداد
  /// -------------------------------------------------------------
  static Future<void> holdBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
    String method = 'deposit',
  }) async {
    _escrowBalance += amount;
    final transaction = {
      'id': 'ESC-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': -amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'escrow',
      'method': method,
      'category': 'booking_deposit',
      'bookingId': bookingId,
      'status': 'held',
    };
    _transactions.insert(0, transaction);
    await _saveData();
  }

  /// -------------------------------------------------------------
  /// استرداد العربون عند عدم إتمام الصفقة
  /// -------------------------------------------------------------
  static Future<void> refundBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
  }) async {
    _escrowBalance = (_escrowBalance - amount).clamp(0.0, double.infinity);
    final transaction = {
      'id': 'REF-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'refund',
      'method': 'refund',
      'category': 'booking_deposit',
      'bookingId': bookingId,
      'status': 'completed',
    };
    _transactions.insert(0, transaction);
    await _saveData();
  }

  /// -------------------------------------------------------------
  /// ترحيل العربون المحجوز إلى التسوية النهائية
  /// -------------------------------------------------------------
  static Future<void> releaseBookingDeposit({
    required String title,
    required double amount,
    required String bookingId,
    required String ownerId,
  }) async {
    _escrowBalance = (_escrowBalance - amount).clamp(0.0, double.infinity);
    await depositToOwner(ownerId: ownerId, totalAmount: amount);
    final transaction = {
      'id': 'REL-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'amount': 0,
      'date': DateTime.now().toIso8601String(),
      'type': 'release',
      'method': 'system',
      'category': 'booking_deposit',
      'bookingId': bookingId,
      'status': 'completed',
    };
    _transactions.insert(0, transaction);
    await _saveData();
  }

  /// -------------------------------------------------------------
  /// شحن الرصيد
  /// -------------------------------------------------------------
  static Future<void> topUpWallet(double amount) async {
    _balance += amount;
    final transaction = {
      'id': 'TOP-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'شحن رصيد',
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'type': 'income',
      'method': 'card',
      'category': 'topup',
      'status': 'completed',
    };
    _transactions.insert(0, transaction);
    await _saveData();
  }

  static Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, _balance);
    await prefs.setDouble(_pendingBalanceKey, _pendingBalance);
    await prefs.setDouble(_escrowBalanceKey, _escrowBalance);
    await prefs.setString(_transactionsKey, jsonEncode(_transactions));
  }
}
