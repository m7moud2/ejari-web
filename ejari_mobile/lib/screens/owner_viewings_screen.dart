import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/viewing_appointment.dart';
import '../services/auth_service.dart';
import '../services/live_sync_service.dart';
import '../services/viewing_appointment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../widgets/viewing_widgets.dart';

/// لوحة طلبات المعاينة للمالك — موافقة / رفض / إعادة جدولة / اكتمال.
class OwnerViewingsPanel extends StatefulWidget {
  final bool embedded;
  final int maxItems;

  const OwnerViewingsPanel({
    super.key,
    this.embedded = true,
    this.maxItems = 8,
  });

  @override
  State<OwnerViewingsPanel> createState() => _OwnerViewingsPanelState();
}

class _OwnerViewingsPanelState extends State<OwnerViewingsPanel> {
  List<ViewingAppointment> _items = [];
  bool _loading = true;
  LiveSyncService? _liveSync;
  int _lastGen = 0;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _liveSync = context.read<LiveSyncService>();
      _liveSync?.addListener(_onSync);
    });
  }

  @override
  void dispose() {
    _liveSync?.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    final gen = _liveSync?.syncGeneration ?? 0;
    if (gen == _lastGen) return;
    _lastGen = gen;
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? 'owner@ejari.app';
    final all = await ViewingAppointmentService.getForOwner(email);
    final pending = all
        .where((a) =>
            a.status == ViewingStatus.requested ||
            a.status == ViewingStatus.confirmed ||
            a.status == ViewingStatus.rescheduled)
        .toList();
    if (!mounted) return;
    setState(() {
      _items = pending;
      _loading = false;
    });
  }

  Future<void> _act(
    ViewingAppointment a,
    String status, {
    DateTime? rescheduleAt,
    String? note,
    bool markComplete = false,
  }) async {
    final result = await ViewingAppointmentService.updateStatus(
      id: a.id,
      newStatus: status,
      rescheduleAt: rescheduleAt,
      ownerNote: note,
      ownerMarkComplete: markComplete,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? 'تم التحديث ✅'
            : result['message']?.toString() ?? 'فشل التحديث'),
        backgroundColor: result['success'] == true
            ? AppTheme.primaryColor
            : AppTheme.errorColor,
      ),
    );
    _load();
  }

  Future<void> _reject(ViewingAppointment a) async {
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض المعاينة'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'سبب الرفض (اختياري)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await _act(a, ViewingStatus.rejected, note: note.isEmpty ? null : note);
  }

  Future<void> _reschedule(ViewingAppointment a) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: a.scheduledAt.isAfter(now)
          ? a.scheduledAt
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('ar'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(a.scheduledAt),
    );
    if (time == null || !mounted) return;
    final slot = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _act(a, ViewingStatus.rescheduled, rescheduleAt: slot);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_items.isEmpty) {
      return EjariSurfaceCard(
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'لا توجد طلبات معاينة حالياً.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (widget.maxItems <= 8) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerViewingsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('فتح صفحة المعاينات',
                      style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final shown = _items.take(widget.maxItems).toList();
    return ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: shown.map((a) {
        final status = ViewingStatus.normalize(a.status);
        final actions = <Widget>[];
        if (status == ViewingStatus.requested) {
          actions.addAll([
            OutlinedButton(
              onPressed: () => _reject(a),
              child: const Text('رفض', style: TextStyle(fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () => _reschedule(a),
              child: const Text('إعادة جدولة', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => _act(a, ViewingStatus.confirmed),
              child: const Text('موافقة', style: TextStyle(fontSize: 12)),
            ),
          ]);
        } else if (status == ViewingStatus.confirmed) {
          actions.addAll([
            OutlinedButton(
              onPressed: () => _act(a, ViewingStatus.noShow),
              child: const Text('لم يحضر', style: TextStyle(fontSize: 12)),
            ),
            OutlinedButton(
              onPressed: () => _reschedule(a),
              child: const Text('إعادة جدولة', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => _act(
                a,
                ViewingStatus.completed,
                markComplete: true,
              ),
              child: const Text('اكتملت', style: TextStyle(fontSize: 12)),
            ),
          ]);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
          child: ViewingAppointmentCard(
            appointment: a,
            showTenant: true,
            actions: actions,
          ),
        );
      }).toList(),
    );
  }
}

/// شاشة كاملة لطلبات المعاينة للمالك.
class OwnerViewingsScreen extends StatelessWidget {
  const OwnerViewingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('طلبات المعاينة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: OwnerViewingsPanel(embedded: true, maxItems: 50),
      ),
    );
  }
}
