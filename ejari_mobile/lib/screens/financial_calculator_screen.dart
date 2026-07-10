import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class FinancialCalculatorScreen extends StatefulWidget {
  final double initialPropertyPrice;
  final double initialRentPrice;

  const FinancialCalculatorScreen({
    super.key,
    required this.initialPropertyPrice,
    required this.initialRentPrice,
  });

  @override
  State<FinancialCalculatorScreen> createState() =>
      _FinancialCalculatorScreenState();
}

class _FinancialCalculatorScreenState extends State<FinancialCalculatorScreen> {
  late TextEditingController _priceController;
  late TextEditingController _rentController;
  late TextEditingController _downPaymentController;
  late TextEditingController _interestRateController;
  late TextEditingController _loanYearsController;

  double _monthlyPayment = 0;
  double _annualROI = 0;
  double _totalInterest = 0;

  // Taxes and Fees
  double _vat = 0;
  double _commission = 0;
  double _registrationFee = 0;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
        text: widget.initialPropertyPrice.toStringAsFixed(0));
    _rentController =
        TextEditingController(text: widget.initialRentPrice.toStringAsFixed(0));
    _downPaymentController = TextEditingController(
        text: (widget.initialPropertyPrice * 0.2).toStringAsFixed(0));
    _interestRateController =
        TextEditingController(text: '7'); // 7% annual interest
    _loanYearsController = TextEditingController(text: '15'); // 15 years

    _calculate();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _rentController.dispose();
    _downPaymentController.dispose();
    _interestRateController.dispose();
    _loanYearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double rent = double.tryParse(_rentController.text) ?? 0;
    final double downPayment =
        double.tryParse(_downPaymentController.text) ?? 0;
    final double interestRate =
        double.tryParse(_interestRateController.text) ?? 0;
    final double years = double.tryParse(_loanYearsController.text) ?? 0;

    final double principal = price - downPayment;

    // Legal & Taxes Calculation
    _vat = price * 0.14; // 14% VAT
    _commission = price * 0.025; // 2.5% Ejari Commission
    _registrationFee = price * 0.01; // 1% Contract Registration

    if (principal > 0 && years > 0 && interestRate > 0) {
      final double monthlyRate = (interestRate / 100) / 12;
      final double numberOfPayments = years * 12;

      _monthlyPayment = principal *
          (monthlyRate * math.pow(1 + monthlyRate, numberOfPayments)) /
          (math.pow(1 + monthlyRate, numberOfPayments) - 1);

      _totalInterest = (_monthlyPayment * numberOfPayments) - principal;
    } else {
      _monthlyPayment = 0;
      _totalInterest = 0;
    }

    // Advanced ROI Calculation including taxes
    final double annualRent = rent * 12;
    final double annualMortgagePayment = _monthlyPayment * 12;

    final double annualCosts =
        annualMortgagePayment + (annualRent * 0.05); // 5% property management
    final double totalInitialInvestment =
        downPayment + _vat + _commission + _registrationFee;

    if (totalInitialInvestment > 0) {
      _annualROI = ((annualRent - annualCosts) / totalInitialInvestment) * 100;
    } else if (price > 0) {
      _annualROI = ((annualRent - (annualRent * 0.05)) / price) * 100;
    } else {
      _annualROI = 0;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('المستشار المالي لإيجاري',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultCards(),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 24),
            _buildLegalAndTaxSection(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التحليل المالي للاستثمار',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                      'قيمة الوحدة الإجمالية (ج.م)', _priceController),
                  _buildInputField(
                      'الإيجار الشهري المتوقع (ج.م)', _rentController),
                  _buildInputField(
                      'الدفعة المقدمة للاستثمار (ج.م)', _downPaymentController),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInputField(
                              'نسبة الفائدة (%)', _interestRateController)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildInputField(
                              'مدة القسط (سنة)', _loanYearsController)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('إعادة حساب الجدوى المحدثة',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCards() {
    return Row(
      children: [
        Expanded(
          child: _buildResultCard(
            'القسط الشهري المتوقع',
            '${_monthlyPayment.toStringAsFixed(0)} ج.م',
            Icons.account_balance_wallet_rounded,
            AppTheme.borderColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildResultCard(
            'العائد الاستثماري (ROI)',
            '${_annualROI.toStringAsFixed(2)} %',
            Icons.trending_up_rounded,
            _annualROI >= 0 ? AppTheme.primaryColor : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalAndTaxSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppTheme.borderColor, size: 24),
              SizedBox(width: 12),
              Text(
                'الالتزامات الضريبية والقانونية',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTaxRow(
              'ضريبة القيمة المضافة (14% قانون الضرائب)', _vat, Colors.white70),
          _buildTaxRow(
              'رسوم التسجيل والتوثيق (1%)', _registrationFee, Colors.white70),
          _buildTaxRow(
              'عمولة وساطة إيجاري (2.5%)', _commission, AppTheme.borderColor,
              isBold: true),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            '* جميع الحسابات المذكورة هي مسودة مبدئية ولا تغني عن الاستشارة الضريبية المعتمدة وقت توقيع العقد الإلكتروني الملزم، وتحتسب نسب العائد بعد اقتطاع الرسوم الأساسية.',
            style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String title, double amount, Color textColor,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight:
                          isBold ? FontWeight.bold : FontWeight.normal))),
          Text('${amount.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final double principal = (double.tryParse(_priceController.text) ?? 0) -
        (double.tryParse(_downPaymentController.text) ?? 0);

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع الاحتكارات الرأسمالية',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.primaryColor,
                          value: principal > 0 ? principal : 1,
                          title: 'الأصل',
                          radius: 25,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: AppTheme.borderColor,
                          value: _totalInterest > 0 ? _totalInterest : 0.1,
                          title: 'تسهيلات',
                          radius: 25,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: AppTheme.borderColor,
                          value: _vat + _registrationFee + _commission > 0
                              ? _vat + _registrationFee + _commission
                              : 0.1,
                          title: 'رسوم',
                          radius: 25,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('أصل الاستثمار', AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      _buildLegendItem(
                          'التسهيلات الائتمانية', AppTheme.borderColor),
                      const SizedBox(height: 12),
                      _buildLegendItem('الرسوم والضرائب', AppTheme.borderColor),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => _calculate(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: AppTheme.primaryColor, fontSize: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2)),
          filled: true,
          fillColor: AppTheme.backgroundColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
