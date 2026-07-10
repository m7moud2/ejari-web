import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/smart_pricing_service.dart';
import '../services/auth_service.dart';
import '../utils/haptic_utils.dart';

class OwnerDiscountSchedulerScreen extends StatefulWidget {
  const OwnerDiscountSchedulerScreen({super.key});

  @override
  State<OwnerDiscountSchedulerScreen> createState() =>
      _OwnerDiscountSchedulerScreenState();
}

class _OwnerDiscountSchedulerScreenState
    extends State<OwnerDiscountSchedulerScreen> {
  int _vacantDays = 3;
  double _discountPct = 10;
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final config = await SmartPricingService.getDiscountScheduler(ownerId);
    if (mounted) {
      setState(() {
        _vacantDays = config['vacantDays'] as int? ?? 3;
        _discountPct = (config['discountPercent'] as num?)?.toDouble() ?? 10;
        _enabled = config['enabled'] == true;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    await SmartPricingService.saveDiscountScheduler(
      ownerId: ownerId,
      vacantDays: _vacantDays,
      discountPercent: _discountPct,
      enabled: _enabled,
    );
    HapticUtils.success();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ جدولة التخفيض التلقائي')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدولة التخفيض التلقائي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('تفعيل التخفيض التلقائي'),
                    subtitle: const Text(
                      'عند شغور السرير لعدة أيام يُطبّق تخفيض تلقائياً',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  const SizedBox(height: 16),
                  Text('أيام الشغور: $_vacantDays',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _vacantDays.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: '$_vacantDays',
                    onChanged: _enabled
                        ? (v) => setState(() => _vacantDays = v.round())
                        : null,
                  ),
                  Text('نسبة التخفيض: ${_discountPct.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _discountPct,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    label: '${_discountPct.toStringAsFixed(0)}%',
                    onChanged: _enabled
                        ? (v) => setState(() => _discountPct = v)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'مثال: إذا بقي السرير شاغراً $_vacantDays أيام → خصم ${_discountPct.toStringAsFixed(0)}% تلقائياً',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ الجدولة'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
