import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking_status.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../widgets/ejari_section.dart';
import 'payment_screen.dart';

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
  bool get _showLiveQr => _ready || _alreadyIn;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final qr = await BookingQrService.generateForBooking(widget.booking);
    if (mounted) setState(() => _qr = qr);
  }

  double get _payAmount {
    final raw = widget.booking['remainingAmount'] ??
        widget.booking['depositAmount'] ??
        widget.booking['preEntryAmount'] ??
        widget.booking['price'] ??
        0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
  }

  void _openPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'property',
          itemData: widget.booking,
          amount: _payAmount > 0 ? _payAmount : 500,
          paymentStage: widget.booking['status']?.toString() ==
                  BookingStatus.approved
              ? 'remaining'
              : 'deposit',
        ),
      ),
    );
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
                  if (!_showLiveQr)
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
                  if (!_showLiveQr) const SizedBox(height: 12),
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
                          subtitle: _showLiveQr
                              ? 'اعرض هذا الرمز للمالك عند الاستلام'
                              : 'الرمز غير مفعّل بعد — أكمل الدفع أولاً',
                        ),
                        const SizedBox(height: 20),
                        if (_showLiveQr) ...[
                          Container(
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
                        ] else ...[
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.borderColor.withOpacity(0.35),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 48,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'QR مقفل\nحتى اكتمال الدفع والموافقة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'معرّف الحجز: ${_qr!['bookingId']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: AppTheme.ctaHeight,
                            child: ElevatedButton.icon(
                              onPressed: _openPayment,
                              icon: const Icon(Icons.payment_rounded),
                              label: Text(
                                status == BookingStatus.approved
                                    ? 'إكمال الدفع لتفعيل الرمز'
                                    : 'الدفع الآن لتفعيل الرمز',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EjariSurfaceCard(
                    elevated: false,
                    child: Text(
                      _showLiveQr
                          ? 'المالك يمسح الرمز من شاشة «التحقق من QR» ثم يضغط '
                              '«تأكيد الاستلام» لتسجيل دخولك.'
                          : 'لن يظهر رمز قابل للمسح قبل تفعيل الحجز — تجنّباً للالتباس.',
                      style: const TextStyle(
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
