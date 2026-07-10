import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/camera_capture_widget.dart';

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
  String? _selectedPropertyId;
  String _selectedPropertyTitle = '';
  DateTime? _preferredTime;
  bool _submitting = false;
  List<String> _attachedImages = [];
  List<Map<String, dynamic>> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final bookings = await DataService.getBookings();
    final props = bookings
        .map((b) => {
              'id': b['propertyId']?.toString() ?? b['id']?.toString() ?? '',
              'title': b['title']?.toString() ?? 'عقار محجوز',
            })
        .where((p) => p['id'].toString().isNotEmpty)
        .toList();

    if (props.isEmpty) {
      final all = await DataService.getAllProperties();
      props.addAll(all
          .take(5)
          .map((p) => {
                'id': p['id']?.toString() ?? '',
                'title': p['title']?.toString() ?? 'عقار',
              }));
    }

    if (mounted) {
      setState(() {
        _properties = props;
        if (props.isNotEmpty) {
          _selectedPropertyId = props.first['id']?.toString();
          _selectedPropertyTitle = props.first['title']?.toString() ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('طلب صيانة جديد'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EjariSurfaceCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'اختر العقار ونوع المشكلة — سيتم إرسال الطلب للمالك والإدارة وتعيين فني.',
                        style: TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const EjariSectionHeader(title: 'العقار المرتبط'),
              const SizedBox(height: 10),
              if (_properties.isEmpty)
                const Text('لا توجد عقارات — أضف حجزاً أولاً',
                    style: TextStyle(color: AppTheme.textSecondary))
              else
                DropdownButtonFormField<String>(
                  value: _selectedPropertyId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home_work_outlined),
                    labelText: 'اختر العقار',
                  ),
                  items: _properties
                      .map((p) => DropdownMenuItem(
                            value: p['id']?.toString(),
                            child: Text(p['title']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedPropertyId = v;
                    _selectedPropertyTitle = _properties
                        .firstWhere((p) => p['id'] == v,
                            orElse: () => {'title': ''})['title']
                        ?.toString() ?? '';
                  }),
                  validator: (v) => v == null ? 'اختر العقار' : null,
                ),
              const SizedBox(height: 20),
              const EjariSectionHeader(title: 'نوع المشكلة'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: MaintenanceService.categories.map((category) {
                  final isSelected = _selectedCategory == category['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category['icon'],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const EjariSectionHeader(title: 'الأولوية'),
              const SizedBox(height: 10),
              ...MaintenanceService.priorities.entries.map((entry) {
                final isSelected = _selectedPriority == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPriority = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentColor
                            : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: entry.key,
                          groupValue: _selectedPriority,
                          onChanged: (v) =>
                              setState(() => _selectedPriority = v!),
                          activeColor: AppTheme.primaryColor,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(
                                'وقت الاستجابة: ${entry.value['responseTime']}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المشكلة',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف المشكلة',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded,
                    color: AppTheme.primaryColor),
                title: const Text('الوقت المفضل'),
                subtitle: Text(_preferredTime == null
                    ? 'اختياري'
                    : _preferredTime!.toLocal().toString().substring(0, 16)),
                trailing: const Icon(Icons.chevron_left),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date == null || !mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _preferredTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              EjariSurfaceCard(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('صور المشكلة (اختياري)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    CameraCaptureWidget(
                      label: 'التقط صورة للمشكلة',
                      captureHint: 'استخدم الكاميرا فقط لتوثيق العطل',
                      icon: Icons.photo_camera_outlined,
                      onImageCaptured: (img) {
                        if (img == null) return;
                        setState(() {
                          if (_attachedImages.length < 3) {
                            _attachedImages.add(img);
                          }
                        });
                      },
                    ),
                    if (_attachedImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'تم إرفاق ${_attachedImages.length} صورة',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('إرسال الطلب',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
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
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    setState(() => _submitting = true);

    await MaintenanceService.createRequest(
      userId: user['email'],
      propertyId: _selectedPropertyId ?? 'none',
      propertyTitle: _selectedPropertyTitle,
      category: _selectedCategory!,
      priority: _selectedPriority,
      title: _titleController.text,
      description: _descriptionController.text,
      scheduledAt: _preferredTime?.toIso8601String(),
      images: _attachedImages.isEmpty ? null : _attachedImages,
      lat: 30.0444 + (DateTime.now().millisecond % 100) / 10000,
      lng: 31.2357 + (DateTime.now().microsecond % 100) / 10000,
    );

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الطلب — بانتظار التعيين ✅'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
