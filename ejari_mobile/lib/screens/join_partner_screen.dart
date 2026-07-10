import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

class JoinPartnerScreen extends StatefulWidget {
  const JoinPartnerScreen({super.key});

  @override
  State<JoinPartnerScreen> createState() => _JoinPartnerScreenState();
}

class _JoinPartnerScreenState extends State<JoinPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _commercialRecordController = TextEditingController();

  // Simulated File Paths
  String? _taxCardPath;
  String? _commercialRecordPath;
  String? _idCardPath;

  bool _isSubmitting = false;
  bool _isCompany = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'تصوير عقارات',
    'سباكة',
    'كهرباء',
    'نقاشة ودهانات',
    'نقل أثاث',
    'نظافة فندقية',
    'صيانة مكيفات',
    'تنسيق حدائق',
  ];

  void _pickFile(String type) {
    // Simulate file picking
    setState(() {
      if (type == 'tax') _taxCardPath = 'tax_card.pdf';
      if (type == 'cr') _commercialRecordPath = 'commercial_record.pdf';
      if (type == 'id') _idCardPath = 'owner_id.jpg';
      if (type == 'work') _workSamplePath = 'work_sample.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرفاق ملف $type بنجاح (محاكاة)')),
    );
  }

  String? _workSamplePath;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCompany) {
      if (_taxCardPath == null ||
          _commercialRecordPath == null ||
          _idCardPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('يرجى إرفاق جميع المستندات المطلوبة للشركة')));
        return;
      }
    } else {
      if (_idCardPath == null || _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('يرجى اختيار التخصص وإرفاق صورة البطاقة')));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final requestData = {
      'type': _isCompany ? 'company' : 'individual',
      'category': _selectedCategory ?? 'General',
      'companyName': _isCompany ? _companyNameController.text : 'عمل حر',
      'ownerName': _ownerNameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'taxId': _isCompany ? _taxIdController.text : '',
      'commercialRecord': _isCompany ? _commercialRecordController.text : '',
      'taxCardPath': _taxCardPath,
      'commercialRecordPath': _commercialRecordPath,
      'idCardPath': _idCardPath,
      'workSamplePath': _workSamplePath,
      'status': 'pending',
      'requestDate': DateTime.now().toIso8601String(),
    };

    await DataService.submitMerchantRequest(requestData);

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle,
              color: AppTheme.borderColor, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تم استلام طلبك بنجاح!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isCompany
                    ? 'سيتم مراجعة أوراق شركتك والرد عليك خلال 48 ساعة.'
                    : 'أهلاً بك في عائلة محترفي إيجاري! سيتم مراجعة بياناتك وتفعيل حسابك قريباً.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, color: AppTheme.primaryColor),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child:
                    const Text('حسناً', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انضم كشريك نجاح 🤝'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type Selection Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompany = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isCompany
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'شركة / مكتب',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isCompany
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompany = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isCompany
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'فرد / فني محترف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isCompany
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text(
              _isCompany ? 'بيانات المنشأة' : 'بياناتك الشخصية',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),

            if (_isCompany) ...[
              _buildTextField('اسم الشركة / المنشأة', _companyNameController,
                  Icons.business),
              const SizedBox(height: 12),
            ],

            _buildTextField(
                _isCompany ? 'اسم المالك (كما في البطاقة)' : 'الاسم بالكامل',
                _ownerNameController,
                Icons.person),
            const SizedBox(height: 12),

            if (!_isCompany) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('اختر التخصص / المهنة'),
                items: _categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.category, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                validator: (value) =>
                    value == null ? 'يرجى اختيار التخصص' : null,
              ),
              const SizedBox(height: 12),
            ],

            _buildTextField('رقم الهاتف للتواصل', _phoneController, Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(
                'البريد الإلكتروني (اختياري)', _emailController, Icons.email,
                keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 30),
            const Text(
              'المستندات المطلوبة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),

            if (_isCompany) ...[
              _buildTextField(
                  'رقم البطاقة الضريبية', _taxIdController, Icons.numbers),
              const SizedBox(height: 12),
              _buildTextField('رقم السجل التجاري', _commercialRecordController,
                  Icons.store),
              const SizedBox(height: 20),
              _buildUploadCard('صورة البطاقة الضريبية', 'tax', _taxCardPath),
              _buildUploadCard(
                  'صورة السجل التجاري', 'cr', _commercialRecordPath),
            ],

            _buildUploadCard('صورة بطاقة الرقم القومي', 'id', _idCardPath),
            if (!_isCompany)
              _buildUploadCard(
                  'نموذج من أعمالك (اختياري)', 'work', _workSamplePath),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال طلب الانضمام',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }

  Widget _buildUploadCard(String title, String type, String? path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(path != null ? Icons.check_circle : Icons.upload_file,
              color:
                  path != null ? AppTheme.primaryColor : AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path != null ? '$title (تم الإرفاق)' : 'إرفاق $title',
              style: TextStyle(
                  color: path != null
                      ? AppTheme.textPrimary
                      : AppTheme.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => _pickFile(type),
            child: const Text('استعراض'),
          ),
        ],
      ),
    );
  }
}
