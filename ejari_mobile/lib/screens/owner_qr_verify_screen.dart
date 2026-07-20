import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../services/check_in_out_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../models/booking_status.dart';
import '../widgets/ejari_section.dart';
import 'move_in_inspection_screen.dart';

/// شاشة تحقق المالك من QR الحجز — مسح بالكاميرا أو إدخال يدوي ثم تأكيد الاستلام.
class OwnerQrVerifyScreen extends StatefulWidget {
  const OwnerQrVerifyScreen({super.key});

  @override
  State<OwnerQrVerifyScreen> createState() => _OwnerQrVerifyScreenState();
}

class _OwnerQrVerifyScreenState extends State<OwnerQrVerifyScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _handoverLoading = false;
  bool _cameraActive = false;
  bool _cameraInitializing = false;
  String? _cameraError;
  bool _scanLock = false;
  MobileScannerController? _scannerController;
  List<Map<String, dynamic>> _ownerBookings = [];

  static const double _previewHeight = 280;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _loadBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final scanner = _scannerController;
    if (scanner == null || !_cameraActive) return;
    if (!scanner.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        scanner.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        scanner.stop();
    }
  }

  void _onTabChanged() {
    if (_tabs.index != 1 && _cameraActive) {
      _stopCameraScan();
    }
  }

  Future<void> _loadBookings() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['uid']?.toString() ??
        user?['email']?.toString() ??
        'owner@ejari.app';
    final bookings = await DataService.getOwnerBookings(ownerId);
    if (mounted) {
      setState(() => _ownerBookings = bookings.take(8).toList());
    }
  }

  Future<void> _verifyFromInput(String input) async {
    if (input.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    Map<String, dynamic> result;
    if (input.contains('|')) {
      result = await BookingQrService.verifyQrCode(input.trim());
    } else {
      result = await BookingQrService.verifyByBookingId(input.trim());
    }
    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
        _scanLock = false;
      });
    }
  }

  Future<void> _startCameraScan() async {
    setState(() {
      _cameraActive = true;
      _cameraInitializing = true;
      _cameraError = null;
      _scanLock = false;
      _result = null;
    });

    _scannerController ??= MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );

    try {
      await _scannerController!.start();
      if (mounted) {
        setState(() => _cameraInitializing = false);
      }
    } on MobileScannerException catch (e) {
      _handleCameraFailure(_cameraErrorMessage(e));
    } catch (_) {
      _handleCameraFailure(
        'تعذّر تشغيل الكاميرا. جرّب الإدخال اليدوي أو حدّث الصفحة.',
      );
    }
  }

  Future<void> _stopCameraScan() async {
    await _scannerController?.stop();
    if (mounted) {
      setState(() {
        _cameraActive = false;
        _cameraInitializing = false;
      });
    }
  }

  void _handleCameraFailure(String message) {
    if (!mounted) return;
    setState(() {
      _cameraActive = false;
      _cameraInitializing = false;
      _cameraError = message;
    });
  }

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'تم رفض إذن الكاميرا. فعّل الكاميرا من إعدادات المتصفح/الجهاز ثم أعد المحاولة، أو استخدم الإدخال اليدوي.';
      case MobileScannerErrorCode.unsupported:
        return 'الكاميرا غير متاحة على هذا الجهاز. استخدم الإدخال اليدوي.';
      default:
        return error.errorDetails?.message ??
            'تعذّر تشغيل الكاميرا. جرّب الإدخال اليدوي.';
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_scanLock || _loading || !_cameraActive) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _scanLock = true;
    _stopCameraScan();
    _verifyFromInput(raw);
  }

  Future<void> _simulateCameraScan(Map<String, dynamic> booking) async {
    final qr = await BookingQrService.generateForBooking(booking);
    await _verifyFromInput(qr['qrData'] as String);
  }

  Future<void> _confirmHandover() async {
    final bookingId = _result?['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty || _handoverLoading) return;

    setState(() => _handoverLoading = true);
    final result = await CheckInOutService.confirmHandover(bookingId);
    if (!mounted) return;

    setState(() {
      _handoverLoading = false;
      if (result['success'] == true) {
        _result = {
          ...?_result,
          'alreadyCheckedIn': true,
          'canConfirmHandover': false,
          'bookingStatus': BookingStatus.active,
          'bookingStatusLabel': BookingStatus.arabicLabel(BookingStatus.active),
          'message': result['message']?.toString() ?? 'تم تأكيد الاستلام ✓',
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? ''),
        backgroundColor: result['success'] == true
            ? AppTheme.primaryColor
            : AppTheme.errorColor,
      ),
    );

    if (result['success'] == true && mounted) {
      final goInspect = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم الاستلام'),
          content: const Text(
            'هل تريد فتح فحص الاستلام (صور الغرف) الآن؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لاحقاً'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('فتح الفحص'),
            ),
          ],
        ),
      );
      if (goInspect == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoveInInspectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('التحقق من QR'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.edit_rounded), text: 'يدوي'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'مسح'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildManualTab(),
          _buildCameraTab(),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EjariSurfaceCard(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: _previewHeight,
                    width: double.infinity,
                    child: _buildCameraPreview(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_cameraError != null) ...[
                  _cameraErrorBanner(),
                  const SizedBox(height: 10),
                ],
                if (_cameraActive)
                  OutlinedButton.icon(
                    onPressed: _cameraInitializing ? null : _stopCameraScan,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('إيقاف المسح'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _startCameraScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('بدء المسح'),
                  ),
                const SizedBox(height: 8),
                Text(
                  _cameraActive
                      ? 'وجّه الكاميرا نحو رمز QR — سيتم التحقق تلقائياً عند المسح'
                      : kIsWeb
                          ? 'اضغط «بدء المسح» للسماح بالكاميرا (localhost مدعوم)'
                          : 'اضغط «بدء المسح» لفتح الكاميرا ومسح رمز الحجز',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EjariSectionHeader(
            title: 'حجوزات للاختبار',
            subtitle: 'محاكاة مسح QR بدون كاميرا',
          ),
          const SizedBox(height: 8),
          if (_ownerBookings.isEmpty)
            const EjariSurfaceCard(
              elevated: false,
              child: Text(
                'لا توجد حجوزات نشطة للمسح.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            ..._ownerBookings.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EjariSurfaceCard(
                  elevated: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.qr_code_2_rounded,
                        color: AppTheme.primaryColor),
                    title: Text(
                      b['title']?.toString() ?? 'حجز',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${b['tenantName'] ?? 'مستأجر'} — ${b['id']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _simulateCameraScan(b),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('اختبار', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              );
            }),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _resultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraActive) {
      return Container(
        color: Colors.black87,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: AppTheme.accentColor.withOpacity(0.8), size: 56),
                const SizedBox(height: 8),
                Text(
                  'اضغط «بدء المسح» لفتح الكاميرا',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraInitializing || _scannerController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentColor),
              SizedBox(height: 12),
              Text(
                'جاري تشغيل الكاميرا…',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController!,
          onDetect: _handleBarcode,
          errorBuilder: (context, error, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _cameraActive) {
                _handleCameraFailure(_cameraErrorMessage(error));
              }
            });
            return Container(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _cameraErrorMessage(error),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
          placeholderBuilder: (context, child) {
            return Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
            );
          },
          overlayBuilder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Container(
                    width: constraints.maxWidth * 0.72,
                    height: constraints.maxHeight * 0.55,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.accentColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_loading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.accentColor),
                          SizedBox(height: 12),
                          Text(
                            'جاري التحقق…',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cameraErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: AppTheme.errorColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cameraError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _tabs.animateTo(0),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('الانتقال للإدخال اليدوي'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EjariSurfaceCard(
            elevated: false,
            child: Text(
              'أدخل معرّف الحجز (مثل demo_req_1) أو الصق رمز QR كاملاً للتحقق.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'مثال: demo_req_1 أو EJARI|...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.confirmation_number_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('demo_req_1'),
                onPressed: _loading
                    ? null
                    : () {
                        _controller.text = 'demo_req_1';
                        _verifyFromInput('demo_req_1');
                      },
              ),
              ActionChip(
                label: const Text('demo_bed_booking'),
                onPressed: _loading
                    ? null
                    : () {
                        _controller.text = 'demo_bed_booking';
                        _verifyFromInput('demo_bed_booking');
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                _loading ? null : () => _verifyFromInput(_controller.text),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تحقق'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _resultCard(),
          ],
        ],
      ),
    );
  }

  Widget _resultCard() {
    final valid = _result!['valid'] == true;
    final expired = _result!['expired'] == true;
    final color = valid
        ? const Color(0xFF2D6A5A)
        : expired
            ? Colors.orange.shade800
            : AppTheme.errorColor;

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                valid
                    ? Icons.check_circle_rounded
                    : expired
                        ? Icons.schedule_rounded
                        : Icons.cancel_rounded,
                color: color,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valid
                          ? 'صالح ✓'
                          : expired
                              ? 'منتهي ✗'
                              : 'غير صالح ✗',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                    Text(
                      _result!['message']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_result!['bookingId'] != null) ...[
            const Divider(height: 24),
            _detailRow('معرّف الحجز', _result!['bookingId']?.toString()),
            _detailRow('المستأجر', _result!['tenantName']?.toString()),
            _detailRow('العقار', _result!['propertyTitle']?.toString()),
            if (_result!['bedLabel'] != null)
              _detailRow('السرير', _result!['bedLabel']?.toString()),
            _detailRow('تاريخ الدخول', _formatDate(_result!['checkInDate'])),
            _detailRow('المدة', _result!['duration']?.toString()),
            _detailRow('حالة الدفع', _result!['paymentStatus']?.toString()),
            _detailRow(
              'حالة الحجز',
              _result!['bookingStatusLabel']?.toString() ??
                  BookingStatus.arabicLabel(
                    _result!['bookingStatus']?.toString(),
                  ),
            ),
          ],
          if (_result!['valid'] == true) ...[
            const SizedBox(height: 16),
            if (_result!['alreadyCheckedIn'] == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'تم تأكيد الاستلام وتسجيل دخول المستأجر مسبقاً.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_result!['canConfirmHandover'] == true)
              SizedBox(
                width: double.infinity,
                height: AppTheme.ctaHeight,
                child: ElevatedButton.icon(
                  onPressed: _handoverLoading ? null : _confirmHandover,
                  icon: _handoverLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.home_work_rounded, size: 20),
                  label: Text(
                    _handoverLoading
                        ? 'جاري تأكيد الاستلام…'
                        : 'تأكيد الاستلام وتسجيل الدخول',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  _result!['message']?.toString() ??
                      'الحجز غير جاهز للاستلام بعد.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
