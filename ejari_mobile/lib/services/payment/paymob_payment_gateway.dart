import '../../models/app_region.dart';
import '../paymob_service.dart';
import 'payment_gateway.dart';

/// Egypt card corridor — wraps existing [PaymobService].
class PaymobPaymentGateway implements PaymentGateway {
  @override
  String get id => 'paymob';

  @override
  String get displayName => 'Paymob';

  @override
  AppRegion get region => AppRegion.egypt;

  @override
  bool get isConfigured => PaymobService.isConfigured;

  @override
  bool get shouldUseGateway => PaymobService.shouldUseGateway;

  @override
  Future<PaymentCheckoutSession> createCheckout({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? userData,
  }) async {
    final url = await PaymobService.getPaymentUrl(
      amount: amount,
      referenceId: referenceId,
      userData: userData,
    );
    return PaymentCheckoutSession(
      paymentUrl: url,
      gatewayId: id,
      currencyCode: AppRegion.egypt.currencyCode,
      providerReference: referenceId,
    );
  }
}
