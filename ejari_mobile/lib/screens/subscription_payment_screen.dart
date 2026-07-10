import 'package:flutter/material.dart';

import 'payment_screen.dart';

class SubscriptionPaymentScreen extends StatelessWidget {
  final String planId;
  final String userType;
  final Map<String, dynamic> planDetails;

  const SubscriptionPaymentScreen({
    super.key,
    required this.planId,
    required this.userType,
    required this.planDetails,
  });

  @override
  Widget build(BuildContext context) {
    final price = planDetails['price'] ?? 0;

    return PaymentScreen(
      itemType: 'subscription',
      itemData: {
        'id': planId,
        'name': planDetails['name'],
        'planId': planId,
        'userType': userType,
      },
      amount: price.toDouble(),
    );
  }
}
