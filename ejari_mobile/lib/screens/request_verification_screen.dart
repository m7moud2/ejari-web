import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../widgets/camera_capture_widget.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

class RequestVerificationScreen extends StatefulWidget {
  const RequestVerificationScreen({super.key});

  @override
  State<RequestVerificationScreen> createState() =>
      _RequestVerificationScreenState();
}

class _RequestVerificationScreenState extends State<RequestVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String? _idFront;
  String? _idBack;
  String? _selfie;
  String _docType = 'national_id';
  bool _isLoading = false;
  bool _isLoadingStatus = true;
  Map<String, String> _status = {'status': 'none', 'label': 'غير موثق'};
  Map<String, dynamic>? _submission;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? '';
    if (email.isEmpty) {
      setState(() => _isLoadingStatus = false);
      return;
    }

    final status = await DataService.getIdentityVerificationStatus(email);
    final submission = await DataService.getIdentityVerificationForUser(email);
    if (mounted) {
      setState(() {
        _status = status;
        _submission = submission;
        _phoneController.text = submission?['phone']?.toString() ?? '';
        _isLoadingStatus = false;
      });
    }
  }

  bool get _canSubmit {
    final status = _status['status'];
    return status == 'none' || status == 'rejected';
  }

  Future<void> _submitRequest() async {
    if (!_canSubmit) return;

    if (_idFront == null || _idBack == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التقاط صور البطاقة (الوجهين) والسيلفي'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await AuthService.getCurrentUser();
    final result = await DataService.submitIdentityVerification(
      userId: user?['id']?.toString() ?? user?['email']?.toString() ?? '',
      userName: user?['name']?.toString() ?? 'مستخدم',
      userType: user?['type']?.toString() ?? user?['role']?.toString() ?? 'tenant',
      email: user?['email']?.toString() ?? '',
      phone: _phoneController.text.trim(),
      idFront: _idFront!,
      idBack: _idBack!,
      selfie: _selfie!,
      docType: _docType,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'تعذر إرسال الطلب'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    await _loadStatus();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.primaryColor, size: 80),
            const SizedBox(height: 20),
            const Text(
              'تم إرسال طلب التوثيق! ✅',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'سيتم مراجعة الصور الملتقطة من قبل الإدارة وإشعارك بالنتيجة قريباً.',
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

  Color _statusColor() {
    switch (_status['status']) {
      case 'approved':
        return AppTheme.primaryColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'pending':
        return AppTheme.borderColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('توثيق الحساب'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingStatus
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    EjariSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EjariSectionHeader(
                            title: 'التقط مستنداتك',
                            subtitle:
                                'يجب التقاط الصور مباشرة من الكاميرا — لا يمكن رفع صور من المعرض.',
                          ),
                          const SizedBox(height: 16),
                          if (_canSubmit) ...[
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                prefixIcon: Icon(Icons.phone),
                                hintText: '01xxxxxxxxx',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 20),
                            const Text('نوع المستند',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _docChip('national_id', 'بطاقة'),
                                _docChip('passport', 'جواز'),
                                _docChip('license', 'رخصة'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CameraCaptureWidget(
                              label: _docFrontLabel(),
                              captureHint: 'وجّه الكاميرا نحو وجه البطاقة',
                              icon: Icons.badge_outlined,
                              onImageCaptured: (img) =>
                                  setState(() => _idFront = img),
                            ),
                            const SizedBox(height: 16),
                            CameraCaptureWidget(
                              label: _docBackLabel(),
                              captureHint: 'التقط الصورة من الكاميرا',
                              icon: Icons.credit_card_rounded,
                              onImageCaptured: (img) =>
                                  setState(() => _idBack = img),
                            ),
                            const SizedBox(height: 16),
                            CameraCaptureWidget(
                              label: 'صورة سيلفي',
                              captureHint: 'التقط صورة لوجهك بوضوح',
                              icon: Icons.face_retouching_natural_rounded,
                              useFrontCamera: true,
                              onImageCaptured: (img) =>
                                  setState(() => _selfie = img),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'إرسال للمراجعة',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ] else if (_status['status'] == 'pending') ...[
                            const Text(
                              'طلبك قيد المراجعة من قبل الإدارة. ستصلك إشعار بالنتيجة قريباً.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            if (_submission != null) ...[
                              const SizedBox(height: 16),
                              _buildSubmittedPreview(),
                            ],
                          ] else if (_status['status'] == 'approved') ...[
                            const Text(
                              'تم توثيق حسابك بنجاح. يمكنك الآن الاستفادة من كافة مميزات إيجاري.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final label = _status['label'] ?? 'غير موثق';
    final reason = _status['reason'];

    return EjariSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _status['status'] == 'approved'
                  ? Icons.verified_rounded
                  : Icons.verified_user_outlined,
              color: _statusColor(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حالة التوثيق',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(),
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'السبب: $reason',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docChip(String type, String label) {
    final selected = _docType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: _canSubmit ? (_) => setState(() => _docType = type) : null,
      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
    );
  }

  String _docFrontLabel() {
    switch (_docType) {
      case 'passport':
        return 'صفحة جواز السفر';
      case 'license':
        return 'وجه الرخصة';
      default:
        return 'وجه البطاقة الأمامي';
    }
  }

  String _docBackLabel() {
    switch (_docType) {
      case 'passport':
        return 'صفحة إضافية (إن وجدت)';
      case 'license':
        return 'ظهر الرخصة';
      default:
        return 'وجه البطاقة الخلفي';
    }
  }

  Widget _buildSubmittedPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الصور المرسلة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _previewTile('الأمام', _submission?['idFront']),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _previewTile('الخلف', _submission?['idBack']),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _previewTile('سيلفي', _submission?['selfie']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewTile(String label, String? data) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: data != null
                ? VerificationImage(data: data)
                : Container(color: AppTheme.backgroundColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
