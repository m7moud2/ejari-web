import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';
import '../widgets/sla_timer_chip.dart';
import '../utils/safe_parse.dart';
import '../utils/auth_gate.dart';
import 'create_maintenance_request_screen.dart';
import 'maintenance_request_detail_screen.dart';
import 'payment_screen.dart';

class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  State<MyServiceRequestsScreen> createState() =>
      _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final email = safeStr(user?['email'], 'user@ejari.app');
    final requests = await MaintenanceService.getUserRequests(email);
    if (mounted) {
      setState(() {
        _requests = requests.reversed.toList();
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final ok = await AuthGate.requireLogin(context,
        actionLabel: 'إنشاء طلب صيانة');
    if (!ok || !mounted) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateMaintenanceRequestScreen(),
      ),
    );
    if (created == true || created == null) await _load();
  }

  Color _statusColor(String status) {
    return switch (MaintenanceStatus.normalize(status)) {
      MaintenanceStatus.submitted => AppTheme.accentColor,
      MaintenanceStatus.assigned => AppTheme.primaryLight,
      MaintenanceStatus.enRoute || MaintenanceStatus.arrived =>
        AppTheme.primaryColor,
      MaintenanceStatus.inProgress => AppTheme.primaryColor,
      MaintenanceStatus.pendingClientConfirm ||
      MaintenanceStatus.completed =>
        AppTheme.accentColor,
      MaintenanceStatus.paid => AppTheme.successColor,
      MaintenanceStatus.cancelled ||
      MaintenanceStatus.rejected ||
      MaintenanceStatus.disputed =>
        AppTheme.errorColor,
      _ => AppTheme.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'all'
        ? _requests
        : _requests
            .where((r) =>
                MaintenanceStatus.normalize(r['status']) == _selectedFilter)
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('طلبات الصيانة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب صيانة جديد',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: _filters(),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _card(filtered[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filters() {
    const options = [
      ('all', 'الكل'),
      (MaintenanceStatus.submitted, 'مُرسَل'),
      (MaintenanceStatus.inProgress, 'جاري'),
      (MaintenanceStatus.pendingClientConfirm, 'تأكيد'),
      (MaintenanceStatus.completed, 'دفع'),
      (MaintenanceStatus.paid, 'مغلق'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = options[index];
          final selected = _selectedFilter == item.$1;
          return FilterChip(
            selected: selected,
            label: Text(item.$2),
            onSelected: (_) => setState(() => _selectedFilter = item.$1),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _card(Map<String, dynamic> request) {
    final status = MaintenanceStatus.normalize(request['status']?.toString());
    final color = _statusColor(status);
    final createdAt =
        DateTime.tryParse(request['createdAt']?.toString() ?? '');
    final step = MaintenanceStatus.trackingStepIndex(status).clamp(0, 7);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceRequestDetailScreen(
              requestId: request['id'].toString(),
              initialRequest: request,
            ),
          ),
        );
        await _load();
      },
      child: EjariSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.build_circle_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(safeStr(request['title'], 'طلب صيانة'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(_categoryLabel(request['category']?.toString()),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _statusChip(status, color),
            ],
          ),
          const SizedBox(height: 8),
          SlaTimerChip(request: request),
          const SizedBox(height: 12),
          EjariStepIndicator(
            labels: const [
              'استلام',
              'تعيين',
              'طريق',
              'وصول',
              'تنفيذ',
              'تأكيد',
              'دفع',
              'إغلاق',
            ],
            activeIndex: step,
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'أُنشئ: ${DateFormat('yyyy/MM/dd hh:mm a').format(createdAt)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          _actions(request, status),
        ],
      ),
    ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        MaintenanceStatus.labelAr(status),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _actions(Map<String, dynamic> request, String status) {
    if (status == MaintenanceStatus.pendingClientConfirm) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _dispute(request),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor),
              child: const Text('نزاع'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmOnly(request),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: const Text('تأكيد'),
            ),
          ),
        ],
      );
    }
    if (status == MaintenanceStatus.completed) {
      final cost = (request['finalCost'] as num?)?.toDouble() ??
          (request['estimatedCost'] as num?)?.toDouble() ??
          0;
      return ElevatedButton.icon(
        onPressed: () => _pay(request, cost),
        icon: const Icon(Icons.payments_rounded, size: 18),
        label: Text('ادفع ${cost.toStringAsFixed(0)} ج.م'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white),
      );
    }
    if (status == MaintenanceStatus.submitted ||
        status == MaintenanceStatus.assigned) {
      return OutlinedButton(
        onPressed: () => _cancelRequest(request),
        child: const Text('إلغاء الطلب'),
      );
    }
    if (status == MaintenanceStatus.paid && request['rating'] == null) {
      return ElevatedButton.icon(
        onPressed: () => _rateService(request),
        icon: const Icon(Icons.star_rounded),
        label: const Text('تقييم الخدمة'),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaintenanceRequestDetailScreen(
                requestId: request['id'].toString(),
                initialRequest: request,
              ),
            ),
          );
          await _load();
        },
        icon: const Icon(Icons.timeline_rounded, size: 18),
        label: const Text('عرض التتبع'),
      ),
    );
  }

  String _categoryLabel(String? id) {
    for (final c in MaintenanceService.categories) {
      if (c['id'] == id) return safeStr(c['name'], 'خدمة');
    }
    return id ?? 'خدمة';
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined,
                size: 72, color: AppTheme.primaryColor.withOpacity(0.45)),
            const SizedBox(height: 14),
            const Text(
              'لا توجد طلبات صيانة بعد',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'اطلب صيانة معتمدة وتتبع الفني حتى الإغلاق',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('طلب صيانة جديد',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest(Map<String, dynamic> request) async {
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.cancelRequest(
      request['id'].toString(),
      actor: safeStr(user?['email']),
    );
    await _load();
  }

  Future<void> _confirmOnly(Map<String, dynamic> request) async {
    final user = await AuthService.getCurrentUser();
    final ok = await MaintenanceService.confirmCompletion(
      request['id'].toString(),
      safeStr(user?['email'], 'user@ejari.app'),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التأكيد — يمكنك الدفع الآن'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
    await _load();
  }

  Future<void> _pay(Map<String, dynamic> request, double cost) async {
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'service',
          itemData: {
            'id': request['id'],
            'title': request['title'],
            'price': cost,
            'finalCost': cost,
          },
          amount: cost,
        ),
      ),
    );
    if (paid == true) await _load();
  }

  Future<void> _dispute(Map<String, dynamic> request) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فتح نزاع'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'سبب النزاع'),
          maxLines: 3,
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
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.disputeCompletion(
      request['id'].toString(),
      safeStr(user?['email'], 'user@ejari.app'),
      controller.text.trim().isEmpty
          ? 'العميل لم يوافق على جودة العمل'
          : controller.text.trim(),
    );
    controller.dispose();
    await _load();
  }

  Future<void> _rateService(Map<String, dynamic> request) async {
    int rating = 5;
    final feedbackController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تقييم الخدمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = i + 1),
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: AppTheme.accentColor,
                    ),
                  );
                }),
              ),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(hintText: 'ملاحظاتك'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إرسال')),
          ],
        ),
      ),
    );
    if (submitted != true) {
      feedbackController.dispose();
      return;
    }
    await MaintenanceService.rateTechnician(
      request['id'].toString(),
      rating,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    await _load();
  }
}
