import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'dart:async';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  // Real-time Statistics (Dynamic)
  final Map<String, dynamic> _stats = {
    'todayOrders': 12,
    'pendingOrders': 5,
    'completedToday': 7,
    'todayRevenue': 4250.0,
    'monthRevenue': 45800.0,
    'rating': 4.8,
    'totalReviews': 156,
    'activeOrders': 3,
    'responseTime': 15, // minutes
    'completionRate': 94, // percentage
  };

  // Orders with real-time updates
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeOrders();
    _startRealTimeUpdates();
  }

  void _initializeOrders() {
    _orders = [
      {
        'id': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        'service': 'صيانة تكييف مركزي',
        'tenant': 'أحمد محمد علي',
        'phone': '01012345678',
        'address': 'شقة 4، عمارة 12، المعادي، القاهرة',
        'date': DateTime.now(),
        'scheduledTime': '10:00 ص - 12:00 م',
        'status': 'new',
        'priority': 'high',
        'price': 450.0,
        'description': 'تكييف لا يعمل بكفاءة، يحتاج فحص وصيانة',
      },
      {
        'id': 'ORD-${DateTime.now().millisecondsSinceEpoch + 1}',
        'service': 'نظافة شاملة للشقة',
        'tenant': 'سارة علي حسن',
        'phone': '01098765432',
        'address': 'فيلا 5، الحي الثالث، التجمع الخامس',
        'date': DateTime.now().add(const Duration(hours: 2)),
        'scheduledTime': '02:00 م - 05:00 م',
        'status': 'in_progress',
        'priority': 'medium',
        'price': 800.0,
        'description': 'نظافة شاملة بعد الانتقال',
      },
      {
        'id': 'ORD-${DateTime.now().millisecondsSinceEpoch + 2}',
        'service': 'نقل عفش',
        'tenant': 'محمود خالد',
        'phone': '01123456789',
        'address': 'من المعادي إلى 6 أكتوبر',
        'date': DateTime.now().add(const Duration(days: 1)),
        'scheduledTime': '09:00 ص - 03:00 م',
        'status': 'scheduled',
        'priority': 'high',
        'price': 1500.0,
        'description': 'نقل عفش شقة 3 غرف',
      },
    ];
  }

  void _startRealTimeUpdates() {
    // Simulate real-time updates every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // Simulate new order occasionally
          if (DateTime.now().second % 2 == 0) {
            _stats['todayOrders'] = (_stats['todayOrders'] as int) + 1;
            _stats['pendingOrders'] = (_stats['pendingOrders'] as int) + 1;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return AppTheme.primaryColor;
      case 'in_progress':
        return AppTheme.borderColor;
      case 'scheduled':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'طلب جديد';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'scheduled':
        return 'مجدول';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('لوحة تحكم التاجر 💼'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${_stats['pendingOrders']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (c) => const LoginScreen()));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard, size: 20), text: 'الرئيسية'),
            Tab(icon: Icon(Icons.list_alt, size: 20), text: 'الطلبات'),
            Tab(icon: Icon(Icons.analytics, size: 20), text: 'الإحصائيات'),
            Tab(
                icon: Icon(Icons.account_balance_wallet, size: 20),
                text: 'المالية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildOrdersTab(),
          _buildAnalyticsTab(),
          _buildFinanceTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _stats['todayOrders'] = (_stats['todayOrders'] as int) + 1;
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            const Text('الإحصائيات اللحظية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              children: [
                _buildStatCard('طلبات اليوم', '${_stats['todayOrders']}',
                    Icons.shopping_bag, AppTheme.primaryColor),
                _buildStatCard('قيد الانتظار', '${_stats['pendingOrders']}',
                    Icons.pending_actions, AppTheme.borderColor),
                _buildStatCard('مكتمل اليوم', '${_stats['completedToday']}',
                    Icons.check_circle, AppTheme.primaryColor),
                _buildStatCard('إيرادات اليوم', '${_stats['todayRevenue']} ج.م',
                    Icons.attach_money, AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الطلبات الأخيرة',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._orders
                .take(3)
                .map((order) => _buildOrderCard(order, compact: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final newOrders = _orders.where((o) => o['status'] == 'new').toList();
    final inProgressOrders =
        _orders.where((o) => o['status'] == 'in_progress').toList();

    _orders.where((o) => o['status'] == 'scheduled').toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                  child: _buildFilterChip('الكل (${_orders.length})', true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildFilterChip('جديد (${newOrders.length})', false)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildFilterChip(
                      'تنفيذ (${inProgressOrders.length})', false)),
            ],
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 80, color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text('لا توجد طلبات حالياً',
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(_orders[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليلات الأداء',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPerformanceCard('معدل الإنجاز', '${_stats['completionRate']}%',
              Icons.trending_up, AppTheme.primaryColor),
          const SizedBox(height: 12),
          _buildPerformanceCard(
              'متوسط وقت الاستجابة',
              '${_stats['responseTime']} دقيقة',
              Icons.timer,
              AppTheme.primaryColor),
          const SizedBox(height: 12),
          _buildPerformanceCard('رضا العملاء', '${_stats['rating']}/5',
              Icons.star, AppTheme.borderColor),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 60, color: AppTheme.primaryColor),
                  SizedBox(height: 12),
                  Text('رسم بياني للإيرادات',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إجمالي الإيرادات (هذا الشهر)',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('${_stats['monthRevenue']} ج.م',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text('+18% عن الشهر الماضي',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('المعاملات الأخيرة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.store, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('شركة الفني المحترف',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    const Text('حساب موثق',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    const Icon(Icons.star,
                        color: AppTheme.borderColor, size: 16),
                    const SizedBox(width: 4),
                    Text('${_stats['rating']}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward, color: color, size: 8),
              ),
            ],
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {bool compact = false}) {
    final timeAgo = _getTimeAgo(order['date']);

    final statusColor = _getStatusColor(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    if (order['priority'] == 'high')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.priority_high,
                            color: AppTheme.errorColor, size: 16),
                      ),
                    Expanded(
                      child: Text(
                        order['service'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(order['status']),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الطلب: ${order['id']}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person_outline, order['tenant']),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone_outlined, order['phone']),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on_outlined, order['address']),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time,
                        '${order['scheduledTime']} • $timeAgo'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money, '${order['price']} ج.م',
                        color: AppTheme.primaryColor),
                    if (!compact && order['status'] == 'new') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await DataService.updateRequestStatus(
                                    order['id'], 'rejected');
                                setState(() {
                                  _orders.remove(order);
                                  _stats['pendingOrders'] =
                                      (_stats['pendingOrders'] as int) - 1;
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم رفض الطلب')));
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('رفض'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(
                                    color: AppTheme.errorColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await DataService.updateRequestStatus(
                                    order['id'], 'approved');
                                if (!mounted) return;
                                setState(() {
                                  order['status'] = 'in_progress';
                                  _stats['pendingOrders'] =
                                      (_stats['pendingOrders'] as int) - 1;
                                  _stats['activeOrders'] =
                                      (_stats['activeOrders'] as int) + 1;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم قبول الطلب ✅')));
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('قبول'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.textPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                TextStyle(fontSize: 13, color: color ?? AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.primaryColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionsList() {
    final transactions = [
      {
        'date': 'اليوم، 10:30 ص',
        'description':
            'طلب #${_orders.isNotEmpty ? _orders[0]['id'] : 'ORD-001'}',
        'amount': '+450 ج.م',
        'type': 'income'
      },
      {
        'date': 'اليوم، 09:15 ص',
        'description': 'طلب #ORD-998',
        'amount': '+800 ج.م',
        'type': 'income'
      },
      {
        'date': 'أمس، 04:20 م',
        'description': 'سحب رصيد',
        'amount': '-5000 ج.م',
        'type': 'withdrawal'
      },
      {
        'date': 'أمس، 11:00 ص',
        'description': 'طلب #ORD-995',
        'amount': '+1200 ج.م',
        'type': 'income'
      },
    ];

    return transactions.map((transaction) {
      final isIncome = transaction['type'] == 'income';
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.backgroundColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isIncome
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? AppTheme.primaryColor : AppTheme.borderColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction['description']!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(transaction['date']!,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              transaction['amount']!,
              style: TextStyle(
                color: isIncome ? AppTheme.primaryColor : AppTheme.borderColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(order['service'],
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_getStatusText(order['status']),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order['id'],
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    const Divider(height: 32),
                    const Text('معلومات العميل',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildDetailRow('الاسم', order['tenant']),
                    _buildDetailRow('الهاتف', order['phone']),
                    const SizedBox(height: 16),
                    const Text('تفاصيل الطلب',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildDetailRow('العنوان', order['address']),
                    _buildDetailRow('الموعد', order['scheduledTime']),
                    _buildDetailRow('السعر', '${order['price']} ج.م'),
                    const SizedBox(height: 16),
                    const Text('الوصف',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(order['description'],
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    const SizedBox(height: 24),
                    if (order['status'] == 'new')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await DataService.updateRequestStatus(
                                    order['id'], 'rejected');
                                setState(() {
                                  _orders.remove(order);
                                  _stats['pendingOrders'] =
                                      (_stats['pendingOrders'] as int) - 1;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('رفض الطلب'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await DataService.updateRequestStatus(
                                    order['id'], 'approved');
                                setState(() {
                                  order['status'] = 'in_progress';
                                  // In a real app, 'in_progress' might mean approved and started.
                                  // For payment flow, we might want 'approved_waiting_payment'
                                  // But let's stick to 'in_progress' as "Working on it" for Merchant view
                                  _stats['pendingOrders'] =
                                      (_stats['pendingOrders'] as int) - 1;
                                  _stats['activeOrders'] =
                                      (_stats['activeOrders'] as int) + 1;
                                });
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('تم قبول الطلب ✅')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('قبول الطلب'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإشعارات'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildNotificationItem('طلب جديد', 'لديك طلب جديد من أحمد محمد',
                  'منذ 5 دقائق', Icons.shopping_bag, AppTheme.primaryColor),
              _buildNotificationItem('تقييم جديد', 'حصلت على تقييم 5 نجوم',
                  'منذ ساعة', Icons.star, AppTheme.borderColor),
              _buildNotificationItem('دفعة جديدة', 'تم إضافة 450 ج.م لحسابك',
                  'منذ ساعتين', Icons.attach_money, AppTheme.primaryColor),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(time,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
