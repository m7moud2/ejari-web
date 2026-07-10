import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';
import '../utils/safe_parse.dart';
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
    final email = user?['email']?.toString() ?? 'user@ejari.app';
    final requests = await MaintenanceService.getUserRequests(email);
    if (mounted) {
      setState(() {
        _requests = requests.reversed.toList();
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    return switch (MaintenanceStatus.normalize(status)) {
      MaintenanceStatus.submitted => AppTheme.accentColor,
      MaintenanceStatus.assigned => AppTheme.primaryLight,
      MaintenanceStatus.enRoute => AppTheme.primaryColor,
      MaintenanceStatus.inProgress => AppTheme.primaryColor,
      MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
      MaintenanceStatus.completed || MaintenanceStatus.paid =>
        AppTheme.successColor,
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
        title: const Text('تتبع طلبات الصيانة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
      (MaintenanceStatus.paid, 'مدفوع'),
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

    return EjariSurfaceCard(
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
                    Text(request['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(_categoryLabel(request['category']),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _statusChip(status, color),
            ],
          ),
          const SizedBox(height: 12),
          EjariStepIndicator(
            labels: const [
              'إرسال',
              'تعيين',
              'تنفيذ',
              'تأكيد',
              'دفع',
            ],
            activeIndex: MaintenanceStatus.stepIndex(status).clamp(0, 4),
          ),
          const SizedBox(height: 12),
          _timeline(request),
          if (createdAt != null)
            Text(
              'أُنشئ: ${DateFormat('yyyy/MM/dd hh:mm a').format(createdAt)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          const SizedBox(height: 12),
          _actions(request, status),
        ],
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

  Widget _timeline(Map<String, dynamic> request) {
    final events = (request['timeline'] as List?) ?? [];
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الجدول الزمني',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 8),
        ...events.take(5).map((e) {
          final at = DateTime.tryParse(e['at']?.toString() ?? '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${e['label'] ?? e['status']}${e['note']?.toString().isNotEmpty == true ? ' — ${e['note']}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (at != null)
                  Text(DateFormat('MM/dd HH:mm').format(at),
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _actions(Map<String, dynamic> request, String status) {
    if (status == MaintenanceStatus.pendingClientConfirm) {
      final cost = (request['finalCost'] as num?)?.toDouble() ??
          (request['estimatedCost'] as num?)?.toDouble() ??
          0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('التكلفة النهائية: $cost ج.م',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
          const SizedBox(height: 10),
          Row(
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
                  onPressed: () => _confirmAndPay(request, cost),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                  child: const Text('تأكيد ودفع'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (status == MaintenanceStatus.submitted ||
        status == MaintenanceStatus.assigned) {
      return OutlinedButton(
        onPressed: () => _cancelRequest(request),
        child: const Text('إلغاء الطلب'),
      );
    }
    if ((status == MaintenanceStatus.paid ||
            status == MaintenanceStatus.completed) &&
        request['rating'] == null) {
      return ElevatedButton.icon(
        onPressed: () => _rateService(request),
        icon: const Icon(Icons.star_rounded),
        label: const Text('تقييم الخدمة'),
      );
    }
    return const SizedBox.shrink();
  }

  String _categoryLabel(String? id) {
    for (final c in MaintenanceService.categories) {
      if (c['id'] == id) return safeStr(c['name'], 'خدمة');
    }
    return id ?? 'خدمة';
  }

  Widget _empty() {
    return const Center(child: Text('لا توجد طلبات صيانة'));
  }

  Future<void> _cancelRequest(Map<String, dynamic> request) async {
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.cancelRequest(
      request['id'].toString(),
      actor: user?['email']?.toString(),
    );
    await _load();
  }

  Future<void> _confirmAndPay(Map<String, dynamic> request, double cost) async {
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
      user?['email']?.toString() ?? '',
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
    await MaintenanceService.addFeedback(
      request['id'].toString(),
      rating,
      feedbackController.text.trim(),
    );
    feedbackController.dispose();
    await _load();
  }
}
