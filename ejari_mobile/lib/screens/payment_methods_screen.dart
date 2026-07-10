import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Demo Data
  final List<Map<String, dynamic>> _cards = [
    {
      'id': '1',
      'number': '**** **** **** 1234',
      'expiry': '12/25',
      'holder': 'MAHMOUD ABDELKAWY',
      'type': 'visa',
      'isDefault': true,
    },
    {
      'id': '2',
      'number': '**** **** **** 5678',
      'expiry': '09/24',
      'holder': 'MAHMOUD ABDELKAWY',
      'type': 'mastercard',
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقات الدفع'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // List of Cards
            ..._cards.map((card) => _buildCardItem(card)),

            const SizedBox(height: 24),

            // Add New Card Button
            InkWell(
              onTap: _showAddCardDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.primaryColor, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'إضافة بطاقة جديدة',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    final bool isVisa = card['type'] == 'visa';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVisa
              ? [AppTheme.primaryColor, AppTheme.primaryColor]
              : [AppTheme.textPrimary, AppTheme.textPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white.withOpacity(0.8),
                size: 30,
              ),
              if (card['isDefault'])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('الافتراضية',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            card['number'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Holder',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                  Text(
                    card['holder'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expires',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                  Text(
                    card['expiry'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    final cardNumberCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة بطاقة جديدة', textAlign: TextAlign.center),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  decoration: InputDecoration(
                    labelText: 'رقم البطاقة',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v?.length ?? 0) < 16 ? 'رقم البطاقة غير صحيح' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: holderCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'اسم حامل البطاقة',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expiryCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: 'تاريخ الانتهاء',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            (v?.length ?? 0) < 5 ? 'غير صحيح' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            (v?.length ?? 0) < 3 ? 'غير صحيح' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final rawNum = cardNumberCtrl.text.replaceAll(' ', '');
                final last4 = rawNum.length >= 4
                    ? rawNum.substring(rawNum.length - 4)
                    : rawNum;
                final isVisa = rawNum.startsWith('4');
                setState(() {
                  _cards.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'number': '**** **** **** $last4',
                    'expiry': expiryCtrl.text,
                    'holder': holderCtrl.text.toUpperCase(),
                    'type': isVisa ? 'visa' : 'mastercard',
                    'isDefault': _cards.isEmpty,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم إضافة البطاقة بنجاح'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('إضافة البطاقة',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
