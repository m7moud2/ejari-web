import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../../services/auth_service.dart';
import '../../services/maintenance_service.dart';
import '../notification_center_screen.dart';
import '../provider_jobs_screen.dart';
import '../provider_timeline_screen.dart';
import '../tech_job_screen.dart';

class TechnicianHomeView extends StatefulWidget {
  const TechnicianHomeView({super.key});

  @override
  State<TechnicianHomeView> createState() => _TechnicianHomeViewState();
}

class _TechnicianHomeViewState extends State<TechnicianHomeView> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _activeJobs = [];
  List<Map<String, dynamic>> _newJobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final techId = user?['email']?.toString() ?? 'tech@ejari.app';
    final stats = await MaintenanceService.getTechnicianStats(techId);
    final all = await MaintenanceService.getTechnicianRequests(techId);
    final active = all
        .where((j) {
          final s = MaintenanceStatus.normalize(j['status']);
          return s == MaintenanceStatus.inProgress ||
              s == MaintenanceStatus.enRoute ||
              (s == MaintenanceStatus.assigned && j['techAccepted'] == true);
        })
        .toList();
    final fresh = all
        .where((j) =>
            MaintenanceStatus.normalize(j['status']) ==
                MaintenanceStatus.assigned &&
            j['techAccepted'] != true)
        .toList();

    if (mounted) {
      setState(() {
        _stats = stats;
        _activeJobs = active;
        _newJobs = fresh;
        _loading = false;
      });
    }
    if (mounted) {
      context.read<HomeProvider>().loadHomeData('technician');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _hero(),
          const SizedBox(height: 14),
          _statsGrid(),
          if ((_stats['urgentRequests'] ?? 0) > 0) ...[
            const SizedBox(height: 14),
            _urgentBanner(),
          ],
          const SizedBox(height: 14),
          EjariSectionHeader(
            title: 'الطلبات الجارية',
            actionLabel: 'الكل',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderJobsScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(height: 10),
          if (_activeJobs.isEmpty)
            const Text('لا مهام جارية',
                style: TextStyle(color: AppTheme.textSecondary))
          else
            ..._activeJobs.map(_jobTile),
          const SizedBox(height: 14),
          EjariSectionHeader(
            title: 'طلبات جديدة',
            actionLabel: 'الجدول',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProviderTimelineScreen()),
            ),
          ),
          const SizedBox(height: 10),
          if (_newJobs.isEmpty)
            const Text('لا طلبات جديدة',
                style: TextStyle(color: AppTheme.textSecondary))
          else
            ..._newJobs.map(_jobTile),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentColor,
                child: Icon(Icons.handyman_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('لوحة الفني',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen()),
                ),
                icon: const Icon(Icons.notifications_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _heroMetric('جديد', '${_stats['newRequests'] ?? 0}'),
              const SizedBox(width: 8),
              _heroMetric('اليوم', '${_stats['todayEarnings'] ?? 0} ج.م'),
              const SizedBox(width: 8),
              _heroMetric('التقييم', '${_stats['rating'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      children: [
        EjariStatTile(
          icon: Icons.payments_rounded,
          label: 'أرباح الشهر',
          value: '${_stats['monthlyEarnings'] ?? 0} ج.م',
          accentColor: AppTheme.accentColor,
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.task_alt_rounded,
          label: 'منجز',
          value: '${_stats['completedJobs'] ?? 0}',
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.engineering_rounded,
          label: 'نشط',
          value: '${_stats['activeJobs'] ?? 0}',
          accentColor: AppTheme.primaryLight,
          compact: true,
        ),
        EjariStatTile(
          icon: Icons.account_balance_wallet_rounded,
          label: 'الرصيد',
          value: '${_stats['availableBalance'] ?? 0} ج.م',
          accentColor: AppTheme.primaryColor,
          compact: true,
        ),
      ],
    );
  }

  Widget _urgentBanner() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderJobsScreen()),
      ).then((_) => _load()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
        ),
        child: Text(
          '⚠️ ${_stats['urgentRequests']} طلب عاجل يحتاج تدخلك',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _jobTile(Map<String, dynamic> job) {
    final status = MaintenanceStatus.normalize(job['status']?.toString());
    return EjariSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechJobScreen(requestId: job['id']?.toString()),
          ),
        ).then((_) => _load()),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.build_circle_rounded,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(
                    '${job['propertyTitle'] ?? job['propertyId']} • ${MaintenanceStatus.labelAr(status)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
