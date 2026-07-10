import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MyServiceRequestsScreen extends StatefulWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  State<MyServiceRequestsScreen> createState() =>
      _MyServiceRequestsScreenState();
}

class _MyServiceRequestsScreenState extends State<MyServiceRequestsScreen> {
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'SR001',
      'service': 'تنظيف شامل',
      'provider': 'شركة النظافة المثالية',
      'date': '2026-07-05',
      'time': '10:00 ص',
      'status': 'pending',
      'price': '300',
      'address': 'شقة 12، المعادي',
      'notes': 'تنظيف شامل بعد الانتقال'
    },
    {
      'id': 'SR002',
      'service': 'صيانة تكييف',
      'provider': 'مركز الصيانة السريع',
      'date': '2026-07-03',
      'time': '02:00 م',
      'status': 'in_progress',
      'price': '150',
      'address': 'فيلا 5، الشيخ زايد',
      'notes': 'صيانة دورية'
    },
    {
      'id': 'SR003',
      'service': 'نقل أثاث',
      'provider': 'شركة النقل الآمن',
      'date': '2026-07-01',
      'time': '09:00 ص',
      'status': 'completed',
      'price': '500',
      'address': 'من المعادي إلى مدينة نصر',
      'notes': 'نقل أثاث غرفة نوم',
      'rating': 5
    },
  ];

  String _selectedFilter = 'all';

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
      body: Column(
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
                    itemBuilder: (context, index) => _card(filtered[index]),
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
                    Text(request['service'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(request['provider'],
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
          _row(Icons.location_on_outlined, request['address']),
          _row(Icons.calendar_today_outlined,
              '${request['date']} - ${request['time']}'),
          _row(Icons.attach_money_rounded, '${request['price']} ج.م'),
          if (request['notes'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(18)),
              child: Text(request['notes'],
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
              child:
                  OutlinedButton(onPressed: () {}, child: const Text('إلغاء'))),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
                  onPressed: () {}, child: const Text('تتبع الطلب'))),
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
          onPressed: () {},
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

  void _trackService(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الفني في الطريق إليك.')),
    );
  }
}
