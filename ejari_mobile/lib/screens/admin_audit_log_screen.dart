import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/activity_log_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await ActivityLogService.getAllLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _logs;
    return _logs.where((l) => l['category'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل نشاط المستخدمين'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('all', 'الكل'),
                _chip('auth', 'دخول'),
                _chip('payment', 'دفع'),
                _chip('admin', 'إدارة'),
                _chip('booking', 'حجز'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('لا يوجد سجل بعد'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final log = _filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.history,
                                  color: AppTheme.primaryColor, size: 18),
                            ),
                            title: Text(log['action']?.toString() ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: Text(
                              '${log['userId'] ?? ''}\n${log['detail'] ?? ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              (log['date']?.toString() ?? '').split('T').first,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
      ),
    );
  }
}
