import '../../models/app_region.dart';
import '../../config/app_config.dart';
import '../paymob_service.dart';
import '../region_service.dart';
import 'gulf_payment_gateway.dart';
import 'paymob_payment_gateway.dart';

/// Result of initiating a hosted card checkout.
class PaymentCheckoutSession {
  final String paymentUrl;
  final String gatewayId;
  final String currencyCode;
  final String? providerReference;

  const PaymentCheckoutSession({
    required this.paymentUrl,
    required this.gatewayId,
    required this.currencyCode,
    this.providerReference,
  });
}

/// Pluggable card payment gateway (Paymob Egypt / Gulf providers).
abstract class PaymentGateway {
  String get id;
  String get displayName;
  AppRegion get region;

  /// True when dart-define credentials are present and look real.
  bool get isConfigured;

  /// Use hosted card iframe/redirect when configured and not pure demo.
  bool get shouldUseGateway => isConfigured && !AppConfig.demoMode;

  Future<PaymentCheckoutSession> createCheckout({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? userData,
  });
}

/// Routes to the gateway for the active (or override) region.
class PaymentGatewayRouter {
  PaymentGatewayRouter._();

  static PaymentGateway forRegion([AppRegion? region]) {
    final r = region ?? RegionService.current;
    switch (r) {
      case AppRegion.egypt:
        return PaymobPaymentGateway();
      case AppRegion.saudiArabia:
      case AppRegion.uae:
        return GulfPaymentGateway(region: r);
    }
  }

  static PaymentGateway get current => forRegion();

  /// Backward-compatible mirror of [PaymobService.shouldUseGateway] for Egypt,
  /// and Gulf stub keys for SA/AE.
  static bool get shouldUseCardGateway => current.shouldUseGateway;

  /// Prefer region-aware checkout; falls back to legacy Paymob static API
  /// when the active gateway is Paymob (keeps existing iframe screen).
  static Future<String> getPaymentUrl({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? userData,
    AppRegion? region,
  }) async {
    final gateway = forRegion(region);
    if (gateway is PaymobPaymentGateway) {
      return PaymobService.getPaymentUrl(
        amount: amount,
        referenceId: referenceId,
        userData: userData,
      );
    }
    final session = await gateway.createCheckout(
      amount: amount,
      referenceId: referenceId,
      userData: userData,
    );
    return session.paymentUrl;
  }
}
