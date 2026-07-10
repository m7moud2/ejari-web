import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/wallet_service.dart';
import '../services/data_service.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';
import '../utils/rental_schedule_utils.dart';
import '../utils/safe_parse.dart';
import 'payment_methods_screen.dart';
import 'rewards_screen.dart';
import 'rental_statement_screen.dart';
import '../utils/wallet_category_labels.dart';

class TenantWalletScreen extends StatefulWidget {
  const TenantWalletScreen({super.key});

  @override
  State<TenantWalletScreen> createState() => _TenantWalletScreenState();
}

class _TenantWalletScreenState extends State<TenantWalletScreen> {
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _rentSummary;
  List<Map<String, dynamic>> _relatedBookings = [];
  String _selectedFilter = 'الكل'; // الكل، إيجار، عربون، استرداد، إيداع، سحب
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    await WalletService.init();
    final balance = await WalletService.getBalance();
    final transactions = await WalletService.getTransactions();
    final bookings = await DataService.getBookings();

    final activeBookings = bookings
        .where((b) =>
            (b['status'] ?? '').toString() != 'deposit_refunded' &&
            (b['status'] ?? '').toString() != 'rejected')
        .toList();

    Map<String, dynamic>? rentSummary;
    if (activeBookings.isNotEmpty) {
      final booking = activeBookings.first;
      final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
      rentSummary = {
        'title': booking['title']?.toString() ?? 'حجز إيجار',
        'monthlyRent': safeDouble(snapshot['monthlyRent']),
        'nextDueAmount': safeDouble(snapshot['nextDueAmount']),
        'nextDueDate': snapshot['nextDueDate'] as DateTime?,
        'remainingMonths': safeInt(snapshot['remainingMonths']),
        'paidMonths': safeInt(booking['paidMonths']),
        'leaseMonths': safeInt(snapshot['leaseMonths'], 1),
        'depositAmount': safeDouble(snapshot['depositAmount']),
        'remainingAmount': safeDouble(snapshot['remainingAmount']),
      };
    }

    if (mounted) {
      setState(() {
        _balance = balance;
        _transactions = transactions;
        _relatedBookings = activeBookings;
        _rentSummary = rentSummary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('المحفظة المالية',
            style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildOverviewCard(),
                    _buildBalanceCard(),
                    const SizedBox(height: 16),
                    _buildRentSummaryCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildStatementsCard(),
                    const SizedBox(height: 32),
                    _buildTransactionHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final creditCount =
        _transactions.where((t) => t['type'] == 'credit').length;
    final expenseCount =
        _transactions.where((t) => t['type'] == 'expense').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'ملخص سريع',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewTile(
                  label: 'إجمالي الرصيد',
                  value: '${NumberFormat('#,##0.00').format(_balance)} ج.م',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewTile(
                  label: 'العمليات',
                  value: '${_transactions.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildOverviewTile(
                  label: 'إيداعات',
                  value: '$creditCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewTile(
                  label: 'سحوبات',
                  value: '$expenseCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.borderColor, AppTheme.borderColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.wifi_rounded,
                size: 100, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ejari Ejari',
                      style: TextStyle(
                          color: AppTheme.borderColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2)),
                  Icon(Icons.contactless_rounded,
                      color: Colors.white.withOpacity(0.5), size: 28),
                ],
              ),
              const SizedBox(height: 32),
              const Text('الرصيد المتاح',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                '${NumberFormat('#,##0.00').format(_balance)} ج.م',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildBalanceAction(Icons.add_circle_outline_rounded,
                      'شحن الرصيد', _showTopUpDialog),
                  _buildBalanceAction(Icons.arrow_circle_up_rounded, 'تحويل',
                      _showQuickPayDialog),
                  _buildBalanceAction(
                      Icons.receipt_long_rounded,
                      'الكشوفات',
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RentalStatementScreen(),
                            ),
                          )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('شحن المحفظة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل ترغب بإضافة 5000 ج.م للمحفظة كتجربة؟',
            style: TextStyle(color: AppTheme.primaryColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await WalletService.topUpWallet(5000.0);
              await _loadWalletData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('تم الشحن 💳'),
                    backgroundColor: AppTheme.primaryColor));
              }
            },
            child: const Text('تأكيد الشحن',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickPayDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تحويل استثماري',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'المبلغ (ج.م)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final success = await WalletService.payFromWallet(
                title: 'تحويل معتمد',
                amount: amount,
                category: 'service',
                bookingId: 'SVC-${DateTime.now().millisecondsSinceEpoch}',
              );

              await _loadWalletData();

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم التحويل ✅'),
                      backgroundColor: AppTheme.primaryColor));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('الرصيد غير كافٍ'),
                      backgroundColor: AppTheme.errorColor));
                }
              }
            },
            child: const Text('تحويل',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).cardColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen())),
              child: _buildActionCard('بطاقات الائتمان', 'إدارة البطاقات',
                  Icons.credit_score_rounded, AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RewardsScreen())),
              child: _buildActionCard('المكافآت', 'نقاط وعروض',
                  Icons.workspace_premium_rounded, AppTheme.borderColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementsCard() {
    final activeCount = _relatedBookings.length;
    final paidCount = _rentSummary?['paidMonths'] ?? 0;
    final remainingMonths = _rentSummary?['remainingMonths'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الكشوفات والملخصات',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('راجع كل التحركات المالية والرسوم والإيصالات من هنا.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RentalStatementScreen(),
                  ),
                ),
                child: const Text('فتح'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniStat('عقود نشطة', '$activeCount'),
              _miniStat('مدفوع', '$paidCount'),
              _miniStat('متبقي', '$remainingMonths'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentSummaryCard() {
    if (_rentSummary == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'لن تظهر تفاصيل الأقساط إلا بعد وجود حجز/عقد فعّال.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final nextDue = _rentSummary?['nextDueDate'] as DateTime?;
    final nextDueText =
        nextDue == null ? 'قريباً' : DateFormat('yyyy/MM/dd').format(nextDue);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _rentSummary?['title']?.toString() ?? 'ملخص الأقساط',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniStat('القسط القادم',
                  '${(_rentSummary?['nextDueAmount'] ?? 0).toString()} ج.م'),
              _miniStat('تاريخه', nextDueText),
              _miniStat('المدفوع', '${_rentSummary?['paidMonths'] ?? 0} شهر'),
              _miniStat(
                  'المتبقي', '${_rentSummary?['remainingMonths'] ?? 0} شهر'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  const TextStyle(color: AppTheme.primaryColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final filteredTransactions = _transactions.where((t) {
      return WalletCategoryLabels.matchesFilter(t, _selectedFilter);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('سجل العمليات',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color)),
              Text('${filteredTransactions.length} عملية',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['الكل', 'إيجار', 'عربون', 'استرداد', 'إيداع', 'سحب']
                  .map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? AppTheme.backgroundColor
                            : Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.5)
                                : Colors.transparent)),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (filteredTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: AppTheme.primaryColor, size: 52),
                  SizedBox(height: 12),
                  Text('لا توجد معاملات تطابق الفلتر',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('جرّب اختيار “الكل” أو راجع الفلاتر',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final isExpense = transaction['type'] == 'expense' ||
                    transaction['type'] == 'escrow';
                final categoryLabel =
                    WalletCategoryLabels.labelFor(transaction);
                final DateTime date =
                    DateTime.tryParse(transaction['date']) ?? DateTime.now();

                return InkWell(
                  onTap: () => _showTransactionDetails(transaction),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: AppTheme.backgroundColor))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isExpense
                                  ? AppTheme.backgroundColor
                                  : AppTheme.backgroundColor,
                              shape: BoxShape.circle),
                          child: Icon(
                              isExpense
                                  ? Icons.arrow_outward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: isExpense
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                              size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(transaction['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  categoryLabel,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(date),
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          '${isExpense ? '-' : '+'}${NumberFormat('#,##0').format((transaction['amount'] as num).abs())}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isExpense
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إيصال المعاملة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 30,
              backgroundColor: tx['type'] == 'expense'
                  ? AppTheme.backgroundColor
                  : AppTheme.backgroundColor,
              child: Icon(
                  tx['type'] == 'expense'
                      ? Icons.payment_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: tx['type'] == 'expense'
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  size: 30),
            ),
            const SizedBox(height: 16),
            Text('${tx['amount']} ج.م',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1)),
            Text(tx['title'] ?? '',
                style: const TextStyle(color: AppTheme.primaryColor)),
            const Divider(height: 40),
            _buildDetailRow('التصنيف',
                WalletCategoryLabels.labelFor(tx)),
            _buildDetailRow('الحالة', 'مكتملة الموثوقية ✅'),
            _buildDetailRow('الرقم المرجعي',
                'TXN-${DateTime.now().millisecondsSinceEpoch}'),
            _buildDetailRow(
                'التاريخ',
                DateFormat('dd MMM yyyy, hh:mm a')
                    .format(DateParsing.parse(tx['date']) ?? DateTime.now())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم تصدير الإيصال البنكي 📄')));
                },
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: const Text('تصدير كوثيقة',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.primaryColor)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}
