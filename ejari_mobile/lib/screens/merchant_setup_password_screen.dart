import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'merchant_dashboard_screen.dart';

class MerchantSetupPasswordScreen extends StatefulWidget {
  final String? initialPhone; // Optional, if navigated internally
  const MerchantSetupPasswordScreen({super.key, this.initialPhone});

  @override
  State<MerchantSetupPasswordScreen> createState() =>
      _MerchantSetupPasswordScreenState();
}

class _MerchantSetupPasswordScreenState
    extends State<MerchantSetupPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  Future<void> _setupAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await DataService.activateMerchantAccount(
      _phoneController.text,
      _passController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        // Log them in automatically
        await AuthService.login(_phoneController.text,
            _passController.text); // Mock login using phone as email/id

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const MerchantDashboardScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'فشل التفعيل. تأكد من رقم الهاتف أو أن الحساب تمت الموافقة عليه مسبقاً.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل حساب التاجر 🔐')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset,
                    size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'تعيين كلمة المرور',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'أدخل رقم هاتفك وكلمة المرور الجديدة لتفعيل حسابك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف المسجل',
                      prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passController,
                  decoration: const InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) =>
                      v!.length < 6 ? 'يجب أن تكون 6 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassController,
                  decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  validator: (v) => v != _passController.text
                      ? 'كلمة المرور غير متطابقة'
                      : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تفعيل وبدء العمل'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
