import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ejari_image.dart';
import '../widgets/ejari_section.dart';
import '../services/subscription_service.dart';
import '../utils/rental_rules.dart';
import '../utils/booking_validator.dart';
import '../models/booking_status.dart';
import '../models/rental_duration_tier.dart';
import '../widgets/rental_booking_widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../models/payment_receipt.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';
import '../services/payment_methods_service.dart';
import 'success_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String itemType;
  final Map<String, dynamic> itemData;
  final double amount;
  final String paymentStage;
  final double? totalAmount;
  final double? depositAmount;
  final double? remainingAmount;

  const PaymentScreen({
    super.key,
    required this.itemType,
    required this.itemData,
    required this.amount,
    this.paymentStage = 'full',
    this.totalAmount,
    this.depositAmount,
    this.remainingAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedCategory = 'cards';
  String _selectedSubMethod = 'visa';
  bool _isProcessing = false;
  String? _receiptPath;
  bool _acceptedPaymentSummary = false;

  bool get _showInstallments {
    if (widget.itemData['showInstallments'] == true) return true;
    final tierName = widget.itemData['rentalTier']?.toString();
    if (tierName != null) {
      try {
        final tier =
            RentalDurationTier.values.firstWhere((t) => t.name == tierName);
        return RentalRules.showMonthlyInstallments(tier);
      } catch (_) {}
    }
    return false;
  }

  double get _leaseTotalAmount {
    final raw = widget.itemData['leaseTotal'] ??
        widget.itemData['totalAmount'] ??
        widget.totalAmount;
    return BookingValidator.parsePrice(raw ?? widget.amount);
  }

  String? get _pricingTierLabel =>
      widget.itemData['pricingTierLabel']?.toString();

  RentalDurationTier? get _tier {
    final tierName = widget.itemData['rentalTier']?.toString();
    if (tierName == null) return null;
    try {
      return RentalDurationTier.values.firstWhere((t) => t.name == tierName);
    } catch (_) {
      return null;
    }
  }

  final List<Map<String, dynamic>> _bnplMethods = [
    {
      'id': 'valu',
      'name': 'ValU',
      'color': AppTheme.borderColor,
      'icon': Icons.flash_on_rounded,
      'logo': 'V'
    },
    {
      'id': 'halan',
      'name': 'Halan',
      'color': AppTheme.errorColor,
      'icon': Icons.bolt_rounded,
      'logo': 'H'
    },
    {
      'id': 'migo',
      'name': 'Migo',
      'color': AppTheme.primaryColor,
      'icon': Icons.shopping_bag_rounded,
      'logo': 'M'
    },
    {
      'id': 'mylo',
      'name': 'Mylo',
      'color': AppTheme.primaryColor,
      'icon': Icons.favorite_rounded,
      'logo': 'My'
    },
    {
      'id': 'souhoola',
      'name': 'Souhoola',
      'color': AppTheme.primaryColor,
      'icon': Icons.calendar_month_rounded,
      'logo': 'S'
    },
  ];

  final List<Map<String, dynamic>> _walletMethods = [
    {
      'id': 'vodafone',
      'name': 'Vodafone Cash',
      'color': AppTheme.errorColor,
      'icon': Icons.phone_android,
      'logo': 'VC'
    },
    {
      'id': 'instapay',
      'name': 'InstaPay',
      'color': AppTheme.primaryColor,
      'icon': Icons.send_rounded,
      'logo': 'IP'
    },
    {
      'id': 'fawry',
      'name': 'Fawry',
      'color': AppTheme.borderColor,
      'icon': Icons.storefront_rounded,
      'logo': 'F'
    },
    {
      'id': 'orange',
      'name': 'Orange Cash',
      'color': AppTheme.borderColor,
      'icon': Icons.phone_iphone,
      'logo': 'OC'
    },
  ];

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPaymentMethod();
  }

  Future<void> _loadSavedPaymentMethod() async {
    final saved = await PaymentMethodsService.getSelectedMethod();
    final defaultCard = await PaymentMethodsService.getDefaultCard();
    if (!mounted) return;
    setState(() {
      _selectedCategory = saved['category'] ?? 'cards';
      _selectedSubMethod = saved['subMethod'] ?? 'visa';
    });
    if (defaultCard != null && _selectedCategory == 'cards') {
      final num = defaultCard['number']?.toString() ?? '';
      final last4 = num.replaceAll('*', '').trim().split(' ').last;
      _cardNumberController.text = last4.length == 4
          ? '424242424242$last4'.substring(0, 16)
          : '';
      _expiryController.text = defaultCard['expiry']?.toString() ?? '';
      _nameController.text = defaultCard['holder']?.toString() ?? '';
    }
  }

  Future<void> _persistPaymentSelection() async {
    await PaymentMethodsService.saveSelectedMethod(
      category: _selectedCategory,
      subMethod: _selectedSubMethod,
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    if (!_acceptedPaymentSummary) {
      return false;
    }
    if (_selectedCategory == 'cards') {
      return _cardNumberController.text.length >= 16 &&
          _expiryController.text.contains('/') &&
          _cvvController.text.length >= 3;
    } else if (_selectedCategory == 'bnpl' || _selectedCategory == 'wallets') {
      return _phoneController.text.length >= 10;
    } else if (_selectedCategory == 'manual') {
      return _receiptPath != null;
    }
    return true;
  }

  double get _displayAmount {
    if (widget.paymentStage == 'remaining') {
      return widget.remainingAmount ?? widget.amount;
    }
    if (widget.paymentStage == 'deposit') {
      return widget.depositAmount ?? widget.amount;
    }
    return widget.amount;
  }

  String get _purposeTitle {
    if (widget.paymentStage == 'remaining') return 'استكمال دفعة الشهر الأول';
    if (widget.paymentStage == 'deposit') return 'عربون معاينة قابل للاسترداد';
    return 'دفع آمن وموثق';
  }

  Future<void> _processPayment() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على ملخص الدفع وإكمال البيانات المطلوبة'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    await _persistPaymentSelection();

    final bookingId = widget.itemData['id']?.toString() ?? '';
    final useWallet = _selectedCategory == 'wallet_balance';
    final method = useWallet
        ? 'wallet'
        : _selectedCategory == 'cards'
            ? _selectedSubMethod
            : _selectedSubMethod;

    Map<String, dynamic> result = {'success': false};

    if (widget.itemType == 'booking') {
      final bookingStatus =
          BookingStatus.normalize(widget.itemData['status']?.toString());
      if (widget.paymentStage == 'remaining' ||
          bookingStatus == BookingStatus.approved) {
        result = await DataService.completeBookingPaymentWithReceipt(
          bookingId,
          amount: _displayAmount,
          method: method,
          useWallet: useWallet,
        );
      } else {
        result = await DataService.payForBooking(
          bookingId,
          amount: _displayAmount,
          method: method,
          useWallet: useWallet,
        );
      }
    } else if (widget.itemType == 'subscription') {
      final planId =
          widget.itemData['id'] ?? widget.itemData['planId'] ?? 'bronze';
      final userType = widget.itemData['userType'] ?? 'owner';
      await SubscriptionService.subscribe(planId.toString(), userType.toString());
      final user = await AuthService.getCurrentUser();
      await WalletService.recordExternalPayment(
        title: 'اشتراك ${widget.itemData['name'] ?? planId}',
        amount: _displayAmount,
        method: method,
        bookingId: 'SUB-$planId',
        userId: user?['email']?.toString(),
      );
      result = {'success': true};
    } else if (widget.itemType == 'service') {
      final requestId = widget.itemData['id']?.toString() ?? '';
      final user = await AuthService.getCurrentUser();
      final tenantId = user?['email']?.toString() ?? '';
      result = await MaintenanceService.confirmAndPay(
        requestId: requestId,
        tenantId: tenantId,
        useWallet: useWallet,
        method: method,
      );
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'فشلت عملية الدفع'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final receipt = result['receipt'] as PaymentReceipt?;
    final successMessage = widget.itemType == 'subscription'
        ? 'تم تفعيل باقة ${widget.itemData['name'] ?? ''} بنجاح!'
        : _selectedCategory == 'manual'
            ? 'تم إرسال إيصال الدفع للمراجعة.'
            : widget.paymentStage == 'remaining'
                ? 'تم استلام المتبقي (${_displayAmount.toStringAsFixed(0)} ج.م) بنجاح.'
                : 'تم استلام العربون (${_displayAmount.toStringAsFixed(0)} ج.م) بنجاح.';

    if (receipt != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPaymentScreen(
            amount: receipt.amount,
            transactionId: receipt.id,
            paymentMethod: receipt.method,
            receipt: receipt,
            successTitle: widget.paymentStage == 'remaining'
                ? 'تم استكمال الصفقة! 🎉'
                : 'تم الدفع بنجاح! 🎉',
            successMessage: successMessage,
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: AppTheme.primaryColor),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  String _getFriendlyMethodName() {
    if (_selectedCategory == 'cards') return 'البطاقة البنكية';
    if (_selectedCategory == 'wallets') return 'المحفظة الإلكترونية';
    if (_selectedCategory == 'bnpl') return _selectedSubMethod.toUpperCase();
    return 'بوابة الدفع';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'الدفع الآمن',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0A2E26), Color(0xFF0F3A30), Color(0xFF1B594B)],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    72,
                    AppTheme.screenPadding,
                    0,
                  ),
                  child: const EjariStepIndicator(
                    labels: ['الملخص', 'طريقة الدفع', 'التأكيد'],
                    activeIndex: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    AppTheme.spaceMd,
                    AppTheme.screenPadding,
                    0,
                  ),
                  child: _buildHeroSummary(),
                ),
                if (widget.paymentStage != 'full' && _showInstallments)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenPadding,
                      AppTheme.spaceSm,
                      AppTheme.screenPadding,
                      0,
                    ),
                    child: _buildPaymentPlanCard(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    AppTheme.spaceLg,
                    AppTheme.screenPadding,
                    AppTheme.spaceSm,
                  ),
                  child: const EjariSectionHeader(
                    title: 'اختر وسيلة الدفع',
                    subtitle: 'بطاقة، محفظة، تقسيط، أو تحويل بنكي',
                  ),
                ),
                _buildCategoryGrid(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.screenPadding,
                  ),
                  child: _buildMethodSpecificForm(),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.screenPadding,
                  ),
                  child: _buildConsentCard(),
                ),
                if (_tier != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const RefundRuleTooltip(),
                              const Spacer(),
                              Text(_tier!.arabicLabel,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(RentalRules.refundPolicyShortArabic,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
                    child: EjariTrustBadges(showOwner: false),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                ],
              ],
            ),
          ),
          _buildBottomPayBar(),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSummary() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F3A30), Color(0xFF1B594B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.paymentStage == 'remaining'
                            ? 'استكمال'
                            : widget.paymentStage == 'deposit'
                                ? 'عربون'
                                : 'دفع كامل',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.shield_rounded,
                        color: AppTheme.accentColor, size: 22),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _purposeTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getItemTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.paymentStage == 'remaining'
                                ? 'المتبقي'
                                : widget.paymentStage == 'deposit'
                                    ? 'العربون'
                                    : 'المبلغ',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_displayAmount.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.paymentStage != 'full') ...[
                  const SizedBox(height: 14),
                  _buildMiniRow(
                    'إجمالي العملية',
                    widget.totalAmount ?? widget.amount,
                    light: true,
                  ),
                  _buildMiniRow(
                    'المتبقي بعد الدفع',
                    widget.paymentStage == 'remaining'
                        ? 0
                        : (widget.remainingAmount ??
                            ((widget.totalAmount ?? widget.amount) -
                                (widget.depositAmount ??
                                    ((widget.totalAmount ?? widget.amount) *
                                        0.10)))),
                    light: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, double value, {bool light = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: light
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${value.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              color: light ? Colors.white : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlanCard() {
    final isRemaining = widget.paymentStage == 'remaining';
    final isDeposit = widget.paymentStage == 'deposit';
    final title = isRemaining
        ? 'خطة استكمال الشهر الأول'
        : isDeposit
            ? 'خطة الحجز المبدئي'
            : 'خطة الدفع الحالية';
    final subtitle = isRemaining
        ? 'لن تدفع دفعة كبيرة مرة واحدة؛ فقط المتبقي من الشهر الأول، ثم سداد شهري لاحقًا.'
        : isDeposit
            ? 'العربون يحجز المعاينة ويثبت الجدية بشكل واضح.'
            : 'كل شيء ظاهر قبل التأكيد بدون التباس.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isRemaining
                      ? Icons.event_repeat_rounded
                      : isDeposit
                          ? Icons.verified_user_rounded
                          : Icons.payments_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_pricingTierLabel != null) ...[
            Text(
              'فئة التسعير: $_pricingTierLabel',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPlanChip(
                'إجمالي التعاقد',
                '${_leaseTotalAmount.toStringAsFixed(0)} ج.م',
                AppTheme.textSecondary,
              ),
              _buildPlanChip(
                'الآن',
                '${_displayAmount.toStringAsFixed(0)} ج.م',
                AppTheme.primaryColor,
              ),
              _buildPlanChip(
                'العربون',
                '${(widget.depositAmount ?? widget.amount).toStringAsFixed(0)} ج.م',
                AppTheme.borderColor,
              ),
              _buildPlanChip(
                isRemaining ? 'بعدها' : 'المتبقي',
                isRemaining
                    ? 'سداد شهري'
                    : '${(widget.remainingAmount ?? 0).toStringAsFixed(0)} ج.م',
                AppTheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard() {
    return EjariSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'تأكيد نهائي قبل الدفع',
            subtitle: 'راجع الملخص ووافق للمتابعة بأمان',
          ),
          const SizedBox(height: AppTheme.spaceSm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _acceptedPaymentSummary,
            onChanged: (value) {
              setState(() => _acceptedPaymentSummary = value ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primaryColor,
            title: const Text(
              'راجعت ملخص الدفع، وفهمت قيمة العربون/المتبقي، وأوافق على المتابعة.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'العقد النهائي هو المرجع الأساسي لأي التزام مالي.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 82,
        ),
        children: [
          _buildCatCard('wallet_balance', 'محفظة إيجاري', Icons.wallet_rounded),
          _buildCatCard('cards', 'بطاقة بنكية', Icons.credit_card_rounded),
          _buildCatCard('bnpl', 'تقسيط مباشر', Icons.timer_outlined),
          _buildCatCard(
              'wallets', 'محافظ كاش', Icons.account_balance_wallet_rounded),
          _buildCatCard('manual', 'إيداع بنكي', Icons.account_balance_rounded),
        ],
      ),
    );
  }

  Widget _buildCatCard(String id, String label, IconData icon) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() {
        _selectedCategory = id;
        if (id == 'bnpl') _selectedSubMethod = 'valu';
        if (id == 'wallets') _selectedSubMethod = 'vodafone';
        });
        _persistPaymentSelection();
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0F3A30), Color(0xFF1B594B)],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor.withOpacity(0.4)
                : AppTheme.borderColor.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSpecificForm() {
    switch (_selectedCategory) {
      case 'cards':
        return _buildCardsForm();
      case 'bnpl':
        return _buildSubMethodsGrid(_bnplMethods);
      case 'wallets':
        return _buildSubMethodsGrid(_walletMethods);
      case 'manual':
        return _buildManualForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardsForm() {
    return Column(
      children: [
        _buildInputField(_cardNumberController, 'رقم البطاقة',
            Icons.credit_card, 'xxxx xxxx xxxx xxxx'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildInputField(_expiryController, 'الانتهاء',
                    Icons.calendar_today, 'MM/YY')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildInputField(
                    _cvvController, 'CVV', Icons.lock_outline, 'xxx')),
          ],
        ),
        const SizedBox(height: 12),
        _buildInputField(_nameController, 'الاسم بالكامل', Icons.person_outline,
            'كما هو في البطاقة'),
        const SizedBox(height: 15),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 14),
            SizedBox(width: 5),
            Text('مشفر بواسطة SSL ومعتمد من البنك المركزي',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildSubMethodsGrid(List<Map<String, dynamic>> methods) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 360
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: methods
                  .map((m) => SizedBox(
                        width: itemWidth,
                        child: _buildSubMethodItem(m),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _buildInputField(_phoneController, 'رقم الموبايل المسجل',
                Icons.phone_android, '01x xxxx xxxx'),
          ],
        );
      },
    );
  }

  Widget _buildSubMethodItem(Map<String, dynamic> m) {
    final isSelected = _selectedSubMethod == m['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedSubMethod = m['id']),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? m['color']
                  : (Theme.of(context).brightness == Brightness.light
                      ? AppTheme.backgroundColor
                      : AppTheme.textPrimary),
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: m['color'].withOpacity(0.1), shape: BoxShape.circle),
              child: Center(
                  child: Text(m['logo'],
                      style: TextStyle(
                          color: m['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
            ),
            const SizedBox(height: 8),
            Text(m['name'],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.backgroundColor
                  : AppTheme.textPrimary,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(
                'سيتم إضافة تفاصيل التحويل لاحقاً. بعد إتمام التحويل، ارفع الإيصال أدناه:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            final xFile =
                await ImageUtils.pickAndCompress(source: ImageSource.gallery);
            if (xFile != null) setState(() => _receiptPath = xFile.path);
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _receiptPath == null
                      ? (Theme.of(context).brightness == Brightness.light
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary)
                      : AppTheme.primaryColor),
              image: _receiptPath != null
                  ? EjariImage.decoration(
                      path: _receiptPath!, isLocalFile: true)
                  : null,
            ),
            child: _receiptPath == null
                ? const Center(
                    child: Text('اضغط لرفع صورة الإيصال 📸',
                        style: TextStyle(color: AppTheme.primaryColor)))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      IconData icon, String hint) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.backgroundColor
                  : AppTheme.textPrimary)),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.textPrimary
                  : AppTheme.primaryColor),
          hintText: hint,
          hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBottomPayBar() {
    final buttonText = widget.paymentStage == 'remaining'
        ? 'تأكيد استكمال دفعة الشهر الأول (${_displayAmount.toStringAsFixed(0)} ج.م)'
        : widget.paymentStage == 'deposit'
            ? 'تأكيد العربون (${_displayAmount.toStringAsFixed(0)} ج.م)'
            : 'تأكيد الدفع (${_displayAmount.toStringAsFixed(0)} ج.م)';
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPadding,
          AppTheme.spaceMd,
          AppTheme.screenPadding,
          AppTheme.spaceLg,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _acceptedPaymentSummary
                          ? AppTheme.successColor.withOpacity(0.12)
                          : AppTheme.borderColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _acceptedPaymentSummary
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      color: _acceptedPaymentSummary
                          ? AppTheme.successColor
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _acceptedPaymentSummary
                          ? 'جاهز للدفع — سيتم إنشاء سجل واضح.'
                          : 'فعّل الموافقة أولاً لتأكيد الفهم والشفافية.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              SizedBox(
                width: double.infinity,
                height: AppTheme.ctaHeight,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor:
                        AppTheme.primaryColor.withOpacity(0.45),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.paymentStage == 'deposit') ...[
                const SizedBox(height: 8),
                const Text(
                  'العربون قابل للتتبع داخل العملية، والمتبقي يظهر لك لاحقًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.95),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('جاري معالجة الدفع بأمان...',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _getItemTitle() {
    return widget.itemData['title'] ?? widget.itemData['name'] ?? 'وحدة إيجاري';
  }
}
