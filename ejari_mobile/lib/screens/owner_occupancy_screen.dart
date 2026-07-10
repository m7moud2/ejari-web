import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/auth_gate.dart';
import '../widgets/ejari_section.dart';
import '../widgets/occupancy_calendar_widget.dart';

class OwnerOccupancyScreen extends StatefulWidget {
  final String? propertyId;
  const OwnerOccupancyScreen({super.key, this.propertyId});

  @override
  State<OwnerOccupancyScreen> createState() => _OwnerOccupancyScreenState();
}

class _OwnerOccupancyScreenState extends State<OwnerOccupancyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _tenants = [];
  Map<String, dynamic> _calendar = {};
  List<Map<String, dynamic>> _properties = [];
  String? _selectedPropertyId;
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedPropertyId = widget.propertyId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await AuthGate.requireRole(
        context,
        allowedRoles: const ['owner'],
        deniedMessage: 'إدارة الإشغال متاحة للمالك فقط.',
      );
      if (allowed) _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final props = await DataService.getOwnerProperties(ownerId);
    final shared = props
        .where((p) => DataService.isSharedAccommodation(p))
        .toList();
    _properties = shared.isNotEmpty ? shared : props;
    _selectedPropertyId ??=
        _properties.isNotEmpty ? _properties.first['id']?.toString() : 'shared_egy1';

    final tenants = await DataService.getOccupancyTenants(
      ownerId,
      propertyId: _selectedPropertyId,
    );
    final calendar = _selectedPropertyId != null
        ? await DataService.getOccupancyCalendar(
            _selectedPropertyId!,
            year: _calendarMonth.year,
            month: _calendarMonth.month,
          )
        : <String, dynamic>{};

    if (mounted) {
      setState(() {
        _tenants = tenants;
        _calendar = calendar;
        _loading = false;
      });
    }
  }

  Future<void> _sendReminder(Map<String, dynamic> tenant) async {
    final user = await AuthService.getCurrentUser();
    await DataService.sendPaymentReminder(
      tenantEmail: tenant['email']?.toString() ?? '',
      bookingId: tenant['id']?.toString() ?? '',
      ownerEmail: user?['email']?.toString(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال تذكير الدفع للمستأجر'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('إدارة الإشغال'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'المستأجرون (${_tenants.length})'),
            const Tab(text: 'التقويم'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  if (_properties.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPropertyId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'العقار',
                        ),
                        items: _properties
                            .map(
                              (p) => DropdownMenuItem(
                                value: p['id']?.toString(),
                                child: Text(p['title']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedPropertyId = v);
                          _load();
                        },
                      ),
                    ),
                  _summaryBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _tenantList(),
                        _calendarView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryBar() {
    final vacant = (_calendar['vacantCount'] as num?)?.toInt() ?? 0;
    final overdue =
        _tenants.where((t) => t['paymentStatus'] == 'overdue').length;
    final redFlag = _tenants
        .where((t) => t['paymentStatus'] == 'living_without_pay')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _chip('فاضي: $vacant', AppTheme.accentColor),
          const SizedBox(width: 8),
          _chip('متأخر: $overdue', AppTheme.errorColor),
          const SizedBox(width: 8),
          if (redFlag > 0)
            _chip('🚩 بدون دفع: $redFlag', AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color == AppTheme.accentColor
              ? AppTheme.primaryColor
              : AppTheme.errorColor,
        ),
      ),
    );
  }

  Widget _tenantList() {
    if (_tenants.isEmpty) {
      return const Center(child: Text('لا يوجد مستأجرون بعد'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenants.length,
      itemBuilder: (context, i) => _tenantCard(_tenants[i]),
    );
  }

  Widget _tenantCard(Map<String, dynamic> t) {
    final status = t['paymentStatus']?.toString() ?? '';
    final prePaid = t['preEntryPaid'] == true;
    Color statusColor = AppTheme.primaryColor;
    String statusLabel = 'مدفوع';
    if (status == 'overdue') {
      statusColor = AppTheme.errorColor;
      statusLabel = 'متأخر';
    } else if (status == 'living_without_pay') {
      statusColor = AppTheme.errorColor;
      statusLabel = '🚩 يسكن بدون دفع';
    }

    final leaseStart = DateTime.tryParse(t['leaseStart']?.toString() ?? '');
    final leaseEnd = DateTime.tryParse(t['leaseEnd']?.toString() ?? '');
    final fmt = DateFormat('d/M/y', 'ar');

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Text(
                  (t['name']?.toString() ?? 'م')[0],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['name']?.toString() ?? 'مستأجر',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      t['bedLabel']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                t['phone']?.toString() ?? '',
                style: const TextStyle(fontSize: 11),
              ),
              const Spacer(),
              Text(
                prePaid ? 'مدفوع قبل الدخول ✓' : 'لم يُحصّل',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: prePaid ? AppTheme.primaryColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          if (leaseStart != null && leaseEnd != null) ...[
            const SizedBox(height: 6),
            Text(
              'الإيجار: ${fmt.format(leaseStart)} — ${fmt.format(leaseEnd)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (status == 'overdue' || status == 'living_without_pay') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendReminder(t),
                icon: const Icon(Icons.notifications_active, size: 16),
                label: const Text('إرسال تذكير'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _calendarView() {
    final occupied = Map<String, List<String>>.from(
      (_calendar['occupiedByDate'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), List<String>.from(v as List)),
          ) ??
          {},
    );
    final vacant =
        List<String>.from(_calendar['vacantBedLabels'] as List? ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EjariSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                        );
                      });
                      _load();
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'ar').format(_calendarMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                        );
                      });
                      _load();
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OccupancyCalendarWidget(
                year: _calendarMonth.year,
                month: _calendarMonth.month,
                occupiedByDate: occupied,
                vacantBedLabels: vacant,
              ),
              const SizedBox(height: 12),
              const EjariSectionHeader(
                title: 'أماكن فاضية',
                subtitle: 'أسرّة متاحة للإيجار السريع',
              ),
              const SizedBox(height: 8),
              if (vacant.isEmpty)
                const Text('لا توجد أسرّة فاضية حالياً')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vacant
                      .map(
                        (v) => Chip(
                          label: Text(v),
                          backgroundColor:
                              AppTheme.accentColor.withOpacity(0.15),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
