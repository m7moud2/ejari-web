import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState
    extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSpecialty = 'سباك';
  final List<String> _specialties = [
    'سباك',
    'كهربائي',
    'فني تكييف',
    'نجار',
    'نقاش',
    'مصور عقارات',
    'شركة نقل عفش',
    'أخرى'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    final application = {
      'id': 'JR-${DateTime.now().millisecondsSinceEpoch}',
      'userName': _nameController.text,
      'customerPhone': _phoneController.text,
      'service': 'طلب انضمام: $_selectedSpecialty',
      'experience': _expController.text,
      'notes': _bioController.text,
      'email': user?['email'] ?? 'unknown',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save to maintenance/provider requests
    await MaintenanceService.submitRequest(application);

    // Notify Admin
    await DataService.addNotificationToUser(
        'admin@ejari.app',
        'طلب انضمام شريك جديد 👷‍♂️',
        'قدم ${_nameController.text} طلباً للانضمام كـ $_selectedSpecialty.');

    setState(() => _isLoading = false);

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title:
            const Text('تم استلام طلبك بنجاح! ✅', textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_rounded,
                size: 64, color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'طلبك الآن قيد المراجعة من قبل إدارة إيجاري لضمان معايير الجودة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'سيتم الرد عليك في خلال ساعة بحد أقصى يوم عمل واحد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حسناً'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('انضم كشريك إيجاري'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'كن جزءاً من أكبر منظومة عقارية 🚀',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'املأ بياناتك المهنية وسيقوم فريقنا بالتواصل معك.',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 32),
              _buildLabel('الاسم الكامل'),
              _buildTextField(
                  _nameController, 'مثال: محمد أحمد علي', Icons.person_outline),
              const SizedBox(height: 20),
              _buildLabel('رقم الواتساب'),
              _buildTextField(
                  _phoneController, '01*********', Icons.phone_android_rounded,
                  isPhone: true),
              const SizedBox(height: 20),
              _buildLabel('التخصص المهني'),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel('سنوات الخبرة'),
              _buildTextField(
                  _expController, 'مثال: 5 سنوات', Icons.history_edu_rounded),
              const SizedBox(height: 20),
              _buildLabel('نبذة عن أعمالك (اختياري)'),
              _buildTextField(
                  _bioController,
                  'اذكر أهم المشاريع أو الخبرات السابقة...',
                  Icons.description_outlined,
                  maxLines: 4),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.borderColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال طلب الانضمام',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'نحن نضمن سرية بياناتك المهنية 🔒',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      validator: (value) =>
          value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.backgroundColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.backgroundColor)),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSpecialty,
          isExpanded: true,
          items: _specialties.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSpecialty = newValue!;
            });
          },
        ),
      ),
    );
  }
}
