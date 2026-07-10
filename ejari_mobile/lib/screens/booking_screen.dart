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
import '../utils/rental_schedule_utils.dart';
import '../utils/rental_pricing.dart';
import '../utils/rental_rules.dart';
import '../models/rental_duration_tier.dart';
import '../models/booking_status.dart';
import '../models/tenant_type.dart';
import '../widgets/rental_booking_widgets.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/ejari_image.dart';
import '../widgets/ejari_section.dart';
import '../widgets/smart_booking_assistant.dart';
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
  TenantType _tenantType = TenantType.individual;

  // Pricing
  double _basePrice = 0;
  double _totalPrice = 0;
  double _adminFees = 0;
  double _profit = 0;
  double _insurancePrice = 0;
  String? _selectedInsuranceType;
  double _finalTotal = 0;
  RentalPricingResult? _pricingResult;

  // Verification
  String? _selfieImage;
  String? _idFrontImage;
  String? _idBackImage;
  bool _isPromissorySigned = false;
  String? _incomeLetterImage;
  String? _bankStatementImage;
  String? _employmentLetterImage;
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
  bool get _isCar => widget.itemType == 'car';
  bool get _isPropertyRent => widget.itemType == 'property' && !isSale;
  double get _monthlyRent => _basePrice;

  RentalDurationTier get _rentalTier =>
      RentalRules.resolveTier(_selectedDurationType, _duration);

  bool get _showInstallments =>
      _isPropertyRent && RentalRules.showMonthlyInstallments(_rentalTier);

  bool get _requiresIncomeProof =>
      _isPropertyRent && RentalRules.requiresIncomeProof(_rentalTier);

  bool get _requiresAdvanceOnly =>
      _isPropertyRent && RentalRules.requiresAdvanceDeposit(_rentalTier);

  DateTime get _checkInDate =>
      _bookingRange?.start ?? DateTime.now().add(const Duration(days: 3));

  double get _leaseTotalAmount => isSale || _isCar ? _finalTotal : _totalPrice;

  double get _currentMonthTotal => isSale || _isCar
      ? _finalTotal
      : _totalPrice + _adminFees + _profit + _insurancePrice;

  double get _bookingDepositAmount {
    if (isSale || _isCar) {
      final calculated = (_finalTotal * 0.10).roundToDouble();
      final safeDeposit = calculated < 500 ? 500.0 : calculated;
      return safeDeposit > _finalTotal ? _finalTotal : safeDeposit;
    }

    final calculated = (_currentMonthTotal * RentalRules.advanceDepositRate(_rentalTier))
        .roundToDouble();
    final safeDeposit = calculated < 500 ? 500.0 : calculated;
    return safeDeposit > _currentMonthTotal ? _currentMonthTotal : safeDeposit;
  }

  double get _remainingAfterDepositAmount {
    final remaining = _preEntryTotalAmount - _bookingDepositAmount;
    return remaining < 0 ? 0 : remaining;
  }

  /// المطلوب قبل الدخول: عربون + أول فترة إيجار.
  double get _firstPeriodAmount {
    if (isSale || _isCar) return 0;
    return _currentMonthTotal;
  }

  double get _preEntryTotalAmount {
    if (isSale || _isCar) return _finalTotal;
    return _bookingDepositAmount + _firstPeriodAmount;
  }

  String get _paymentStageLabel => isSale
      ? 'عربون المعاينة'
      : _isCar
          ? 'عربون الحجز'
          : RentalRules.advanceDepositLabel(_rentalTier);

  List<String> get _stepLabels {
    if (isSale) return ['التملك', 'الأمان', 'التوثيق', 'التأكيد'];
    if (_isCar) return ['المدة', 'التحقق', 'العقد', 'الدفع'];
    switch (_rentalTier) {
      case RentalDurationTier.daily:
        return ['إيجار يومي', 'دفع مقدم', 'العقد', 'الدفع'];
      case RentalDurationTier.weekly:
        return ['إيجار أسبوعي', 'دفع مقدم', 'العقد', 'الدفع'];
      case RentalDurationTier.shortTerm:
        return ['قصير المدى', 'دفع مقدم', 'العقد', 'الدفع'];
      case RentalDurationTier.medium:
        return ['٦+ شهور', 'المستندات', 'العقد', 'الأقساط'];
      case RentalDurationTier.longTerm:
        return ['سنة فأكثر', 'المستندات', 'العقد', 'الأقساط'];
    }
  }

  String _stepTitle(int index) {
    if (index < 0 || index >= _stepLabels.length) return '';
    return _stepLabels[index];
  }

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
      // Fixed 2% commission for Ejari Sale
      _profit = _totalPrice * 0.02;
      _adminFees = 5000; // Fixed admin fee for legal checking
      _finalTotal = _totalPrice + _adminFees + _profit;
      return;
    }

    if (_isCar) {
      if (_selectedDurationType == 'يوم') {
        _totalPrice = _basePrice;
      } else if (_selectedDurationType == 'أسبوع') {
        _totalPrice = (_basePrice * 7) * 0.90;
      } else if (_selectedDurationType == 'شهر') {
        _totalPrice = (_basePrice * 30) * 0.80;
      } else if (_selectedDurationType == 'سنة') {
        _totalPrice = (_basePrice * 365) * 0.70;
      } else {
        _totalPrice = _basePrice;
      }
      _adminFees = _totalPrice * 0.05;
      _profit = _totalPrice * 0.10;
      _finalTotal = _totalPrice + _adminFees + _profit + _insurancePrice;
      return;
    }

    _pricingResult = RentalPricing.calculate(
      monthlyRent: _monthlyRent,
      durationType: _selectedDurationType,
      durationCount: _duration,
    );
    _totalPrice = _pricingResult!.totalRent;
    _adminFees = _totalPrice * 0.05;
    _profit = _totalPrice * 0.10;
    _finalTotal = _currentMonthTotal;
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
    final messenger = ScaffoldMessenger.of(context);
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'إتمام الحجز والدفع',
    );
    if (!allowed) return;
    if (!mounted) return;

    // 1. Validation
    if (_selfieImage == null) {
      messenger.showSnackBar(
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
        messenger.showSnackBar(
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
      if (!mounted) return;
    }

    setState(() => _isLoading = true);

    // Initial Wallet Init
    await WalletService.init();

    bool success = false;
    String message = '';
    String transactionId = '';
    final payAmount = _isPropertyRent ? _preEntryTotalAmount : _bookingDepositAmount;

    // 1. Process Payment
    if (_selectedPaymentMethod == 'wallet') {
      success = await WalletService.payFromWallet(
        title: _isPropertyRent
            ? 'دفع قبل الدخول — ${widget.itemData['title']}'
            : 'عربون ${widget.itemData['title']}',
        amount: payAmount,
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
        title: _isPropertyRent
            ? 'دفع قبل الدخول — ${widget.itemData['title']}'
            : 'عربون ${widget.itemData['title']}',
        amount: payAmount,
        method: _selectedPaymentMethod,
        bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    if (success) {
      // 3. Hold the deposit safely until the user confirms the deal
      await WalletService.holdBookingDeposit(
        title: _isPropertyRent
            ? 'إسكرو قبل الدخول — ${widget.itemData['title']}'
            : 'عربون ${widget.itemData['title']}',
        amount: payAmount,
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
    final durationMeta = RentalScheduleUtils.describeDuration(
      '$_duration $_selectedDurationType',
    );
    final durationLabel = durationMeta['label']?.toString() ??
        '$_duration $_selectedDurationType';
    final durationCycle = durationMeta['cycle']?.toString() ?? 'شهري';
    final leaseMonths = _isCar || isSale
        ? 0
        : RentalScheduleUtils.parseLeaseMonths(
            durationLabel,
            fallback: 1,
          );
    final leaseStartDate = _bookingRange?.start ?? _checkInDate;
    final leaseEndDate = _bookingRange?.end ??
        (leaseMonths > 0
            ? RentalScheduleUtils.addMonths(leaseStartDate, leaseMonths)
            : leaseStartDate.add(Duration(days: _duration)));
    final monthlyRent = _monthlyRent;
    final nextDueAmount = _isCar || isSale
        ? _remainingAfterDepositAmount
        : _remainingAfterDepositAmount > 0
            ? _remainingAfterDepositAmount
            : monthlyRent;

    // Save to backend with server-side validation
    final result = await DataService.sendBookingRequest({
      'itemType': widget.itemType,
      'propertyId': widget.itemData['id'],
      'title': widget.itemData['title'],
      'image': widget.itemData['image'],
      'price': _monthlyRent.toStringAsFixed(0),
      'monthlyRent': _monthlyRent.toStringAsFixed(0),
      'tenantName': _currentUser?['name'] ?? 'مستأجر',
      'leaseMonths': leaseMonths,
      'leaseStartDate': leaseStartDate.toIso8601String(),
      'leaseEndDate': leaseEndDate.toIso8601String(),
      'checkInDate': leaseStartDate.toIso8601String(),
      'durationType': _selectedDurationType,
      'durationCount': durationMeta['count'] ?? _duration,
      'durationUnit': durationMeta['unit'],
      'leaseTotal': _leaseTotalAmount.toStringAsFixed(0),
      'totalAmount': _leaseTotalAmount.toStringAsFixed(0),
      'currentAmount': _currentMonthTotal.toStringAsFixed(0),
      'depositAmount': _bookingDepositAmount.toStringAsFixed(0),
      'remainingAmount': _remainingAfterDepositAmount.toStringAsFixed(0),
      'nextDueAmount': nextDueAmount.toStringAsFixed(0),
      'nextDueDate':
          RentalScheduleUtils.addMonths(leaseStartDate, 1).toIso8601String(),
      'paidMonths': 0,
      'remainingMonths': leaseMonths,
      'paymentSchedule': _isCar || isSale ? 'مرة واحدة' : durationCycle,
      'durationLabel': durationLabel,
      'duration': isSale
          ? 'تملك نهائي'
          : _isCar
              ? durationLabel
              : durationLabel,
      'startDate': leaseStartDate.toIso8601String(),
      'endDate': leaseEndDate.toIso8601String(),
      'ownerId': widget.itemData['ownerId'] ?? 'admin',
      'ownerEmail':
          widget.itemData['ownerEmail'] ?? widget.itemData['ownerId'] ?? 'admin',
      'status': BookingStatus.depositPaid,
      'paymentStatus': 'pre_entry_paid',
      'paymentPhase': 'pre_entry',
      'depositPaid': true,
      'firstPeriodPaid': true,
      'preEntryPaid': true,
      'preEntryStatus': 'paid',
      'preEntryAmount': _preEntryTotalAmount.toStringAsFixed(0),
      if (widget.itemData['selectedBedId'] != null)
        'bedId': widget.itemData['selectedBedId'],
      if (widget.itemData['bedLabel'] != null)
        'bedLabel': widget.itemData['bedLabel'],
      'transactionId': transactionId,
      'paymentMethod': _selectedPaymentMethod,
      if (_selectedInsuranceType != null) 'insurance': _selectedInsuranceType,
      if (_insurancePrice > 0) 'insuranceCost': _insurancePrice,
      ...RentalRules.bookingTierPayload(
        tier: _rentalTier,
        tenantType: _tenantType,
        durationType: _selectedDurationType,
        durationCount: _duration,
        checkInDate: leaseStartDate,
        monthlyRent: _monthlyRent,
      ),
      'governorate': widget.itemData['governorate'] ?? '',
      'verification': {
        'selfie': _selfieImage,
        'idFront': _idFrontImage,
        'idBack': _idBackImage,
        'incomeLetter': _incomeLetterImage,
        'bankStatement': _bankStatementImage,
        'employmentLetter': _employmentLetterImage,
        'hasPromissory': _isPromissorySigned,
      }
    });

    if (result['success'] != true) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['message']?.toString() ?? 'تعذر إتمام الحجز'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to Success Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPaymentScreen(
          amount: _isPropertyRent ? _preEntryTotalAmount : _bookingDepositAmount,
          transactionId: transactionId,
          paymentMethod: _selectedPaymentMethod,
          successTitle: 'تم حجز المعاينة بنجاح',
          successMessage: _isCar
              ? 'تم استلام العربون بشكل آمن. ستظهر لك باقي تفاصيل الحجز وفق مدة السيارة المختارة.'
              : 'تم استلام العربون بشكل آمن. يمكنك استكمال المتبقي من الشهر الأول فقط بعد تأكيدك على إتمام الصفقة.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.itemType == 'property' ? 'حجز عقار' : 'حجز سيارة'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPadding,
                AppTheme.spaceSm,
                AppTheme.screenPadding,
                AppTheme.spaceSm,
              ),
              child: EjariSurfaceCard(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                radius: AppTheme.cardRadiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemType == 'property'
                          ? 'رحلة حجز هادئة وواضحة'
                          : 'رحلة حجز السيارة بخطوات بسيطة',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSale
                          ? 'نوضح التملك والرسوم والدفعة الأولى قبل أي التزام.'
                          : 'نرتب العربون، المدة، والتحقق في نفس المسار بدون تشويش.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Wrap(
                      spacing: AppTheme.spaceXs,
                      runSpacing: AppTheme.spaceXs,
                      children: [
                        _buildHeaderChip(
                            isSale ? 'تملك' : 'إيجار', AppTheme.primaryColor),
                        _buildHeaderChip(
                            '${_bookingDepositAmount.toStringAsFixed(0)} ج.م عربون',
                            AppTheme.accentColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPadding,
                0,
                AppTheme.screenPadding,
                AppTheme.spaceSm,
              ),
              child: EjariStepIndicator(
                labels: _stepLabels,
                activeIndex: _currentStep,
                light: false,
              ),
            ),
            if (_isPropertyRent)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: RefundRuleTooltip(),
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: AppTheme.borderColor.withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () async {
                    if (_currentStep == 1) {
                      if (_selfieImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'يرجى التقاط صورة سيلفي للتحقق من هويتك'),
                              backgroundColor: AppTheme.errorColor),
                        );
                        return;
                      }
                      if (_idFrontImage == null || _idBackImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'يرجى إرفاق الوجهين لبطاقة الهوية/الرخصة'),
                              backgroundColor: AppTheme.errorColor),
                        );
                        return;
                      }
                      // For Properties (Rent): Tenant Validation
                      if (_isPropertyRent) {
                        if (_requiresIncomeProof) {
                          if (_incomeLetterImage == null ||
                              _bankStatementImage == null ||
                              _employmentLetterImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'يرجى إكمال قائمة المستندات: هوية، إثبات دخل، وعقد عمل'),
                                  backgroundColor: AppTheme.errorColor),
                            );
                            return;
                          }
                        } else if (_requiresAdvanceOnly) {
                          // Short-term: only ID + selfie required, advance payment shown
                        } else if (_hasFinancialDocs) {
                          if (_incomeLetterImage == null ||
                              _bankStatementImage == null) {
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
                              Text(
                                  'جاري إرسال البيانات ومراجعتها من قبل الإدارة...'),
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
                            child: SizedBox(
                              height: AppTheme.ctaHeight,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.cardRadius - 4),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white))
                                    : Text(_currentStep == 3
                                        ? 'إرسال الطلب'
                                        : 'التالي'),
                              ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                      title: Text(_stepTitle(0),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemSummary(),
                            const SizedBox(height: 16),
                            _buildBookingTrustCard(),
                            if (_isPropertyRent) ...[
                              const SizedBox(height: 12),
                              const EjariTrustBadges(),
                            ],
                            if (_showInstallments) ...[
                              const SizedBox(height: 16),
                              _buildMonthlyPlanCard(),
                            ],
                            if (_isPropertyRent) ...[
                              const SizedBox(height: 16),
                              TenantTypeSelector(
                                selected: _tenantType,
                                onChanged: (t) => setState(() => _tenantType = t),
                              ),
                              const SizedBox(height: 12),
                              SmartBookingAssistant(
                                tier: _rentalTier,
                                tenantType: _tenantType,
                                durationType: _selectedDurationType,
                                duration: _duration,
                                checkInDate: _checkInDate,
                                hasSelfie: _selfieImage != null,
                                hasIdFront: _idFrontImage != null,
                                hasIdBack: _idBackImage != null,
                                hasIncomeProof: _incomeLetterImage != null &&
                                    _bankStatementImage != null,
                                pricingResult: _pricingResult,
                                monthlyRent: _monthlyRent,
                                onApplySuggestion: _selectedDurationType == 'يوم' &&
                                        _duration > 3
                                    ? () => setState(() {
                                          _selectedDurationType = 'أسبوع';
                                          _duration = 1;
                                          _calculatePrice();
                                        })
                                    : null,
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (widget.itemData['isDemo'] == true)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.borderColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.borderColor
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: AppTheme.borderColor),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildCalendarTrigger(),
                              const SizedBox(height: 24),
                              const Text('مدة الإيجار',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: RentalPricing.durationOptions
                                      .map(_buildDurationTab)
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.category_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'فئة الإيجار: ${_rentalTier.arabicLabel}\n${_rentalTier.paymentModelArabic}',
                                        style: const TextStyle(fontSize: 12, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              DurationCostHint(
                                tier: _rentalTier,
                                pricingResult: _pricingResult,
                                totalPrice: _totalPrice,
                                monthlyRent: _monthlyRent,
                                duration: _duration,
                                durationType: _selectedDurationType,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('عدد ال$_selectedDurationType',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
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
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
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
                                          icon: const Icon(
                                              Icons.add_circle_outline),
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
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield,
                                      color: AppTheme.primaryColor),
                                ),
                                title: const Text('إضافة تأمين',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: AppTheme.primaryColor),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'أنت الآن بصدد تقديم طلب شراء لهذا العقار بموجب عمولات إيجاري المخفضة (2%)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildPurchaseOption('نقداً (Cash)',
                                  'احصل على خصم إضافي 5% عند الدفع كاش'),
                              const SizedBox(height: 12),
                              _buildPurchaseOption('تقسيط',
                                  'خطط سداد تصل إلى 7 سنوات بأقل فائدة'),
                              const SizedBox(height: 12),
                              _buildPurchaseOption('تمويل عقاري',
                                  'متاح عبر مبادرات البنك المركزي المصري'),
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
                                      isSale ? 'قيمة العقار' : 'الإيجار الشهري',
                                      _totalPrice),
                                  if (!isSale && !_isCar)
                                    _buildPriceRow('إجمالي مدة التعاقد',
                                        _leaseTotalAmount),
                                  _buildPriceRow(
                                      isSale ? 'عمولة إيجاري (2%)' : 'الرسوم',
                                      isSale
                                          ? _profit
                                          : (_adminFees + _profit)),
                                  if (isSale)
                                    _buildPriceRow(
                                        'مصاريف إدارية وقانونية', _adminFees),
                                  if (!isSale && _insurancePrice > 0)
                                    _buildPriceRow('التأمين', _insurancePrice),
                                  ...[
                                    _buildPriceRow('العربون (إسكرو)',
                                        _bookingDepositAmount),
                                    if (_isPropertyRent)
                                      _buildPriceRow('أول فترة إيجار',
                                          _firstPeriodAmount),
                                    if (!_isPropertyRent)
                                      _buildPriceRow(
                                          _isCar
                                              ? 'المتبقي بعد العربون'
                                              : 'المتبقي من دفعة الشهر الأول',
                                          _remainingAfterDepositAmount),
                                  ],
                                  if (_isPropertyRent) ...[
                                    const Divider(),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.lock,
                                              size: 16,
                                              color: AppTheme.primaryColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'مطلوب: عربون + أول فترة قبل الدخول (${_preEntryTotalAmount.toStringAsFixed(0)} ج.م)',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            isSale
                                                ? 'إجمالي قيمة التعاقد'
                                                : _isCar
                                                    ? 'المطلوب الآن'
                                                    : 'المطلوب الآن',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
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
                      title: Text(_stepTitle(1),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.fingerprint,
                                      color: Colors.white, size: 30),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('التحقق الرقمي الآمن',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text(
                                            'نستخدم أحدث تقنيات الذكاء الاصطناعي لمطابقة الهوية.',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.verified_user,
                                      color: AppTheme.primaryColor),
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
                              if (_requiresIncomeProof) ...[
                                DocumentChecklistStep(
                                  hasId: _idFrontImage != null && _idBackImage != null,
                                  hasIncome: _incomeLetterImage != null && _bankStatementImage != null,
                                  hasEmployment: _employmentLetterImage != null,
                                  onTapItem: (key) {
                                    if (key == 'id') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('ارفع الهوية من البطاقات أعلاه')),
                                      );
                                    } else if (key == 'income') {
                                      _pickDoc((p) => _incomeLetterImage = p, 'خطاب الدخل');
                                    } else if (key == 'employment') {
                                      _pickDoc((p) => _employmentLetterImage = p, 'عقد العمل');
                                    }
                                  },
                                ),
                              ] else if (_requiresAdvanceOnly) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('دفع مقدم (بدون حزمة مستندات كاملة)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'للمدة أقل من ٦ شهور: المطلوب هو ${_paymentStageLabel} '
                                        'بقيمة ${_bookingDepositAmount.toStringAsFixed(0)} ج.م فقط.',
                                        style: const TextStyle(fontSize: 12, height: 1.5),
                                      ),
                                      const SizedBox(height: 8),
                                      const RefundRuleTooltip(),
                                    ],
                                  ),
                                ),
                              ] else ...[
                              const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                      'الملاءة المالية (إلزامي للإيجار)',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text(
                                    'أمتلك إثبات دخل وكشف حساب بنكي'),
                                subtitle:
                                    const Text('لتسريع الموافقة على الحجز'),
                                value: _hasFinancialDocs,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (val) =>
                                    setState(() => _hasFinancialDocs = val),
                              ),
                              if (_hasFinancialDocs) ...[
                                const SizedBox(height: 16),
                                _buildVerificationCard(
                                  title: 'خطاب إثبات دخل أو جهة عمل',
                                  description:
                                      'مستند حديث يثبت الراتب أو الدخل.',
                                  icon: Icons.work_outline,
                                  isDone: _incomeLetterImage != null,
                                  onTap: () => _pickDoc(
                                      (p) => _incomeLetterImage = p, 'خطاب الدخل'),
                                ),
                                const SizedBox(height: 16),
                                _buildVerificationCard(
                                  title: 'كشف حساب بنكي (آخر 3 شهور)',
                                  description:
                                      'للتأكد من القدرة على الالتزام بالإيجار.',
                                  icon: Icons.account_balance,
                                  isDone: _bankStatementImage != null,
                                  onTap: () => _pickDoc(
                                      (p) => _bankStatementImage = p, 'كشف الحساب'),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.borderColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppTheme.borderColor),
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
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: AppTheme.primaryColor),
                                              SizedBox(width: 8),
                                              Text(
                                                  'تم توقيع الإقرار المالي بنجاح ✅',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      else
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ContractScreen(
                                                    itemLabel: 'سند لأمر',
                                                    ownerName:
                                                        'إدارة إيجاري (الضامن)',
                                                    tenantName:
                                                        _currentUser?['name'] ??
                                                            'المستأجر',
                                                    propertyTitle:
                                                        'إقرار بالالتزام الشهري في موعده',
                                                    price: _totalPrice
                                                        .toStringAsFixed(0),
                                                    startDate: DateTime.now()
                                                        .toIso8601String()
                                                        .split('T')[0],
                                                    duration:
                                                        'حتى نهاية التعاقد',
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                setState(() =>
                                                    _isPromissorySigned = true);
                                              }
                                            },
                                            icon:
                                                const Icon(Icons.edit_document),
                                            label: const Text(
                                                'توقيع السند لأمر الآن'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.borderColor,
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
                          ],
                        ),
                      ),
                      isActive: _currentStep >= 1,
                    ),

                    // Step 3: Contract / Documentation
                    Step(
                      title: Text(_stepTitle(2),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            Icon(
                                isSale
                                    ? Icons.assignment_turned_in
                                    : Icons.gavel,
                                size: 50,
                                color: AppTheme.primaryColor),
                            const SizedBox(height: 16),
                            Text(
                                isSale ? 'مستند رغبة الشراء' : 'العقد القانوني',
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
                                  border:
                                      Border.all(color: AppTheme.primaryColor),
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
                                label: Text(isSale
                                    ? 'توقيع طلب الشراء'
                                    : 'عرض وتوقيع العقد'),
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
                      title: Text(_stepTitle(3),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTheme.spaceLg),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A2E26),
                                    AppTheme.primaryColor,
                                    Color(0xFF1B594B),
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.cardRadiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.16),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.receipt_long_rounded,
                                      size: 40, color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text(
                                      isSale
                                          ? 'ملخص رغبة التملك'
                                          : 'ملخص الطلب',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  const SizedBox(height: 16),
                                  _buildWhiteSummaryRow(
                                      'العقار', widget.itemData['title']),
                                  if (!isSale)
                                    _buildWhiteSummaryRow('المدة',
                                        '$_duration $_selectedDurationType'),
                                  if (_isPropertyRent)
                                    _buildWhiteSummaryRow('فئة الإيجار',
                                        _rentalTier.arabicLabel),
                                  if (_isPropertyRent)
                                    _buildWhiteSummaryRow('نوع المستأجر',
                                        _tenantType.arabicLabel),
                                  _buildWhiteSummaryRow('النوع',
                                      isSale ? 'شراء نهائي' : 'إيجار ذكي'),
                                  ...[
                                    const SizedBox(height: 8),
                                    _buildWhiteSummaryRow(
                                        'العربون الآن',
                                        _bookingDepositAmount
                                            .toStringAsFixed(0)),
                                    _buildWhiteSummaryRow(
                                        'المتبقي بعد المعاينة',
                                        _remainingAfterDepositAmount
                                            .toStringAsFixed(0)),
                                  ],
                                  const Divider(color: Colors.white24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          isSale ? 'إجمالي الدفعة' : 'الإجمالي',
                                          style: const TextStyle(
                                              color: Colors.white70)),
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
                            if (_isPropertyRent) ...[
                              const SizedBox(height: 16),
                              BookingSummaryCard(
                                tier: _rentalTier,
                                tenantType: _tenantType,
                                depositAmount: _bookingDepositAmount,
                                totalPrice: _leaseTotalAmount,
                                showInstallments: _showInstallments,
                                checkInDate: _checkInDate,
                                pricingResult: _pricingResult,
                              ),
                              const SizedBox(height: 8),
                              const EjariTrustBadges(showOwner: false),
                            ],
                            const SizedBox(height: 24),
                            if (!isSale) ...[
                              const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('اختر وسيلة الدفع',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(height: 16),
                              GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  mainAxisExtent: 110,
                                ),
                                children: [
                                  _buildPaymentOption(
                                      'محفظة إيجاري',
                                      Icons.account_balance_wallet_rounded,
                                      'wallet',
                                      AppTheme.primaryColor),
                                  _buildPaymentOption(
                                      'Visa',
                                      Icons.credit_card_rounded,
                                      'visa',
                                      const Color(0xFF1A1F71)),
                                  _buildPaymentOption(
                                      'Mastercard',
                                      Icons.credit_card_rounded,
                                      'mastercard',
                                      const Color(0xFFEB001B)),
                                  _buildPaymentOption(
                                      'Apple Pay',
                                      Icons.apple_rounded,
                                      'apple_pay',
                                      AppTheme.textPrimary),
                                  _buildPaymentOption(
                                      'Google Pay',
                                      Icons.g_mobiledata_rounded,
                                      'google_pay',
                                      const Color(0xFF4285F4)),
                                  _buildPaymentOption(
                                      'InstaPay',
                                      Icons.send_to_mobile_rounded,
                                      'instapay',
                                      AppTheme.primaryColor),
                                ],
                              ),
                              if (!isSale &&
                                  _selectedPaymentMethod != 'cash') ...[
                                const SizedBox(height: 24),
                                _buildPaymentInput(),
                              ],
                            ] else ...[
                              const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('خطة التواصل',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(height: 12),
                              const Text(
                                  'سيقوم مستشار إيجاري بالتواصل معك خلال 24 ساعة.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.4)),
                            ],
                            const SizedBox(height: AppTheme.spaceXl),
                            SizedBox(
                              width: double.infinity,
                              height: AppTheme.ctaHeight,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitBooking,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSummary() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: EjariImage.provider(
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

  Widget _buildBookingTrustCard() {
    final accent = isSale ? AppTheme.borderColor : AppTheme.primaryColor;
    final firstLine = isSale
        ? 'أنت هنا في خطوة التملك، والمبلغ يوضح الإجمالي بشكل كامل قبل الاستمرار.'
        : 'أنت هنا في خطوة المعاينة والحجز، والعربون يُحجز مؤقتًا إلى حين قرارك النهائي.';
    final secondLine = isSale
        ? 'سترى العمولة، الرسوم، والإجمالي النهائي بوضوح قبل توقيع الطلب.'
        : 'بعد المعاينة، لو قررت الاستكمال يظهر لك المتبقي فقط بدون أي التباس.';

    return EjariSurfaceCard(
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSale ? Icons.storefront_rounded : Icons.how_to_reg_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EjariSectionHeader(
                  title: isSale ? 'ملخص التملك والرسوم' : 'ملخص الحجز والعربون',
                  subtitle: firstLine,
                ),
                const SizedBox(height: 3),
                Text(
                  secondLine,
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
    );
  }

  Widget _buildMonthlyPlanCard() {
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
                child: const Icon(Icons.event_repeat_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خطة السداد الشهرية',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'العربون يثبت الجدية، ثم يُستكمل الشهر الأول فقط، وبعدها السداد يكون شهريًا.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
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
                'الإيجار الشهري',
                '${_monthlyRent.toStringAsFixed(0)} ج.م',
                AppTheme.primaryColor,
              ),
              _buildPlanChip(
                'عربون الحجز',
                '${_bookingDepositAmount.toStringAsFixed(0)} ج.م',
                AppTheme.borderColor,
              ),
              _buildPlanChip(
                'إجمالي التعاقد',
                '${_leaseTotalAmount.toStringAsFixed(0)} ج.م',
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

  Widget _buildHeaderChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == AppTheme.surfaceColor ? AppTheme.textPrimary : color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
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
    final navigator = Navigator.of(context);
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'توقيع العقد',
    );
    if (!allowed) return;
    if (!mounted) return;

    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => ContractScreen(
          ownerName: 'الشركة المالكة',
          tenantName: _currentUser?['name'] ?? 'المستأجر',
          propertyTitle: widget.itemData['title'],
          price: _monthlyRent.toStringAsFixed(0),
          startDate: DateTime.now().toString().split(' ')[0],
          duration: RentalScheduleUtils.describeDuration(
                      '$_duration $_selectedDurationType')['label']
                  ?.toString() ??
              '$_duration $_selectedDurationType',
          deposit: _bookingDepositAmount.toStringAsFixed(0),
          rentalTierLabel: _rentalTier.arabicLabel,
          tenantTypeLabel: _tenantType.arabicLabel,
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
        label = 'تأكيد الدفع من محفظة إيجاري';
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
                      'سيتم الخصم مباشرة من رصيد محفظة إيجاري الخاص بك المتوفر حالياً.',
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تم إرسال رمز التحقق: 1234 (وضع تجريبي)'),
                          ),
                        );
                      },
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

  void _pickDoc(void Function(String) onSelected, String label) {
    final imageWidget = ImageUploadWidget(
      label: label,
      icon: Icons.document_scanner,
      onImageSelected: (path) => setState(() => onSelected(path)),
    );
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(padding: const EdgeInsets.all(20), child: imageWidget),
    );
  }
}
