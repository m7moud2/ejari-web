import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart';

import 'map_search_screen.dart';

class ProviderTimelineScreen extends StatefulWidget {
  const ProviderTimelineScreen({super.key});

  @override
  State<ProviderTimelineScreen> createState() => _ProviderTimelineScreenState();
}

class _ProviderTimelineScreenState extends State<ProviderTimelineScreen> {
  List<Map<String, dynamic>> _timelineJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    await AuthService.getCurrentUser();
    final allRequests = await MaintenanceService.getAllRequests();

    // In a real app, filter by assignedTo or provider compatibility
    // For demo, we show all pending/in_progress as a queue
    if (mounted) {
      setState(() {
        _timelineJobs = allRequests;
        _timelineJobs.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('الجدول الزمني للخدمات'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timelineJobs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _timelineJobs.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(
                      _timelineJobs[index],
                      isLast: index == _timelineJobs.length - 1,
                    );
                  },
                ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> job, {bool isLast = false}) {
    final DateTime date = DateParsing.parse(job['createdAt']) ?? DateTime.now();
    final bool isCompleted = job['status'] == 'completed';
    final bool isInProgress = job['status'] == 'in_progress';

    Color statusColor = AppTheme.borderColor;
    if (isCompleted) statusColor = AppTheme.primaryColor;
    if (isInProgress) statusColor = AppTheme.primaryColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      width: 3),
                  boxShadow: const [],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('hh:mm a').format(date),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الجدول الزمني للخدمة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          _buildStatusBadge(job['status']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job['title'] ?? 'موقع العميل (كيو)',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Link to the Map Search Screen
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const MapSearchScreen()));
                            },
                            icon:
                                const Icon(Icons.directions_outlined, size: 16),
                            label: const Text('الخريطة',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(job['userName'] ?? 'عميل كيو',
                              style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM').format(date),
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.borderColor;
    String text = 'قيد الانتظار';

    if (status == 'completed') {
      color = AppTheme.primaryColor;
      text = 'مكتمل';
    } else if (status == 'in_progress') {
      color = AppTheme.primaryColor;
      text = 'جاري العمل';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('لا توجد مهام مجدولة حالياً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
