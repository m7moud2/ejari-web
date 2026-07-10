import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import 'ejari_section.dart';
import '../screens/corporate_command_center_screen.dart';

/// ملخص سريع لحجوزات الموظفين — يوجّه إلى مركز قيادة الشركات.
class CorporateBookingsStrip extends StatefulWidget {
  const CorporateBookingsStrip({super.key});

  @override
  State<CorporateBookingsStrip> createState() => _CorporateBookingsStripState();
}

class _CorporateBookingsStripState extends State<CorporateBookingsStrip> {
  List<Map<String, dynamic>> _corporateBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DataService.getBookings();
    setState(() {
      _corporateBookings = all
          .where((b) =>
              b['bookingMode'] == 'corporate' ||
              (b['employeeName'] != null && b['employeeName'].toString().isNotEmpty))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: EjariSectionHeader(
                  title: 'إسكان الموظفين (شركات)',
                  subtitle: 'متابعة من مركز قيادة الشركات — ليس ضمن حجز العقار الشخصي',
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CorporateCommandCenterScreen(),
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.corporate_fare_rounded, size: 16),
                label: const Text('مركز القيادة', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (_corporateBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد حجوزات موظفين بعد. افتح مركز قيادة الشركات لإضافة حجز.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ..._corporateBookings.take(5).map(_employeeRow),
        ],
      ),
      ),
    );
  }

  Widget _employeeRow(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    final (label, color) = switch (status) {
      'corporate_pending' || 'pending' => ('بانتظار', AppTheme.borderColor),
      'paid' || 'active' || 'confirmed' => ('مؤكد', AppTheme.primaryColor),
      'deposit_refunded' || 'cancelled' => ('ملغي', AppTheme.errorColor),
      _ => ('قيد المراجعة', AppTheme.accentColor),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              (b['employeeName'] ?? '?').toString().substring(0, 1),
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['employeeName'] ?? 'موظف',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  '${b['governorate'] ?? ''} — ${b['title'] ?? ''}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
