import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/ejari_section.dart';

/// شاشة تحقق المالك من QR الحجز — مسح بالكاميرا أو إدخال يدوي.
class OwnerQrVerifyScreen extends StatefulWidget {
  const OwnerQrVerifyScreen({super.key});

  @override
  State<OwnerQrVerifyScreen> createState() => _OwnerQrVerifyScreenState();
}

class _OwnerQrVerifyScreenState extends State<OwnerQrVerifyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _scanning = false;
  List<Map<String, dynamic>> _ownerBookings = [];

  static String get _scanTabHint => kIsWeb
      ? 'على الويب: الصق رمز الحجز في تبويب «يدوي» أو اختر حجزاً أدناه لمحاكاة المسح'
      : 'في النسخة التجريبية: اختر حجزاً أدناه لمحاكاة المسح';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
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
        _scanning = false;
      });
    }
  }

  Future<void> _simulateCameraScan(Map<String, dynamic> booking) async {
    setState(() => _scanning = true);
    final qr = await BookingQrService.generateForBooking(booking);
    await _verifyFromInput(qr['qrData'] as String);
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
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_scanning)
                        const CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded,
                                color: AppTheme.accentColor.withOpacity(0.8),
                                size: 56),
                            const SizedBox(height: 8),
                            Text(
                              kIsWeb
                                  ? 'الكاميرا غير متاحة على الويب'
                                  : 'وجّه الكاميرا نحو رمز QR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
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
                            border: Border.all(
                              color: AppTheme.accentColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _scanTabHint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _tabs.animateTo(0),
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    label: const Text('الصق رمز الحجز'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EjariSectionHeader(
            title: 'حجوزات للمسح',
            subtitle: 'اضغط لمحاكاة مسح QR',
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
                      child: const Text('مسح', style: TextStyle(fontSize: 11)),
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
            _detailRow('حالة الحجز', _result!['bookingStatus']?.toString()),
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
