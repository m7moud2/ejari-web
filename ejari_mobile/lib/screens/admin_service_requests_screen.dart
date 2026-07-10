import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/safe_parse.dart';

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
    final joinRequests = await DataService.getJoinRequests();

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
      final title = (r['title'] ?? r['service'] ?? '').toString().toLowerCase();
      final customer =
          (r['userName'] ?? r['tenantId'] ?? r['customer'] ?? '').toString().toLowerCase();
      final provider =
          (r['assignedTo'] ?? r['technicianId'] ?? r['provider'] ?? '').toString().toLowerCase();
      final st = MaintenanceStatus.normalize(r['status']?.toString());
      final legacyFilter = _selectedFilter == 'pending'
          ? st == MaintenanceStatus.submitted
          : _selectedFilter == 'in_progress'
              ? [
                  MaintenanceStatus.assigned,
                  MaintenanceStatus.enRoute,
                  MaintenanceStatus.inProgress,
                ].contains(st)
              : r['status'] == _selectedFilter;
      final matchesFilter =
          _selectedFilter == 'all' || legacyFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          customer.contains(_searchQuery) ||
          provider.contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();

    // Statistics
    final totalRequests = _allRequests.length;
    final pendingCount = _allRequests.where((r) {
      final st = MaintenanceStatus.normalize(r['status']?.toString());
      return st == MaintenanceStatus.submitted || r['status'] == 'pending';
    }).length;
    final inProgressCount = _allRequests.where((r) {
      final st = MaintenanceStatus.normalize(r['status']?.toString());
      return [
        MaintenanceStatus.assigned,
        MaintenanceStatus.enRoute,
        MaintenanceStatus.inProgress,
        MaintenanceStatus.pendingClientConfirm,
      ].contains(st) || r['status'] == 'in_progress';
    }).length;
    final completedCount = _allRequests.where((r) {
      final st = MaintenanceStatus.normalize(r['status']?.toString());
      return st == MaintenanceStatus.paid ||
          st == MaintenanceStatus.completed ||
          r['status'] == 'completed';
    }).length;

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
    final status = MaintenanceStatus.normalize(request['status']?.toString());
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case MaintenanceStatus.submitted:
        statusColor = AppTheme.accentColor;
        statusText = 'مُرسَل';
        statusIcon = Icons.access_time;
        break;
      case MaintenanceStatus.assigned:
      case MaintenanceStatus.enRoute:
      case MaintenanceStatus.inProgress:
      case MaintenanceStatus.pendingClientConfirm:
        statusColor = AppTheme.primaryColor;
        statusText = MaintenanceStatus.labelAr(status);
        statusIcon = Icons.engineering;
        break;
      case MaintenanceStatus.paid:
      case MaintenanceStatus.completed:
        statusColor = AppTheme.successColor;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
        break;
      case MaintenanceStatus.cancelled:
      case MaintenanceStatus.rejected:
      case MaintenanceStatus.disputed:
        statusColor = AppTheme.errorColor;
        statusText = MaintenanceStatus.labelAr(status);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'غير معروف';
        statusIcon = Icons.help_outline;
    }

    final displayTitle = safeStr(
      request['title'] ?? request['service'],
      'طلب صيانة',
    );
    final isMaintenance = request['id']?.toString().startsWith('MNT') == true ||
        request['id']?.toString().startsWith('JR') != true;

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
                  safeStr(request['id']),
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
                        displayTitle,
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
                _buildInfoRow(Icons.person,
                    'العميل: ${safeStr(request['userName'] ?? request['tenantId'], 'عميل')}'),
                _buildInfoRow(
                    Icons.phone,
                    safeStr(
                        request['customerPhone'] ?? request['tenantPhone'],
                        '—')),
                _buildInfoRow(Icons.engineering,
                    'الفني: ${safeStr(request['assignedTo'] ?? request['technicianId'], 'غير معين')}'),
                _buildInfoRow(Icons.calendar_today,
                    safeStr(request['createdAt'], '—')),
                _buildInfoRow(Icons.location_on,
                    safeStr(request['propertyTitle'] ?? request['title'], '—')),
                if (request['description'] != null || request['notes'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      safeStr(request['description'] ?? request['notes']),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildAdminActions(request, isMaintenance),
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

  Widget _buildAdminActions(Map<String, dynamic> request, bool isMaintenance) {
    final status = MaintenanceStatus.normalize(request['status']?.toString());
    final isJoin = request['id']?.toString().startsWith('JR') == true;

    if (isJoin) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateJoinRequest(request, 'rejected'),
              child: const Text('رفض'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJoinRequest(request, 'approved'),
              child: const Text('قبول'),
            ),
          ),
        ],
      );
    }

    if (status == MaintenanceStatus.disputed) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _resolveDispute(request, 'reassign'),
              child: const Text('إعادة تعيين'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _resolveDispute(request, 'close'),
              child: const Text('إغلاق النزاع'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (status == MaintenanceStatus.submitted ||
            (request['status'] == 'pending' && isMaintenance)) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _assignTechnician(request),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('تعيين فني'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                _updateStatus(request, MaintenanceStatus.cancelled),
            icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
          ),
        ] else if ([
          MaintenanceStatus.assigned,
          MaintenanceStatus.enRoute,
          MaintenanceStatus.inProgress,
        ].contains(status)) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _viewDetails(request),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('التفاصيل'),
            ),
          ),
        ] else ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _viewDetails(request),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('عرض'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _assignTechnician(Map<String, dynamic> request) async {
    final technicians = await DataService.getTechnicians();
    if (!mounted) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر الفني'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: technicians.length,
            itemBuilder: (context, index) {
              final tech = technicians[index];
              return ListTile(
                leading: const Icon(Icons.handyman_rounded),
                title: Text(tech['name']?.toString() ?? ''),
                subtitle: Text(tech['email']?.toString() ?? ''),
                onTap: () => Navigator.pop(ctx, tech),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selected == null) return;
    final techEmail = selected['email']?.toString() ?? 'tech@ejari.app';
    final cost = (request['estimatedCost'] as num?)?.toDouble() ?? 200;
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.assignTechnician(
      request['id'].toString(),
      techEmail,
      actor: user?['email']?.toString(),
      estimatedCost: cost,
    );
    _loadRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تعيين $techEmail للمهمة'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _updateJoinRequest(
    Map<String, dynamic> request,
    String status,
  ) async {
    await DataService.updateJoinRequestStatus(
      request['id']?.toString() ?? '',
      status,
    );
    await _loadRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == 'approved' ? 'تم قبول الطلب' : 'تم رفض الطلب'),
      ),
    );
  }

  Future<void> _resolveDispute(
    Map<String, dynamic> request,
    String resolution,
  ) async {
    final user = await AuthService.getCurrentUser();
    await MaintenanceService.resolveDispute(
      request['id']?.toString() ?? '',
      resolution,
      actor: user?['email']?.toString(),
    );
    await _loadRequests();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث حالة النزاع')),
    );
  }

  void _updateStatus(Map<String, dynamic> request, String newStatus) async {
    if (request['id']?.toString().startsWith('JR') == true) {
      await DataService.updateJoinRequestStatus(
        request['id']?.toString() ?? '',
        newStatus == MaintenanceStatus.cancelled ? 'rejected' : 'approved',
      );
    } else {
      await MaintenanceService.updateStatus(request['id'], newStatus);
    }
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
        title: Text(safeStr(request['service'] ?? request['title'], 'طلب خدمة')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الطلب', safeStr(request['id'])),
              _buildDetailRow(
                  'العميل',
                  safeStr(request['customer'] ??
                      request['userName'] ??
                      request['tenantId'],
                      '—')),
              _buildDetailRow('الهاتف',
                  safeStr(request['customerPhone'] ?? request['tenantPhone'], '—')),
              _buildDetailRow(
                  'مقدم الخدمة',
                  safeStr(request['provider'] ??
                      request['assignedTo'] ??
                      request['technicianId'],
                      '—')),
              _buildDetailRow('التاريخ',
                  safeStr(request['date'] ?? request['createdAt'], '—')),
              _buildDetailRow('الوقت', safeStr(request['time'], '—')),
              _buildDetailRow(
                  'السعر',
                  '${safeStr(request['price'] ?? request['estimatedCost'], '0')} ج.م'),
              _buildDetailRow(
                  'العنوان',
                  safeStr(request['address'] ??
                      request['propertyTitle'] ??
                      request['title'],
                      '—')),
              if (request['notes'] != null || request['description'] != null)
                _buildDetailRow(
                    'ملاحظات', safeStr(request['notes'] ?? request['description'])),
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
