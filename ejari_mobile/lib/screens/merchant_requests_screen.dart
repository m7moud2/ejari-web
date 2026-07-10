import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

class MerchantRequestsScreen extends StatefulWidget {
  const MerchantRequestsScreen({super.key});

  @override
  State<MerchantRequestsScreen> createState() => _MerchantRequestsScreenState();
}

class _MerchantRequestsScreenState extends State<MerchantRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final requests = await DataService.getMerchantRequests();
    if (mounted) {
      setState(() {
        _requests = requests.where((r) => r['status'] == 'pending').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    await DataService.approveMerchantRequest(request['id']);

    if (mounted) {
      setState(() => _isLoading = false);
      _loadRequests();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تمت الموافقة ✅'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تم إنشاء حساب موثق للمنشأة: ${request['companyName']}'),
              const SizedBox(height: 10),
              const Text(
                'تم إرسال رسالة نصية (SMS) إلى:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${request['phone']}'),
              const SizedBox(height: 10),
              const Text(
                  'تحتوي الرسالة على رابط لتعيين كلمة المرور وتفعيل الحساب.'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('تم')),
          ],
        ),
      );
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الطلب ❌'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سبب رفض طلب ${request['companyName']}:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'اكتب سبب الرفض...'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(seconds: 1));
              await DataService.rejectMerchantRequest(request['id']);
              if (mounted) {
                setState(() => _isLoading = false);
                _loadRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم رفض الطلب وإبلاغ التاجر.')),
                );
              }
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات التجار الجدد 📋')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('لا توجد طلبات جديدة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: const CircleAvatar(child: Icon(Icons.store)),
                        title: Text(req['companyName'] ?? 'بدون اسم'),
                        subtitle: Text(
                            'المالك: ${req['ownerName']}\n${req['requestDate'].toString().split('T')[0]}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('رقم الهاتف', req['phone']),
                                _buildDetailRow('البريد', req['email']),
                                _buildDetailRow(
                                    'البطاقة الضريبية', req['taxId']),
                                _buildDetailRow(
                                    'السجل التجاري', req['commercialRecord']),
                                const Divider(),
                                const Text('المستندات:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _buildDocLink(
                                    'البطاقة الضريبية', req['taxCardPath']),
                                _buildDocLink('السجل التجاري',
                                    req['commercialRecordPath']),
                                _buildDocLink(
                                    'بطاقة الهوية', req['idCardPath']),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _rejectRequest(req),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.errorColor),
                                        child: const Text('رفض'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approveRequest(req),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white),
                                        child: const Text('قبول وتوثيق'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }

  Widget _buildDocLink(String label, String? path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file,
              size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (path != null)
            const Text('تم التحقق ✅',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 12))
          else
            const Text('مفقود ❌',
                style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
        ],
      ),
    );
  }
}
