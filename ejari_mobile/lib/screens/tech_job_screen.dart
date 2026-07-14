import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../utils/safe_parse.dart';
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
  bool _busy = false;
  String _techId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    _techId = safeStr(user?['email'], 'tech@ejari.app');
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
        MaintenanceStatus.arrived => AppTheme.primaryColor,
        MaintenanceStatus.inProgress => AppTheme.primaryColor,
        MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
        MaintenanceStatus.completed => AppTheme.accentColor,
        MaintenanceStatus.paid => AppTheme.successColor,
        MaintenanceStatus.disputed => AppTheme.errorColor,
        _ => AppTheme.textSecondary,
      };

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    await action();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

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

    final step = MaintenanceStatus.stepIndex(_status).clamp(0, 7);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('مهمة ${safeStr(_job!['id'])}'),
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
                        Text(safeStr(_job!['title'], 'مهمة صيانة'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        _row('العقار',
                            safeStr(_job!['propertyTitle'] ?? _job!['propertyId'])),
                        _row('العميل', safeStr(_job!['tenantId'])),
                        _row('الوصف', safeStr(_job!['description'])),
                        const Divider(height: 24),
                        _row('تقديري', '${_job!['estimatedCost'] ?? 0} ج.م'),
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
                      'وصول',
                      'تنفيذ',
                      'تأكيد',
                      'دفع',
                      'إغلاق',
                      '✓',
                    ],
                    activeIndex: step,
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

  Widget _primaryBtn(String label, VoidCallback onPressed, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildActions() {
    final id = safeStr(_job!['id']);
    final accepted = _job!['techAccepted'] == true;

    if (_status == MaintenanceStatus.assigned && !accepted) {
      return Column(
        children: [
          _primaryBtn('قبول المهمة', () => _run(() async {
                return MaintenanceService.acceptJob(id, _techId);
              })),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    await MaintenanceService.rejectJob(
                        id, _techId, 'غير متاح حالياً');
                    await _load();
                  },
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor),
            child: const Text('رفض'),
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.assigned && accepted) {
      return _primaryBtn(
        'في الطريق للعميل',
        () => _run(() => MaintenanceService.markEnRoute(id, _techId)),
        color: AppTheme.accentColor,
      );
    }

    if (_status == MaintenanceStatus.enRoute) {
      return _primaryBtn(
        'وصلت إلى موقع العميل',
        () => _run(() => MaintenanceService.markArrived(id, _techId)),
        color: AppTheme.accentColor,
      );
    }

    if (_status == MaintenanceStatus.arrived) {
      return _primaryBtn(
        'بدء العمل الميداني',
        () => _run(() => MaintenanceService.startJob(id, _techId)),
      );
    }

    if (_status == MaintenanceStatus.inProgress) {
      return Column(
        children: [
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await MaintenanceService.attachDemoPhotos(id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرفاق صور قبل/بعد')),
                    );
                    await _load();
                  },
            icon: const Icon(Icons.camera_alt),
            label: const Text('إرفاق صور'),
          ),
          const SizedBox(height: 12),
          _primaryBtn(
            'إنهاء وطلب تأكيد العميل',
            () => _complete(id),
            color: AppTheme.accentColor,
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.pendingClientConfirm ||
        _status == MaintenanceStatus.completed) {
      return EjariSurfaceCard(
        elevated: false,
        child: Column(
          children: [
            Icon(Icons.hourglass_top,
                color: AppTheme.accentColor.withOpacity(0.8), size: 40),
            const SizedBox(height: 10),
            Text(
              _status == MaintenanceStatus.completed
                  ? 'بانتظار دفع العميل'
                  : 'بانتظار تأكيد العميل',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
          'نزاع مفتوح: ${safeStr(_job!['disputeReason'], 'قيد مراجعة الإدارة')}',
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
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الخدمة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'التكلفة النهائية',
                suffixText: 'ج.م',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة الإتمام (اختياري)',
              ),
              maxLines: 2,
            ),
          ],
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
      noteController.dispose();
      return;
    }
    final cost = double.tryParse(controller.text) ?? 150;
    controller.dispose();
    noteController.dispose();
    setState(() => _busy = true);
    await MaintenanceService.completeJob(id, _techId, cost);
    await _load();
    if (mounted) setState(() => _busy = false);
  }
}
