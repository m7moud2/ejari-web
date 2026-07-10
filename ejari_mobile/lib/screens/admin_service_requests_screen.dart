import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';

class AdminServiceRequestsScreen extends StatefulWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  State<AdminServiceRequestsScreen> createState() =>
      _AdminServiceRequestsScreenState();
}

class _AdminServiceRequestsScreenState
    extends State<AdminServiceRequestsScreen> {
  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final maintenanceRequests = await MaintenanceService.getAllRequests();

    // Add demo join requests for providers
    final joinRequests = [
      {
        'id': 'JR-101',
        'service': 'طلب انضمام: مصور فوتوغرافي',
        'userName': 'كريم جمال',
        'customerPhone': '01288887777',
        'status': 'pending',
        'createdAt': '2024-04-22',
        'title': 'القاهرة، المعادي',
        'notes': 'خبرة 5 سنوات في تصوير العقارات الفاخرة.',
        'estimatedCost': 0,
      },
      {
        'id': 'JR-102',
        'service': 'طلب انضمام: شركة نقل أثاث',
        'userName': 'شركة السلام للنقل',
        'customerPhone': '01011223344',
        'status': 'pending',
        'createdAt': '2024-04-21',
        'title': 'الجيزة، الشيخ زايد',
        'notes': 'لدينا أسطول من 10 شاحنات مجهزة.',
        'estimatedCost': 0,
      },
    ];

    if (mounted) {
      setState(() {
        _allRequests = [...joinRequests, ...maintenanceRequests];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _allRequests.where((r) {
      final matchesFilter =
          _selectedFilter == 'all' || r['status'] == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          (r['service'] as String).toLowerCase().contains(_searchQuery) ||
          (r['customer'] as String).toLowerCase().contains(_searchQuery) ||
          (r['provider'] as String).toLowerCase().contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();

    // Statistics
    final totalRequests = _allRequests.length;
    final pendingCount =
        _allRequests.where((r) => r['status'] == 'pending').length;
    final inProgressCount =
        _allRequests.where((r) => r['status'] == 'in_progress').length;
    final completedCount =
        _allRequests.where((r) => r['status'] == 'completed').length;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'بحث عن خدمة أو عميل...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              )
            : const Text('إدارة طلبات الخدمات'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // Statistics Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard('الكل', totalRequests, AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      'قيد الانتظار', pendingCount, AppTheme.borderColor),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      'جاري التنفيذ', inProgressCount, AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      'مكتمل', completedCount, AppTheme.primaryColor),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('الكل', 'all', totalRequests),
                    _buildFilterChip('قيد الانتظار', 'pending', pendingCount),
                    _buildFilterChip(
                        'جاري التنفيذ', 'in_progress', inProgressCount),
                    _buildFilterChip('مكتمل', 'completed', completedCount),
                    _buildFilterChip(
                        'ملغي',
                        'cancelled',
                        _allRequests
                            .where((r) => r['status'] == 'cancelled')
                            .length),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Requests List
            Expanded(
              child: filteredRequests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) =>
                          _buildRequestCard(filteredRequests[index]),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isSelected ? AppTheme.primaryColor : AppTheme.primaryColor),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'];
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.borderColor;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.access_time;
        break;
      case 'in_progress':
        statusColor = AppTheme.primaryColor;
        statusText = 'جاري التنفيذ';
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        statusColor = AppTheme.primaryColor;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppTheme.errorColor;
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'غير معروف';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  request['id'],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request['service'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${request['estimatedCost'] ?? 0} ج.م',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.person, 'العميل: ${request['userName'] ?? 'عميل'}'),
                _buildInfoRow(
                    Icons.phone, request['customerPhone'] ?? '01000000000'),
                _buildInfoRow(Icons.business,
                    'مقدم الخدمة: ${request['assignedTo'] ?? 'غير معين'}'),
                _buildInfoRow(Icons.calendar_today, '${request['createdAt']}'),
                _buildInfoRow(Icons.location_on, request['title']),
                if (request['notes'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request['notes'],
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildAdminActions(request),
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

  Widget _buildAdminActions(Map<String, dynamic> request) {
    final status = request['status'];

    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateStatus(request, 'cancelled'),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('إلغاء'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(request, 'in_progress'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('قبول'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
            ),
          ),
        ] else if (status == 'in_progress') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(request, 'completed'),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('تم الإنجاز'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
            ),
          ),
        ] else ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _viewDetails(request),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('عرض التفاصيل'),
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _deleteRequest(request),
          icon: const Icon(Icons.delete, color: AppTheme.errorColor),
          tooltip: 'حذف',
        ),
      ],
    );
  }

  void _updateStatus(Map<String, dynamic> request, String newStatus) async {
    await MaintenanceService.updateStatus(request['id'], newStatus);
    _loadRequests();

    String message;
    switch (newStatus) {
      case 'in_progress':
        message = 'تم قبول الطلب وإرساله لمقدم الخدمة';
        break;
      case 'completed':
        message = 'تم تحديث حالة الطلب إلى مكتمل';
        break;
      case 'cancelled':
        message = 'تم إلغاء الطلب';
        break;
      default:
        message = 'تم تحديث الحالة';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _viewDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request['service']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الطلب', request['id']),
              _buildDetailRow('العميل', request['customer']),
              _buildDetailRow('الهاتف', request['customerPhone']),
              _buildDetailRow('مقدم الخدمة', request['provider']),
              _buildDetailRow('التاريخ', request['date']),
              _buildDetailRow('الوقت', request['time']),
              _buildDetailRow('السعر', '${request['price']} ج.م'),
              _buildDetailRow('العنوان', request['address']),
              if (request['notes'] != null)
                _buildDetailRow('ملاحظات', request['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _deleteRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allRequests.remove(request);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف الطلب')),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
