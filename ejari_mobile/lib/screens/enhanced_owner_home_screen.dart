import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'login_screen.dart';
import 'add_property_screen.dart';
import 'manage_properties_screen.dart';
import 'wallet_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'owner_collection_screen.dart';
import 'notification_center_screen.dart';

class EnhancedOwnerHomeScreen extends StatefulWidget {
  const EnhancedOwnerHomeScreen({super.key});

  @override
  State<EnhancedOwnerHomeScreen> createState() =>
      _EnhancedOwnerHomeScreenState();
}

class _EnhancedOwnerHomeScreenState extends State<EnhancedOwnerHomeScreen> {
  int _totalProperties = 0;
  int _activeBookings = 0;
  double _monthlyRevenue = 0;
  int _pendingRequests = 0;
  List<Map<String, dynamic>> _recentBookings = [];
  List<double> _chartData = [0, 0, 0, 0, 0, 0];
  String _ownerName = 'المالك';

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadData();
  }

  Future<void> _checkRole() async {
    final role = await AuthService.getUserRole();
    if (role != 'owner' && role != 'admin' && mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (r) => false);
    }
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email'] ?? 'owner123';

    final properties = await DataService.getOwnerProperties(ownerId);
    final bookings = await DataService.getOwnerBookings(ownerId);
    final revenue = await DataService.getOwnerRevenue(ownerId);
    final requests = await DataService.getOwnerRequests(ownerId);
    final chartData = await DataService.getRevenueChartData(ownerId);

    if (mounted) {
      setState(() {
        _ownerName = user?['name'] ?? 'المالك';
        _totalProperties = properties.length;
        _activeBookings = bookings.where((b) => b['status'] == 'active').length;
        _monthlyRevenue = revenue;
        _pendingRequests =
            requests.where((r) => r['status'] == 'pending').length;
        _recentBookings = bookings.take(5).toList();
        _chartData = chartData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('لوحة قيادة إيجاري',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_circle_rounded,
                color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 32),
              const Text('الأداء المالي',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildRevenueChart(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRecentBookings(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen())),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('إدراج استثمار جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أهلاً، $_ownerName',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('عضو إيجاري المُوثق 💎',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              height: 140,
              child: _buildStatCard('إجمالي الأصول', '$_totalProperties',
                  Icons.business_center_rounded, AppTheme.primaryColor),
            ),
            SizedBox(
              width: itemWidth,
              height: 140,
              child: _buildStatCard('العقود النشطة', '$_activeBookings',
                  Icons.verified_user_rounded, AppTheme.primaryLight),
            ),
            SizedBox(
              width: itemWidth,
              height: 140,
              child: _buildStatCard(
                  'العوائد الشهرية',
                  '${_monthlyRevenue.toStringAsFixed(0)} ج.م',
                  Icons.account_balance_wallet_rounded,
                  AppTheme.accentColor),
            ),
            SizedBox(
              width: itemWidth,
              height: 140,
              child: _buildStatCard('قيد الانتظار', '$_pendingRequests',
                  Icons.hourglass_top_rounded, AppTheme.errorColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
          ),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تحليل التدفق النقدي',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary)),
              Text('6 أشهر السابقة',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'يناير',
                          'فبراير',
                          'مارس',
                          'أبريل',
                          'مايو',
                          'يونيو'
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(months[value.toInt()],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData.isEmpty
                        ? const [FlSpot(0, 0)]
                        : List.generate(
                            _chartData.length,
                            (i) => FlSpot(i.toDouble(), _chartData[i]),
                          ),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الاختصارات السريعة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildActionButton(
                    'إدارة العقارات',
                    Icons.domain_rounded,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ManagePropertiesScreen())))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildActionButton(
                    'المحفظة المالية',
                    Icons.account_balance_wallet_rounded,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WalletScreen())))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildActionButton(
                    'تحصيل الإيجارات',
                    Icons.receipt_long_rounded,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const OwnerCollectionScreen())))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildActionButton(
                    'مركز الإشعارات',
                    Icons.notifications_active_rounded,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const NotificationCenterScreen())))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildActionButton(
                    'الملف الشخصي',
                    Icons.person_rounded,
                    AppTheme.primaryColor,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen())))),
            const SizedBox(width: 16),
            const Expanded(
                child: SizedBox()), // Empty space to keep layout balanced
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('أحدث المعاملات',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WalletScreen())),
                child: const Text('سجل كامل',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentBookings.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('لا توجد حجوزات حالياً',
                      style: TextStyle(color: AppTheme.primaryColor))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentBookings.length,
            itemBuilder: (context, index) =>
                _buildBookingCard(_recentBookings[index]),
          ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.maps_home_work_rounded,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['propertyTitle'] ?? 'عقار',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(booking['tenantName'] ?? 'عميل',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(booking['amount'] ?? '0 ج.م',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(booking['date'] ?? 'اليوم',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}
