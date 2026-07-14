import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';
import '../services/wallet_service.dart';
import '../utils/wallet_category_labels.dart';
import '../utils/safe_parse.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _walletTx = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    final techId = user?['email']?.toString() ?? 'tech@ejari.app';
    final stats = await DataService.getProviderStats(techId);
    final jobs = await DataService.getProviderRequests(techId);
    await WalletService.init(userId: techId);
    final tx = await WalletService.getTransactions(userId: techId);
    setState(() {
      _stats = stats;
      _jobs = jobs.where((j) {
        final s = (j['status'] ?? '').toString();
        return s == 'completed' ||
            s == MaintenanceStatus.completed ||
            s == MaintenanceStatus.paid;
      }).toList();
      _walletTx = tx
          .where((t) =>
              t['category'] == 'maintenance' ||
              t['type'] == 'income' ||
              t['type'] == 'commission')
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final embedded =
        context.findAncestorWidgetOfExactType<IndexedStack>() != null;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('المحفظة والأرباح'),
        automaticallyImplyLeading: !embedded,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 20, 20, embedded ? 110 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 32),
                    const Text('سجل الدخل من المهام',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_walletTx.isEmpty && _jobs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.handyman_outlined,
                                  size: 56, color: AppTheme.primaryColor),
                              SizedBox(height: 12),
                              Text('لا توجد أرباح بعد',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text('أكمل مهمة صيانة لتظهر أرباحك هنا',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      ..._walletTx.map(_buildWalletTxItem),
                      ..._jobs.map(_buildTransactionItem),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          const Text('الرصيد المتاح للسحب',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${safeDouble(_stats?['earnings']).toStringAsFixed(0)} ج.م',
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final amount = safeDouble(_stats?['earnings']);
              if (amount <= 0) return;
              final user = await AuthService.getCurrentUser();
              final techId = user?['email']?.toString() ?? 'tech@ejari.app';
              final ok = await WalletService.requestWithdrawal(
                amount: amount,
                userId: techId,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'تم تقديم طلب السحب — سيتم التحويل خلال 48 ساعة'
                      : 'تعذر تقديم طلب السحب'),
                  backgroundColor:
                      ok ? AppTheme.primaryColor : AppTheme.errorColor,
                ),
              );
              if (ok) _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('سحب الأرباح الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTxItem(Map<String, dynamic> tx) {
    final amount = safeDouble(tx['amount']).abs();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.backgroundColor),
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
                Text(tx['title']?.toString() ?? 'دخل صيانة',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(WalletCategoryLabels.labelFor(tx),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '+${amount.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child:
                const Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(safeStr(job['service'], 'صيانة'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('رقم الطلب: ${job['id']}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '+${job['price']} ج.م',
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}
