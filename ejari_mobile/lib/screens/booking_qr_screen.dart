import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../widgets/ejari_section.dart';

/// عرض QR للحجز — demo visual code.
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
                        _QrVisual(data: _qr!['qrData']?.toString() ?? ''),
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

class _QrVisual extends StatelessWidget {
  final String data;

  const _QrVisual({required this.data});

  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    const cells = 12;
    final hash = data.hashCode.abs();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cells,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: cells * cells,
        itemBuilder: (_, i) {
          final filled = ((hash >> (i % 30)) & 1) == 1 || i % 7 == 0;
          return Container(color: filled ? AppTheme.primaryColor : Colors.white);
        },
      ),
    );
  }
}
