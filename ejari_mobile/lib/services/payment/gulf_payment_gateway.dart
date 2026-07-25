import 'package:flutter/foundation.dart';

import '../../models/app_region.dart';
import '../../config/app_config.dart';
import 'payment_gateway.dart';

/// Gulf card corridor (KSA / UAE).
///
/// Config-driven stub for PayTabs / Tap / HyperPay — does **not** fake success.
/// When keys are absent, [shouldUseGateway] is false and the app uses wallet/demo
/// (same fail-open pattern as Paymob today).
///
/// Build flags (example):
/// ```
/// flutter build apk \
///   --dart-define=GULF_GATEWAY_PROVIDER=paytabs \
///   --dart-define=GULF_GATEWAY_PROFILE_ID=... \
///   --dart-define=GULF_GATEWAY_SERVER_KEY=... \
///   --dart-define=GULF_GATEWAY_CLIENT_KEY=...
/// ```
class GulfPaymentGateway implements PaymentGateway {
  GulfPaymentGateway({required this.region});

  @override
  final AppRegion region;

  static const String _provider =
      String.fromEnvironment('GULF_GATEWAY_PROVIDER', defaultValue: 'paytabs');
  static const String _profileId =
      String.fromEnvironment('GULF_GATEWAY_PROFILE_ID');
  static const String _serverKey =
      String.fromEnvironment('GULF_GATEWAY_SERVER_KEY');
  static const String _clientKey =
      String.fromEnvironment('GULF_GATEWAY_CLIENT_KEY');

  @override
  String get id => 'gulf_$_provider';

  @override
  String get displayName {
    switch (_provider.toLowerCase()) {
      case 'tap':
        return 'Tap';
      case 'hyperpay':
        return 'HyperPay';
      case 'paytabs':
      default:
        return 'PayTabs';
    }
  }

  @override
  bool get isConfigured {
    final keys = [_profileId, _serverKey, _clientKey]
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty && !k.contains('...'))
        .length;
    // Require at least profile + server key (client key optional for some APIs).
    return keys >= 2 &&
        _profileId.trim().isNotEmpty &&
        _serverKey.trim().isNotEmpty;
  }

  @override
  bool get shouldUseGateway => isConfigured && !AppConfig.demoMode;

  @override
  Future<PaymentCheckoutSession> createCheckout({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? userData,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'بوابة الدفع الخليجية غير مُعدّة. استخدم المحفظة أو أضف مفاتيح GULF_GATEWAY_*.',
      );
    }

    // Stub only: real provider SDK/HTTP would create a hosted page session.
    // We intentionally refuse to invent a success URL that marks payment paid.
    if (kDebugMode) {
      debugPrint(
        'GulfPaymentGateway[$displayName] checkout stub — '
        'amount=$amount ${region.currencyCode} ref=$referenceId '
        'region=${region.countryCode}',
      );
    }

    throw Exception(
      'بوابة $displayName جاهزة للإعداد لكن الربط الحي غير مفعّل بعد '
      '(${region.currencyCode}). استخدم المحفظة حالياً أو أكمل تكامل المزود.',
    );
  }
}
