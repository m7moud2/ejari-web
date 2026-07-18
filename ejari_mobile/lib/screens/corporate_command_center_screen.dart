import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/data_service.dart';
import '../models/booking_status.dart';
import 'corporate_booking_screen.dart';
import 'my_bookings_screen.dart';

/// حساب الشركات — موافقات الحجوزات، الفواتير، وحجوزات الفريق.
class CorporateCommandCenterScreen extends StatefulWidget {
  const CorporateCommandCenterScreen({super.key});

  @override
  State<CorporateCommandCenterScreen> createState() =>
      _CorporateCommandCenterScreenState();
}

class _CorporateCommandCenterScreenState
    extends State<CorporateCommandCenterScreen> {
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _bulkInvoice = {};
  Map<String, dynamic> _wallet = {};
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _teamBookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await DataService.getCorporateCommandSummary();
      final bulk = await DataService.getCorporateBulkInvoiceSummary();
      final wallet = await DataService.getCorporateWalletSummary();
      final employees = await DataService.getCorporateEmployees();
      final bookings = await DataService.getBookings();
      final corporate = bookings
          .where((b) =>
              b['bookingMode'] == 'corporate' ||
              b['status'] == BookingStatus.corporatePending ||
              (b['employeeId']?.toString().isNotEmpty ?? false))
          .toList();
      final pending = corporate
          .where((b) {
            final s = BookingStatus.normalize(b['status']?.toString());
            return s == BookingStatus.corporatePending ||
                s == BookingStatus.pending ||
                s == BookingStatus.submitted ||
                b['status']?.toString() == 'pending';
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _bulkInvoice = bulk;
        _wallet = wallet;
        _employees = employees.isNotEmpty
            ? employees
            : List<Map<String, dynamic>>.from(
                summary['employees'] ?? const [],
              );
        _pendingApprovals = pending;
        _teamBookings = corporate;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _approveBooking(Map<String, dynamic> booking) async {
    final id = booking['id']?.toString() ?? booking['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await DataService.updateRequestStatus(
      id,
      BookingStatus.approved,
      note: 'موافقة إدارة الشركة',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'تمت الموافقة على طلب ${booking['tenantName'] ?? booking['employeeName'] ?? 'الموظف'}'
            : 'تعذر تحديث حالة الطلب'),
        backgroundColor: ok ? AppTheme.primaryColor : AppTheme.errorColor,
      ),
    );
    _load();
  }

  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    final id = booking['id']?.toString() ?? booking['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await DataService.updateRequestStatus(
      id,
      BookingStatus.rejected,
      note: 'رفض إدارة الشركة',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم رفض الطلب' : 'تعذر رفض الطلب'),
        backgroundColor: ok ? AppTheme.primaryColor : AppTheme.errorColor,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('حساب الشركات'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CorporateBookingScreen(),
                ),
              );
              _load();
            },
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'طلب حجز جديد',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.accentColor,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    children: [
                      _buildHero(),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildQuickStats(),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildApprovalsInbox(),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildWalletCard(),
                      const SizedBox(height: AppTheme.spaceSm),
                      _buildBulkInvoiceCard(),
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildTeamBookings(),
                      const SizedBox(height: AppTheme.spaceMd),
                      if (_employees.isNotEmpty) ...[
                        const EjariSectionHeader(
                          title: 'فريق الإسكان',
                          subtitle: 'الموظفون المرتبطون بطلبات الشركة',
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        ..._employees.take(8).map(_employeeCard),
                        if (_employees.length > 8)
                          Text(
                            '+${_employees.length - 8} موظف آخر',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(height: AppTheme.spaceMd),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CorporateBookingScreen(),
                              ),
                            );
                            _load();
                          },
                          icon: const Icon(Icons.add_home_work_rounded),
                          label: const Text('طلب سكن جديد للموظفين'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBookingsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('كل حجوزات الشركة'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3A30), Color(0xFF1B594B)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_rounded, color: AppTheme.accentColor),
              SizedBox(width: 8),
              Text(
                'طلبات الشركات والموافقات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _summary['companyName']?.toString() ?? 'حساب الشركة — إيجاري',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'بانتظار الموافقة: ${_pendingApprovals.length}',
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      ('موافقات', '${_pendingApprovals.length}', Icons.fact_check_rounded),
      ('حجوزات الفريق', '${_teamBookings.length}', Icons.groups_rounded),
      (
        'نشطة',
        '${_summary['activeBookings'] ?? 0}',
        Icons.event_available_rounded,
      ),
      (
        'إنفاق شهري',
        '${_summary['totalSpend'] ?? 0}',
        Icons.payments_rounded,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spaceSm,
      crossAxisSpacing: AppTheme.spaceSm,
      childAspectRatio: 1.55,
      children: stats.map((s) {
        return EjariSurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.$3, color: AppTheme.primaryColor, size: 20),
              const Spacer(),
              Text(
                s.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                s.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApprovalsInbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EjariSectionHeader(
          title: 'صندوق الموافقات',
          subtitle: 'طلبات إسكان الموظفين التي تحتاج قرار الإدارة',
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (_pendingApprovals.isEmpty)
          const EjariSurfaceCard(
            child: Text(
              'لا توجد طلبات معلّقة حالياً. عند تقديم حجز شركة سيظهر هنا للموافقة أو الرفض.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textSecondary,
              ),
            ),
          )
        else
          ..._pendingApprovals.map(_approvalCard),
      ],
    );
  }

  Widget _approvalCard(Map<String, dynamic> booking) {
    final title = booking['title']?.toString() ??
        booking['propertyTitle']?.toString() ??
        'طلب سكن';
    final name = booking['employeeName']?.toString() ??
        booking['tenantName']?.toString() ??
        'موظف';
    final rent = booking['monthlyRent'] ?? booking['price'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'بانتظار القرار',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$name${rent.toString().isNotEmpty ? ' • $rent ج.م' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectBooking(booking),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveBooking(booking),
                    child: const Text('موافقة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EjariSectionHeader(
          title: 'حجوزات الفريق',
          subtitle: 'آخر طلبات الإسكان المرتبطة بالشركة',
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (_teamBookings.isEmpty)
          const EjariSurfaceCard(
            child: Text(
              'لا توجد حجوزات شركة بعد. ابدأ بطلب سكن جديد للموظفين.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          )
        else
          ..._teamBookings.take(6).map((b) {
            final status =
                BookingStatus.normalize(b['status']?.toString());
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
              child: EjariSurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['title']?.toString() ?? 'حجز',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            b['employeeName']?.toString() ??
                                b['tenantName']?.toString() ??
                                '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      BookingStatus.arabicLabel(status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final status = emp['status']?.toString() ?? 'pending';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (emp['name']?.toString() ?? '?')[0],
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp['name']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${emp['role'] ?? ''} • ${emp['governorate'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _statusLabel(status),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'active':
        return 'نشط';
      case 'booked':
        return 'محجوز';
      case BookingStatus.depositPaid:
        return 'عربون مدفوع';
      case BookingStatus.corporatePending:
        return 'بانتظار الإدارة';
      default:
        return 'متاح';
    }
  }

  Widget _buildWalletCard() {
    return EjariSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'محفظة الشركة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  'الرصيد: ${_wallet['balance'] ?? 0} ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'إجمالي الإنفاق: ${_wallet['totalSpend'] ?? _summary['totalSpend'] ?? 0} ج.م',
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildBulkInvoiceCard() {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الفواتير',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'الفترة: ${_bulkInvoice['period'] ?? '—'}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _invoiceStat('فواتير', '${_bulkInvoice['invoiceCount'] ?? 0}'),
              _invoiceStat('إيجار', '${_bulkInvoice['totalRent'] ?? 0} ج.م'),
              _invoiceStat('عربون', '${_bulkInvoice['depositTotal'] ?? 0} ج.م'),
            ],
          ),
          const Divider(height: 16),
          Text(
            'الإجمالي: ${_bulkInvoice['grandTotal'] ?? 0} ج.م',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.accentColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
