import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/data_service.dart';
import '../services/firestore_property_service.dart';
import '../services/wallet_service.dart';
import '../utils/rental_rules.dart';
import '../models/rental_duration_tier.dart';
import '../models/tenant_type.dart';
import 'success_payment_screen.dart';

/// حجز جماعي لموظفين في محافظات مختلفة — MVP مع بيانات تجريبية.
class CorporateBookingScreen extends StatefulWidget {
  const CorporateBookingScreen({super.key});

  @override
  State<CorporateBookingScreen> createState() => _CorporateBookingScreenState();
}

class _CorporateBookingScreenState extends State<CorporateBookingScreen> {
  String _selectedGovernorate = 'الكل';
  bool _isProcessing = false;

  static const List<String> _governorates = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الشرقية',
  ];

  static final List<Map<String, dynamic>> _demoEmployees = [
    {
      'id': 'emp1',
      'name': 'أحمد سالم',
      'role': 'مهندس ميداني',
      'governorate': 'القاهرة',
      'status': 'pending',
      'propertyTitle': null,
      'propertyId': null,
      'monthlyRent': 0.0,
    },
    {
      'id': 'emp2',
      'name': 'محمد حسن',
      'role': 'مشرف تشغيل',
      'governorate': 'الجيزة',
      'status': 'pending',
      'propertyTitle': null,
      'propertyId': null,
      'monthlyRent': 0.0,
    },
    {
      'id': 'emp3',
      'name': 'سارة إبراهيم',
      'role': 'محاسبة',
      'governorate': 'الإسكندرية',
      'status': 'pending',
      'propertyTitle': null,
      'propertyId': null,
      'monthlyRent': 0.0,
    },
    {
      'id': 'emp4',
      'name': 'خالد عمر',
      'role': 'فني صيانة',
      'governorate': 'الشرقية',
      'status': 'pending',
      'propertyTitle': null,
      'propertyId': null,
      'monthlyRent': 0.0,
    },
    {
      'id': 'emp5',
      'name': 'نورا محمود',
      'role': 'مديرة فرع',
      'governorate': 'القليوبية',
      'status': 'pending',
      'propertyTitle': null,
      'propertyId': null,
      'monthlyRent': 0.0,
    },
  ];

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _corporateProperties = [];

  @override
  void initState() {
    super.initState();
    _employees = _demoEmployees.map((e) => Map<String, dynamic>.from(e)).toList();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final props = await FirestorePropertyService.getAllProperties(approvedOnly: true);
    final corporate = props
        .where((p) =>
            p['listingMode'] != 'for_sale' &&
            (p['corporateEligible'] == true || p['type'] == 'شقق'))
        .toList();
    setState(() => _corporateProperties = corporate);
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_selectedGovernorate == 'الكل') return _employees;
    return _employees
        .where((e) => e['governorate'] == _selectedGovernorate)
        .toList();
  }

  List<Map<String, dynamic>> _propertiesForGovernorate(String gov) {
    return _corporateProperties.where((p) {
      final loc = (p['location'] ?? p['governorate'] ?? '').toString();
      return loc.contains(gov);
    }).toList();
  }

  void _assignProperty(String empId, Map<String, dynamic> property) {
    final price = double.tryParse(
            property['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
    setState(() {
      final idx = _employees.indexWhere((e) => e['id'] == empId);
      if (idx >= 0) {
        _employees[idx]['propertyTitle'] = property['title'];
        _employees[idx]['propertyId'] = property['id'];
        _employees[idx]['monthlyRent'] = price;
        _employees[idx]['status'] = 'assigned';
      }
    });
  }

  double get _totalCorporateAmount {
    return _employees
        .where((e) => e['status'] == 'assigned')
        .fold(0.0, (sum, e) => sum + (e['monthlyRent'] as num).toDouble() * 0.20);
  }

  int get _assignedCount =>
      _employees.where((e) => e['status'] == 'assigned').length;

  Future<void> _submitCorporateBooking() async {
    if (_assignedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعيين وحدة سكنية لموظف واحد على الأقل'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await WalletService.init();

    final txId = 'CORP-${DateTime.now().millisecondsSinceEpoch}';
    final assigned = _employees.where((e) => e['status'] == 'assigned').toList();

    for (final emp in assigned) {
      await DataService.sendBookingRequest({
        'itemType': 'property',
        'title': emp['propertyTitle'],
        'price': emp['monthlyRent'].toString(),
        'monthlyRent': emp['monthlyRent'].toString(),
        'status': 'corporate_pending',
        'bookingMode': 'corporate',
        'employeeName': emp['name'],
        'employeeId': emp['id'],
        'governorate': emp['governorate'],
        'tenantType': TenantType.individual.value,
        'tenantTypeLabel': 'موظف (حجز جماعي)',
        'rentalTier': RentalDurationTier.medium.name,
        'rentalTierLabel': RentalDurationTier.medium.arabicLabel,
        'duration': '٦ شهور',
        'durationLabel': '٦ شهور',
        'leaseMonths': 6,
        'depositAmount': ((emp['monthlyRent'] as num) * 0.20).toStringAsFixed(0),
        'transactionId': txId,
        'refundPolicy': RentalRules.refundPolicyLegalArabic,
        'showInstallments': true,
        'requiresIncomeProof': true,
      });
    }

    setState(() => _isProcessing = false);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessPaymentScreen(
          amount: _totalCorporateAmount,
          transactionId: txId,
          paymentMethod: 'wallet',
          successTitle: 'تم إرسال طلب الحجز الجماعي',
          successMessage:
              'تم تعيين $_assignedCount موظف/موظفة وإرسال الطلبات للمراجعة. '
              'يمكنك متابعة الحالة من حجوزاتي.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('حجز لموظفين'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: EjariSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EjariSectionHeader(
                      title: 'حجز جماعي للشركات',
                      subtitle:
                          'عيّن وحدات سكنية لموظفيك في محافظات مختلفة وادفع من التطبيق',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('$_assignedCount معيّن', AppTheme.primaryColor),
                        _chip('${_employees.length} موظف', AppTheme.accentColor),
                        _chip(
                          '${_totalCorporateAmount.toStringAsFixed(0)} ج.م عربون',
                          AppTheme.borderColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded,
                      color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text('المحافظة:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedGovernorate,
                      isExpanded: true,
                      items: _governorates
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGovernorate = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenPadding,
                ),
                itemCount: _filteredEmployees.length,
                itemBuilder: (context, index) {
                  final emp = _filteredEmployees[index];
                  return _buildEmployeeCard(emp);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      RentalRules.refundPolicyShortArabic,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    height: AppTheme.ctaHeight,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _submitCorporateBooking,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'تأكيد الحجز الجماعي (${_totalCorporateAmount.toStringAsFixed(0)} ج.م)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final props = _propertiesForGovernorate(emp['governorate']);
    final isAssigned = emp['status'] == 'assigned';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                child: Text(
                  emp['name'].toString().substring(0, 1),
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${emp['role']} — ${emp['governorate']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              _statusBadge(emp['status']),
            ],
          ),
          if (isAssigned) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apartment_rounded,
                      color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emp['propertyTitle'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${emp['monthlyRent']} ج.م/شهر',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (!isAssigned && props.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'اختر وحدة سكنية',
                isDense: true,
              ),
              items: props
                  .map((p) => DropdownMenuItem(
                        value: p['id'].toString(),
                        child: Text(
                          '${p['title']} — ${p['price']} ج.م',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (id) {
                final prop = props.firstWhere((p) => p['id'].toString() == id);
                _assignProperty(emp['id'], prop);
              },
            )
          else if (!isAssigned)
            const Text(
              'لا توجد وحدات متاحة في هذه المحافظة حالياً',
              style: TextStyle(fontSize: 11, color: AppTheme.borderColor),
            ),
        ],
      ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'assigned' => ('معيّن', AppTheme.primaryColor),
      'paid' => ('مدفوع', AppTheme.successColor),
      _ => ('بانتظار', AppTheme.borderColor),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
