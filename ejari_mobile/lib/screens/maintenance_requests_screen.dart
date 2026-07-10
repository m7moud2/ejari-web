import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import 'create_maintenance_request_screen.dart';
import 'my_service_requests_screen.dart';
import '../utils/auth_gate.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() =>
      _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filter = 'all';
  bool _isOwner = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final role = await AuthService.getUserRole();
    if (role == 'tenant' && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyServiceRequestsScreen()),
      );
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _userEmail = user['email']?.toString() ?? '';
    final role = await AuthService.getUserRole();
    _isOwner = role == 'owner';

    final requests = _isOwner
        ? await MaintenanceService.getOwnerRequests(_userEmail)
        : await MaintenanceService.getUserRequests(_userEmail);

    setState(() {
      _requests = requests.reversed.toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _requests;
    return _requests
        .where((r) =>
            MaintenanceStatus.normalize(r['status']) == _filter)
        .toList();
  }

  Color _chipColor(String status) {
    return switch (MaintenanceStatus.normalize(status)) {
      MaintenanceStatus.submitted => AppTheme.accentColor,
      MaintenanceStatus.assigned || MaintenanceStatus.enRoute =>
        AppTheme.primaryLight,
      MaintenanceStatus.inProgress => AppTheme.primaryColor,
      MaintenanceStatus.pendingClientConfirm => AppTheme.accentColor,
      MaintenanceStatus.paid || MaintenanceStatus.completed =>
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(_isOwner ? 'صيانة عقاراتي' : 'طلبات الصيانة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: _isOwner
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final ok = await AuthGate.requireLogin(context,
                    actionLabel: 'إنشاء طلب صيانة');
                if (!ok || !mounted) return;
                await navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMaintenanceRequestScreen(),
                  ),
                );
                _load();
              },
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد'),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _filters(),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filters() {
    const opts = [
      ('all', 'الكل'),
      (MaintenanceStatus.submitted, 'مُرسَل'),
      (MaintenanceStatus.inProgress, 'تنفيذ'),
      (MaintenanceStatus.pendingClientConfirm, 'تأكيد'),
      (MaintenanceStatus.paid, 'مدفوع'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = opts[i];
          final sel = _filter == o.$1;
          return FilterChip(
            selected: sel,
            label: Text(o.$2),
            onSelected: (_) => setState(() => _filter = o.$1),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: sel ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _card(Map<String, dynamic> req) {
    final status = MaintenanceStatus.normalize(req['status']?.toString());
    final color = _chipColor(status);
    final created =
        DateTime.tryParse(req['createdAt']?.toString() ?? '');

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(req['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
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
          if (req['propertyTitle']?.toString().isNotEmpty == true)
            Text('🏠 ${req['propertyTitle']}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          if (created != null)
            Text(
              DateFormat('yyyy/MM/dd').format(created),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          if ((req['estimatedCost'] as num?) != null &&
              (req['estimatedCost'] as num) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'تقدير: ${req['estimatedCost']} ج.م',
                style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800),
              ),
            ),
          if (_isOwner && status == MaintenanceStatus.submitted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _approveBudget(req),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor),
                child: const Text('الموافقة على الميزانية'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approveBudget(Map<String, dynamic> req) async {
    final cap = (req['estimatedCost'] as num?)?.toDouble() ?? 500;
    await MaintenanceService.approveBudget(
      req['id'].toString(),
      ownerId: _userEmail,
      budgetCap: cap,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الموافقة — بانتظار تعيين الفني'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
    _load();
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined,
              size: 72, color: AppTheme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            _isOwner ? 'لا طلبات صيانة على عقاراتك' : 'لا طلبات صيانة بعد',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
