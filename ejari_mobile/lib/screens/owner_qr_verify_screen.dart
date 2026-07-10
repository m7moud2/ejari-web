import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/booking_qr_service.dart';
import '../widgets/ejari_section.dart';

/// شاشة تحقق المالك من QR الحجز.
class OwnerQrVerifyScreen extends StatefulWidget {
  const OwnerQrVerifyScreen({super.key});

  @override
  State<OwnerQrVerifyScreen> createState() => _OwnerQrVerifyScreenState();
}

class _OwnerQrVerifyScreenState extends State<OwnerQrVerifyScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    final input = _controller.text.trim();
    Map<String, dynamic> result;
    if (input.contains('|')) {
      result = await BookingQrService.verifyQrCode(input);
    } else {
      result = await BookingQrService.verifyByBookingId(input);
    }
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('التحقق من QR'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EjariSurfaceCard(
              elevated: false,
              child: Text(
                'امسح رمز QR للمستأجر أو أدخل معرّف الحجز للتحقق.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'معرّف الحجز أو رمز QR',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
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
              EjariSurfaceCard(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
