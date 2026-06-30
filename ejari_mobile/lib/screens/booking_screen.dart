import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/insurance_service.dart';
import '../services/auth_service.dart';
import 'insurance_selection_screen.dart';
import 'contract_screen.dart';
import '../services/wallet_service.dart';
import 'success_payment_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/keyo_image.dart';
import '../l10n/app_localizations.dart';

class BookingScreen extends StatefulWidget {
  final String itemType; // 'property' or 'car'
  final Map<String, dynamic> itemData;

  const BookingScreen({
    super.key,
    required this.itemType,
    required this.itemData,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  // final _formKey = GlobalKey<FormState>();

  // Duration Settings
  String _selectedDurationType = 'شهر';
  int _duration = 1;

  // Pricing
  double _basePrice = 0;
  double _totalPrice = 0;
  double _adminFees = 0;
  double _profit = 0;
  double _insurancePrice = 0;
  String? _selectedInsuranceType;
  double _finalTotal = 0;

  // Verification
  String? _selfieImage;
  String? _idFrontImage;
  String? _idBackImage;
  bool _isPromissorySigned = false;
  String? _incomeLetterImage;
  String? _bankStatementImage;
  bool _hasFinancialDocs = true;
  bool _isLoading = false;

  bool _isContractSigned = false;
  String _selectedPaymentMethod = 'wallet'; // Default
  Map<String, dynamic>? _currentUser;

  DateTimeRange? _bookingRange;
  List<DateTime> _bookedDates = [];

  final _paymentDetailController = TextEditingController();
  final _otpController = TextEditingController();

  bool get isSale => widget.itemData['listingMode'] == 'for_sale';
  double get _bookingDepositAmount {
    final calculated = (_finalTotal * 0.10).roundToDouble();
    final safeDeposit = calculated < 500 ? 500.0 : calculated;
    return safeDeposit > _finalTotal ? _finalTotal : safeDeposit;
  }

  double get _remainingAfterDepositAmount {
    final remaining = _finalTotal - _bookingDepositAmount;
    return remaining < 0 ? 0 : remaining;
  }

  String get _paymentStageLabel =>
      isSale ? 'عربون المعاينة' : 'عربون الحجز والمعاينة';

  @override
  void initState() {
    super.initState();
    _loadUser();

    try {
      // Remove any non-numeric characters (except dot) to handle "2,500 ج.م" or similar
      String cleanPrice = widget.itemData['price']
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      _basePrice = double.tryParse(cleanPrice) ?? 0.0;
    } catch (e) {
      debugPrint('Error parsing price: $e');
      _basePrice = 0.0;
    }

    if (widget.itemType == 'car') {
      _selectedDurationType = 'يوم';
    } else if (isSale) {
      _selectedDurationType = 'مرة واحدة';
    }

    _loadAvailability();
    _calculatePrice();
  }

  Future<void> _loadAvailability() async {
    final bookedStrs = List<String>.from(widget.itemData['bookedDates'] ?? []);
    setState(() {
      _bookedDates = bookedStrs
          .map((s) => DateParsing.parse(s))
          .whereType<DateTime>()
          .toList();
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() => _currentUser = user);
  }

  void _calculatePrice() {
    if (isSale) {
      _totalPrice = _basePrice;
      // Fixed 2% commission for Keyo Sale
      _profit = _totalPrice * 0.02;
      _adminFees = 5000; // Fixed admin fee for legal checking
      _finalTotal = _totalPrice + _adminFees + _profit;
      return;
    }

    double pricePerUnit = _basePrice;

    if (widget.itemType == 'car') {
      if (_selectedDurationType == 'يوم') {
        pricePerUnit = _basePrice;
      } else if (_selectedDurationType == 'أسبوع') {
        pricePerUnit = (_basePrice * 7) * 0.90;
      } else if (_selectedDurationType == 'شهر') {
        pricePerUnit = (_basePrice * 30) * 0.80;
      } else if (_selectedDurationType == 'سنة') {
        pricePerUnit = (_basePrice * 365) * 0.70;
      }
    } else {
      if (_selectedDurationType == 'يوم') {
        pricePerUnit = _basePrice / 30;
      } else if (_selectedDurationType == 'أسبوع') {
        pricePerUnit = (_basePrice / 30 * 7) * 0.95;
      } else if (_selectedDurationType == 'شهر') {
        pricePerUnit = _basePrice;
      } else if (_selectedDurationType == 'سنة') {
        pricePerUnit = (_basePrice * 12) * 0.85;
      }
    }

    if (_bookingRange != null) {
      _duration = _bookingRange!.duration.inDays + 1;
      _selectedDurationType = 'يوم';
    }

    _totalPrice = pricePerUnit * _duration;
    _adminFees = _totalPrice * 0.05;
    _profit = _totalPrice * 0.10;
    _finalTotal = _totalPrice + _adminFees + _profit + _insurancePrice;
  }

  Future<void> _showInsuranceSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsuranceSelectionScreen(
          rentalPrice: _totalPrice,
          bookingId: widget.itemData['id']?.toString() ?? '1',
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedInsuranceType = result;
        _insurancePrice =
            InsuranceService.calculateInsuranceCost(result, _totalPrice);
      });
    }
  }

  Future<void> _submitBooking() async {
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'إتمام الحجز والدفع',
    );
    if (!allowed) return;

    // 1. Validation
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى التقاط صورة سيلفي للتحقق من هويتك'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    // 2. Payment Detail Validation
    if (_selectedPaymentMethod != 'wallet' &&
        _selectedPaymentMethod != 'cash') {
      if (_paymentDetailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى إدخال بيانات وسيلة الدفع المختارة'),
              backgroundColor: AppTheme.errorColor),
        );
        return;
      }
    }

    // 3. OTP Simulation
    if (_selectedPaymentMethod != 'cash') {
      bool otpConfirmed = await _showOtpDialog();
      if (!otpConfirmed) return;
    }

    setState(() => _isLoading = true);

    // Initial Wallet Init
    await WalletService.init();

    bool success = false;
    String message = '';
    String transactionId = '';
    final bookingDeposit = _bookingDepositAmount;

    // 1. Process Payment
    if (_selectedPaymentMethod == 'wallet') {
      // Strict Wallet Check & Deduct for the refundable deposit
      success = await WalletService.payFromWallet(
        title: 'عربون ${widget.itemData['title']}',
        amount: bookingDeposit,
        category: 'booking_deposit',
        bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!success) {
        message = 'رصيد المحفظة غير كافٍ لإتمام العملية.';
      } else {
        transactionId = 'WAL-${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      // 2. Process External Payment (Simulation)
      await Future.delayed(const Duration(seconds: 2)); // Simulate API
      success = true;
      transactionId =
          '${_selectedPaymentMethod.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';

      // Record in Ledger for Receipt
      await WalletService.recordExternalPayment(
        title: 'عربون ${widget.itemData['title']}',
        amount: bookingDeposit,
        method: _selectedPaymentMethod,
        bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (success) {
      // 3. Hold the deposit safely until the user confirms the deal
      await WalletService.holdBookingDeposit(
        title: 'عربون ${widget.itemData['title']}',
        amount: bookingDeposit,
        bookingId: transactionId,
        method: _selectedPaymentMethod,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _finalizeBooking(transactionId);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('خطأ في الدفع'),
          content: Text(message.isEmpty ? 'فشلت عملية الدفع' : message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))
          ],
        ),
      );
    }
  }

  Future<void> _finalizeBooking(String transactionId) async {
    setState(() => _isLoading = true);

    // Save to backend
    await DataService.sendBookingRequest({
      'itemType': widget.itemType,
      'title': widget.itemData['title'],
      'image': widget.itemData['image'],
      'price': _finalTotal.toStringAsFixed(0),
      'totalAmount': _finalTotal.toStringAsFixed(0),
      'depositAmount': _bookingDepositAmount.toStringAsFixed(0),
      'remainingAmount': _remainingAfterDepositAmount.toStringAsFixed(0),
      'duration': isSale ? 'تملك نهائي' : '$_duration $_selectedDurationType',
      'startDate': DateTime.now().toIso8601String(),
      'ownerId': widget.itemData['ownerId'] ?? 'admin',
      'status': 'viewing_scheduled',
      'paymentStatus': 'deposit_paid',
      'paymentPhase': 'deposit',
      'transactionId': transactionId,
      'paymentMethod': _selectedPaymentMethod,
      if (_selectedInsuranceType != null) 'insurance': _selectedInsuranceType,
      if (_insurancePrice > 0) 'insuranceCost': _insurancePrice,
      'verification': {
        'selfie': _selfieImage,
        'idFront': _idFrontImage,
        'idBack': _idBackImage,
        'incomeLetter': _incomeLetterImage,
        'bankStatement': _bankStatementImage,
        'hasPromissory': _isPromissorySigned,
      }
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to Success Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPaymentScreen(
          amount: _bookingDepositAmount,
          transactionId: transactionId,
          paymentMethod: _selectedPaymentMethod,
          successTitle: 'تم حجز المعاينة بنجاح',
          successMessage:
              'تم استلام العربون بشكل آمن. يمكنك استكمال باقي المبلغ فقط بعد تأكيدك على إتمام الصفقة.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemType == 'property' ? 'حجز عقار' : 'حجز سيارة'),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep == 1) {
            if (_selfieImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('يرجى التقاط صورة سيلفي للتحقق من هويتك'),
                    backgroundColor: AppTheme.errorColor),
              );
              return;
            }
            if (_idFrontImage == null || _idBackImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('يرجى إرفاق الوجهين لبطاقة الهوية/الرخصة'),
                    backgroundColor: AppTheme.errorColor),
              );
              return;
            }
            // For Properties (Rent): Tenant Validation
            if (widget.itemType == 'property' && !isSale) {
              if (_hasFinancialDocs) {
                if (_incomeLetterImage == null || _bankStatementImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'يرجى إرفاق مستندات الدخل وكشف الحساب، أو إيقاف الخيار لتوقيع الإقرار المالي'),
                        backgroundColor: AppTheme.errorColor),
                  );
                  return;
                }
              } else if (!_isPromissorySigned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يجب توقيع الإقرار المالي أولاً'),
                      backgroundColor: AppTheme.errorColor),
                );
                return;
              }
            }

            // Simulate Admin Approval Delay
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري إرسال البيانات ومراجعتها من قبل الإدارة...'),
                  ],
                ),
              ),
            );

            await Future.delayed(const Duration(seconds: 3));
            if (!context.mounted) return;
            Navigator.pop(context); // close dialog

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'تمت الموافقة من قبل الإدارة! ✅ يمكنك الآن متابعة التعاقد.'),
                backgroundColor: AppTheme.primaryColor));
          }
          if (!context.mounted) return;
          if (_currentStep == 2 && !_isContractSigned) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('يرجى توقيع العقد للمتابعة'),
                  backgroundColor: AppTheme.borderColor),
            );
            return;
          }

          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            _submitBooking();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : Text(_currentStep == 3 ? 'إرسال الطلب' : 'التالي'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('السابق'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Details / Purchase Options
          Step(
            title: Text(isSale ? 'التملك' : 'التفاصيل',
                overflow: TextOverflow.ellipsis, maxLines: 1),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemSummary(),
                  const SizedBox(height: 16),
                  if (widget.itemData['isDemo'] == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.borderColor),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'معلومة توضيحية: هذه البيانات مخصصة للشرح داخل التطبيق ومراجعة الخطوات قبل الإرسال.',
                              style: TextStyle(
                                  color: AppTheme.borderColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!isSale) ...[
                    const Text('تحديد فترة الحجز',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCalendarTrigger(),
                    const SizedBox(height: 24),
                    const Text('مدة الإيجار',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDurationTab('يوم'),
                          _buildDurationTab('أسبوع'),
                          _buildDurationTab('شهر'),
                          _buildDurationTab('سنة'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('عدد ال$_selectedDurationType',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_duration > 1) {
                                    setState(() {
                                      _duration--;
                                      _calculatePrice();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$_duration',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _duration++;
                                    _calculatePrice();
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield,
                            color: AppTheme.primaryColor),
                      ),
                      title: const Text('إضافة تأمين',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_insurancePrice > 0
                          ? 'تمت إضافة باقة $_selectedInsuranceType'
                          : 'احمِ استثمارك أثناء الإيجار'),
                      trailing: Switch(
                        value: _insurancePrice > 0,
                        onChanged: (val) {
                          if (val) {
                            _showInsuranceSelection();
                          } else {
                            setState(() {
                              _insurancePrice = 0;
                              _selectedInsuranceType = null;
                              _calculatePrice();
                            });
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    const Text('خيارات التملك',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.primaryColor),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'أنت الآن بصدد تقديم طلب شراء لهذا العقار بموجب عمولات كيو المخفضة (2%)',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPurchaseOption(
                        'نقداً (Cash)', 'احصل على خصم إضافي 5% عند الدفع كاش'),
                    const SizedBox(height: 12),
                    _buildPurchaseOption(
                        'تقسيط', 'خطط سداد تصل إلى 7 سنوات بأقل فائدة'),
                    const SizedBox(height: 12),
                    _buildPurchaseOption(
                        'تمويل عقاري', 'متاح عبر مبادرات البنك المركزي المصري'),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow(
                            isSale ? 'قيمة العقار' : 'الإيجار', _totalPrice),
                        _buildPriceRow(isSale ? 'عمولة كيو (2%)' : 'الرسوم',
                            isSale ? _profit : (_adminFees + _profit)),
                        if (isSale)
                          _buildPriceRow('مصاريف إدارية وقانونية', _adminFees),
                        if (!isSale && _insurancePrice > 0)
                          _buildPriceRow('التأمين', _insurancePrice),
                        ...[
                          _buildPriceRow(
                              _paymentStageLabel, _bookingDepositAmount),
                          _buildPriceRow('المتبقي بعد الموافقة',
                              _remainingAfterDepositAmount),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isSale ? 'إجمالي قيمة التعاقد' : 'الإجمالي',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${_finalTotal.toStringAsFixed(0)} ${context.tr('price_egp')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 2: Security & Verification
          Step(
            title: Text(isSale ? 'الأمان' : 'الهوية',
                overflow: TextOverflow.ellipsis, maxLines: 1),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fingerprint, color: Colors.white, size: 30),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التحقق الرقمي الآمن',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                  'نستخدم أحدث تقنيات الذكاء الاصطناعي لمطابقة الهوية.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_user, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildVerificationCard(
                    title: 'صورة السيلفي (التحقق الفوري)',
                    description: 'يرجى التقاط صورة واضحة لوجهك.',
                    icon: Icons.face,
                    isDone: _selfieImage != null,
                    onTap: () {
                      final imageWidget = ImageUploadWidget(
                        label: 'صورة السيلفي',
                        icon: Icons.camera_alt,
                        onImageSelected: (path) =>
                            setState(() => _selfieImage = path),
                      );
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => Container(
                              padding: const EdgeInsets.all(20),
                              child: imageWidget));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildVerificationCard(
                    title: isSale
                        ? 'الهوية الوطنية (الوجه الأمامي)'
                        : (widget.itemType == 'car'
                            ? 'رخصة القيادة (أمامي)'
                            : 'الهوية الوطنية (أمامي)'),
                    description: 'يرجى تصوير الوجه الأمامي بوضوح.',
                    icon: Icons.credit_card,
                    isDone: _idFrontImage != null,
                    onTap: () {
                      final imageWidget = ImageUploadWidget(
                        label: 'الوجه الأمامي',
                        icon: Icons.document_scanner,
                        onImageSelected: (path) =>
                            setState(() => _idFrontImage = path),
                      );
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => Container(
                              padding: const EdgeInsets.all(20),
                              child: imageWidget));
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildVerificationCard(
                    title: isSale
                        ? 'الهوية الوطنية (الخلفي)'
                        : (widget.itemType == 'car'
                            ? 'رخصة القيادة (الخلفي)'
                            : 'الهوية الوطنية (الخلفي)'),
                    description: 'يرجى تصوير الوجه الخلفي بوضوح.',
                    icon: Icons.credit_card,
                    isDone: _idBackImage != null,
                    onTap: () {
                      final imageWidget = ImageUploadWidget(
                        label: 'الوجه الخلفي',
                        icon: Icons.document_scanner,
                        onImageSelected: (path) =>
                            setState(() => _idBackImage = path),
                      );
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => Container(
                              padding: const EdgeInsets.all(20),
                              child: imageWidget));
                    },
                  ),
                  if (widget.itemType == 'property' && !isSale) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text('الملاءة المالية (إلزامي للإيجار)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('أمتلك إثبات دخل وكشف حساب بنكي'),
                      subtitle: const Text('لتسريع الموافقة على الحجز'),
                      value: _hasFinancialDocs,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) =>
                          setState(() => _hasFinancialDocs = val),
                    ),
                    if (_hasFinancialDocs) ...[
                      const SizedBox(height: 16),
                      _buildVerificationCard(
                        title: 'خطاب إثبات دخل أو جهة عمل',
                        description: 'مستند حديث يثبت الراتب أو الدخل.',
                        icon: Icons.work_outline,
                        isDone: _incomeLetterImage != null,
                        onTap: () {
                          final imageWidget = ImageUploadWidget(
                            label: 'خطاب الدخل',
                            icon: Icons.document_scanner,
                            onImageSelected: (path) =>
                                setState(() => _incomeLetterImage = path),
                          );
                          showModalBottomSheet(
                              context: context,
                              builder: (_) => Container(
                                  padding: const EdgeInsets.all(20),
                                  child: imageWidget));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildVerificationCard(
                        title: 'كشف حساب بنكي (آخر 3 شهور)',
                        description: 'للتأكد من القدرة على الالتزام بالإيجار.',
                        icon: Icons.account_balance,
                        isDone: _bankStatementImage != null,
                        onTap: () {
                          final imageWidget = ImageUploadWidget(
                            label: 'كشف الحساب',
                            icon: Icons.document_scanner,
                            onImageSelected: (path) =>
                                setState(() => _bankStatementImage = path),
                          );
                          showModalBottomSheet(
                              context: context,
                              builder: (_) => Container(
                                  padding: const EdgeInsets.all(20),
                                  child: imageWidget));
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: AppTheme.borderColor),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'في حال عدم توفر مستندات الملاءة المالية، سيُطلب منك التوقيع الإلكتروني على "إقرار التزام مالي / سند لأمر" لضمان تسديد الإيجار شهرياً كشرط أساسي.',
                                    style: TextStyle(
                                        color: AppTheme.borderColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isPromissorySigned)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: AppTheme.primaryColor),
                                    SizedBox(width: 8),
                                    Text('تم توقيع الإقرار المالي بنجاح ✅',
                                        style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ContractScreen(
                                          itemLabel: 'سند لأمر',
                                          ownerName: 'إدارة كيو (الضامن)',
                                          tenantName: _currentUser?['name'] ??
                                              'المستأجر',
                                          propertyTitle:
                                              'إقرار بالالتزام الشهري في موعده',
                                          price: _totalPrice.toStringAsFixed(0),
                                          startDate: DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0],
                                          duration: 'حتى نهاية التعاقد',
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      setState(
                                          () => _isPromissorySigned = true);
                                    }
                                  },
                                  icon: const Icon(Icons.edit_document),
                                  label: const Text('توقيع السند لأمر الآن'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.borderColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            isActive: _currentStep >= 1,
          ),

          // Step 3: Contract / Documentation
          Step(
            title: Text(isSale ? 'التوثيق' : 'العقد',
                overflow: TextOverflow.ellipsis, maxLines: 1),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Icon(isSale ? Icons.assignment_turned_in : Icons.gavel,
                      size: 50, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(isSale ? 'مستند رغبة الشراء' : 'العقد القانوني',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    isSale
                        ? 'يرجى التوقيع على مستند إبداء الرغبة الجدية في الشراء لضمان أولوية الحجز.'
                        : 'يرجى مراجعة وتوقيع العقد الإلكتروني لضمان حقوق كافة الأطراف.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (_isContractSigned)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                              isSale
                                  ? 'تم التوقيع بنجاح ✅'
                                  : 'تم توقيع العقد بنجاح ✅',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _openContractScreen,
                      icon: const Icon(Icons.edit_document),
                      label: Text(
                          isSale ? 'توقيع طلب الشراء' : 'عرض وتوقيع العقد'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12)),
                    ),
                ],
              ),
            ),
            isActive: _currentStep >= 2,
          ),

          // Step 4: Final Review
          Step(
            title: Text(isSale ? 'التأكيد' : 'المراجعة',
                overflow: TextOverflow.ellipsis, maxLines: 1),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 40, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(isSale ? 'ملخص رغبة التملك' : 'ملخص الطلب',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 16),
                        _buildWhiteSummaryRow(
                            'العقار', widget.itemData['title']),
                        if (!isSale)
                          _buildWhiteSummaryRow(
                              'المدة', '$_duration $_selectedDurationType'),
                        _buildWhiteSummaryRow(
                            'النوع', isSale ? 'شراء نهائي' : 'إيجار ذكي'),
                        ...[
                          const SizedBox(height: 8),
                          _buildWhiteSummaryRow('العربون الآن',
                              _bookingDepositAmount.toStringAsFixed(0)),
                          _buildWhiteSummaryRow('المتبقي بعد المعاينة',
                              _remainingAfterDepositAmount.toStringAsFixed(0)),
                        ],
                        const Divider(color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isSale ? 'إجمالي الدفعة' : 'الإجمالي',
                                style: const TextStyle(color: Colors.white70)),
                            Text(
                                '${_finalTotal.toStringAsFixed(0)} ${context.tr('price_egp')}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isSale) ...[
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text('اختر وسيلة الدفع',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio:
                          1.0, // Changed from 0.85 to be more square/stable
                      children: [
                        _buildPaymentOption(
                            'محفظة كيو',
                            Icons.account_balance_wallet_rounded,
                            'wallet',
                            AppTheme.primaryColor),
                        _buildPaymentOption(
                            'إنستاباي',
                            Icons.send_to_mobile_rounded,
                            'instapay',
                            AppTheme.primaryColor),
                        _buildPaymentOption(
                            'فودافون كاش',
                            Icons.phone_android_rounded,
                            'vodafone_cash',
                            AppTheme.errorColor),
                        _buildPaymentOption(
                            'بطاقة ائتمان',
                            Icons.credit_card_rounded,
                            'card',
                            AppTheme.borderColor),
                        _buildPaymentOption('أبل باي', Icons.apple_rounded,
                            'apple_pay', AppTheme.textPrimary),
                        _buildPaymentOption('فوري', Icons.store_rounded,
                            'fawry', AppTheme.borderColor),
                        _buildPaymentOption(
                            'تحويل بنكي',
                            Icons.account_balance_rounded,
                            'bank_transfer',
                            AppTheme.primaryColor),
                        _buildPaymentOption(
                            'دفع نقدي (كاش)',
                            Icons.payments_rounded,
                            'cash',
                            AppTheme.primaryColor),
                      ],
                    ),
                    if (!isSale && _selectedPaymentMethod != 'cash') ...[
                      const SizedBox(height: 24),
                      _buildPaymentInput(),
                    ],
                  ] else ...[
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text('خطة التواصل',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    const Text('سيقوم مستشار كيو بالتواصل معك خلال 24 ساعة.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, height: 1.4)),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isSale
                              ? 'تقديم طلب الشراء'
                              : 'إتمام الحجز والدفع'),
                    ),
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildItemSummary() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: KeyoImage.provider(
              widget.itemData['image'],
              isLocalFile: !widget.itemData['image'].startsWith('assets/'),
            ),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/home1.jpg',
                width: 60,
                height: 60,
                fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.itemData['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.itemData['price']} ${context.tr('price_egp')}',
                  style: const TextStyle(color: AppTheme.primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationTab(String title) {
    bool isSelected = _selectedDurationType == title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDurationType = title;
        _calculatePrice();
      }),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (Theme.of(context).brightness == Brightness.light
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary)),
        ),
        child: Text(title,
            style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.light
                        ? AppTheme.textSecondary
                        : AppTheme.primaryColor))),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text('${amount.toStringAsFixed(0)} ${context.tr('price_egp')}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCalendarTrigger() {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bookingRange == null
                        ? 'اختر تاريخ البداية والنهاية'
                        : 'فترة الحجز المختارة',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            AppTheme.primaryColor),
                  ),
                  if (_bookingRange != null)
                    Text(
                      'من ${_bookingRange!.start.toIso8601String().substring(0, 10)} إلى ${_bookingRange!.end.toIso8601String().substring(0, 10)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  else
                    const Text('تحديد المواعيد المتاحة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _bookingRange,
      helpText: 'اختر مدة الحجز',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      saveText: 'حفظ',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Check for overlap with _bookedDates
      bool hasOverlap = false;
      for (int i = 0; i <= picked.duration.inDays; i++) {
        final date = picked.start.add(Duration(days: i));
        if (_bookedDates.any((d) =>
            d.year == date.year &&
            d.month == date.month &&
            d.day == date.day)) {
          hasOverlap = true;
          break;
        }
      }

      if (hasOverlap) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('عذراً، هذه الفترة تحتوي على أيام محجوزة مسبقاً ❌'),
                backgroundColor: AppTheme.errorColor),
          );
        }
      } else {
        setState(() {
          _bookingRange = picked;
          _calculatePrice();
        });
      }
    }
  }

  Widget _buildWhiteSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? AppTheme.primaryColor : AppTheme.primaryColor,
            width: isDone ? 2 : 1,
          ),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                color: isDone ? AppTheme.primaryColor : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDone ? 'تم التحقق بنجاح' : description,
                    style: TextStyle(
                      color: isDone
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _openContractScreen() async {
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'توقيع العقد',
    );
    if (!allowed) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractScreen(
          ownerName: 'الشركة المالكة',
          tenantName: _currentUser?['name'] ?? 'المستأجر',
          propertyTitle: widget.itemData['title'],
          price: _finalTotal.toStringAsFixed(0),
          startDate: DateTime.now().toString().split(' ')[0],
          duration: '$_duration $_selectedDurationType',
          deposit: _bookingDepositAmount.toStringAsFixed(0),
          itemLabel: widget.itemType == 'car' ? 'السيارة' : 'العقار',
        ),
      ),
    );

    if (result == true) {
      setState(() => _isContractSigned = true);
    }
  }

  Widget _buildPaymentOption(
      String title, IconData icon, String value, Color color) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (Theme.of(context).brightness == Brightness.light
                    ? AppTheme.backgroundColor
                    : AppTheme.textPrimary),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : (Theme.of(context).brightness == Brightness.light
                        ? AppTheme.backgroundColor
                        : AppTheme.textPrimary),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? color
                    : (Theme.of(context).brightness == Brightness.light
                        ? AppTheme.textPrimary
                        : AppTheme.primaryColor),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOption(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.payments_rounded,
                color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            AppTheme.primaryColor,
                        fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildPaymentInput() {
    String label = '';
    String hint = '';
    TextInputType keyboardType = TextInputType.text;

    switch (_selectedPaymentMethod) {
      case 'card':
        label = 'بيانات بطاقة الائتمان';
        hint = '0000 0000 0000 0000';
        keyboardType = TextInputType.number;
        break;
      case 'vodafone_cash':
        label = 'رقم محفظة فودافون كاش';
        hint = '010XXXXXXXX';
        keyboardType = TextInputType.phone;
        break;
      case 'instapay':
        label = 'عنوان الدفع (InstaPay ID)';
        hint = 'username@instapay';
        break;
      case 'fawry':
        label = 'رقم الهاتف للدفع عبر فوري';
        hint = '01XXXXXXXXX';
        keyboardType = TextInputType.phone;
        break;
      case 'apple_pay':
        label = 'تأكيد عبر Apple ID';
        hint = 'أدخل البريد المرتبط بحساب Apple';
        keyboardType = TextInputType.emailAddress;
        break;
      case 'bank_transfer':
        label = 'اسم المحول / رقم الحساب';
        hint = 'أدخل تفاصيل التحويل المرجعية';
        break;
      case 'wallet':
        label = 'تأكيد الدفع من محفظة كيو';
        hint = 'سيتم الخصم من رصيدك المتاح';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.primaryColor.withOpacity(0.2))),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'سيتم الخصم مباشرة من رصيد محفظة كيو الخاص بك المتوفر حالياً.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.primaryColor))),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _paymentDetailController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor)),
          ),
        ),
      ],
    );
  }

  Future<bool> _showOtpDialog() async {
    _otpController.clear();
    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.security_rounded,
                size: 40, color: AppTheme.primaryColor),
            SizedBox(height: 12),
            Text('تأكيد عملية السحب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          // Added scroll view to prevent keyboard overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'من أجل أمانك، تم إرسال رمز تأكيد (OTP) إلى هاتفك لتأكيد سحب المبلغ من حسابك.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8),
                maxLength: 4,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "0000",
                  hintStyle: TextStyle(
                      color: Theme.of(context).hintColor.withOpacity(0.3),
                      letterSpacing: 8),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لم تستلم الرمز؟', style: TextStyle(fontSize: 11)),
                  TextButton(
                      onPressed: () {},
                      child: const Text('إعادة إرسال',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('إلغاء',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color ??
                              AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_otpController.text.length == 4) {
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('يرجى إدخال رمز OTP المكون من 4 أرقام')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تأكيد الدفع'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
