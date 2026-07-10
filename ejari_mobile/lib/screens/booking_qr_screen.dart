import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../widgets/ejari_section.dart';

/// عرض QR للحجز — payload حقيقي يمكن للمالك مسحه/التحقق منه.
class BookingQrScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingQrScreen({super.key, required this.booking});

  @override
  State<BookingQrScreen> createState() => _BookingQrScreenState();
}

class _BookingQrScreenState extends State<BookingQrScreen> {
  Map<String, dynamic>? _qr;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final qr = await BookingQrService.generateForBooking(widget.booking);
    setState(() => _qr = qr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('رمز QR للحجز'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _qr == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Column(
                children: [
                  EjariSurfaceCard(
                    child: Column(
                      children: [
                        EjariSectionHeader(
                          title: widget.booking['title']?.toString() ?? 'حجز',
                          subtitle: 'اعرض هذا الرمز للمالك عند الدخول',
                        ),
                        const SizedBox(height: 20),
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
                            size: 180,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const EjariSurfaceCard(
                    elevated: false,
                    child: Text(
                      'المالك يمسح هذا الرمز أو يدخل المعرّف للتحقق من هويتك.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
