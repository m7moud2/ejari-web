import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ejari_section.dart';
import '../../widgets/home/home_ui_kit.dart';
import '../../services/auth_service.dart';
import '../../services/maintenance_service.dart';
import '../notification_center_screen.dart';
import '../provider_jobs_screen.dart';
import '../provider_timeline_screen.dart';
import '../provider_wallet_screen.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isActiveJob(Map<String, dynamic> j) {
    final s = MaintenanceStatus.normalize(j['status']?.toString());
    return s == MaintenanceStatus.inProgress ||
        s == MaintenanceStatus.enRoute ||
        s == MaintenanceStatus.arrived ||
        s == MaintenanceStatus.pendingClientConfirm ||
        (s == MaintenanceStatus.assigned && j['techAccepted'] == true);
  }

  bool _isNewJob(Map<String, dynamic> j) {
    return MaintenanceStatus.normalize(j['status']?.toString()) ==
            MaintenanceStatus.assigned &&
        j['techAccepted'] != true;
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.getCurrentUser();
      final techId = user?['email']?.toString() ?? 'tech@ejari.app';
      await MaintenanceService.initDemoRequests();
      await MaintenanceService.ensureTechnicianHomeDemo();
      final stats = await MaintenanceService.getTechnicianStats(techId);
      final all = await MaintenanceService.getTechnicianRequests(techId);
      final active = all.where(_isActiveJob).toList();
      final fresh = all.where(_isNewJob).toList();

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _activeJobs = active;
        _newJobs = fresh;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null && _activeJobs.isEmpty && _newJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.primaryColor, size: 40),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل لوحة الفني',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          HomeCompactHeader(
            greeting: 'لوحة الفني',
            subtitle: 'مهامك اليوم والمحفظة',
            badgeLabel: 'فني معتمد',
            onNotificationTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Column(
              children: [
                HomeQuickLookRow(tiles: [
                  HomeQuickLookTile(
                    label: 'مهام اليوم',
                    value: '${_stats['activeJobs'] ?? _activeJobs.length}',
                    hint: '${_stats['newRequests'] ?? _newJobs.length} جديد',
                    icon: Icons.engineering_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  HomeQuickLookTile(
                    label: 'أرباح اليوم',
                    value: '${_stats['todayEarnings'] ?? 0}',
                    hint: 'ج.م',
                    icon: Icons.payments_rounded,
                    color: AppTheme.accentColor,
                  ),
                  HomeQuickLookTile(
                    label: 'المحفظة',
                    value: '${_stats['availableBalance'] ?? 0}',
                    hint: 'ج.م',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2D6A5A),
                  ),
                  HomeQuickLookTile(
                    label: 'التقييم',
                    value: '${_stats['rating'] ?? 0}',
                    icon: Icons.star_rounded,
                    color: Colors.orange,
                  ),
                ]),
                const SizedBox(height: 10),
                HomePrimaryActionRow(actions: [
                  HomePrimaryAction(
                    label: 'المهام',
                    icon: Icons.build_circle_rounded,
                    color: AppTheme.primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProviderJobsScreen(),
                      ),
                    ).then((_) => _load()),
                  ),
                  HomePrimaryAction(
                    label: 'الجدول',
                    icon: Icons.timeline_rounded,
                    color: AppTheme.accentColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProviderTimelineScreen(),
                      ),
                    ),
                  ),
                  HomePrimaryAction(
                    label: 'المحفظة',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF2D6A5A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProviderWalletScreen(),
                      ),
                    ).then((_) => _load()),
                  ),
                  HomePrimaryAction(
                    label: 'المزيد',
                    icon: Icons.apps_rounded,
                    color: AppTheme.primaryLight,
                    onTap: () => showHomeMoreSheet(
                      context,
                      title: 'المزيد',
                      items: [
                        (
                          label: 'منجز: ${_stats['completedJobs'] ?? 0}',
                          icon: Icons.task_alt_rounded,
                          onTap: () {},
                        ),
                        (
                          label:
                              'أرباح الشهر: ${_stats['monthlyEarnings'] ?? 0} ج.م',
                          icon: Icons.calendar_month_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
          if ((_stats['urgentRequests'] ?? 0) > 0) ...[
            const SizedBox(height: 4),
            _urgentBanner(),
          ],
          const SizedBox(height: 12),
          EjariSectionHeader(
            title: 'الطلبات الجارية',
            actionLabel: 'الكل',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderJobsScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(height: 8),
          if (_activeJobs.isEmpty)
            const EjariSurfaceCard(
              elevated: false,
              child: Text(
                'لا مهام جارية',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            )
          else
            ..._activeJobs.map(_jobTile),
          const SizedBox(height: 12),
          EjariSectionHeader(
            title: 'طلبات جديدة',
            actionLabel: 'الجدول',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProviderTimelineScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_newJobs.isEmpty)
            const EjariSurfaceCard(
              elevated: false,
              child: Text(
                'لا طلبات جديدة',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            )
          else
            ..._newJobs.map(_jobTile),
        ],
      ),
    );
  }

  Widget _urgentBanner() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderJobsScreen()),
      ).then((_) => _load()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
        ),
        child: Text(
          '⚠️ ${_stats['urgentRequests']} طلب عاجل',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }

  Widget _jobTile(Map<String, dynamic> job) {
    final status = MaintenanceStatus.normalize(job['status']?.toString());
    final title = (job['title'] ?? job['service'] ?? 'مهمة صيانة').toString();
    final place = (job['propertyTitle'] ??
            job['propertyId'] ??
            job['address'] ??
            'موقع')
        .toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EjariSurfaceCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TechJobScreen(requestId: job['id']?.toString()),
              ),
            ).then((_) => _load()),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.build_circle_rounded,
                        color: AppTheme.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$place • ${MaintenanceStatus.labelAr(status)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left,
                      color: AppTheme.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
