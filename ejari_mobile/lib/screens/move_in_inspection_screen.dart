import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_widget.dart';

class MoveInInspectionScreen extends StatefulWidget {
  const MoveInInspectionScreen({super.key});

  @override
  State<MoveInInspectionScreen> createState() => _MoveInInspectionScreenState();
}

class _MoveInInspectionScreenState extends State<MoveInInspectionScreen> {
  int _currentStep = 0;

  // Data
  final Map<String, String?> _roomPhotos = {
    'الصالة': null,
    'المطبخ': null,
    'الحمام': null,
    'غرفة النوم': null,
  };

  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فحص الاستلام (Move-in Check)')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _submitInspection();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : Text(_currentStep == 2 ? 'اعتماد التقرير' : 'التالي'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('رجوع'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('إرشادات هامة ⚠️'),
            content: _buildGuidelines(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('توثيق الحالة 📸'),
            content: _buildPhotoUploads(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('ملاحظات إضافية 📝'),
            content: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'اكتب أي ملاحظات أو عيوب غير ظاهرة في الصور (مثل: خدوش في الباب، بقع في السجاد...)',
                border: OutlineInputBorder(),
              ),
            ),
            isActive: _currentStep >= 2,
            state: StepState.editing,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Text(
            'حفاظاً على حقوقك وحقوق المالك، يرجى اتباع الآتي:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.check_circle_outline,
                color: AppTheme.borderColor, size: 28),
            title: Text(
                'افحص جميع الغرف وتأكد من سلامة المرافق (الكهرباء، المياه).'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined,
                color: AppTheme.borderColor, size: 28),
            title: Text('صور أي تلفيات أو خدوش موجودة مسبقاً بشكل واضح.'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(Icons.shield_outlined,
                color: AppTheme.borderColor, size: 28),
            title: Text(
                'هذا التقرير هو المرجع الرسمي عند تسليم الشقة واسترداد التأمين.'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploads() {
    return Column(
      children: _roomPhotos.keys.map((room) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ImageUploadWidget(
            label: 'صورة $room',
            icon: Icons.camera_indoor,
            onImageSelected: (path) {
              setState(() => _roomPhotos[room] = path);
            },
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitInspection() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('تم الحفظ')
        ]),
        content: const Text(
            'تم حفظ تقرير الاستلام بنجاح. تم إرسال نسخة للمالك وتخزين نسخة في سجلاتك.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
