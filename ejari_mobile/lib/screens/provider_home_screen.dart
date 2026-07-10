import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'provider_jobs_screen.dart';
import 'provider_wallet_screen.dart';
import 'provider_timeline_screen.dart';
import 'service_provider_profile_screen.dart';

class ServiceProviderHomeScreen extends StatefulWidget {
  const ServiceProviderHomeScreen({super.key});

  @override
  State<ServiceProviderHomeScreen> createState() =>
      _ServiceProviderHomeScreenState();
}

class _ServiceProviderHomeScreenState extends State<ServiceProviderHomeScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _activeJob;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    final stats = await DataService.getProviderStats(user?['email'] ?? '');
    final activeJob =
        await DataService.getActiveProviderJob(user?['email'] ?? '');
    setState(() {
      _userData = user;
      _stats = stats;
      _activeJob = activeJob;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Premium Header
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF163C2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك، ${_userData?['name']?.split(' ')[0] ?? 'فني إيجاري'} 👋',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'لوحة تحكم الخدمات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            // Quick Stats Row
                            Row(
                              children: [
                                _buildHeaderStat(
                                    'الأرباح',
                                    '${_stats?['earnings'].toStringAsFixed(0)} ج.م',
                                    Icons.account_balance_wallet),
                                const SizedBox(width: 24),
                                _buildHeaderStat('التقييم',
                                    '${_stats?['rating']}', Icons.star),
                                const SizedBox(width: 24),
                                _buildHeaderStat(
                                    'المهام',
                                    '${_stats?['completedCount']}',
                                    Icons.check_circle),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Jobs Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المهام النشطة',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProviderJobsScreen())),
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActiveJobsPreview(),

                        const SizedBox(height: 32),
                        const Text('الأدوات السريعة',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 110,
                          ),
                          children: [
                            _buildToolCard(
                                'طلبات جديدة',
                                Icons.add_task_rounded,
                                AppTheme.primaryColor,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ProviderJobsScreen()))),
                            _buildToolCard(
                                'المحفظة',
                                Icons.account_balance_wallet_rounded,
                                AppTheme.primaryColor,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ProviderWalletScreen()))),
                            _buildToolCard(
                                'الجدول الزمني',
                                Icons.calendar_today_rounded,
                                AppTheme.borderColor, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ProviderTimelineScreen()));
                            }),
                            _buildToolCard(
                                'الملف المهني',
                                Icons.verified_user_rounded,
                                AppTheme.primaryColor, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ServiceProviderProfileScreen()));
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveJobsPreview() {
    if (_activeJob == null) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: const Center(
          child: Text('لا توجد مهام نشطة حالياً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final isPending = _activeJob!['status'] == 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: (isPending
                            ? AppTheme.borderColor
                            : AppTheme.primaryColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    isPending
                        ? Icons.new_releases_rounded
                        : Icons.engineering_rounded,
                    color: isPending
                        ? AppTheme.borderColor
                        : AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_activeJob!['service'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                        '${_activeJob!['address']} - ${_activeJob!['customer']}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderJobsScreen()));
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              backgroundColor:
                  isPending ? AppTheme.borderColor : AppTheme.primaryColor,
            ),
            child: Text(isPending
                ? 'عرض تفاصيل الطلب الجديد'
                : 'متابعة المهمة الحالية'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
