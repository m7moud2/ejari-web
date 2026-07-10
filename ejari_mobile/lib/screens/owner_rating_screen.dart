import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tenant_score_service.dart';

/// تقييم المالك من المستأجر — دقة، صدق السعر، احترام.
class OwnerRatingScreen extends StatefulWidget {
  final String ownerEmail;
  final String tenantEmail;
  final String? bookingId;

  const OwnerRatingScreen({
    super.key,
    required this.ownerEmail,
    required this.tenantEmail,
    this.bookingId,
  });

  @override
  State<OwnerRatingScreen> createState() => _OwnerRatingScreenState();
}

class _OwnerRatingScreenState extends State<OwnerRatingScreen> {
  double _accuracy = 4;
  double _priceHonesty = 4;
  double _respect = 4;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await TenantScoreService.rateOwner(
      ownerEmail: widget.ownerEmail,
      tenantEmail: widget.tenantEmail,
      accuracy: _accuracy,
      priceHonesty: _priceHonesty,
      respect: _respect,
      bookingId: widget.bookingId,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('شكراً — تم تسجيل تقييمك للمالك ⭐')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('قيّم المالك'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          children: [
            _slider('دقة الوصف', _accuracy, (v) => setState(() => _accuracy = v)),
            _slider('صدق السعر', _priceHonesty, (v) => setState(() => _priceHonesty = v)),
            _slider('الاحترام', _respect, (v) => setState(() => _respect = v)),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label — ${value.toStringAsFixed(1)}/5',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 8,
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
