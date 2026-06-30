import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'contract_screen.dart';

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
    setState(() {
      _userType = user?['type'] ?? 'tenant';
    });

    try {
      final bookings = await DataService.getBookings();
      final paidBookings = bookings
          .where((b) =>
              b['status'] == 'paid' ||
              b['status'] == 'active' ||
              b['status'] == 'completed' ||
              b['status'] == 'deposit_paid')
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
            'propertyTitle': b['title'] ?? 'شقة سكنية كيو',
            'ownerName': b['ownerName'] ?? 'أحمد محمد',
            'tenantName': b['tenantName'] ?? user?['name'] ?? 'محمود عبد القوي',
            'price': b['price']?.toString() ?? '0',
            'startDate': b['startDate']?.toString().isNotEmpty == true
                ? b['startDate'].toString().substring(0, 10)
                : '2026-06-06',
            'endDate': b['endDate']?.toString().isNotEmpty == true
                ? b['endDate'].toString().substring(0, 10)
                : '2027-06-06',
            'duration': 'سنة واحدة',
            'status': 'active',
            'signedByOwner': true,
            'signedByTenant': true,
            'createdAt': b['requestDate']?.toString().isNotEmpty == true
                ? b['requestDate'].toString().substring(0, 10)
                : '2026-06-06',
            'address': b['location'] ?? 'كيو، مصر',
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
    final activeCount =
        _contracts.where((c) => c['status'] == 'active').length;
    final pendingCount =
        _contracts.where((c) => c['status'] == 'pending').length;
    final expiredCount =
        _contracts.where((c) => c['status'] == 'expired').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عقودي الإلكترونية'),
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
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                              'سارية', '$activeCount', AppTheme.primaryColor),
                        ),
                        Expanded(
                          child: _buildMiniStat('قيد التوقيع', '$pendingCount',
                              AppTheme.borderColor),
                        ),
                        Expanded(
                          child: _buildMiniStat(
                              'منتهية', '$expiredCount', AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color ??
                        AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, contract['address']),
                const Divider(height: 24),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.backgroundColor
                        : AppTheme.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('القيمة الشهرية',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          Text('${contract['price']} ج.م',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المدة',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                          Text(
                            contract['duration'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.textPrimary
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
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

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد عقود',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر العقود بعد إتمام الدفع والتوقيع.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
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
