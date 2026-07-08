import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ejari_image.dart';
import 'rental_statement_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'success_screen.dart';

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
          content: Text('يرجى إكمال كافة البيانات المطلوبة لإتمام الدفع الآمن'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 4));

    if (widget.itemType == 'booking') {
      if (widget.paymentStage == 'remaining') {
        await WalletService.recordExternalPayment(
          title:
              'استكمال دفعة الشهر الأول ${widget.itemData['title'] ?? 'الحجز'}',
          amount: _displayAmount,
          method: _selectedCategory,
          bookingId: widget.itemData['id']?.toString() ?? '',
        );
        await DataService.completeBookingPayment(widget.itemData['id']);
        await WalletService.releaseBookingDeposit(
          title: 'عربون ${widget.itemData['title'] ?? 'الحجز'}',
          amount: widget.depositAmount ??
              ((widget.totalAmount ?? widget.amount) * 0.10),
          bookingId: widget.itemData['id']?.toString() ?? '',
          ownerId: widget.itemData['ownerId']?.toString() ?? 'unknown_owner',
        );
      } else {
        await WalletService.recordExternalPayment(
          title: 'عربون ${widget.itemData['title'] ?? 'الحجز'}',
          amount: _displayAmount,
          method: _selectedCategory,
          bookingId: widget.itemData['id']?.toString() ?? '',
        );
        await DataService.payForBooking(widget.itemData['id']);
      }
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final successMessage = _selectedCategory == 'manual'
        ? 'لقد تم إرسال إيصال الدفع للمراجعة. سيتم تفعيل الخدمة فور التأكد من التحويل.'
        : widget.paymentStage == 'remaining'
            ? 'تم استلام المتبقي من الشهر الأول (${_displayAmount.toStringAsFixed(0)} ج.م) بنجاح عبر ${_getFriendlyMethodName()}.'
            : 'تم استلام عربون المعاينة (${_displayAmount.toStringAsFixed(0)} ج.م) بنجاح عبر ${_getFriendlyMethodName()}.';

    await _showSuccessVibe(successMessage);
  }

  Future<void> _showSuccessVibe(String message) async {
    final shouldOpenStatement = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessScreen(
          title: widget.paymentStage == 'remaining'
              ? 'تم استكمال الصفقة! 🎉'
              : 'تم حفظ العربون بنجاح! 🎉',
          message: message,
          onContinue: () {
            Navigator.pop(context, true); // Close success and signal continue
          },
          buttonText: 'عرض كشف الحساب',
        ),
      ),
    );

    if (!mounted) return;
    if (shouldOpenStatement == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RentalStatementScreen(),
        ),
      );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الدفع',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildCheckoutSteps(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _buildHeroSummary(),
                ),
                if (widget.paymentStage != 'full')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _buildPaymentPlanCard(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildMethodSectionHeader(),
                ),
                _buildCategoryGrid(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMethodSpecificForm(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildConsentCard(),
                ),
              ],
            ),
          ),
          _buildBottomPayBar(),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCheckoutSteps() {
    const steps = ['الملخص', 'طريقة الدفع', 'التأكيد'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color:
                                isActive ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: index == 0
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : AppTheme.borderColor.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeroSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_purposeTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 4),
          Text(_getItemTitle(),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
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
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text('${_displayAmount.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.paymentStage == 'remaining'
                      ? 'استكمال'
                      : widget.paymentStage == 'deposit'
                          ? 'عربون'
                          : 'كامل',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          if (widget.paymentStage != 'full') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildMiniRow(
                'إجمالي العملية', widget.totalAmount ?? widget.amount),
            _buildMiniRow(
                'المتبقي بعد الدفع',
                widget.paymentStage == 'remaining'
                    ? 0
                    : (widget.remainingAmount ??
                        ((widget.totalAmount ?? widget.amount) -
                            (widget.depositAmount ??
                                ((widget.totalAmount ?? widget.amount) *
                                    0.10))))),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text('${value.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMethodSectionHeader() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('2',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 0),
        const Text('اختر وسيلة الدفع',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
      ],
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تأكيد نهائي قبل الدفع',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 10),
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
          mainAxisExtent: 75,
        ),
        children: [
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
      onTap: () => setState(() {
        _selectedCategory = id;
        if (id == 'bnpl') _selectedSubMethod = 'valu';
        if (id == 'wallets') _selectedSubMethod = 'vodafone';
      }),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10)
                ]
              : [],
          border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (Theme.of(context).brightness == Brightness.light
                      ? AppTheme.backgroundColor
                      : AppTheme.textPrimary)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (Theme.of(context).brightness == Brightness.light
                            ? AppTheme.textPrimary
                            : AppTheme.primaryColor),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal)),
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
              Text('قم بالتحويل لأي من الحسابات التالية وارفع الإيصال:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              _buildAccountLine('فودافون كاش:', '01069813210'),
              const SizedBox(height: 8),
              _buildAccountLine('InstaPay IPA:', 'ejari@instapay'),
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

  Widget _buildAccountLine(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            boxShadow: const []),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _acceptedPaymentSummary
                    ? 'بمجرد الضغط سيتم إنشاء سجل دفع واضح وإشعار للحالة.'
                    : 'فعّل الموافقة أولاً لتأكيد الفهم والشفافية.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor:
                      AppTheme.primaryColor.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.paymentStage == 'deposit') ...[
                const SizedBox(height: 8),
                const Text(
                  'العربون قابل للتتبع داخل العملية، والمتبقي يظهر لك لاحقًا قبل الإتمام النهائي.',
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
