import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    List<String>? requests = prefs.getStringList('verification_requests');

    if (requests != null) {
      setState(() {
        _verificationRequests =
            requests.map((r) => jsonDecode(r) as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } else {
      // Add demo requests
      _verificationRequests = [
        {
          'id': '1',
          'userName': 'أحمد محمد',
          'userType': 'owner',
          'email': 'ahmed@example.com',
          'phone': '01012345678',
          'status': 'pending',
          'documents': ['بطاقة الرقم القومي', 'عقد ملكية'],
        },
        {
          'id': '2',
          'userName': 'سارة علي',
          'userType': 'tenant',
          'email': 'sara@example.com',
          'phone': '01098765432',
          'status': 'pending',
          'documents': ['بطاقة الرقم القومي'],
        },
      ];
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int index, String status) async {
    setState(() {
      _verificationRequests[index]['status'] = status;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'verification_requests',
      _verificationRequests.map((r) => jsonEncode(r)).toList(),
    );

    // Update user verification status if approved
    if (status == 'approved') {
      final userEmail = _verificationRequests[index]['email'];
      final userKey = 'user_$userEmail';
      final userJson = prefs.getString(userKey);

      if (userJson != null) {
        Map<String, dynamic> userData = jsonDecode(userJson);
        userData['isVerified'] = true;
        userData['verifiedAt'] = DateTime.now().toIso8601String();
        await prefs.setString(userKey, jsonEncode(userData));
      }

      // Add Notification
      await DataService.addNotification('تم توثيق حسابك! 🎉',
          'تهانينا ${_verificationRequests[index]['userName']}، لقد تم فحص مستنداتك وتوثيق حسابك بنجاح. يمكنك الآن التمتع بكافة مميزات إيجاري.');
    } else if (status == 'rejected') {
      // Add Notification
      await DataService.addNotification('تم رفض طلب التوثيق ❌',
          'عذراً ${_verificationRequests[index]['userName']}، لم نتمكن من قبول مستندات التوثيق الخاصة بك. يرجى مراجعة البيانات والمحاولة مرة أخرى.');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              status == 'approved' ? 'تم توثيق الحساب ✅' : 'تم رفض التوثيق ❌'),
          backgroundColor: status == 'approved'
              ? AppTheme.primaryColor
              : AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('طلبات التوثيق'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildSummaryStrip(),
                const SizedBox(height: 18),
                if (_verificationRequests.isEmpty)
                  _buildEmptyState()
                else
                  ..._verificationRequests.asMap().entries.map(
                        (entry) => _buildRequestCard(entry.value, entry.key),
                      ),
              ],
            ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/promo/hero_reviews.jpg',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.primaryColor.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'لوحة التوثيق',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary.withOpacity(0.60),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'مراجعة واضحة • قرار سريع',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryChip('إجمالي الطلبات', '${_verificationRequests.length}'),
        _summaryChip('قيد المراجعة', '$pending'),
        _summaryChip('موثقة', '$approved'),
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
    String status = request['status'] ?? 'pending';
    Color statusColor = status == 'pending'
        ? AppTheme.borderColor
        : (status == 'approved' ? AppTheme.primaryColor : AppTheme.errorColor);
    String statusText = status == 'pending'
        ? 'قيد المراجعة'
        : (status == 'approved' ? 'موثق' : 'مرفوض');
    IconData userIcon =
        request['userType'] == 'owner' ? Icons.business : Icons.person;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                    Text(request['userName'],
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
          _buildInfoRow(Icons.email, request['email']),
          _buildInfoRow(Icons.phone, request['phone']),
          const SizedBox(height: 12),
          const Text('المستندات المرفقة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...(request['documents'] as List).map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(doc, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(index, 'rejected'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(index, 'approved'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor),
                    child: const Text('توثيق'),
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
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
