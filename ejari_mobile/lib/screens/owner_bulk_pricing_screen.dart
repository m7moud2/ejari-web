import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../utils/haptic_utils.dart';

class OwnerBulkPricingScreen extends StatefulWidget {
  const OwnerBulkPricingScreen({super.key});

  @override
  State<OwnerBulkPricingScreen> createState() => _OwnerBulkPricingScreenState();
}

class _OwnerBulkPricingScreenState extends State<OwnerBulkPricingScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _loading = true;
  double _percentChange = 0;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final props = await DataService.getOwnerProperties(ownerId);
    final shared = props
        .where((p) => DataService.isSharedAccommodation(p))
        .toList();
    if (mounted) {
      setState(() {
        _properties = shared;
        _loading = false;
      });
    }
  }

  Future<void> _apply() async {
    if (_properties.isEmpty) return;
    setState(() => _applying = true);
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final result = await DataService.bulkUpdateBedPrices(
      ownerId: ownerId,
      percentChange: _percentChange,
    );
    HapticUtils.success();
    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث ${result['updated']} عقار بنسبة ${_percentChange.toStringAsFixed(0)}%',
          ),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث أسعار جماعي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حدّث أسعار كل الأسرّة في العقارات المشتركة دفعة واحدة',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'نسبة التغيير: ${_percentChange >= 0 ? '+' : ''}${_percentChange.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _percentChange,
                    min: -30,
                    max: 30,
                    divisions: 12,
                    label: '${_percentChange.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _percentChange = v),
                  ),
                  Text('${_properties.length} عقار مشترك متأثر',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applying || _properties.isEmpty ? null : _apply,
                      child: _applying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('تطبيق على الكل'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
