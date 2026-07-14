import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';
import '../utils/safe_parse.dart';
import '../widgets/sla_timer_chip.dart';
import 'payment_screen.dart';

/// شاشة تتبع طلب صيانة للمستأجر — خط زمني كامل + تأكيد ودفع.
class MaintenanceRequestDetailScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic>? initialRequest;

  const MaintenanceRequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  State<MaintenanceRequestDetailScreen> createState() =>
      _MaintenanceRequestDetailScreenState();
}

class _MaintenanceRequestDetailScreenState
    extends State<MaintenanceRequestDetailScreen> {
  Map<String, dynamic>? _request;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    _load();
  }

  Future<void> _load() async {
    final req = await MaintenanceService.getRequest(widget.requestId);
    if (!mounted) return;
    setState(() {
      _request = req;
      _loading = false;
    });
  }

  String get _status =>
      MaintenanceStatus.normalize(_request?['status']?.toString());

  Color get _statusColor => switch (_status) {
        MaintenanceStatus.submitted => AppTheme.accentColor,
        MaintenanceStatus.assigned => AppTheme.primaryLight,
        MaintenanceStatus.enRoute || MaintenanceStatus.arrived =>
          AppTheme.primaryColor,
        MaintenanceStatus.inProgress => AppTheme.primaryColor,
        MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
        MaintenanceStatus.completed => AppTheme.accentColor,
        MaintenanceStatus.paid => AppTheme.successColor,
        MaintenanceStatus.cancelled ||
        MaintenanceStatus.rejected ||
        MaintenanceStatus.disputed =>
          AppTheme.errorColor,
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading && _request == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final req = _request;
    if (req == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تتبع الصيانة')),
        body: const Center(child: Text('الطلب غير موجود')),
      );
    }

    final cost = (req['finalCost'] as num?)?.toDouble() ??
        (req['estimatedCost'] as num?)?.toDouble() ??
        0.0;
    final step = MaintenanceStatus.trackingStepIndex(_status);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('تتبع طلب الصيانة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          EjariSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        safeStr(req['title'], 'طلب صيانة'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        MaintenanceStatus.labelAr(_status),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (safeStr(req['propertyTitle']).isNotEmpty)
                  Text(
                    '🏠 ${safeStr(req['propertyTitle'])}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                if (safeStr(req['description']).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(safeStr(req['description']),
                      style: const TextStyle(height: 1.45)),
                ],
                const SizedBox(height: 10),
                SlaTimerChip(request: req),
                if (cost > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'التكلفة: ${cost.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EjariSectionHeader(title: 'مراحل الخدمة'),
          const SizedBox(height: 10),
          EjariSurfaceCard(
            child: _TrackingTimeline(activeIndex: step, status: _status),
          ),
          const SizedBox(height: 16),
          if ((_request!['timeline'] as List?)?.isNotEmpty == true) ...[
            const EjariSectionHeader(title: 'سجل الأحداث'),
            const SizedBox(height: 10),
            EjariSurfaceCard(child: _eventsList(req)),
            const SizedBox(height: 16),
          ],
          _actions(req, cost),
        ],
      ),
    );
  }

  Widget _eventsList(Map<String, dynamic> req) {
    final events = List<Map<String, dynamic>>.from(
      ((req['timeline'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)),
    );
    events.sort((a, b) {
      final ta = DateTime.tryParse(a['at']?.toString() ?? '') ?? DateTime(0);
      final tb = DateTime.tryParse(b['at']?.toString() ?? '') ?? DateTime(0);
      return tb.compareTo(ta);
    });

    return Column(
      children: events.map((e) {
        final at = DateTime.tryParse(e['at']?.toString() ?? '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 8, color: AppTheme.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeStr(e['label'] ?? e['status'], 'تحديث'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (safeStr(e['note']).isNotEmpty)
                      Text(safeStr(e['note']),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              if (at != null)
                Text(
                  DateFormat('MM/dd HH:mm').format(at),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _actions(Map<String, dynamic> req, double cost) {
    if (_status == MaintenanceStatus.pendingClientConfirm) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أنهى الفني العمل — أكّد الإتمام أو افتح نزاعاً',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : () => _confirm(req),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('تأكيد إتمام الخدمة',
                    style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _dispute(req),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor),
            child: const Text('فتح نزاع'),
          ),
        ],
      );
    }

    if (_status == MaintenanceStatus.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تم التأكيد — ادفع ${cost.toStringAsFixed(0)} ج.م من المحفظة',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _pay(req, cost),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: const Text('ادفع الآن',
                style: TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      );
    }

    if ((_status == MaintenanceStatus.paid) && req['rating'] == null) {
      return ElevatedButton.icon(
        onPressed: () => _rate(req),
        icon: const Icon(Icons.star_rounded),
        label: const Text('تقييم الخدمة'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor),
      );
    }

    if (_status == MaintenanceStatus.submitted ||
        _status == MaintenanceStatus.assigned) {
      return OutlinedButton(
        onPressed: _busy ? null : () => _cancel(req),
        child: const Text('إلغاء الطلب'),
      );
    }

    if (_status == MaintenanceStatus.paid) {
      return const EjariSurfaceCard(
        elevated: false,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 10),
            Expanded(
              child: Text('تم إغلاق الطلب بعد الدفع',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successColor)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirm(Map<String, dynamic> req) async {
    setState(() => _busy = true);
    final user = await AuthService.getCurrentUser();
    final ok = await MaintenanceService.confirmCompletion(
      req['id'].toString(),
      safeStr(user?['email'], 'user@ejari.app'),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التأكيد — يمكنك الدفع الآن'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      await _load();
    }
  }

  Future<void> _pay(Map<String, dynamic> req, double cost) async {
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'service',
          itemData: {
            'id': req['id'],
            'title': req['title'],
            'price': cost,
            'finalCost': cost,
          },
          amount: cost,
        ),
      ),
    );
    if (paid == true) await _load();
  }

  Future<void> _dispute(Map<String, dynamic> req) async {
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
    setState(() => _busy = true);
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.disputeCompletion(
      req['id'].toString(),
      safeStr(user?['email'], 'user@ejari.app'),
      controller.text.trim().isEmpty
          ? 'العميل لم يوافق على جودة العمل'
          : controller.text.trim(),
    );
    controller.dispose();
    if (mounted) {
      setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _cancel(Map<String, dynamic> req) async {
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.cancelRequest(
      req['id'].toString(),
      actor: safeStr(user?['email']),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _rate(Map<String, dynamic> req) async {
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
      req['id'].toString(),
      rating,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    await _load();
  }
}

class _TrackingTimeline extends StatelessWidget {
  final int activeIndex;
  final String status;

  const _TrackingTimeline({required this.activeIndex, required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = MaintenanceStatus.trackingStepsAr;
    final terminal = [
      MaintenanceStatus.cancelled,
      MaintenanceStatus.rejected,
      MaintenanceStatus.disputed,
    ].contains(MaintenanceStatus.normalize(status));

    return Column(
      children: List.generate(steps.length, (i) {
        final done = !terminal && i < activeIndex;
        final current = !terminal && i == activeIndex;
        final color = done || current
            ? (current ? AppTheme.accentColor : AppTheme.primaryColor)
            : AppTheme.borderColor;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done || current ? color : AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: current
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: done
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.borderColor,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  steps[i],
                  style: TextStyle(
                    fontWeight:
                        current ? FontWeight.w900 : FontWeight.w600,
                    color: done || current
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
