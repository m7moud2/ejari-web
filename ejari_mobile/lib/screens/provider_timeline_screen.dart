import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'tech_job_screen.dart';

class ProviderTimelineScreen extends StatefulWidget {
  const ProviderTimelineScreen({super.key});

  @override
  State<ProviderTimelineScreen> createState() => _ProviderTimelineScreenState();
}

class _ProviderTimelineScreenState extends State<ProviderTimelineScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final user = await AuthService.getCurrentUser();
    final techId = user?['email']?.toString() ?? 'tech@ejari.app';
    final requests = await MaintenanceService.getTechnicianRequests(techId);
    requests.sort((a, b) =>
        (b['scheduledAt'] ?? b['createdAt'])
            .toString()
            .compareTo((a['scheduledAt'] ?? a['createdAt']).toString()));

    if (mounted) {
      setState(() {
        _jobs = requests;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('جدول المهام'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _jobs.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) =>
                      _item(_jobs[index], isLast: index == _jobs.length - 1),
                ),
    );
  }

  Widget _item(Map<String, dynamic> job, {bool isLast = false}) {
    final status = MaintenanceStatus.normalize(job['status']?.toString());
    final color = switch (status) {
      MaintenanceStatus.paid || MaintenanceStatus.completed =>
        AppTheme.successColor,
      MaintenanceStatus.inProgress ||
      MaintenanceStatus.enRoute =>
        AppTheme.primaryColor,
      MaintenanceStatus.assigned => AppTheme.accentColor,
      _ => AppTheme.textSecondary,
    };
    final dateStr = job['scheduledAt'] ?? job['createdAt'];
    final date = DateTime.tryParse(dateStr?.toString() ?? '') ?? DateTime.now();
    final events = (job['timeline'] as List?) ?? [];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surfaceColor, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: EjariSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TechJobScreen(requestId: job['id']?.toString()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(job['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900)),
                      ),
                      Text(MaintenanceStatus.labelAr(status),
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE dd/MM — hh:mm a').format(date),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...events.take(3).map((e) => Text(
                          '• ${e['label'] ?? e['status']}',
                          style: const TextStyle(fontSize: 11),
                        )),
                  ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text('لا مهام مجدولة',
          style: TextStyle(color: AppTheme.textSecondary)),
    );
  }
}
