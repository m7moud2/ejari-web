import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, in_progress, completed

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = await AuthService.getCurrentUser();
    final jobs = await DataService.getProviderRequests(user?['email'] ?? '');
    setState(() {
      _jobs = jobs;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String jobId, String status) async {
    await AuthService.getCurrentUser();
    await DataService.updateProviderRequestStatus(jobId, status);
    _loadJobs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == 'accepted'
                ? 'تم قبول المهمة بنجاح ✅'
                : 'تم تحديث حالة المهمة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _selectedFilter == 'all'
        ? _jobs
        : _jobs.where((j) => j['status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('إدارة المهام'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('طلبات جديدة', 'pending'),
                  _buildFilterChip('جاري العمل',
                      'accepted'), // accepted covers in_progress for now
                  _buildFilterChip('مكتملة', 'completed'),
                ],
              ),
            ),
          ),

          // Jobs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredJobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) =>
                            _buildJobCard(filteredJobs[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedFilter == value;
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'];
    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.borderColor;
        statusText = 'طلب جديد';
        break;
      case 'accepted':
      case 'in_progress':
        statusColor = AppTheme.primaryColor;
        statusText = 'جاري العمل';
        break;
      case 'completed':
        statusColor = AppTheme.primaryColor;
        statusText = 'مكتملة';
        break;
      default:
        statusColor = AppTheme.primaryColor;
        statusText = 'غير معروف';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              Text(job['id'],
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(job['service'],
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline, job['customer'],
              action: () async {
            final Uri telLaunchUri =
                Uri(scheme: 'tel', path: job['customerPhone'] ?? job['phone']);
            if (await canLaunchUrl(telLaunchUri)) {
              await launchUrl(telLaunchUri);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('لا يمكن إجراء الاتصال حالياً')));
            }
          }, actionIcon: Icons.phone_android),
          _buildInfoRow(Icons.location_on_outlined, job['address'],
              action: () async {
            final lat = job['lat'];
            final lng = job['lng'];
            final url = (lat != null && lng != null)
                ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
                : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(job['address'])}';

            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لا يمكن فتح الخرائط حالياً')));
            }
          }, actionIcon: Icons.map_outlined),
          _buildInfoRow(Icons.payments_outlined, '${job['price']} ج.م'),
          if (job['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(job['notes'],
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          _buildActions(job),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {VoidCallback? action, IconData? actionIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ),
          if (action != null)
            IconButton(
              icon: Icon(actionIcon ?? Icons.open_in_new,
                  size: 18, color: AppTheme.primaryColor),
              onPressed: action,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> job) {
    if (job['status'] == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor),
              child: const Text('رفض'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(job['id'], 'accepted'),
              child: const Text('قبول المهمة'),
            ),
          ),
        ],
      );
    } else if (job['status'] == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(job['id'], 'completed'),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('إتمام المهمة'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('لا توجد مهام حالياً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
