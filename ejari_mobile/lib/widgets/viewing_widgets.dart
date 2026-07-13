import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/viewing_appointment.dart';
import '../services/viewing_appointment_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../widgets/ejari_section.dart';
import '../screens/booking_screen.dart';
import '../screens/my_viewings_screen.dart';

/// حوار طلب معاينة من صفحة تفاصيل العقار (إيجار فقط).
class RequestViewingSheet extends StatefulWidget {
  final Map<String, dynamic> property;

  const RequestViewingSheet({super.key, required this.property});

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> property,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestViewingSheet(property: property),
    );
  }

  @override
  State<RequestViewingSheet> createState() => _RequestViewingSheetState();
}

class _RequestViewingSheetState extends State<RequestViewingSheet> {
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime? get _combined {
    if (_date == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time.hour,
      _time.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final slot = _combined;
    if (slot == null) {
      setState(() => _error = 'اختر التاريخ والوقت');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ViewingAppointmentService.requestViewing(
      property: widget.property,
      scheduledAt: slot,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب المعاينة للمالك ✅'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } else {
      setState(() => _error = result['message']?.toString() ?? 'تعذر الإرسال');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.property['title']?.toString() ?? 'العقار';
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'طلب معاينة العقار',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(
                    _date == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy/MM/dd').format(_date!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: Text(_time.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'ملاحظة اختيارية للمالك...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'إرسال طلب المعاينة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyViewingsScreen()),
              );
            },
            child: const Text('عرض مواعيدي'),
          ),
        ],
      ),
    );
  }
}

/// بطاقة معاينة مشتركة للمستأجر/المالك/الإدارة.
class ViewingAppointmentCard extends StatelessWidget {
  final ViewingAppointment appointment;
  final List<Widget> actions;
  final bool showTenant;
  final bool showOwner;

  const ViewingAppointmentCard({
    super.key,
    required this.appointment,
    this.actions = const [],
    this.showTenant = true,
    this.showOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    return EjariSurfaceCard(
      elevated: false,
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment.propertyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'الموعد: ${DateParsing.displayArabic(appointment.scheduledAt, withTime: true)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (showTenant)
            Text(
              'المستأجر: ${appointment.tenantName}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          if (showOwner)
            Text(
              'المالك: ${appointment.ownerEmail}',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          if (appointment.note != null && appointment.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                appointment.note!,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (ViewingStatus.normalize(status)) {
      case ViewingStatus.confirmed:
        return AppTheme.primaryColor;
      case ViewingStatus.completed:
        return AppTheme.accentColor;
      case ViewingStatus.rejected:
      case ViewingStatus.cancelled:
      case ViewingStatus.noShow:
        return AppTheme.errorColor;
      default:
        return const Color(0xFFB58D3D);
    }
  }
}

/// اختصار للانتقال للحجز بعد المعاينة.
Future<void> proceedToBookingFromViewing(
  BuildContext context,
  ViewingAppointment appointment,
  Map<String, dynamic>? property,
) async {
  final allowed = await AuthGate.requireLogin(
    context,
    actionLabel: 'الحجز بعد المعاينة',
  );
  if (!allowed || !context.mounted) return;
  final data = property ??
      {
        'id': appointment.propertyId,
        'title': appointment.propertyTitle,
        'image': appointment.propertyImage,
        'ownerEmail': appointment.ownerEmail,
        'ownerId': appointment.ownerEmail,
      };
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookingScreen(itemType: 'property', itemData: data),
    ),
  );
}
