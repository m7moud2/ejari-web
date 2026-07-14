import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/auth_gate.dart';
import '../utils/safe_parse.dart';
import '../utils/rental_schedule_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/ejari_section.dart';

class OwnerCollectionScreen extends StatefulWidget {
  const OwnerCollectionScreen({super.key});

  @override
  State<OwnerCollectionScreen> createState() => _OwnerCollectionScreenState();
}

class _OwnerCollectionScreenState extends State<OwnerCollectionScreen> {
  bool _loading = true;
  double expectedThisMonth = 0;
  double collectedThisMonth = 0;
  double lateAmount = 0;
  List<Map<String, dynamic>> _tenants = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Tab shell already role-gates owner screens; only gate pushed routes.
      final embedded =
          context.findAncestorWidgetOfExactType<IndexedStack>() != null;
      if (!embedded) {
        final allowed = await AuthGate.requireRole(
          context,
          allowedRoles: const ['owner'],
          deniedMessage: 'صفحة التحصيل متاحة للمالك فقط.',
        );
        if (!allowed) return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ??
        user?['uid']?.toString() ??
        'owner@ejari.app';
    final requests = await DataService.getOwnerRequests(ownerId);
    final occupancyTenants = await DataService.getOccupancyTenants(ownerId);
    final active = requests
        .where((r) =>
            r['status'] == 'approved' ||
            r['status'] == 'paid' ||
            r['status'] == 'deposit_paid' ||
            r['status'] == 'completed')
        .toList();

    final tenants = <Map<String, dynamic>>[];
    double expected = 0;
    double collected = 0;
    double late = 0;

    for (final t in occupancyTenants) {
      final rent = (t['monthlyRent'] as num?)?.toDouble() ?? 2500;
      expected += rent;
      final status = t['paymentStatus']?.toString() ?? '';
      final isLate = status == 'overdue' || status == 'living_without_pay';
      if (status == 'paid') {
        collected += rent;
      } else if (isLate) {
        late += rent;
      }
      tenants.add({
        'name': t['name'] ?? 'مستأجر',
        'email': t['email'] ?? '',
        'property': t['bedLabel'] ?? 'سرير',
        'status': isLate ? 'متأخر' : 'مدفوع',
        'lateAmount': isLate ? rent : 0.0,
        'preEntryLabel': t['preEntryPaid'] == true
            ? 'مدفوع قبل الدخول ✓'
            : 'لم يُحصّل',
        'nextDueDate': DateTime.tryParse(t['leaseEnd']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 15)),
        'lastPayment': DateTime.tryParse(
                t['lastPaymentDate']?.toString() ?? '') ??
            DateTime.now().subtract(const Duration(days: 10)),
        'rent': rent,
        'id': t['id'],
        'isRedFlag': status == 'living_without_pay',
      });
    }

    for (final r in active) {
      final rent = double.tryParse(
              (r['monthlyRent'] ?? r['price'] ?? '0')
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      expected += rent;
      final paidMonths =
          int.tryParse((r['paidMonths'] ?? '0').toString()) ?? 0;
      final collectedPart = rent * paidMonths;
      collected += collectedPart > 0 ? collectedPart : rent * 0.2;
      final snapshot = RentalScheduleUtils.buildLeaseSnapshot(r);
      final nextDue = snapshot['nextDueDate'] as DateTime? ??
          DateParsing.bookingCheckIn(r) ??
          DateTime.now().add(const Duration(days: 15));
      final isLate = nextDue.isBefore(DateTime.now()) &&
          (r['status'] == 'deposit_paid' || paidMonths == 0);
      if (isLate) late += rent * 0.8;

      tenants.add({
        'name': r['tenantName'] ?? r['employeeName'] ?? 'مستأجر',
        'email': r['tenantEmail'] ?? r['tenantId'] ?? 'user@ejari.app',
        'property': r['title'] ?? 'عقار',
        'status': isLate ? 'متأخر' : (paidMonths > 0 ? 'مدفوع' : 'قريب'),
        'lateAmount': isLate ? rent * 0.8 : 0.0,
        'nextDueDate': nextDue,
        'lastPayment': DateParsing.parse(r['paidAt'] ?? r['depositPaidAt']) ??
            DateTime.now().subtract(const Duration(days: 10)),
        'rent': rent,
      });
    }

    if (tenants.isEmpty) {
      tenants.addAll([
        {
          'name': 'لا يوجد مستأجرون بعد',
          'property': 'أضف عقاراً واقبل حجزاً لبدء التحصيل',
          'status': 'قريب',
          'lateAmount': 0.0,
          'nextDueDate': DateTime.now().add(const Duration(days: 30)),
          'lastPayment': DateTime.now(),
          'rent': 0.0,
        },
      ]);
    }

    setState(() {
      _tenants = tenants;
      expectedThisMonth = expected;
      collectedThisMonth = collected;
      lateAmount = late;
      _loading = false;
    });
  }

  Future<void> _exportSummary() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final summary = await DataService.exportCollectionSummary(ownerId);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملخص التحصيل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إيراد الشهر: ${summary['monthlyRevenue']} ج.م'),
            Text('متأخرات: ${summary['overdueCount']} مستأجر'),
            Text('إجمالي المتأخر: ${summary['overdueTotal']} ج.م'),
            Text('عدد المستأجرين: ${summary['tenantCount']}'),
            const SizedBox(height: 8),
            Text(
              'تاريخ: ${summary['generatedAt']?.toString().substring(0, 10) ?? ''}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Future<void> _batchRemindOverdue() async {
    final user = await AuthService.getCurrentUser();
    final ownerEmail = user?['email']?.toString() ?? 'owner@ejari.app';
    final sent = await DataService.batchSendPaymentReminders(
      ownerEmail,
      _tenants,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent > 0
              ? 'تم إرسال $sent تذكير للمتأخرين'
              : 'لا يوجد مستأجرون متأخرون',
        ),
      ),
    );
  }

  int get _overdueCount =>
      _tenants.where((t) => t['status']?.toString() == 'متأخر').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('تحصيل الإيجارات'),
        titleTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'تصدير الملخص',
            onPressed: _exportSummary,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _summary(),
          const SizedBox(height: 14),
          _overview(),
          const SizedBox(height: 14),
          const EjariSectionHeader(
            title: 'حالة المستأجرين',
            subtitle: 'متأخرات مميزة — تذكير ودفع مسبق',
          ),
          if (_overdueCount > 0) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _batchRemindOverdue,
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: Text('تذكير جميع المتأخرين ($_overdueCount)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ..._tenants.map(_tenantCard),
        ],
              ),
            ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجمالي المتوقع تحصيله هذا الشهر',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${expectedThisMonth.toStringAsFixed(0)} ج.م',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _smallMetric('المحصّل',
                      '${collectedThisMonth.toStringAsFixed(0)} ج.م')),
              const SizedBox(width: 10),
              Expanded(
                  child: _smallMetric(
                      'المتأخرات', '${lateAmount.toStringAsFixed(0)} ج.م')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _overview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الشفافية المالية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
              'كل مستأجر يظهر لك حالته بوضوح: مدفوع، قريب الاستحقاق، متأخر، مع سجل دفع وإيصال لكل عملية.',
              style: TextStyle(height: 1.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _tenantCard(Map<String, dynamic> tenant) {
    final status = safeStr(tenant['status'], 'قريب');
    final isLate = status == 'متأخر';
    final isPaid = status == 'مدفوع';
    final color = isLate
        ? AppTheme.errorColor
        : (isPaid ? AppTheme.primaryColor : Colors.orange);
    final text = isLate ? 'متأخر' : (isPaid ? 'مدفوع' : 'قريب الاستحقاق');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLate
            ? AppTheme.errorColor.withOpacity(0.04)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLate ? AppTheme.errorColor.withOpacity(0.35) : color.withOpacity(0.18),
          width: isLate ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(safeStr(tenant['name'], 'مستأجر'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(safeStr(tenant['property'], 'عقار'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                    'القسط القادم',
                    DateFormat('yyyy/MM/dd')
                        .format(tenant['nextDueDate'] as DateTime)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfo(
                    'آخر دفع',
                    DateFormat('yyyy/MM/dd')
                        .format(tenant['lastPayment'] as DateTime)),
              ),
            ],
          ),
          if (tenant['preEntryLabel'] != null) ...[
            const SizedBox(height: 8),
            Text(
              tenant['preEntryLabel'].toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tenant['preEntryLabel']
                        .toString()
                        .contains('✓')
                    ? AppTheme.primaryColor
                    : AppTheme.errorColor,
              ),
            ),
          ],
          if (tenant['isRedFlag'] == true) ...[
            const SizedBox(height: 6),
            const Text(
              '🚩 يسكن بدون دفع',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
          if (isLate) ...[
            const SizedBox(height: 10),
            _miniInfo('المبلغ المتأخر', '${tenant['lateAmount']} ج.م'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentHistory(tenant),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('سجل الدفعات'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendReminder(tenant),
                  icon:
                      const Icon(Icons.notifications_active_rounded, size: 16),
                  label: const Text('إشعار'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showPaymentHistory(Map<String, dynamic> tenant) {
    final rent = tenant['rent'] as double? ?? 0;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سجل دفعات ${tenant['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العقار: ${tenant['property']}'),
            const SizedBox(height: 8),
            Text(
              'آخر دفع: ${DateFormat('yyyy/MM/dd').format(tenant['lastPayment'] as DateTime)}',
            ),
            Text('الإيجار الشهري: ${rent.toStringAsFixed(0)} ج.م'),
            Text(
              'الحالة: ${tenant['status'] == 'متأخر' ? 'متأخر' : tenant['status'] == 'مدفوع' ? 'مدفوع' : 'قريب الاستحقاق'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(Map<String, dynamic> tenant) async {
    final user = await AuthService.getCurrentUser();
    final ownerEmail = user?['email']?.toString() ?? 'owner@ejari.app';
    final tenantEmail = tenant['email']?.toString() ?? 'user@ejari.app';
    await DataService.sendPaymentReminder(
      tenantEmail: tenantEmail,
      bookingId: tenant['id']?.toString() ?? '',
      ownerEmail: ownerEmail,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال تذكير إلى ${tenant['name']}'),
      ),
    );
  }
}
