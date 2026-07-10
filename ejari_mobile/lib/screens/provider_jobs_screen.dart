import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../utils/safe_parse.dart';
import 'tech_job_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _techId = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = await AuthService.getCurrentUser();
    _techId = user?['email']?.toString() ?? 'tech@ejari.app';
    final raw = await MaintenanceService.getTechnicianRequests(_techId);
    setState(() {
      _jobs = raw;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'all') return _jobs;
    return _jobs
        .where((j) =>
            MaintenanceStatus.normalize(j['status']) == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مهام الصيانة'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadJobs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('الكل', 'all'),
                  _chip('جديد', MaintenanceStatus.assigned),
                  _chip('تنفيذ', MaintenanceStatus.inProgress),
                  _chip('تأكيد', MaintenanceStatus.pendingClientConfirm),
                  _chip('مكتمل', MaintenanceStatus.paid),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : _filtered.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _jobCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: sel,
        label: Text(label),
        onSelected: (_) => setState(() => _selectedFilter = value),
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: sel ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final status = MaintenanceStatus.normalize(job['status']?.toString());
    final color = switch (status) {
      MaintenanceStatus.assigned => AppTheme.accentColor,
      MaintenanceStatus.enRoute || MaintenanceStatus.inProgress =>
        AppTheme.primaryColor,
      MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
      MaintenanceStatus.paid => AppTheme.successColor,
      _ => AppTheme.textSecondary,
    };

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(MaintenanceStatus.labelAr(status),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _info(Icons.person_outline, safeStr(job['tenantId'])),
          _info(
              Icons.location_on_outlined,
              safeStr(
                job['propertyTitle']?.toString().isNotEmpty == true
                    ? job['propertyTitle']
                    : job['propertyId'],
                'موقع غير محدد',
              )),
          _info(Icons.payments_outlined,
              '${job['estimatedCost'] ?? 0} ج.م تقديري'),
          if (safeStr(job['description']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(safeStr(job['description']),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
          const SizedBox(height: 14),
          _actions(job, status),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _actions(Map<String, dynamic> job, String status) {
    final id = job['id']?.toString() ?? '';

    if (status == MaintenanceStatus.assigned && job['techAccepted'] != true) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _reject(id),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor),
              child: const Text('رفض'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await MaintenanceService.acceptJob(id, _techId);
                await _loadJobs();
              },
              child: const Text('قبول'),
            ),
          ),
        ],
      );
    }

    if (status == MaintenanceStatus.assigned ||
        status == MaintenanceStatus.enRoute ||
        status == MaintenanceStatus.inProgress ||
        status == MaintenanceStatus.pendingClientConfirm) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status == MaintenanceStatus.assigned && job['techAccepted'] == true)
            ElevatedButton(
              onPressed: () async {
                await MaintenanceService.markEnRoute(id, _techId);
                await _loadJobs();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor),
              child: const Text('في الطريق'),
            ),
          if (status == MaintenanceStatus.enRoute)
            ElevatedButton(
              onPressed: () async {
                await MaintenanceService.startJob(id, _techId);
                await _loadJobs();
              },
              child: const Text('بدء العمل'),
            ),
          if (status == MaintenanceStatus.inProgress)
            ElevatedButton(
              onPressed: () => _complete(id, job),
              child: const Text('إنهاء وطلب تأكيد'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TechJobScreen(requestId: id),
              ),
            ).then((_) => _loadJobs()),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('تفاصيل المهمة'),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: () async {
        final lat = job['lat'];
        final lng = job['lng'];
        if (lat != null && lng != null) {
          final uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      icon: const Icon(Icons.map_outlined, size: 16),
      label: const Text('الخريطة'),
    );
  }

  Future<void> _reject(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('سبب الرفض'),
          content: TextField(
              controller: c, decoration: const InputDecoration(hintText: 'السبب')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تراجع')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: const Text('رفض')),
          ],
        );
      },
    );
    if (reason == null) return;
    await MaintenanceService.rejectJob(
        id, _techId, reason.isEmpty ? 'غير متاح' : reason);
    await _loadJobs();
  }

  Future<void> _complete(String id, Map<String, dynamic> job) async {
    final controller = TextEditingController(
      text: (job['estimatedCost'] ?? 150).toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التكلفة النهائية'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'ج.م'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال للعميل')),
        ],
      ),
    );
    if (ok != true) {
      controller.dispose();
      return;
    }
    final cost = double.tryParse(controller.text) ?? 150;
    controller.dispose();
    await MaintenanceService.completeJob(id, _techId, cost);
    await _loadJobs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('بانتظار تأكيد العميل للدفع'),
            backgroundColor: AppTheme.primaryColor),
      );
    }
  }

  Widget _empty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handyman_outlined,
              size: 72, color: AppTheme.primaryColor),
          SizedBox(height: 12),
          Text('لا توجد مهام حالياً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
