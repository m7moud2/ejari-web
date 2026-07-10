import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RequestVerificationScreen extends StatefulWidget {
  const RequestVerificationScreen({super.key});

  @override
  State<RequestVerificationScreen> createState() =>
      _RequestVerificationScreenState();
}

class _RequestVerificationScreenState extends State<RequestVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _hasNationalId = false;
  bool _hasOwnershipDoc = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() &&
        (_hasNationalId || _hasOwnershipDoc)) {
      setState(() => _isLoading = true);

      final user = await AuthService.getCurrentUser();
      List<String> documents = [];
      if (_hasNationalId) documents.add('بطاقة الرقم القومي');
      if (_hasOwnershipDoc) documents.add('عقد ملكية');

      final request = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userName': user?['name'] ?? 'مستخدم',
        'userType': user?['type'] ?? 'tenant',
        'email': user?['email'] ?? '',
        'phone': _phoneController.text,
        'status': 'pending',
        'documents': documents,
      };

      final prefs = await SharedPreferences.getInstance();
      List<String> requests =
          prefs.getStringList('verification_requests') ?? [];
      requests.add(jsonEncode(request));
      await prefs.setStringList('verification_requests', requests);

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 80),
                const SizedBox(height: 20),
                const Text('تم إرسال طلب التوثيق! ✅',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'سيتم مراجعة طلبك من قبل الإدارة وإشعارك بالنتيجة قريباً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('حسناً'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى رفع مستند واحد على الأقل'),
            backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب توثيق الحساب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'توثيق حسابك يمنحك مصداقية أكبر ويزيد من فرص قبول طلباتك.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('معلومات التواصل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '01xxxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              const Text('المستندات المطلوبة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('بطاقة الرقم القومي'),
                subtitle: const Text('صورة واضحة من البطاقة'),
                value: _hasNationalId,
                onChanged: (val) => setState(() => _hasNationalId = val!),
                secondary:
                    const Icon(Icons.badge, color: AppTheme.primaryColor),
              ),
              CheckboxListTile(
                title: const Text('عقد ملكية (للملاك فقط)'),
                subtitle: const Text('إثبات ملكية العقار'),
                value: _hasOwnershipDoc,
                onChanged: (val) => setState(() => _hasOwnershipDoc = val!),
                secondary:
                    const Icon(Icons.description, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('إرسال طلب التوثيق',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
