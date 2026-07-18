import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/payment_methods_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await PaymentMethodsService.getCards();
    if (mounted) {
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistCards() async {
    await PaymentMethodsService.saveCards(_cards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('وسائل الدفع المحفوظة'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_cards.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.credit_card_off_rounded,
                              size: 40, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد بطاقات محفوظة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'أضف بطاقة لاستخدامها لاحقاً في الدفع. نعرض آخر 4 أرقام فقط ولا نخزّن CVV.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._cards.map((card) => _buildCardItem(card)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showAddCardDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppTheme.primaryColor,
                            style: BorderStyle.solid),
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
    final isDefault = card['isDefault'] == true;
    return Dismissible(
      key: Key(card['id']?.toString() ?? card['number']?.toString() ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('حذف البطاقة؟'),
                content: const Text('لن تُحذف من البنك — فقط من وسائل الدفع المحفوظة في التطبيق.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        setState(() {
          _cards.removeWhere((c) => c['id'] == card['id']);
          if (_cards.isNotEmpty && !_cards.any((c) => c['isDefault'] == true)) {
            _cards.first['isDefault'] = true;
          }
        });
        await _persistCards();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البطاقة')),
        );
      },
      child: GestureDetector(
      onTap: () async {
        await PaymentMethodsService.setDefaultCard(card['id'].toString());
        await PaymentMethodsService.saveSelectedMethod(
          category: 'cards',
          subMethod: isVisa ? 'visa' : 'mastercard',
        );
        await _loadCards();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين البطاقة الافتراضية')),
        );
      },
      child: Container(
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
          border: isDefault
              ? Border.all(color: AppTheme.accentColor, width: 2)
              : null,
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
                if (isDefault)
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
                      'حامل البطاقة',
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
                      'الانتهاء',
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
      ),
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
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final rawNum = cardNumberCtrl.text.replaceAll(' ', '');
                final last4 = rawNum.length >= 4
                    ? rawNum.substring(rawNum.length - 4)
                    : rawNum;
                final isVisa = rawNum.startsWith('4');
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                setState(() {
                  if (_cards.isEmpty) {
                    _cards.add({
                      'id': id,
                      'number': '**** **** **** $last4',
                      'expiry': expiryCtrl.text,
                      'holder': holderCtrl.text.toUpperCase(),
                      'type': isVisa ? 'visa' : 'mastercard',
                      'isDefault': true,
                    });
                  } else {
                    _cards.add({
                      'id': id,
                      'number': '**** **** **** $last4',
                      'expiry': expiryCtrl.text,
                      'holder': holderCtrl.text.toUpperCase(),
                      'type': isVisa ? 'visa' : 'mastercard',
                      'isDefault': false,
                    });
                  }
                });
                await _persistCards();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم إضافة البطاقة بنجاح'),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
