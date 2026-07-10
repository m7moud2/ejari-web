import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

class AdminFinancialsScreen extends StatefulWidget {
  const AdminFinancialsScreen({super.key});

  @override
  State<AdminFinancialsScreen> createState() => _AdminFinancialsScreenState();
}

class _AdminFinancialsScreenState extends State<AdminFinancialsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _totalVolume = 0;
  double _platformEarnings = 0;
  double _escrowBalance = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DataService.getAdminGlobalStats();

    if (mounted) {
      setState(() {
        _totalVolume = stats['totalRevenue'];
        _platformEarnings = _totalVolume * 0.15;
        _escrowBalance = _totalVolume * 0.10;
        _recentTransactions = [
          {
            'title': 'عمولة حجز - إيجاري',
            'amount': '+${(_totalVolume * 0.05).toStringAsFixed(0)}',
            'date': 'اليوم، 10:30 ص',
            'status': 'completed',
            'type': 'commission'
          },
          {
            'title': 'تسوية أرباح - InstaPay',
            'amount': '-5,000',
            'date': 'اليوم، 09:45 ص',
            'status': 'completed',
            'account': '01069813210',
            'type': 'withdrawal'
          },
          {
            'title': 'رسوم توثيق عقد رقم #882',
            'amount': '+450',
            'date': 'أمس، 04:15 م',
            'status': 'completed',
            'type': 'fees'
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('الإدارة المالية والقانونية ⚖️',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'التدفق المالي'),
            Tab(text: 'العقود الرقمية'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFinancialsTab(),
                _buildContractsTab(),
              ],
            ),
    );
  }

  Widget _buildFinancialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEjariWalletCard(),
          const SizedBox(height: 24),
          const Text('ملخص مالي سريع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallStatCard(
                  'أرباح المنصة',
                  '${_platformEarnings.toStringAsFixed(0)} ج.م',
                  AppTheme.primaryColor),
              const SizedBox(width: 12),
              _buildSmallStatCard(
                  'قيد التسوية',
                  '${(_totalVolume * 0.05).toStringAsFixed(0)} ج.م',
                  AppTheme.borderColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallStatCard(
                  'رصيد escrow',
                  '${_escrowBalance.toStringAsFixed(0)} ج.م',
                  AppTheme.primaryColor),
              const SizedBox(width: 12),
              _buildSmallStatCard(
                  'عدد العمليات',
                  '${_recentTransactions.length}',
                  AppTheme.errorColor),
            ],
          ),
          const SizedBox(height: 32),
          const Text('المعاملات المالية الأخيرة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._recentTransactions.map((tx) => _buildTransactionItem(tx)),
        ],
      ),
    );
  }

  Widget _buildEjariWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.borderColor, AppTheme.textPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجمالي حجم التداول المدار',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text('${_totalVolume.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildWalletDetail(
                  'قيد التسوية',
                  '${_escrowBalance.toStringAsFixed(0)} ج.م',
                  AppTheme.borderColor),
              _buildWalletDetail(
                  'جاهز للسحب',
                  '${(_platformEarnings * 0.8).toStringAsFixed(0)} ج.م',
                  AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'القيم المعروضة هنا هي ملخص إداري سريع لمتابعة الحركة المالية داخل النظام.',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletDetail(String label, String value, Color color) {
    return SizedBox(
      width: 150,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildContractActionCard(
            'توثيق العقود القانونية',
            'نظام يضمن حقوق الطرفين (مالك ومستأجر)',
            Icons.gavel_rounded,
            AppTheme.borderColor),
        const SizedBox(height: 24),
        const Text('العقود الرقمية النشطة (الجارية)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildContractItem('عقد إيجار رقم #882', 'المستأجر: أحمد محمد',
            'ينتهي في: 2024-12-01', 'نشط', AppTheme.primaryColor),
        _buildContractItem('عقد تمليك رقم #910', 'المشتري: سارة علي',
            'الحالة: قيد التسجيل', 'معلق', AppTheme.borderColor),
        _buildContractItem('عقد إيجار رقم #750', 'المستأجر: محمود حسن',
            'منتهي في: 2023-11-15', 'منتهي', AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildContractActionCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(subtitle,
                    style:
                        TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractItem(String title, String parties, String date,
      String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(parties,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
          Text(date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('تحميل PDF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12))),
              ),
              const Spacer(),
              const Icon(Icons.verified_rounded,
                  color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 5),
              const Text('موثق رقمياً',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final bool isPositive = tx['amount'].toString().startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color:
                      (isPositive ? AppTheme.primaryColor : AppTheme.errorColor)
                          .withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(isPositive ? Icons.add_rounded : Icons.remove_rounded,
                  color:
                      isPositive ? AppTheme.primaryColor : AppTheme.errorColor,
                  size: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(tx['date'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${tx['amount']} ج.م',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? AppTheme.primaryColor
                          : AppTheme.errorColor)),
              const SizedBox(height: 2),
              Text(
                tx['status'] == 'completed' ? 'مكتملة' : 'قيد المراجعة',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isPositive
                      ? AppTheme.primaryColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
