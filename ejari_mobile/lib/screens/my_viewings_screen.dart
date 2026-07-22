import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/viewing_appointment.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/live_sync_service.dart';
import '../services/viewing_appointment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/viewing_widgets.dart';
import '../widgets/empty_state_view.dart';
import 'properties_screen.dart';

/// مواعيد المعاينة للمستأجر.
class MyViewingsScreen extends StatefulWidget {
  const MyViewingsScreen({super.key});

  @override
  State<MyViewingsScreen> createState() => _MyViewingsScreenState();
}

class _MyViewingsScreenState extends State<MyViewingsScreen> {
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
    try {
      final user = await AuthService.getCurrentUser();
      final hint = user?['email']?.toString().trim().isNotEmpty == true
          ? user!['email'].toString()
          : (user?['uid']?.toString() ?? user?['id']?.toString() ?? '');
      final items = hint.isEmpty
          ? <ViewingAppointment>[]
          : await ViewingAppointmentService.getForTenant(hint);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is String ? e : 'تعذر تحميل مواعيد المعاينة',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _cancel(ViewingAppointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء المعاينة؟'),
        content: const Text('هل تريد إلغاء موعد المعاينة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ViewingAppointmentService.updateStatus(
      id: a.id,
      newStatus: ViewingStatus.cancelled,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? 'تم إلغاء الموعد'
            : result['message']?.toString() ?? 'فشل الإلغاء'),
      ),
    );
    _load();
  }

  Future<void> _confirmAttendance(ViewingAppointment a) async {
    final result = await ViewingAppointmentService.updateStatus(
      id: a.id,
      newStatus: ViewingStatus.completed,
      tenantConfirmAttendance: true,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] == true
            ? 'تم تأكيد حضورك — اكتملت المعاينة'
            : result['message']?.toString() ?? 'تعذر التأكيد'),
        backgroundColor: result['success'] == true
            ? AppTheme.primaryColor
            : AppTheme.errorColor,
      ),
    );
    _load();
  }

  Future<void> _book(ViewingAppointment a) async {
    Map<String, dynamic>? property;
    try {
      final all = await DataService.getAllProperties();
      for (final p in all) {
        if (p['id']?.toString() == a.propertyId) {
          property = p;
          break;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    await proceedToBookingFromViewing(context, a, property);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مواعيدي للمعاينة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 48),
                        EmptyStateView(
                          icon: Icons.event_available_outlined,
                          title: 'لا توجد مواعيد معاينة بعد',
                          subtitle:
                              'اطلب معاينة من صفحة العقار وسيظهر الموعد هنا مع إمكانية الإلغاء.',
                          actionLabel: 'استكشف العقارات',
                          actionIcon: Icons.search_rounded,
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PropertiesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = _items[i];
                        final status = ViewingStatus.normalize(a.status);
                        final actions = <Widget>[];
                        if (status == ViewingStatus.requested ||
                            status == ViewingStatus.confirmed) {
                          actions.add(
                            OutlinedButton(
                              onPressed: () => _cancel(a),
                              child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                            ),
                          );
                        }
                        if (status == ViewingStatus.confirmed) {
                          actions.add(
                            ElevatedButton(
                              onPressed: () => _confirmAttendance(a),
                              child: const Text('أكدت الحضور',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          );
                        }
                        if (status == ViewingStatus.completed ||
                            status == ViewingStatus.confirmed) {
                          actions.add(
                            ElevatedButton.icon(
                              onPressed: () => _book(a),
                              icon: const Icon(Icons.key_rounded, size: 16),
                              label: const Text('احجز الآن',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          );
                        }
                        return ViewingAppointmentCard(
                          appointment: a,
                          showTenant: false,
                          actions: actions,
                        );
                      },
                    ),
            ),
    );
  }
}
