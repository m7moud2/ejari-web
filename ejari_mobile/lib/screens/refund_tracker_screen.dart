import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';

class RefundTrackerScreen extends StatefulWidget {
  const RefundTrackerScreen({super.key});

  @override
  State<RefundTrackerScreen> createState() => _RefundTrackerScreenState();
}

class _RefundTrackerScreenState extends State<RefundTrackerScreen> {
  List<Map<String, dynamic>> _trackers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['email']?.toString() ?? 'user@ejari.app';
    final trackers = await DataService.getRefundTrackers(userId);
    if (mounted) {
      setState(() {
        _trackers = trackers;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة الاسترداد')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trackers.isEmpty
              ? const Center(
                  child: Text('لا توجد طلبات استرداد حالياً',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trackers.length,
                  itemBuilder: (context, index) {
                    final t = _trackers[index];
                    final steps = List<Map<String, dynamic>>.from(
                      t['timeline'] as List? ?? [],
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['title']?.toString() ?? 'استرداد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              '${t['amount']?.toString() ?? '0'} ج.م — ${t['statusLabel'] ?? ''}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            ...steps.map((step) {
                              final done = step['done'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      done
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: done
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        step['label']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: done
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: done
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
