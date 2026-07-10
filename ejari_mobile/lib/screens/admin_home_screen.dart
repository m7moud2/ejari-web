import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_financials_screen.dart';
import 'chat_list_screen.dart';
import '../services/data_service.dart';
import '../utils/auth_gate.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _totalUsers = 0;
  int _totalProperties = 0;

  double _totalRevenue = 0;
  int _pendingVerifications = 0;
  int _reportedIssues = 0;

  List<double> _userGrowth = [0, 0, 0, 0, 0, 0];
  List<double> _revenueGrowth = [0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await AuthGate.requireRole(
        context,
        allowedRoles: const ['admin'],
        deniedMessage: 'لوحة الإدارة متاحة للمدير فقط.',
      );
      if (allowed) _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final stats = await DataService.getAdminGlobalStats();
    final chartData = await DataService.getAdminChartData();

    if (mounted) {
      setState(() {
        _totalUsers = stats['totalUsers'];
        _totalProperties = stats['totalProperties'];

        _totalRevenue = stats['totalRevenue'];
        _pendingVerifications = stats['pendingVerifications'];
        _reportedIssues = stats['newFeedbackCount'];

        _userGrowth = chartData['userGrowth']!;
        _revenueGrowth = chartData['revenueGrowth']!;
        _isLoading = false;
      });
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('لوحة تحكم إيجاري 🛡️',
            style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'إحصائيات حية'),
            Tab(text: 'إدارة العمليات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStatsTab(),
                _buildActionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminWelcome(),
            const SizedBox(height: 24),
            _buildKeyMetrics(),
            const SizedBox(height: 24),
            _buildOfferProgressBar(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminWelcome() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white10,
              child: Icon(Icons.admin_panel_settings,
                  size: 35, color: Colors.white)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مرحباً، المدير التنفيذي 👋',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('نظام إيجاري يعمل بكفاءة عالية',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('متصل',
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 110,
      ),
      children: [
        _buildMetricCard('إجمالي المستخدمين', '$_totalUsers', Icons.people,
            AppTheme.primaryColor),
        _buildMetricCard('العقارات المدرجة', '$_totalProperties',
            Icons.home_work, AppTheme.borderColor),
        _buildMetricCard(
            'حجم التداول',
            '${(_totalRevenue / 1000).toStringAsFixed(1)}K ج.م',
            Icons.attach_money,
            AppTheme.primaryColor),
        _buildMetricCard('بلاغات معلقة', '$_reportedIssues',
            Icons.report_problem, AppTheme.errorColor),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const []),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferProgressBar() {
    double progress = _totalUsers / 100;
    if (progress > 1) progress = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('هدف أول 100 عميل إيجاري 🎯',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 10),
          Text(
              'لقد وصلت إلى $_totalUsers من أصل 100 عميل مستهدف في المرحلة الأولى.',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildChartContainer('تحليل نمو المستخدمين', _buildUserGrowthChart()),
          const SizedBox(height: 20),
          _buildChartContainer('تحليل الإيرادات الحية', _buildRevenueChart()),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
            _userGrowth.length,
            (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: _userGrowth[i],
                      color: AppTheme.primaryColor,
                      width: 15,
                      borderRadius: BorderRadius.circular(4))
                ])),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(_revenueGrowth.length,
                (i) => FlSpot(i.toDouble(), _revenueGrowth[i])),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 4,
            belowBarData: BarAreaData(
                show: true, color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActionCard(
            'إدارة المستخدمين',
            'التحكم في كافة الحسابات والبيانات',
            Icons.people_alt_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen()))),
        _buildActionCard(
            'الإدارة المالية والعقود',
            'تحليل الأرباح والعقود القانونية',
            Icons.account_balance_wallet_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminFinancialsScreen()))),
        _buildActionCard(
            'مراجعة العقارات',
            '$_pendingVerifications طلبات تنتظر الموافقة',
            Icons.home_work_rounded,
            AppTheme.borderColor,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminPropertiesScreen()))),
        _buildActionCard(
            'البلاغات والشكاوى',
            '$_reportedIssues شكوى فنية وإدارية',
            Icons.report_gmailerrorred_rounded,
            AppTheme.errorColor,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminReportsScreen()))),
        _buildActionCard(
            'شات الدعم الفني',
            'الرد المباشر على استفسارات العملاء',
            Icons.chat_bubble_rounded,
            AppTheme.primaryColor,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChatListScreen()))),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('النشاط اللحظي للنظام ⚡',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildActivityItem('تم حجز وحدة جديدة', 'منذ 3 دقائق',
            Icons.shopping_bag_rounded, AppTheme.primaryColor),
        _buildActivityItem('تسجيل مستخدم جديد', 'منذ 10 دقائق',
            Icons.person_add_rounded, AppTheme.primaryColor),
        _buildActivityItem('بلاغ صيانة طارئ', 'منذ ساعة', Icons.build_rounded,
            AppTheme.borderColor),
      ],
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 15),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold))),
          Text(time,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
