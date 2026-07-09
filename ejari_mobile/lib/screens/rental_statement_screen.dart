import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/data_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/rental_schedule_utils.dart';

class RentalStatementScreen extends StatefulWidget {
  const RentalStatementScreen({super.key});

  @override
  State<RentalStatementScreen> createState() => _RentalStatementScreenState();
}

class _RentalStatementScreenState extends State<RentalStatementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _activeSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await WalletService.init();
    final bookings = await DataService.getBookings();
    final txs = await WalletService.getTransactions();
    final activeBookings = bookings
        .where((b) =>
            b['itemType'] != 'car' &&
            (b['status'] ?? '') != 'deposit_refunded' &&
            (b['status'] ?? '') != 'rejected')
        .toList();

    Map<String, dynamic>? activeSummary;
    if (activeBookings.isNotEmpty) {
      final booking = activeBookings.first;
      final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
      activeSummary = {
        'title': booking['title']?.toString() ?? 'عقد إيجار',
        'status': booking['status']?.toString() ?? 'pending',
        'monthlyRent': (snapshot['monthlyRent'] as num?)?.toDouble() ?? 0.0,
        'nextDueAmount': (snapshot['nextDueAmount'] as num?)?.toDouble() ?? 0.0,
        'nextDueDate': snapshot['nextDueDate'] as DateTime?,
        'remainingMonths': (snapshot['remainingMonths'] as num?)?.toInt() ?? 0,
        'paidMonths': (booking['paidMonths'] is num)
            ? (booking['paidMonths'] as num).toInt()
            : int.tryParse((booking['paidMonths'] ?? '0').toString()) ?? 0,
        'leaseMonths': (snapshot['leaseMonths'] as num?)?.toInt() ?? 0,
        'depositAmount': (snapshot['depositAmount'] as num?)?.toDouble() ?? 0.0,
        'remainingAmount':
            (snapshot['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      };
    }

    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _transactions = txs;
      _activeSummary = activeSummary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('كشف حساب الإيجار'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأقساط'),
            Tab(text: 'المدفوعات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInstallmentsTab(),
                  _buildPaymentsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildInstallmentsTab() {
    final activeBookings = _bookings
        .where((b) =>
            b['itemType'] != 'car' && (b['status'] ?? '') != 'deposit_refunded')
        .toList();

    if (activeBookings.isEmpty) {
      return _emptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد أقساط حالياً',
        subtitle: 'أول ما تعمل حجز إيجار أو تفعّل عقد، هيظهر هنا جدول السداد.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activeBookings.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _statementHero(activeBookings.length),
              const SizedBox(height: 12),
              _statementSummaryCard(),
              const SizedBox(height: 12),
              _statementInfoCard(),
            ],
          );
        }

        final booking = activeBookings[index - 1];
        final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
        final progress =
            ((snapshot['progress'] as num?) ?? 0.0).toDouble().clamp(0.0, 1.0);
        final nextDueDate = DateParsing.display(
          snapshot['nextDueDate'],
          fallback: 'قريباً',
          pattern: 'dd/MM/yyyy',
        );
        final durationLabel = booking['durationLabel']?.toString() ??
            booking['duration']?.toString() ??
            '${snapshot['leaseMonths']} شهر';
        final paymentSchedule =
            booking['paymentSchedule']?.toString().isNotEmpty == true
                ? booking['paymentSchedule'].toString()
                : 'شهري';
        final totalUnits = (snapshot['totalUnits'] as num?)?.toInt() ??
            (snapshot['leaseMonths'] as num?)?.toInt() ??
            0;
        final remainingUnits =
            (snapshot['remainingUnits'] as num?)?.toInt() ?? 0;
        final elapsedUnits = (snapshot['elapsedUnits'] as num?)?.toInt() ?? 0;
        final unitLabel = snapshot['durationUnit']?.toString() ?? 'شهر';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking['title']?.toString() ?? 'عقد إيجار',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      paymentSchedule,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'المدة المختارة: $durationLabel',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip('القسط الشهري',
                      '${(snapshot['monthlyRent'] as num).toStringAsFixed(0)} ج.م'),
                  _statChip('أقرب دفعة',
                      '${(snapshot['nextDueAmount'] as num).toStringAsFixed(0)} ج.م'),
                  _statChip('موعدها', nextDueDate),
                  _statChip('المتبقي', '$remainingUnits $unitLabel'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'أنقضى $elapsedUnits من $totalUnits $unitLabel • المبلغ المتبقي الحالي: ${(snapshot['remainingAmount'] as num).toStringAsFixed(0)} ج.م',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_transactions.isEmpty) {
      return _emptyState(
        icon: Icons.payments_outlined,
        title: 'لا توجد مدفوعات مسجلة',
        subtitle:
            'أي دفعة أو استكمال أو استرداد هتظهر هنا مع التاريخ والوسيلة.',
      );
    }

    final credits = _transactions
        .where((tx) =>
            tx['type'] == 'credit' ||
            tx['type'] == 'income' ||
            ((tx['amount'] as num?)?.toDouble() ?? 0) > 0)
        .length;
    final expenses = _transactions
        .where((tx) =>
            tx['type'] == 'expense' ||
            ((tx['amount'] as num?)?.toDouble() ?? 0) < 0)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _paymentsHero(credits, expenses),
        const SizedBox(height: 12),
        _statementSummaryCard(),
        const SizedBox(height: 12),
        _statementInfoCard(),
        const SizedBox(height: 14),
        ...List.generate(_transactions.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(height: 10);
          final index = i ~/ 2;
          final tx = _transactions[index];
          final DateTime date = DateParsing.parse(tx['date']) ?? DateTime.now();
          final isExpense = tx['type'] == 'expense';
          final amount = (tx['amount'] as num).toDouble();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isExpense
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    color:
                        isExpense ? AppTheme.errorColor : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['title']?.toString() ?? 'معاملة',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx['reason']?.toString() ?? 'تفاصيل الدفع تظهر هنا',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(date),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}${NumberFormat('#,##0').format(amount.abs())} ج.م',
                  style: TextStyle(
                    color:
                        isExpense ? AppTheme.errorColor : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statementHero(int activeBookingsCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.82)
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الكشف المالي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'تتبع الأقساط والمدفوعات من مكان واحد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statementChip('عقود نشطة', '$activeBookingsCount'),
              _statementChip('مدفوعات', '${_transactions.length}'),
              _statementChip('إيداعات',
                  '${_transactions.where((t) => t['type'] == 'credit' || t['type'] == 'income' || ((t['amount'] as num?)?.toDouble() ?? 0) > 0).length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statementChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _paymentsHero(int credits, int expenses) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المدفوعات المسجلة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'كل عملية موضحة بالتاريخ والسبب والاتجاه المالي عشان تقدر تراجع كل حاجة بسرعة.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 140, child: _statementMini('إيجابي', '$credits')),
              SizedBox(width: 140, child: _statementMini('سلبي', '$expenses')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statementMini(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _statementSummaryCard() {
    if (_activeSummary == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.12)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص الحجز',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            SizedBox(height: 6),
            Text(
              'بمجرد وجود حجز فعّال، سيظهر هنا ملخص القسط القادم والمدة المتبقية.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final nextDue = _activeSummary?['nextDueDate'] as DateTime?;
    final nextDueText = nextDue == null
        ? 'قريباً'
        : DateFormat('dd/MM/yyyy', 'ar').format(nextDue);
    final status = _activeSummary?['status']?.toString() ?? 'pending';
    final statusLabel = switch (status) {
      'completed' => 'مكتمل',
      'deposit_paid' => 'العربون مدفوع',
      'deposit_refunded' => 'مسترد',
      _ => 'نشط',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _activeSummary?['title']?.toString() ?? 'ملخص الحجز',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              _statusChip(statusLabel, AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip('القسط القادم',
                  '${_activeSummary?['nextDueAmount']?.toString() ?? '0'} ج.م'),
              _statChip('تاريخه', nextDueText),
              _statChip('المدفوع', '${_activeSummary?['paidMonths'] ?? 0} شهر'),
              _statChip(
                  'المتبقي', '${_activeSummary?['remainingMonths'] ?? 0} شهر'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _statementInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.12)),
      ),
      child: const Text(
        'الكشف هنا يجمع الأقساط المسجلة والمدفوعات الفعلية، بحيث تقدر تتبع أي دفعة أو استكمال أو استرداد بدون لخبطة.',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppTheme.primaryColor),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
