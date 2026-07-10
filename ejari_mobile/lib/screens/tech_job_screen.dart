import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import 'provider_wallet_screen.dart';

class TechJobScreen extends StatefulWidget {
  final String? requestId;

  const TechJobScreen({super.key, this.requestId});

  @override
  State<TechJobScreen> createState() => _TechJobScreenState();
}

class _TechJobScreenState extends State<TechJobScreen> {
  Map<String, dynamic>? _job;
  bool _loading = true;
  String _techId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    _techId = user?['email']?.toString() ?? 'tech@ejari.app';
    if (widget.requestId != null) {
      _job = await MaintenanceService.getRequest(widget.requestId!);
    } else {
      final jobs = await MaintenanceService.getTechnicianRequests(_techId);
      _job = jobs.isNotEmpty ? jobs.first : null;
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _status =>
      MaintenanceStatus.normalize(_job?['status']?.toString());

  Color get _statusColor => switch (_status) {
        MaintenanceStatus.assigned => AppTheme.accentColor,
        MaintenanceStatus.enRoute => AppTheme.primaryLight,
        MaintenanceStatus.inProgress => AppTheme.primaryColor,
        MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
        MaintenanceStatus.paid => AppTheme.successColor,
        MaintenanceStatus.disputed => AppTheme.errorColor,
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المهمة')),
        body: const Center(child: Text('لا توجد مهمة')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('مهمة ${_job!['id']}'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: _statusColor,
              child: Text(
                MaintenanceStatus.labelAr(_status),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EjariSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_job!['title'] ?? '',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        _row('العقار', _job!['propertyTitle'] ?? _job!['propertyId']),
                        _row('العميل', _job!['tenantId'] ?? ''),
                        _row('الوصف', _job!['description'] ?? ''),
                        const Divider(height: 24),
                        _row('تقديري', '${_job!['estimatedCost']} ج.م'),
                        if ((_job!['finalCost'] as num?) != null &&
                            (_job!['finalCost'] as num) > 0)
                          _row('نهائي', '${_job!['finalCost']} ج.م'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  EjariStepIndicator(
                    labels: const [
                      'تعيين',
                      'طريق',
                      'تنفيذ',
                      'تأكيد',
                      'دفع',
                    ],
                    activeIndex:
                        MaintenanceStatus.stepIndex(_status).clamp(0, 4),
                  ),
                  const SizedBox(height: 20),
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final id = _job!['id']?.toString() ?? '';

    if (_status == MaintenanceStatus.assigned) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await MaintenanceService.markEnRoute(id, _techId);
                await _load();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor),
              child: const Text('في الطريق للعميل'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await MaintenanceService.startJob(id, _techId);
                await _load();
              },
              child: const Text('بدء المهمة'),
            ),
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.enRoute) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await MaintenanceService.startJob(id, _techId);
            await _load();
          },
          child: const Text('بدء العمل الميداني'),
        ),
      );
    }

    if (_status == MaintenanceStatus.inProgress) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم إرفاق صور قبل/بعد — تجريبي')),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('إرفاق صور'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _complete(id),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor),
              child: const Text('إنهاء وطلب تأكيد العميل'),
            ),
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.pendingClientConfirm) {
      return EjariSurfaceCard(
        elevated: false,
        child: Column(
          children: [
            Icon(Icons.hourglass_top,
                color: AppTheme.accentColor.withOpacity(0.8), size: 40),
            const SizedBox(height: 10),
            const Text('بانتظار تأكيد العميل والدفع',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    if (_status == MaintenanceStatus.paid) {
      return Column(
        children: [
          const Icon(Icons.check_circle,
              color: AppTheme.successColor, size: 48),
          const SizedBox(height: 10),
          const Text('تم الدفع — أُضيف لمحفظتك',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.successColor)),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProviderWalletScreen()),
            ),
            child: const Text('عرض المحفظة'),
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.disputed) {
      return EjariSurfaceCard(
        elevated: false,
        child: Text(
          'نزاع مفتوح: ${_job!['disputeReason'] ?? 'قيد مراجعة الإدارة'}',
          style: const TextStyle(
              color: AppTheme.errorColor, fontWeight: FontWeight.w700),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _complete(String id) async {
    final controller = TextEditingController(
      text: (_job!['estimatedCost'] ?? 150).toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التكلفة النهائية'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال')),
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
    await _load();
  }
}
