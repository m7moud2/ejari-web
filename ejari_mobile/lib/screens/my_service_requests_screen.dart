import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';

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
        _requests = requests;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'all'
        ? _requests
        : _requests.where((r) => r['status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('طلبات الصيانة والخدمات'),
        titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
      ('pending', 'قيد الانتظار'),
      ('in_progress', 'جاري التنفيذ'),
      ('completed', 'مكتمل'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = options[index];
          final selected = _selectedFilter == item.$1;
          return ChoiceChip(
            selected: selected,
            label: Text(item.$2),
            onSelected: (_) => setState(() => _selectedFilter = item.$1),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800),
            backgroundColor: AppTheme.surfaceColor,
          );
        },
      ),
    );
  }

  String _categoryLabel(String? id) {
    for (final c in MaintenanceService.categories) {
      if (c['id'] == id) return c['name'] as String;
    }
    return id ?? 'خدمة';
  }

  Widget _card(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final (text, color) = switch (status) {
      'pending' => ('قيد الانتظار', AppTheme.borderColor),
      'accepted' => ('مقبول', AppTheme.primaryColor),
      'in_progress' => ('جاري التنفيذ', Colors.blue),
      'completed' => ('مكتمل', AppTheme.primaryColor),
      'cancelled' => ('ملغي', AppTheme.errorColor),
      _ => ('غير معروف', AppTheme.textSecondary),
    };
    final createdAt = DateTime.tryParse(request['createdAt']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.build_circle_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request['title'] ?? _categoryLabel(request['category']),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_categoryLabel(request['category']),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (createdAt != null)
            _row(Icons.calendar_today_outlined,
                DateFormat('yyyy/MM/dd - hh:mm a').format(createdAt)),
          if (request['estimatedCost'] != null &&
              (request['estimatedCost'] as num) > 0)
            _row(Icons.attach_money_rounded,
                '${request['estimatedCost']} ج.م'),
          if (request['description'] != null &&
              request['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(18)),
              child: Text(request['description'],
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.5)),
            ),
          ],
          const SizedBox(height: 12),
          _actions(request),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _actions(Map<String, dynamic> request) {
    final status = request['status'];
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelRequest(request),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _trackService(request),
              child: const Text('تتبع الطلب'),
            ),
          ),
        ],
      );
    }
    if (status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _trackService(request),
          icon: const Icon(Icons.location_searching),
          label: const Text('تتبع الخدمة'),
        ),
      );
    }
    if (status == 'completed' && request['rating'] == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _rateService(request),
          icon: const Icon(Icons.star_rounded),
          label: const Text('تقييم الخدمة'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _empty() {
    return const Center(
      child: Text('لا توجد طلبات'),
    );
  }

  Future<void> _cancelRequest(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء طلب الصيانة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await MaintenanceService.updateStatus(
      request['id'].toString(),
      'cancelled',
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إلغاء طلب الصيانة')),
    );
  }

  void _trackService(Map<String, dynamic> request) {
    final status = request['status'];
    final message = status == 'pending'
        ? 'طلبك قيد المراجعة وسيتم تعيين فني قريباً.'
        : 'الفني في الطريق إليك.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  hintText: 'ملاحظاتك (اختياري)',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) {
      feedbackController.dispose();
      return;
    }

    final feedback = feedbackController.text.trim();
    feedbackController.dispose();

    await MaintenanceService.addFeedback(
      request['id'].toString(),
      rating,
      feedback,
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('شكراً! تم إرسال تقييمك')),
    );
  }
}
