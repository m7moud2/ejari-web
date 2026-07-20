import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking_status.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../widgets/ejari_section.dart';

/// عرض QR للحجز — payload حقيقي يمكن للمالك مسحه/التحقق منه ثم تأكيد الاستلام.
class BookingQrScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingQrScreen({super.key, required this.booking});

  @override
  State<BookingQrScreen> createState() => _BookingQrScreenState();
}

class _BookingQrScreenState extends State<BookingQrScreen> {
  Map<String, dynamic>? _qr;
  bool get _ready => BookingQrService.isQrReady(widget.booking);
  bool get _alreadyIn => widget.booking['checkedInAt'] != null;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final qr = await BookingQrService.generateForBooking(widget.booking);
    if (mounted) setState(() => _qr = qr);
  }

  @override
  Widget build(BuildContext context) {
    final status = BookingStatus.normalize(widget.booking['status']?.toString());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('رمز QR للاستلام'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _qr == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Column(
                children: [
                  if (!_ready && !_alreadyIn)
                    EjariSurfaceCard(
                      elevated: false,
                      child: Text(
                        status == BookingStatus.approved
                            ? 'أكمل الدفع المتبقي أولاً لتفعيل رمز الاستلام.'
                            : 'رمز الاستلام يُفعَّل بعد اكتمال الدفع وموافقة المالك.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!_ready && !_alreadyIn) const SizedBox(height: 12),
                  if (_alreadyIn)
                    const EjariSurfaceCard(
                      elevated: false,
                      child: Text(
                        'تم تأكيد الاستلام مسبقاً — يمكنك عرض الرمز للمرجع فقط.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_alreadyIn) const SizedBox(height: 12),
                  EjariSurfaceCard(
                    child: Column(
                      children: [
                        EjariSectionHeader(
                          title: widget.booking['title']?.toString() ?? 'حجز',
                          subtitle: 'اعرض هذا الرمز للمالك عند الاستلام',
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: _ready || _alreadyIn ? 1 : 0.45,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: QrImageView(
                              data: _qr!['qrData']?.toString() ?? '',
                              version: QrVersions.auto,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                              size: 200,
                              gapless: true,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.primaryColor,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _qr!['displayCode']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'معرّف الحجز: ${_qr!['bookingId']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _qr!['qrData']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const EjariSurfaceCard(
                    elevated: false,
                    child: Text(
                      'المالك يمسح الرمز من شاشة «التحقق من QR» ثم يضغط '
                      '«تأكيد الاستلام» لتسجيل دخولك.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
