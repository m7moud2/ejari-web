import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/safe_parse.dart';
import 'contract_screen.dart';
import 'rental_statement_screen.dart';
import 'tenant_installments_screen.dart';

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    final user = await AuthService.getCurrentUser();
    final role = await AuthService.getUserRole();
    setState(() {
      _userType = role == 'owner' ? 'owner' : (user?['type'] ?? 'tenant');
    });

    try {
      List<Map<String, dynamic>> sourceBookings;
      if (role == 'owner') {
        final ownerId = user?['email']?.toString() ??
            user?['uid']?.toString() ??
            'owner@ejari.app';
        sourceBookings = await DataService.getOwnerRequests(ownerId);
      } else {
        sourceBookings = await DataService.getBookings();
      }

      final paidBookings = sourceBookings
          .where((b) =>
              b['status'] == 'paid' ||
              b['status'] == 'active' ||
              b['status'] == 'completed' ||
              b['status'] == 'deposit_paid' ||
              b['status'] == 'approved' ||
              b['status'] == 'viewing_scheduled')
          .toList();
      if (paidBookings.isNotEmpty) {
        final List<Map<String, dynamic>> realContracts = paidBookings.map((b) {
          final cleanedPrice =
              b['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
          final numericPrice = double.tryParse(cleanedPrice) ?? 0.0;
          String displayId = b['contractNumber'] ?? '';
          if (displayId.isEmpty && b['id'] != null) {
            String cleanId = b['id'].toString();
            displayId =
                'CTR-${cleanId.length > 5 ? cleanId.substring(cleanId.length - 5) : cleanId}';
          } else if (displayId.isEmpty) {
            displayId = 'CTR-001';
          }

          return {
            'id': displayId,
            'propertyTitle': b['title'] ?? 'شقة سكنية إيجاري',
            'ownerName': b['ownerName'] ?? 'أحمد محمد',
            'tenantName': b['tenantName'] ?? user?['name'] ?? 'محمود عبد القوي',
            'price': b['price']?.toString() ?? '0',
            'startDate': b['startDate']?.toString().isNotEmpty == true
                ? b['startDate'].toString().substring(0, 10)
                : '2026-06-06',
            'endDate': b['endDate']?.toString().isNotEmpty == true
                ? b['endDate'].toString().substring(0, 10)
                : '2027-06-06',
            'duration': b['durationLabel'] ?? b['duration'] ?? 'سنة واحدة',
            'rentalTierLabel': b['rentalTierLabel'] ?? '',
            'tenantTypeLabel': b['tenantTypeLabel'] ?? '',
            'status': 'active',
            'signedByOwner': true,
            'signedByTenant': true,
            'createdAt': b['requestDate']?.toString().isNotEmpty == true
                ? b['requestDate'].toString().substring(0, 10)
                : '2026-06-06',
            'address': b['location'] ?? 'إيجاري، مصر',
            'deposit': b['depositAmount']?.toString() ??
                (numericPrice > 0
                    ? (numericPrice * 0.10).toStringAsFixed(0)
                    : '0'),
            'remaining': b['remainingAmount']?.toString() ??
                (numericPrice > 0
                    ? (numericPrice * 0.90).toStringAsFixed(0)
                    : '0'),
          };
        }).toList();

        setState(() {
          _contracts = realContracts;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading contracts from bookings: $e');
    }

    // Demo data fallback
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _contracts = [
        {
          'id': 'CTR-001',
          'propertyTitle': 'شقة المعادي الفاخرة',
          'ownerName': 'أحمد محمد',
          'tenantName': 'محمود عبد القوي',
          'price': '5,000',
          'startDate': '2023-12-01',
          'endDate': '2024-12-01',
          'duration': 'سنة واحدة',
          'status': 'active', // active, pending, expired
          'signedByOwner': true,
          'signedByTenant': true,
          'createdAt': '2023-11-25',
          'address': 'شارع 9، المعادي، القاهرة',
          'deposit': '5,000',
        },
        {
          'id': 'CTR-002',
          'propertyTitle': 'فيلا الشيخ زايد',
          'ownerName': 'سارة أحمد',
          'tenantName': 'محمود عبد القوي',
          'price': '12,000',
          'startDate': '2024-01-01',
          'endDate': '2024-07-01',
          'duration': '6 أشهر',
          'status': 'pending',
          'signedByOwner': true,
          'signedByTenant': false,
          'createdAt': '2023-12-20',
          'address': 'الحي السابع، الشيخ زايد، الجيزة',
          'deposit': '12,000',
        },
        {
          'id': 'CTR-003',
          'propertyTitle': 'شقة مدينة نصر',
          'ownerName': 'خالد حسن',
          'tenantName': 'محمود عبد القوي',
          'price': '4,500',
          'startDate': '2022-06-01',
          'endDate': '2023-06-01',
          'duration': 'سنة واحدة',
          'status': 'expired',
          'signedByOwner': true,
          'signedByTenant': true,
          'createdAt': '2022-05-20',
          'address': 'شارع مصطفى النحاس، مدينة نصر، القاهرة',
          'deposit': '4,500',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _contracts.where((c) => c['status'] == 'active').length;
    final pendingCount =
        _contracts.where((c) => c['status'] == 'pending').length;
    final expiredCount =
        _contracts.where((c) => c['status'] == 'expired').length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('عقودي الإلكترونية'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContracts,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPadding,
                  4,
                  AppTheme.screenPadding,
                  AppTheme.spaceXl,
                ),
                children: [
                  _buildHeaderCard(activeCount, pendingCount, expiredCount),
                  const SizedBox(height: 14),
                  if (_contracts.isEmpty)
                    _buildEmptyState()
                  else
                    ..._contracts
                        .map((contract) => _buildContractCard(contract)),
                ],
              ),
            ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['status'];
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'active':
        statusColor = AppTheme.primaryColor;
        statusText = 'ساري';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.borderColor;
        statusText = 'قيد التوقيع';
        statusIcon = Icons.pending;
        break;
      case 'expired':
        statusColor = AppTheme.primaryColor;
        statusText = 'منتهي';
        statusIcon = Icons.history;
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'غير معروف';
        statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: EjariSurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  contract['id'],
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['propertyTitle'],
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.titleLarge?.color ??
                        AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, safeStr(contract['address'], '—')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'القيمة الشهرية',
                          '${contract['price']} ج.م',
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          'المدة',
                          contract['duration'],
                          AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المالك',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                contract['ownerName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      AppTheme.textPrimary,
                                ),
                              ),
                              if (contract['signedByOwner'])
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.verified,
                                      color: AppTheme.primaryColor, size: 16),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المستأجر',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                contract['tenantName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      AppTheme.textPrimary,
                                ),
                              ),
                              if (contract['signedByTenant'])
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.verified,
                                      color: AppTheme.primaryColor, size: 16),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'من ${contract['startDate']} إلى ${contract['endDate']}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.ctaHeight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContractScreen(
                            contractId: contract['id'],
                            propertyTitle: contract['propertyTitle'],
                            ownerName: contract['ownerName'],
                            tenantName: contract['tenantName'],
                            price: contract['price'],
                            startDate: contract['startDate'],
                            duration: contract['duration'],
                            address: contract['address'],
                            deposit: contract['deposit'],
                            signedByOwner: contract['signedByOwner'],
                            signedByTenant: contract['signedByTenant'],
                            isOwner: _userType == 'owner',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض العقد'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(int activeCount, int pendingCount, int expiredCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2E26), AppTheme.primaryColor, Color(0xFF1B594B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'كل عقودك في مكان واحد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'تابع العقود السارية، قيد التوقيع، والمنتهية من شاشة واحدة بشكل هادئ وواضح.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildHeaderMetric('سارية', '$activeCount')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildHeaderMetric('قيد التوقيع', '$pendingCount')),
              const SizedBox(width: 10),
              Expanded(child: _buildHeaderMetric('منتهية', '$expiredCount')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TenantInstallmentsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('الأقساط'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RentalStatementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('كشف الحساب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EjariSurfaceCard(
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              size: 72, color: AppTheme.primaryColor),
          SizedBox(height: AppTheme.spaceMd),
          Text(
            'لا توجد عقود حتى الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceXs),
          Text(
            'ستظهر العقود بعد إتمام الدفع والمراجعة والتوقيع.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية العقود'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('الكل'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('العقود السارية'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('قيد التوقيع'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('المنتهية'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
