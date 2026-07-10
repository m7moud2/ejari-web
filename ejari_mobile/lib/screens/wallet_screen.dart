import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../utils/safe_parse.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  double _totalBalance = 0;
  double _available = 0;
  double _escrow = 0;
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email'] ?? 'owner123';
    final walletData = await DataService.getWalletData(ownerId);
    final transactions = await DataService.getWalletTransactions(ownerId);
    if (mounted) {
      setState(() {
        _totalBalance = (walletData['totalBalance'] as num?)?.toDouble() ?? 0;
        _available = (walletData['available'] as num?)?.toDouble() ?? 0;
        _escrow = (walletData['escrow'] as num?)?.toDouble() ?? 0;
        _allTransactions = transactions;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('المحفظة المالية'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        centerTitle: true,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _buildTotalBalanceHeader(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.arrow_circle_up_rounded,
                          title: 'سحب الأرباح',
                          subtitle: 'نقل الرصيد المتاح',
                          onTap: () => _showWithdrawDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.add_card_rounded,
                          title: 'شحن رصيد',
                          subtitle: 'زيادة المحفظة فوراً',
                          onTap: () => _showTopUpDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.25),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                      tabs: const [
                        Tab(text: 'الكل'),
                        Tab(text: 'الإيداعات'),
                        Tab(text: 'السحوبات'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsList('all'),
                      _buildTransactionsList('deposit'),
                      _buildTransactionsList('withdraw'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTotalBalanceHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرصيد الكلي الحالي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalBalance.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildBalanceDetail(
                  'متاح للسحب',
                  '${_available.toStringAsFixed(0)} ج.م',
                  Icons.check_circle_outline,
                  AppTheme.accentColor),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
              _buildBalanceDetail(
                  'معلق (Escrow)',
                  '${_escrow.toStringAsFixed(0)} ج.م',
                  Icons.access_time,
                  AppTheme.borderColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDetail(
      String label, String amount, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(amount,
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(String filter) {
    List<Map<String, dynamic>> filteredList = _allTransactions;
    if (filter != 'all') {
      filteredList =
          _allTransactions.where((t) => t['type'] == filter).toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long,
                size: 60, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('لا توجد معاملات $filter',
                style: const TextStyle(color: AppTheme.primaryColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        final isDeposit = item['type'] == 'deposit';
        final isPending = item['status'] == 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDeposit
                  ? AppTheme.primaryColor.withOpacity(0.16)
                  : AppTheme.errorColor.withOpacity(0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: isDeposit
                  ? (isPending
                      ? AppTheme.accentColor.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.12))
                  : AppTheme.errorColor.withOpacity(0.12),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit
                    ? (isPending
                        ? AppTheme.textSecondary
                        : AppTheme.primaryColor)
                    : AppTheme.errorColor,
              ),
            ),
            title: Text(
              safeStr(item['title'], 'معاملة'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(safeStr(item['reason']),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item['date'] as DateTime),
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontSize: 11),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['amount']} ج.م',
                  style: TextStyle(
                    color:
                        isDeposit ? AppTheme.primaryColor : AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (isPending)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.24),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.35)),
                    ),
                    child: const Text(
                      'معلق',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showWithdrawDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سحب الأرباح', textAlign: TextAlign.center),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم إضافة طريقة السحب لاحقاً. اختر وسيلة التحويل المفضلة:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            _buildWithdrawOption(context, 'تحويل بنكي', Icons.account_balance,
                AppTheme.primaryColor),
            _buildWithdrawOption(context, 'محفظة إلكترونية', Icons.phone_android,
                AppTheme.errorColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawOption(
      BuildContext context, String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.backgroundColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppTheme.primaryColor),
        onTap: () {
          Navigator.pop(context);
          _showAmountDialog(context, title);
        },
      ),
    );
  }

  Future<void> _showAmountDialog(BuildContext context, String method) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سحب عبر $method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('الحد الأدنى للسحب 500 ج.م',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primaryColor))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المراد سحبه',
                suffixText: 'ج.م',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: method == 'تحويل بنكي'
                    ? 'رقم الحساب (IBAN)'
                    : 'رقم الهاتف (Wallet)',
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final amount = double.tryParse(controller.text) ?? 0;
              final user = await AuthService.getCurrentUser();
              final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
              final ok = await WalletService.requestWithdrawal(
                amount: amount,
                userId: ownerId,
                method: method,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle : Icons.error_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ok
                            ? 'تم تقديم طلب سحب ${controller.text} ج.م عبر $method'
                            : 'تعذر تقديم طلب السحب — تحقق من الرصيد'),
                      ),
                    ],
                  ),
                  backgroundColor:
                      ok ? AppTheme.primaryColor : AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (ok) _loadWalletData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('تأكيد السحب',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTopUpDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('شحن الرصيد', textAlign: TextAlign.center),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر وسيلة الدفع:',
                style: TextStyle(color: AppTheme.primaryColor)),
            const SizedBox(height: 20),
            _buildWithdrawOption(context, 'فوري (Fawry)', Icons.receipt_long,
                AppTheme.borderColor),
            _buildWithdrawOption(context, 'فيزا / ماستركارد', Icons.credit_card,
                AppTheme.primaryColor),
            _buildWithdrawOption(context, 'فودافون كاش', Icons.phone_android,
                AppTheme.errorColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}
