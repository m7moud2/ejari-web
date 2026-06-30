import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ejari_image.dart';
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

  String get _purposeDescription {
    if (widget.paymentStage == 'remaining') {
      return 'هذا الجزء يُسدَّد لاستكمال الشهر الأول فقط، ثم تُستكمل الدفعات شهرياً وفق العقد.';
    }
    if (widget.paymentStage == 'deposit') {
      return 'هذا المبلغ يُستخدم لحجز المعاينة وتثبيت الجدية، ويظهر لك بوضوح قبل التأكيد.';
    }
    return 'مبلغ العملية يظهر لك قبل الدفع مع سجل واضح وإيصال رقمي.';
  }

  String get _flowTitle {
    if (widget.paymentStage == 'remaining') return 'استكمال دفعة الشهر الأول';
    if (widget.paymentStage == 'deposit') return 'عربون حجز واضح وقابل للتتبع';
    return 'دفع كامل موضح قبل التأكيد';
  }

  String get _flowSubtitle {
    if (widget.paymentStage == 'remaining') {
      return 'أنت هنا في مرحلة استكمال المتبقي من الشهر الأول فقط بعد الموافقة.';
    }
    if (widget.paymentStage == 'deposit') {
      return 'أنت تدفع عربونًا أوليًا لحجز المعاينة وتثبيت الجدية.';
    }
    return 'أنت تدفع المبلغ كاملًا مع ملخص واضح قبل التنفيذ.';
  }

  List<String> get _legalNotes {
    if (widget.paymentStage == 'remaining') {
      return [
        'لن يتم احتساب سوى المتبقي من الشهر الأول هنا، ثم تُفعل المتابعة الشهرية.',
        'ستصل لك فاتورة/إيصال رقمي ورقم مرجعي للعملية.',
        'العقد النهائي يوضح قيمة الإيجار الشهري والعربون والالتزامات.',
      ];
    }

    return [
      'العربون يثبت جدية الحجز والمعاينة وليس دفعة نهائية.',
      'يظهر لك المبلغ المتبقي قبل استكمال أي خطوة لاحقة.',
      'يمكن معالجة الاسترداد حسب حالة الصفقة والشروط المتفق عليها.',
      'هذه الشاشة لا تغني عن مراجعة العقد النهائي قبل التوقيع.',
    ];
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

    _showSuccessVibe(successMessage);
  }

  void _showSuccessVibe(String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessScreen(
          title: widget.paymentStage == 'remaining'
              ? 'تم استكمال الصفقة! 🎉'
              : 'تم حفظ العربون بنجاح! 🎉',
          message: message,
          onContinue: () {
            Navigator.pop(context); // Pop Success
            Navigator.pop(context, true); // Pop Payment
          },
        ),
      ),
    );
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
        title: const Text('الدفع الآمن والموضح',
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
                  child: _buildHeroSummary(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _buildStageBanner(),
                ),
                if (widget.paymentStage != 'full')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _buildPaymentPlanCard(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildLegalClarityCard(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildFlowCard(),
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

  Widget _buildHeroSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.payments_rounded,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_purposeTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 4),
                    Text(_getItemTitle(),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('معرف العملية: #EJ-${widget.itemData['id'] ?? '882'}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.paymentStage == 'remaining'
                              ? 'المتبقي من الشهر الأول'
                              : widget.paymentStage == 'deposit'
                                  ? 'العربون الآن'
                                  : 'المبلغ الحالي',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${_displayAmount.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.paymentStage == 'remaining'
                        ? 'استكمال شهري'
                        : widget.paymentStage == 'deposit'
                            ? 'عربون'
                            : 'دفع كامل',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildMiniRow(
              widget.paymentStage == 'remaining'
                  ? 'قيمة الشهر الحالي'
                  : 'إجمالي العملية',
              widget.totalAmount ?? widget.amount),
          _buildMiniRow(
              widget.paymentStage == 'remaining'
                  ? 'العربون المحجوز'
                  : 'العربون',
              widget.paymentStage == 'remaining'
                  ? _displayAmount
                  : (widget.depositAmount ??
                      ((widget.totalAmount ?? widget.amount) * 0.10))),
          _buildMiniRow(
              widget.paymentStage == 'remaining'
                  ? 'المتبقي بعد العربون'
                  : 'المبلغ المتبقي',
              widget.paymentStage == 'remaining'
                  ? 0
                  : (widget.remainingAmount ??
                      ((widget.totalAmount ?? widget.amount) -
                          (widget.depositAmount ??
                              ((widget.totalAmount ?? widget.amount) *
                                  0.10))))),
          const SizedBox(height: 10),
          Text(_purposeDescription,
              style: const TextStyle(
                  color: AppTheme.textSecondary, height: 1.5, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStageBanner() {
    final isDeposit = widget.paymentStage == 'deposit';
    final isRemaining = widget.paymentStage == 'remaining';
    final accent = isRemaining ? AppTheme.borderColor : AppTheme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRemaining
                  ? Icons.check_circle_outline_rounded
                  : isDeposit
                      ? Icons.how_to_reg_rounded
                      : Icons.verified_outlined,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRemaining
                      ? 'أنت في مرحلة الاستكمال النهائية'
                      : isDeposit
                          ? 'أنت في مرحلة العربون المبدئي'
                          : 'أنت في مرحلة الدفع الكامل',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRemaining
                      ? 'ادفع الجزء المتبقي فقط بعد موافقتك النهائية على الإتمام.'
                      : isDeposit
                          ? 'العربون يثبت الجدية ويُوضح لك المتبقي قبل أي خطوة لاحقة.'
                          : 'راجع المبلغ، اختر وسيلة الدفع، وأكد العملية بوضوح.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text('${value.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMethodSectionHeader() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('1',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        const Text('اختر وسيلة الدفع',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
      ],
    );
  }

  Widget _buildLegalClarityCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded,
                    size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('ملخص قانوني وشفاف',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ),
              TextButton(
                onPressed: _showLegalDetailsSheet,
                child: const Text('التفاصيل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._legalNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'هذه الشاشة تعرض طريقة الدفع، لكن العقد النهائي هو المرجع الأساسي لأي التزام مالي أو قانوني.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary.withOpacity(0.9),
              height: 1.4,
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

  Widget _buildFlowCard() {
    final steps = widget.paymentStage == 'remaining'
        ? const [
            ('راجع ملخص الشهر', 'تأكد أن استكمال الشهر الأول مناسب لك.'),
            (
              'ادفع الباقي فقط',
              'لا توجد أي دفعة إضافية غير المتبقي من الشهر الأول.'
            ),
            ('أكمل التوثيق', 'سيتم تسجيل العملية وإصدار الإشعار.'),
          ]
        : widget.paymentStage == 'deposit'
            ? const [
                ('ادفع العربون', 'المبلغ يثبت الجدية ويحجز المعاينة.'),
                ('عاين على الواقع', 'راجع الوحدة قبل القرار النهائي.'),
                ('استكمل أو أوقف', 'بعد المعاينة، قرر الخطوة التالية.'),
              ]
            : const [
                ('راجع الإجمالي', 'شاهد كل الأرقام قبل التأكيد.'),
                ('اختر وسيلة الدفع', 'حدد الوسيلة الأنسب لك.'),
                ('أصدر الإيصال', 'يتم إنشاء سجل واضح فورًا.'),
              ];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route_rounded,
                    size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('كيف تمشي العملية؟',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _flowTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _flowSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (widget.paymentStage == 'deposit') ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.borderColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.18),
                ),
              ),
              child: const Text(
                'مهم: العربون هنا ليس دفعة نهائية. المتبقي يظهر لك بوضوح بعد المعاينة، وتكمل فقط إذا قررت إتمام الصفقة.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
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
            'لو عندك أي جزء غير واضح، افتح "التفاصيل" قبل الضغط على زر الدفع.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _showLegalDetailsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التوضيح القانوني المختصر',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
                const SizedBox(height: 12),
                const Text(
                  '• العربون هنا مخصص لحجز المعاينة أو تثبيت الجدية.\n'
                  '• المبلغ المتبقي هنا هو فقط المتبقي من دفعة الشهر الأول.\n'
                  '• أي استرداد أو ترحيل مالي يجب أن يتبع حالة الصفقة الموثقة في العقد.\n'
                  '• يفضّل مراجعة النسخة النهائية من العقد أو المستشار القانوني قبل التوقيع.',
                  style: TextStyle(height: 1.7, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('فهمت',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
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
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((m) => _buildSubMethodItem(m)).toList(),
        ),
        const SizedBox(height: 20),
        _buildInputField(_phoneController, 'رقم الموبايل المسجل',
            Icons.phone_android, '01x xxxx xxxx'),
      ],
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('فودافون كاش:',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color)),
                const Text('01069813210',
                    style: TextStyle(fontWeight: FontWeight.bold))
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('InstaPay IPA:',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color)),
                const Text('ejari@instapay',
                    style: TextStyle(fontWeight: FontWeight.bold))
              ]),
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
                child: Text(buttonText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
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
