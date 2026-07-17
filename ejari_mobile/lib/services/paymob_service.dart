import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Paymob Accept gateway (optional).
///
/// Configure at build time:
/// ```
/// flutter build apk --dart-define=PAYMOB_API_KEY=... \
///   --dart-define=PAYMOB_INTEGRATION_ID=... \
///   --dart-define=PAYMOB_IFRAME_ID=...
/// ```
/// When not configured, [isConfigured] is false and the app uses demo wallet payment.
class PaymobService {
  static const String _apiKey = String.fromEnvironment('PAYMOB_API_KEY');
  static const String _integrationId =
      String.fromEnvironment('PAYMOB_INTEGRATION_ID');
  static const String _iframeId = String.fromEnvironment('PAYMOB_IFRAME_ID');
  static const String _baseUrl = 'https://accept.paymob.com/api';

  /// True only when all Paymob credentials are provided via dart-define.
  static bool get isConfigured =>
      _apiKey.trim().isNotEmpty &&
      _integrationId.trim().isNotEmpty &&
      _iframeId.trim().isNotEmpty &&
      !_apiKey.contains('...') &&
      _integrationId != '456789' &&
      _iframeId != '123456';

  /// Prefer Paymob for card payments when configured and not in pure demo mode.
  static bool get shouldUseGateway =>
      isConfigured && !AppConfig.demoMode;

  static Future<String> _getAuthenticationToken() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/tokens'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'api_key': _apiKey}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'].toString();
      }
      throw Exception('فشل التوثيق مع بوابة الدفع');
    } catch (e) {
      if (kDebugMode) print('Paymob Auth Error: $e');
      throw Exception('تعذر الاتصال ببوابة الدفع. أكمل الدفع التجريبي أو أعد المحاولة.');
    }
  }

  static Future<String> _registerOrder({
    required String authToken,
    required double amount,
    required String merchantOrderId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ecommerce/orders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'auth_token': authToken,
              'delivery_needed': 'false',
              'amount_cents': (amount * 100).round().toString(),
              'currency': 'EGP',
              'merchant_order_id': merchantOrderId,
              'items': [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'].toString();
      }
      throw Exception('فشل تسجيل طلب الدفع');
    } catch (e) {
      if (kDebugMode) print('Paymob Order Error: $e');
      throw Exception('حدث خطأ أثناء تسجيل طلب الدفع.');
    }
  }

  static Future<String> _getPaymentKey({
    required String authToken,
    required String orderId,
    required double amount,
    required Map<String, dynamic> billingData,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/acceptance/payment_keys'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'auth_token': authToken,
              'amount_cents': (amount * 100).round().toString(),
              'expiration': 3600,
              'order_id': orderId,
              'billing_data': {
                'apartment': 'NA',
                'email': billingData['email'] ?? 'test@ejari.app',
                'floor': 'NA',
                'first_name': billingData['first_name'] ?? 'Ejari',
                'street': 'NA',
                'building': 'NA',
                'phone_number': billingData['phone'] ?? '+201000000000',
                'shipping_method': 'NA',
                'postal_code': 'NA',
                'city': 'Cairo',
                'country': 'EG',
                'last_name': billingData['last_name'] ?? 'User',
                'state': 'NA',
              },
              'currency': 'EGP',
              'integration_id': int.tryParse(_integrationId) ?? _integrationId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'].toString();
      }
      throw Exception('فشل الحصول على مفتاح الدفع');
    } catch (e) {
      if (kDebugMode) print('Paymob Payment Key Error: $e');
      throw Exception('تعذر تهيئة صفحة الدفع.');
    }
  }

  /// Returns Paymob iframe URL, or throws if not configured / network fails.
  static Future<String> getPaymentUrl({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? userData,
  }) async {
    if (!isConfigured) {
      throw Exception('بوابة Paymob غير مُعدّة بعد');
    }

    final authToken = await _getAuthenticationToken();
    final uniqueOrderId =
        '${referenceId}_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = await _registerOrder(
      authToken: authToken,
      amount: amount,
      merchantOrderId: uniqueOrderId,
    );

    final billingData = {
      'first_name': userData?['name'] ?? 'مستخدم إيجاري',
      'email': userData?['email'] ?? 'test@ejari.app',
      'phone': userData?['phone'] ?? '+201000000000',
    };

    final paymentKey = await _getPaymentKey(
      authToken: authToken,
      orderId: orderId,
      amount: amount,
      billingData: billingData,
    );

    return 'https://accept.paymob.com/api/acceptance/iframes/$_iframeId'
        '?payment_token=$paymentKey';
  }
}
