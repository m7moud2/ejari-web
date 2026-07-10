import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reviews = await DataService.getAllModeratedReviews();
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _reviews;
    return _reviews.where((r) => r['moderationStatus'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('مراجعة التقييمات (${_reviews.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _chip('الكل', 'all'),
                      _chip('معلّق', 'pending'),
                      _chip('معتمد', 'approved'),
                      _chip('مخفي', 'hidden'),
                      _chip('مُبلّغ', 'flagged'),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text('لا توجد تقييمات',
                              style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildReviewCard(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final status = review['moderationStatus']?.toString() ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review['propertyTitle']?.toString() ?? 'عقار',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.borderColor,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review['userName']?.toString() ?? 'مستخدم',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              review['comment']?.toString() ?? 'بدون تعليق',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (review['adminResponse'] != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'رد الإدارة: ${review['adminResponse']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionBtn('اعتماد', Icons.check_rounded, AppTheme.primaryColor,
                    () => _moderate(review['id'].toString(), 'approved')),
                _actionBtn('إخفاء', Icons.visibility_off_rounded,
                    AppTheme.textSecondary,
                    () => _moderate(review['id'].toString(), 'hidden')),
                _actionBtn('تبليغ', Icons.flag_rounded, AppTheme.errorColor,
                    () => _moderate(review['id'].toString(), 'flagged')),
                _actionBtn('رد', Icons.reply_rounded, AppTheme.accentColor,
                    () => _respond(review)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'الحالة: ${_statusLabel(status)}',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor.withOpacity(0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'hidden':
        return 'مخفي';
      case 'flagged':
        return 'مُبلّغ';
      default:
        return 'معلّق';
    }
  }

  Future<void> _moderate(String id, String status) async {
    await DataService.moderateReview(id, status);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث الحالة إلى ${_statusLabel(status)}')),
    );
  }

  Future<void> _respond(Map<String, dynamic> review) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رد الإدارة على التقييم'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب ردك...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final admin = await AuthService.getCurrentUser();
      await DataService.respondToReview(
        review['id'].toString(),
        result,
        adminEmail: admin?['email']?.toString(),
      );
      _load();
    }
    controller.dispose();
  }
}
