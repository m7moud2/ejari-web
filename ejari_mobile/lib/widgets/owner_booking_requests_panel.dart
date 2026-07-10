import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/ejari_section.dart';
import '../widgets/tenant_score_card.dart';

/// طلبات الحجز الواردة للمالك — قبول/رفض مع سبب ودرجة المستأجر.
class OwnerBookingRequestsPanel extends StatefulWidget {
  const OwnerBookingRequestsPanel({super.key});

  @override
  State<OwnerBookingRequestsPanel> createState() =>
      _OwnerBookingRequestsPanelState();
}

class _OwnerBookingRequestsPanelState extends State<OwnerBookingRequestsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ??
        user?['uid']?.toString() ??
        user?['id']?.toString() ??
        'owner@ejari.app';
    final requests = await DataService.getOwnerRequests(ownerId);
    setState(() {
      _requests = requests
          .where((r) =>
              r['status'] == 'viewing_scheduled' ||
              r['status'] == 'deposit_paid' ||
              r['status'] == 'pending' ||
              r['status'] == 'submitted' ||
              r['status'] == 'corporate_pending')
          .toList();
      _loading = false;
    });
  }

  Future<void> _handle(String id, String status, {String? reason}) async {
    await DataService.updateRequestStatus(id, status, note: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == 'approved'
            ? 'تم قبول الطلب ✅'
            : 'تم رفض الطلب${reason != null ? ': $reason' : ''}'),
        backgroundColor:
            status == 'approved' ? AppTheme.primaryColor : AppTheme.errorColor,
      ),
    );
    _load();
  }

  Future<void> _rejectWithReason(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'مثال: السعر غير مناسب، الوحدة محجوزة...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      await _handle(id, 'rejected', reason: reason);
    } else if (reason != null && reason.isEmpty) {
      await _handle(id, 'rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ));
    }

    if (_requests.isEmpty) {
      return const EjariSurfaceCard(
        elevated: false,
        child: Text(
          'لا توجد طلبات حجز جديدة حالياً.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _requests.take(5).map((r) {
        final id = (r['id'] ?? r['_id'] ?? '').toString();
        final prePaid = DataService.isPreEntryPaid(r);
        final bedInfo = r['bedLabel']?.toString() ??
            r['roomLabel']?.toString() ??
            r['unitLabel']?.toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
          child: EjariSurfaceCard(
            elevated: false,
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r['tenantName'] ??
                            r['tenantTypeLabel'] ??
                            r['employeeName'] ??
                            'مستأجر',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: prePaid
                            ? const Color(0xFF2D6A5A).withOpacity(0.12)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prePaid ? 'مدفوع مسبقاً ✓' : 'لم يُدفع',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: prePaid
                              ? const Color(0xFF2D6A5A)
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r['title'] ?? 'عقار',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (bedInfo != null)
                  Text('الوحدة: $bedInfo',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  '${r['durationLabel'] ?? r['duration'] ?? ''} — عربون ${r['depositAmount'] ?? ''} ج.م',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                if (r['tenantEmail'] != null) ...[
                  const SizedBox(height: 8),
                  TenantScoreCard(
                    scoreData: {
                      'tenantEmail': r['tenantEmail']?.toString() ?? '',
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectWithReason(id),
                        child: const Text('رفض', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handle(id, 'approved'),
                        child: const Text('قبول', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
