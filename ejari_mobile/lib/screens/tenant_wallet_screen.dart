import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_status.dart';
import '../models/payment_receipt.dart';
import '../services/data_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/safe_parse.dart';
import '../utils/wallet_category_labels.dart';
import '../widgets/ejari_section.dart';
import '../widgets/skeleton_list_loader.dart';
import 'payment_methods_screen.dart';
import 'payment_reminders_screen.dart';
import 'payment_screen.dart';
import 'receipt_screen.dart';
import 'rental_statement_screen.dart';

class TenantWalletScreen extends StatefulWidget {
  const TenantWalletScreen({super.key});

  @override
  State<TenantWalletScreen> createState() => _TenantWalletScreenState();
}

class _TenantWalletScreenState extends State<TenantWalletScreen> {
  double _balance = 0;
  double _escrow = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _upcomingPayments = [];
  String _selectedFilter = 'الكل';
  bool _isLoading = true;

  static const _filters = [
    'الكل',
    'إيجار',
    'عربون',
    'استرداد',
    'شحن',
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    await WalletService.init();
    final summary = await WalletService.getWalletSummary();
    final transactions = await WalletService.getTransactions();
    final upcoming = await DataService.getTenantUpcomingPayments();

    if (!mounted) return;
    setState(() {
      _balance = (summary['balance'] as num?)?.toDouble() ?? 0;
      _escrow = (summary['escrow'] as num?)?.toDouble() ?? 0;
      _transactions = transactions;
      _upcomingPayments = upcoming;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredTransactions => _transactions
      .where((t) => WalletCategoryLabels.matchesFilter(t, _selectedFilter))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'المحفظة',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: Navigator.canPop(context),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).iconTheme.color,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'الإيصالات',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RentalStatementScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const SkeletonListLoader(itemCount: 6, itemHeight: 100)
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                await _loadWalletData();
              },
              color: AppTheme.primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPadding,
                  AppTheme.spaceSm,
                  AppTheme.screenPadding,
                  AppTheme.homeBottomClearance,
                ),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildEscrowCard(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildQuickActions(),
                  const SizedBox(height: AppTheme.spaceXl),
                  _buildUpcomingSection(),
                  const SizedBox(height: AppTheme.spaceXl),
                  _buildTransactionSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الرصيد المتاح',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'إيجاري',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${NumberFormat('#,##0.00').format(_balance)} ج.م',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BalanceActionChip(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'شحن',
                  onTap: _showTopUpDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceActionChip(
                  icon: Icons.south_west_rounded,
                  label: 'طلب سحب',
                  onTap: _showWithdrawDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceActionChip(
                  icon: Icons.receipt_long_rounded,
                  label: 'إيصالات',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RentalStatementScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowCard() {
    return EjariSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مبالغ محجوزة (ضمان)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'عربون أو تأمين محتجز حتى إتمام العقد',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${NumberFormat('#,##0').format(_escrow)} ج.م',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppTheme.accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            title: 'طرق الدفع',
            subtitle: 'بطاقات ومحافظ',
            icon: Icons.credit_card_rounded,
            color: AppTheme.primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickTile(
            title: 'تذكيرات',
            subtitle: '${_upcomingPayments.length} دفعة',
            icon: Icons.notifications_active_outlined,
            color: AppTheme.accentColor,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentRemindersScreen(),
                ),
              );
              _loadWalletData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EjariSectionHeader(
          title: 'الدفعات القادمة',
          subtitle: 'أقساط وعربون مستحق',
          actionLabel: 'عرض الكل',
          onAction: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PaymentRemindersScreen(),
              ),
            );
            _loadWalletData();
          },
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (_upcomingPayments.isEmpty)
          EjariSurfaceCard(
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.primaryColor.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'لا توجد دفعات قادمة حالياً',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._upcomingPayments.take(3).map((payment) {
            final due =
                DateTime.tryParse(payment['dueDate']?.toString() ?? '');
            final dueText =
                due == null ? '—' : DateFormat('yyyy/MM/dd').format(due);
            final isOverdue = payment['isOverdue'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EjariSurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['property']?.toString() ??
                                payment['title']?.toString() ??
                                'قسط إيجار',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dueText • ${payment['statusLabel']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat('#,##0').format(safeDouble(payment['amount']))} ج.م',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isOverdue
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openPaymentForReminder(payment),
                          child: const Text('ادفع'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTransactionSection() {
    final filtered = _filteredTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EjariSectionHeader(
          title: 'سجل العمليات',
          subtitle: '${filtered.length} عملية',
        ),
        const SizedBox(height: AppTheme.spaceSm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final selected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedFilter = filter),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        if (filtered.isEmpty)
          EjariSurfaceCard(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppTheme.primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد معاملات لهذا التصنيف',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'جرّب فلتر «الكل» أو اشحن رصيدك لتظهر العمليات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          EjariSurfaceCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = filtered[index];
                final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
                final isExpense = amount < 0 ||
                    tx['type'] == 'expense' ||
                    tx['type'] == 'withdrawal' ||
                    tx['type'] == 'escrow';
                final date =
                    DateParsing.parse(tx['date']) ?? DateTime.now();

                return ListTile(
                  onTap: () => _showTransactionDetails(tx),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isExpense
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.successColor.withOpacity(0.1),
                    child: Icon(
                      isExpense
                          ? Icons.arrow_outward_rounded
                          : Icons.arrow_downward_rounded,
                      color: isExpense
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx['title']?.toString() ?? 'عملية',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            WalletCategoryLabels.labelFor(tx),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(date),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    '${isExpense ? '-' : '+'}${NumberFormat('#,##0').format(amount.abs())}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isExpense
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showTopUpDialog() {
    final controller = TextEditingController(text: '500');
    final presets = [200.0, 500.0, 1000.0, 5000.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            AppTheme.spaceLg,
            AppTheme.screenPadding,
            MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'شحن الرصيد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'أضف رصيداً للمحفظة (وضع تجريبي)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets
                    .map(
                      (p) => ActionChip(
                        label: Text('${p.toStringAsFixed(0)} ج.م'),
                        onPressed: () =>
                            controller.text = p.toStringAsFixed(0),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ (ج.م)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              SizedBox(
                width: double.infinity,
                height: AppTheme.ctaHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text.trim());
                    if (amount == null || amount <= 0) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    await WalletService.topUpWallet(amount);
                    await _loadWalletData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم شحن ${NumberFormat('#,##0').format(amount)} ج.م',
                        ),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تأكيد الشحن',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            AppTheme.spaceLg,
            AppTheme.screenPadding,
            MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'طلب سحب رصيد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'المتاح: ${NumberFormat('#,##0.00').format(_balance)} ج.م',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ المطلوب',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              SizedBox(
                width: double.infinity,
                height: AppTheme.ctaHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text.trim());
                    if (amount == null || amount <= 0) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final ok = await WalletService.requestWithdrawal(
                      amount: amount,
                    );
                    await _loadWalletData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'تم تسجيل طلب السحب — قيد المراجعة'
                              : 'تعذر السحب. تحقق من الرصيد',
                        ),
                        backgroundColor: ok
                            ? AppTheme.primaryColor
                            : AppTheme.errorColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'إرسال الطلب',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPaymentForReminder(Map<String, dynamic> payment) async {
    final bookingId = payment['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty) return;
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null || !mounted) return;

    final amount = safeDouble(payment['amount']);
    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);
    final deposit = safeDouble(booking['depositAmount']);
    final leaseTotal = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );
    final status = (booking['status'] ?? '').toString();
    final needsDeposit = status == BookingStatus.submitted ||
        status == BookingStatus.pending ||
        status == BookingStatus.corporatePending;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: needsDeposit
              ? (deposit > 0 ? deposit : monthly * 0.2)
              : (amount > 0 ? amount : monthly),
          paymentStage: needsDeposit ? 'deposit' : 'remaining',
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: needsDeposit
              ? (deposit > 0 ? deposit : monthly * 0.2)
              : (amount > 0 ? amount : monthly),
        ),
      ),
    );
    _loadWalletData();
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final date = DateParsing.parse(tx['date']) ?? DateTime.now();
    final receipt = PaymentReceipt(
      id: tx['id']?.toString() ?? 'TXN-${date.millisecondsSinceEpoch}',
      amount: amount.abs(),
      date: date,
      bookingRef: tx['bookingId']?.toString() ?? '—',
      payer: 'محفظة المستأجر',
      payee: 'إيجاري',
      method: tx['method']?.toString() ?? 'wallet',
      status: tx['status']?.toString() ?? 'completed',
      title: tx['title']?.toString(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReceiptScreen(receipt: receipt),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'التصنيف: ${WalletCategoryLabels.labelFor(tx)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _BalanceActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BalanceActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.surfaceCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
