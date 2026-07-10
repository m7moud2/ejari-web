import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';

class CreateMaintenanceRequestScreen extends StatefulWidget {
  const CreateMaintenanceRequestScreen({super.key});

  @override
  State<CreateMaintenanceRequestScreen> createState() =>
      _CreateMaintenanceRequestScreenState();
}

class _CreateMaintenanceRequestScreenState
    extends State<CreateMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _selectedPriority = 'medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب صيانة جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded,
                        color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'اكتب المشكلة بشكل واضح، واختار النوع والأولوية، وسيتم تجهيز الطلب بشكل منظم قبل أي متابعة.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'أمثلة سريعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickIssueChip(
                    label: 'تسريب مياه',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'plumbing';
                        _selectedPriority = 'urgent';
                        _titleController.text = 'تسريب مياه';
                        _descriptionController.text =
                            'يوجد تسريب مياه ويحتاج فحص سريع وإصلاح.';
                      });
                    },
                  ),
                  _QuickIssueChip(
                    label: 'عطل كهرباء',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'electrical';
                        _selectedPriority = 'urgent';
                        _titleController.text = 'عطل في الكهرباء';
                        _descriptionController.text =
                            'هناك مشكلة كهربائية متكررة وتحتاج تدخل سريع.';
                      });
                    },
                  ),
                  _QuickIssueChip(
                    label: 'صيانة تكييف',
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'ac';
                        _selectedPriority = 'medium';
                        _titleController.text = 'صيانة التكييف';
                        _descriptionController.text =
                            'أحتاج تنظيف وفحص وصيانة للتكييف.';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Selection
              const Text(
                'نوع المشكلة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: MaintenanceService.categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category['icon'],
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Priority Selection
              const Text(
                'الأولوية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...MaintenanceService.priorities.entries.map((entry) {
                final isSelected = _selectedPriority == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPriority = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Color(entry.value['color'])
                            : AppTheme.primaryColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: entry.key,
                          groupValue: _selectedPriority,
                          onChanged: (value) =>
                              setState(() => _selectedPriority = value!),
                          activeColor: Color(entry.value['color']),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'وقت الاستجابة: ${entry.value['responseTime']}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(entry.value['color']),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المشكلة',
                  hintText: 'مثال: تسريب في الحمام',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف المشكلة',
                  hintText: 'اشرح المشكلة بالتفصيل...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'إرسال الطلب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الرجاء اختيار نوع المشكلة'),
            backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    // Simulate some location within Cairo/New Cairo area for demo purposes
    final lat = 30.0 + (DateTime.now().millisecond % 500) / 1000;
    final lng = 31.2 + (DateTime.now().microsecond % 500) / 1000;

    await MaintenanceService.createRequest(
      userId: user['email'],
      propertyId: 'PROP001', // Should be from actual property
      category: _selectedCategory!,
      priority: _selectedPriority,
      title: _titleController.text,
      description: _descriptionController.text,
      lat: lat,
      lng: lng,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال الطلب بنجاح! ✅'),
            backgroundColor: AppTheme.primaryColor),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _QuickIssueChip extends StatelessWidget {
  const _QuickIssueChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.borderColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.borderColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
