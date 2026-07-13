import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../utils/auth_gate.dart';
import 'rental_statement_screen.dart';
import 'payment_screen.dart';
import '../utils/rental_schedule_utils.dart';
import '../utils/safe_parse.dart';

class TenantInstallmentsScreen extends StatefulWidget {
  const TenantInstallmentsScreen({super.key});

  @override
  State<TenantInstallmentsScreen> createState() =>
      _TenantInstallmentsScreenState();
}

class _TenantInstallmentsScreenState extends State<TenantInstallmentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _installments = [];
  double _monthlyRent = 0.0;
  double _totalPaid = 0.0;
  double _totalRemaining = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);
    final bookings = await DataService.getBookings();
    if (!mounted) return;
    final activeBookings = bookings
        .where((b) =>
            (b['status'] ?? '').toString() != 'deposit_refunded' &&
            (b['status'] ?? '').toString() != 'rejected')
        .toList();

    final generated = _buildInstallmentsFromBookings(activeBookings);
    final monthlyRent = generated.isNotEmpty
        ? (generated.first['amount'] as num).toDouble()
        : 0.0;
    final totalPaid = generated
        .where((inst) => inst['status'] == 'Paid')
        .fold<double>(
            0.0, (sum, inst) => sum + ((inst['amount'] as num).toDouble()));
    final totalRemaining = generated
        .where((inst) => inst['status'] != 'Paid')
        .fold<double>(
            0.0, (sum, inst) => sum + ((inst['amount'] as num).toDouble()));

    setState(() {
      _installments = generated;
      _monthlyRent = monthlyRent;
      _totalPaid = totalPaid;
      _totalRemaining = totalRemaining;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _buildInstallmentsFromBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final eligible = bookings.where((b) {
      if (b['showInstallments'] == false) return false;
      final tier = b['rentalTier']?.toString() ?? '';
      if (tier == 'daily' || tier == 'weekly' || tier == 'shortTerm') {
        return false;
      }
      final months = int.tryParse((b['leaseMonths'] ?? '0').toString()) ?? 0;
      return months >= 6 || b['showInstallments'] == true;
    }).toList();

    if (eligible.isEmpty) {
      return [
        {
          'id': 'DEMO-001',
          'amount': 8500.0,
          'dueDate': DateTime.now().subtract(const Duration(days: 40)),
          'status': 'Paid',
          'paidAt': DateTime.now().subtract(const Duration(days: 41)),
          'receiptId': 'REC-9921',
          'lateFees': 0.0,
          'discount': 0.0,
          'bookingTitle': 'شقة تجريبية',
          'bookingId': 'DEMO-001',
        },
        {
          'id': 'DEMO-002',
          'amount': 8500.0,
          'dueDate': DateTime.now().subtract(const Duration(days: 10)),
          'status': 'Grace Period',
          'paidAt': null,
          'receiptId': null,
          'lateFees': 150.0,
          'discount': 0.0,
          'bookingTitle': 'شقة تجريبية',
          'bookingId': 'DEMO-001',
        },
      ];
    }

    final installments = <Map<String, dynamic>>[];
    for (final booking in eligible) {
      final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
      final leaseMonths = (snapshot['leaseMonths'] as num?)?.toInt() ?? 1;
      final monthlyRent = (snapshot['monthlyRent'] as num?)?.toDouble() ?? 0.0;
      final startDate = snapshot['startDate'] as DateTime? ?? DateTime.now();
      final paidMonths = (booking['paidMonths'] is num)
          ? (booking['paidMonths'] as num).toInt()
          : int.tryParse((booking['paidMonths'] ?? '0').toString()) ?? 0;
      final remainingMonths = (snapshot['remainingMonths'] as num?)?.toInt() ??
          (leaseMonths - paidMonths).clamp(0, leaseMonths);

      for (var i = 0; i < leaseMonths; i++) {
        final dueDate = RentalScheduleUtils.addMonths(startDate, i);
        final isPaid = i < paidMonths;
        final isDueSoon = !isPaid &&
            dueDate.difference(DateTime.now()).inDays <= 14 &&
            dueDate.difference(DateTime.now()).inDays >= 0;
        final isLate = !isPaid &&
            DateTime.now().isAfter(dueDate.add(const Duration(days: 5)));

        installments.add({
          'id':
              '${booking['id'] ?? booking['contractNumber'] ?? 'BOOK'}-${i + 1}',
          'bookingId': booking['id']?.toString() ?? '',
          'bookingTitle': booking['title']?.toString() ?? 'عقد إيجار',
          'amount': monthlyRent,
          'dueDate': dueDate,
          'paidDate': isPaid ? dueDate.add(const Duration(days: 1)) : null,
          'status': isPaid
              ? 'Paid'
              : isLate
                  ? 'Late'
                  : isDueSoon
                      ? 'Due Soon'
                      : 'Upcoming',
          'paidAt': isPaid ? dueDate.add(const Duration(days: 1)) : null,
          'receiptId': isPaid ? _buildReceiptId(booking, i + 1) : null,
          'lateFees': isLate ? (monthlyRent * 0.03) : 0.0,
          'discount': 0.0,
          'remainingMonths': remainingMonths,
          'paidMonths': paidMonths,
          'nextDueDate': snapshot['nextDueDate'],
          'nextDueAmount': snapshot['nextDueAmount'],
        });
      }
    }

    installments.sort((a, b) =>
        (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));
    return installments;
  }

  String _buildReceiptId(Map<String, dynamic> booking, int installmentIndex) {
    final rawId = (booking['id'] ?? booking['contractNumber'] ?? 'BOOK')
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final suffix = rawId.length > 6 ? rawId.substring(rawId.length - 6) : rawId;
    return 'REC-$suffix-$installmentIndex';
  }

  @override
  Widget build(BuildContext context) {
    final paidCount =
        _installments.where((inst) => inst['status'] == 'Paid').length;
    final pendingCount = _installments.length - paidCount;
    final paidRatio =
        _installments.isEmpty ? 0.0 : paidCount / _installments.length;
    final nextInstallment = _installments.firstWhere(
      (inst) => inst['status'] != 'Paid',
      orElse: () => _installments.isNotEmpty
          ? _installments.last
          : {
              'dueDate': DateTime.now(),
              'status': 'Upcoming',
              'amount': _monthlyRent,
            },
    );
    final daysLeft = (nextInstallment['dueDate'] as DateTime)
        .difference(DateTime.now())
        .inDays;
    final isLate = nextInstallment['status'] == 'Grace Period' ||
        nextInstallment['status'] == 'Late';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('أقساطي الشهرية'),
        titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInstallments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInstallments,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _hero(daysLeft, nextInstallment, isLate, paidCount),
                  const SizedBox(height: 14),
                  _overview(),
                  const SizedBox(height: 14),
                  _progressCard(paidCount, pendingCount, paidRatio),
                  const SizedBox(height: 14),
                  _summaryCard(),
                  const SizedBox(height: 14),
                  _timelineCard(
                      paidCount, pendingCount, nextInstallment, daysLeft),
                  const SizedBox(height: 14),
                  _statementShortcutCard(),
                  const SizedBox(height: 14),
                  const Text('سجل الأقساط',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  if (_installments.isEmpty)
                    _emptyState()
                  else
                    ..._installments.map(_installmentCard),
                ],
              ),
            ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('لا توجد أقساط متاحة حالياً',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
            'بمجرد وجود حجز فعّال أو عقد مؤكد، هيظهر لك الجدول كامل هنا مع الشهور المدفوعة والمتبقية.',
            style: TextStyle(height: 1.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _hero(
      int daysLeft, Map<String, dynamic> nextInst, bool isLate, int paidCount) {
    final dueText = isLate
        ? 'القسط داخل فترة السماح أو متأخر'
        : (daysLeft <= 0
            ? 'القسط مستحق اليوم'
            : 'متبقي $daysLeft أيام على القسط القادم');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('القسط القادم',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${_monthlyRent.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(dueText,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('قيمة الإيجار الشهري', AppTheme.surfaceColor),
              _pill('إجمالي المدفوع: ${_totalPaid.toStringAsFixed(0)} ج.م',
                  AppTheme.accentColor),
              _pill('المتبقي: ${_totalRemaining.toStringAsFixed(0)} ج.م',
                  AppTheme.surfaceColor),
              _pill('الشهور المدفوعة: $paidCount', AppTheme.accentColor),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _payInstallment(nextInst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('دفع القسط الآن'),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color == AppTheme.surfaceColor
                  ? AppTheme.textPrimary
                  : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _overview() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _statCard(
              'إجمالي المدفوع', '${_totalPaid.toStringAsFixed(0)} ج.م'),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _statCard(
              'إجمالي المتبقي', '${_totalRemaining.toStringAsFixed(0)} ج.م'),
        ),
      ],
    );
  }

  Widget _progressCard(int paidCount, int pendingCount, double paidRatio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نسبة السداد',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: paidRatio,
              backgroundColor: AppTheme.backgroundColor.withOpacity(0.55),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _miniBadge('الشهور المدفوعة: $paidCount', AppTheme.primaryColor),
              _miniBadge(
                  'الشهور المتبقية: $pendingCount', AppTheme.borderColor),
              _miniBadge('إجمالي الشهور: ${_installments.length}',
                  AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الشفافية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'كل قسط مرتبط بالعقد، الحجز، والمالك. عند الدفع يتم تحديث الحالة فوراً وإصدار إيصال.',
              style: TextStyle(height: 1.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _timelineCard(int paidCount, int pendingCount,
      Map<String, dynamic> nextInst, int daysLeft) {
    final nextMonth =
        DateFormat('MMMM yyyy', 'ar').format(nextInst['dueDate'] as DateTime);
    final dueText =
        daysLeft >= 0 ? 'متبقي $daysLeft يوم' : 'متأخر ${daysLeft.abs()} يوم';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('متابعة سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                child: _installmentStat(
                    'مدفوع', '$paidCount', AppTheme.primaryColor),
              ),
              SizedBox(
                width: 150,
                child: _installmentStat(
                    'متبقي', '$pendingCount', AppTheme.borderColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'القسط التالي: $nextMonth • $dueText',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _installmentStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _installmentCard(Map<String, dynamic> inst) {
    final status = safeStr(inst['status'], 'Upcoming');
    final isPaid = status == 'Paid';
    final dueDate = inst['dueDate'] as DateTime;
    final days = dueDate.difference(DateTime.now()).inDays;
    final statusColor = switch (status) {
      'Paid' => AppTheme.primaryColor,
      'Grace Period' => AppTheme.borderColor,
      'Due Soon' => Colors.orange,
      'Upcoming' => AppTheme.textSecondary,
      _ => AppTheme.errorColor,
    };
    final statusText = switch (status) {
      'Paid' => 'مدفوع',
      'Grace Period' => 'فترة سماح',
      'Due Soon' => 'قريب الاستحقاق',
      'Upcoming' => 'قادم',
      _ => 'متأخر',
    };
    final monthLabel = DateFormat('MMM yyyy', 'ar').format(dueDate);
    final paidAt = inst['paidAt'] as DateTime?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'قسط $monthLabel',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('تاريخ الاستحقاق: ${DateFormat('yyyy/MM/dd').format(dueDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(days >= 0 ? 'متبقي $days يوم' : 'متأخر ${days.abs()} يوم',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 170,
                child: _installmentMeta('المبلغ', '${inst['amount']} ج.م'),
              ),
              if (isPaid)
                TextButton.icon(
                  onPressed: () => _showReceipt(inst),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(
                    'إيصال ${inst['receiptId']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _payInstallment(inst),
                  child: const Text('دفع القسط'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                child: _installmentMeta(
                    'الاستحقاق', DateFormat('yyyy/MM/dd').format(dueDate)),
              ),
              SizedBox(
                width: 150,
                child: _installmentMeta(
                  'السداد',
                  paidAt != null
                      ? DateFormat('yyyy/MM/dd').format(paidAt)
                      : 'غير مسدد',
                ),
              ),
            ],
          ),
          if ((inst['lateFees'] ?? 0) > 0 || (inst['discount'] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((inst['lateFees'] ?? 0) > 0)
                  _miniBadge(
                      'غرامة: ${inst['lateFees']} ج.م', AppTheme.errorColor),
                if ((inst['discount'] ?? 0) > 0)
                  _miniBadge(
                      'خصم: ${inst['discount']} ج.م', AppTheme.primaryColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _installmentMeta(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _statementShortcutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كشف حساب الإيجار',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'راجع الأقساط والمدفوعات والإيصالات من صفحة واحدة.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RentalStatementScreen(),
                ),
              );
            },
            child: const Text('فتح الكشف'),
          ),
        ],
      ),
    );
  }

  Future<void> _payInstallment(Map<String, dynamic> inst) async {
    final allowed = await AuthGate.requireLogin(
      context,
      actionLabel: 'دفع القسط الشهري',
    );
    if (!allowed || !mounted) return;

    final total = double.tryParse(inst['amount']?.toString() ?? '0') ?? 0.0;
    final deposit = total * 0.10;
    final remaining = total - deposit;
    final canSplit = (inst['status']?.toString() ?? '') != 'Paid';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          itemType: 'booking',
          itemData: {
            'id': inst['id'],
            'title':
                'قسط ${DateFormat('MMM yyyy', 'ar').format(inst['dueDate'] as DateTime)}',
            'monthlyRent': total,
            'price': total,
            'status': inst['status'],
          },
          amount: canSplit ? total : total,
          paymentStage: canSplit
              ? (inst['status'] == 'Paid' ? 'full' : 'remaining')
              : 'full',
          totalAmount: total,
          depositAmount: deposit,
          remainingAmount: canSplit ? remaining : 0,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فتح صفحة الدفع لإتمام سداد القسط وإصدار الإيصال.'),
        ),
      );
    }
  }

  void _showReceipt(Map<String, dynamic> inst) {
    final dueDate = inst['dueDate'] as DateTime;
    final paidAt = inst['paidAt'] as DateTime?;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيصال سداد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم الإيصال: ${inst['receiptId'] ?? 'REC-DEMO'}'),
            Text('المبلغ: ${inst['amount']} ج.م'),
            Text(
              'تاريخ الاستحقاق: ${DateFormat('yyyy/MM/dd').format(dueDate)}',
            ),
            Text(
              paidAt != null
                  ? 'تاريخ السداد: ${DateFormat('yyyy/MM/dd').format(paidAt)}'
                  : 'الحالة: مسدد',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
