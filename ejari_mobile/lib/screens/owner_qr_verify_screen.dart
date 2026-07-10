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
    setState(() {
      _result = result;
      _loading = false;
      _scanning = false;
    });
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
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'مسح'),
            Tab(icon: Icon(Icons.edit_rounded), text: 'يدوي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCameraTab(),
          _buildManualTab(),
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
                              'وجّه الكاميرا نحو رمز QR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
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
                const Text(
                  'في النسخة التجريبية: اختر حجزاً أدناه لمحاكاة المسح',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
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
    return Padding(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EjariSurfaceCard(
            elevated: false,
            child: Text(
              'أدخل معرّف الحجز أو الصق رمز QR كاملاً للتحقق.',
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
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : () => _verifyFromInput(_controller.text),
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
    return EjariSurfaceCard(
      child: Column(
        children: [
          Icon(
            _result!['valid'] == true
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: _result!['valid'] == true
                ? const Color(0xFF2D6A5A)
                : AppTheme.errorColor,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _result!['message']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_result!['valid'] == true) ...[
            const SizedBox(height: 8),
            Text(
              '${_result!['tenantName']} — ${_result!['propertyTitle']}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
