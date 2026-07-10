import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../widgets/camera_capture_widget.dart';
import '../services/data_service.dart';
import '../utils/safe_parse.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<Map<String, dynamic>> _verificationRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final requests = await DataService.getAllIdentityVerifications();
    if (mounted) {
      setState(() {
        _verificationRequests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(int index) async {
    final request = _verificationRequests[index];
    final id = request['id']?.toString() ?? '';
    final ok = await DataService.approveIdentityVerification(id);
    if (!mounted) return;

    if (ok) {
      await _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم توثيق الحساب ✅'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _reject(int index) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.trim().isEmpty) return;

    final request = _verificationRequests[index];
    final id = request['id']?.toString() ?? '';
    final ok =
        await DataService.rejectIdentityVerification(id, reason.trim());
    if (!mounted) return;

    if (ok) {
      await _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض التوثيق ❌'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب سبب الرفض (مطلوب)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سبب الرفض مطلوب'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('رفض الطلب'),
          ),
        ],
      ),
    );
  }

  void _showImages(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صور ${safeStr(request['userName'], 'المستخدم')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _imagePreview('وجه البطاقة الأمامي', request['idFront']),
            const SizedBox(height: 12),
            _imagePreview('وجه البطاقة الخلفي', request['idBack']),
            const SizedBox(height: 12),
            _imagePreview('صورة السيلفي', request['selfie']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview(String label, dynamic data) {
    final imageData = data?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: imageData != null && imageData.isNotEmpty
                ? VerificationImage(data: imageData)
                : Container(
                    color: AppTheme.backgroundColor,
                    child: const Center(
                      child: Text('لا توجد صورة'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مراجعة التوثيق'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRequests();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadRequests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EjariSurfaceCard(
                    child: const EjariSectionHeader(
                      title: 'طلبات توثيق الهوية',
                      subtitle:
                          'راجع صور البطاقة والسيلفي واتخذ قرار الموافقة أو الرفض مع توضيح السبب.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryStrip(),
                  const SizedBox(height: 18),
                  if (_verificationRequests.isEmpty)
                    _buildEmptyState()
                  else
                    ..._verificationRequests.asMap().entries.map(
                          (entry) =>
                              _buildRequestCard(entry.value, entry.key),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryStrip() {
    final pending = _verificationRequests
        .where((item) => (item['status'] ?? 'pending') == 'pending')
        .length;
    final approved = _verificationRequests
        .where((item) => (item['status'] ?? '') == 'approved')
        .length;
    final rejected = _verificationRequests
        .where((item) => (item['status'] ?? '') == 'rejected')
        .length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryChip('إجمالي الطلبات', '${_verificationRequests.length}'),
        _summaryChip('قيد المراجعة', '$pending'),
        _summaryChip('موافق', '$approved'),
        _summaryChip('مرفوض', '$rejected'),
      ],
    );
  }

  Widget _summaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status']?.toString() ?? 'pending';
    final statusColor = status == 'pending'
        ? AppTheme.borderColor
        : (status == 'approved'
            ? AppTheme.primaryColor
            : AppTheme.errorColor);
    final statusText = status == 'pending'
        ? 'قيد المراجعة'
        : (status == 'approved' ? 'موافق' : 'مرفوض');
    final userIcon =
        request['userType'] == 'owner' ? Icons.business : Icons.person;

    return EjariSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(userIcon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(safeStr(request['userName'], 'مستخدم'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      request['userType'] == 'owner' ? 'مالك' : 'مستأجر',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.email, safeStr(request['email'], '')),
          _buildInfoRow(Icons.phone, safeStr(request['phone'], '')),
          if (request['submittedAt'] != null)
            _buildInfoRow(
              Icons.schedule_rounded,
              'أُرسل: ${request['submittedAt']}',
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showImages(request),
            icon: const Icon(Icons.photo_library_rounded, size: 18),
            label: const Text('عرض الصور الملتقطة'),
          ),
          if (status == 'rejected' &&
              (request['rejectionReason']?.toString().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'سبب الرفض: ${request['rejectionReason']}',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(index),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(index),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor),
                    child: const Text('موافقة'),
                  ),
                ),
              ],
            ),
          ],
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
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EjariSurfaceCard(
      child: Column(
        children: [
          Icon(Icons.verified_user, size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('لا توجد طلبات توثيق حالياً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
