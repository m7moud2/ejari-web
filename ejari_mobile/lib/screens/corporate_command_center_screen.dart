import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/data_service.dart';
import '../models/booking_status.dart';
import 'corporate_booking_screen.dart';
import 'my_bookings_screen.dart';

/// مركز قيادة الشركات — إدارة حجوزات الموظفين عبر المحافظات.
class CorporateCommandCenterScreen extends StatefulWidget {
  const CorporateCommandCenterScreen({super.key});

  @override
  State<CorporateCommandCenterScreen> createState() =>
      _CorporateCommandCenterScreenState();
}

class _CorporateCommandCenterScreenState
    extends State<CorporateCommandCenterScreen> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String _filterGov = 'الكل';

  static const _governorates = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الشرقية',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await DataService.getCorporateCommandSummary();
    final employees = await DataService.getCorporateEmployees();
    if (mounted) {
      setState(() {
        _summary = summary;
        _employees = employees.isNotEmpty
            ? employees
            : List<Map<String, dynamic>>.from(
                summary['employees'] ?? const [],
              );
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_filterGov == 'الكل') return _employees;
    return _employees
        .where((e) => e['governorate']?.toString() == _filterGov)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('مركز قيادة الشركات'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CorporateBookingScreen(),
              ),
            ),
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'حجز جديد',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppTheme.accentColor,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                children: [
                  _buildHero(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildStats(),
                  const SizedBox(height: AppTheme.spaceLg),
                  const EjariSectionHeader(
                    title: 'الموظفون حسب المحافظة',
                    subtitle: 'حالة كل حجز وإجمالي الإنفاق',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildGovernorateFilter(),
                  const SizedBox(height: AppTheme.spaceSm),
                  ..._filteredEmployees.map(_employeeCard),
                  if (_filteredEmployees.isEmpty)
                    const EjariSurfaceCard(
                      child: Text(
                        'لا موظفين في هذه المحافظة — أضف حجزاً جديداً.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppTheme.spaceLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CorporateBookingScreen(),
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.add_home_work_rounded),
                      label: const Text('حجز سكن جديد للموظفين'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('عرض كل حجوزات الشركة'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2E26), Color(0xFF1B594B)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.corporate_fare_rounded, color: AppTheme.accentColor),
              SizedBox(width: 8),
              Text(
                'إسكان موظفين متعدد المحافظات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _summary['companyName']?.toString() ?? 'شركة تجريبية — إيجاري',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إجمالي الإنفاق: ${_summary['totalSpend'] ?? 0} ج.م / شهر',
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      (
        'موظفون',
        '${_summary['totalEmployees'] ?? _employees.length}',
        Icons.people_rounded,
      ),
      (
        'حجوزات نشطة',
        '${_summary['activeBookings'] ?? 0}',
        Icons.event_available_rounded,
      ),
      (
        'بانتظار الموافقة',
        '${_summary['pendingBookings'] ?? 0}',
        Icons.hourglass_top_rounded,
      ),
      (
        'محافظات',
        '${_summary['governorateCount'] ?? 0}',
        Icons.map_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spaceSm,
      crossAxisSpacing: AppTheme.spaceSm,
      childAspectRatio: 1.6,
      children: stats.map((s) {
        return EjariSurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.$3, color: AppTheme.primaryColor, size: 20),
              const Spacer(),
              Text(
                s.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                s.$1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGovernorateFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _governorates.map((gov) {
          final selected = _filterGov == gov;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text(gov, style: const TextStyle(fontSize: 11)),
              selected: selected,
              onSelected: (_) => setState(() => _filterGov = gov),
              selectedColor: AppTheme.primaryColor.withOpacity(0.15),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final status = emp['status']?.toString() ?? 'pending';
    final rent = (emp['monthlyRent'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (emp['name']?.toString() ?? '?')[0],
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${emp['role'] ?? ''} • ${emp['governorate'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (emp['propertyTitle'] != null)
                    Text(
                      emp['propertyTitle'].toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                if (rent > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${rent.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'active':
        return AppTheme.successColor;
      case 'booked':
      case BookingStatus.depositPaid:
        return AppTheme.primaryColor;
      case 'pending':
      case BookingStatus.corporatePending:
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'active':
        return 'نشط';
      case 'booked':
        return 'محجوز';
      case BookingStatus.depositPaid:
        return 'عربون مدفوع';
      case BookingStatus.corporatePending:
        return 'بانتظار الإدارة';
      default:
        return 'بانتظار الحجز';
    }
  }
}
