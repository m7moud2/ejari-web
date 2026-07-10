import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/insurance_service.dart';

class InsuranceSelectionScreen extends StatefulWidget {
  final double rentalPrice;
  final String bookingId;

  const InsuranceSelectionScreen({
    super.key,
    required this.rentalPrice,
    required this.bookingId,
  });

  @override
  State<InsuranceSelectionScreen> createState() =>
      _InsuranceSelectionScreenState();
}

class _InsuranceSelectionScreenState extends State<InsuranceSelectionScreen> {
  String? _selectedInsurance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر باقة التأمين 🛡️')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: const Column(
              children: [
                Icon(Icons.security, size: 60, color: AppTheme.primaryColor),
                SizedBox(height: 12),
                Text(
                  'احمِ استثمارك',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'اختر باقة التأمين المناسبة لحماية حقوقك المالية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInsuranceCard('property_damage'),
                _buildInsuranceCard('theft'),
                _buildInsuranceCard('liability'),
                _buildInsuranceCard('comprehensive'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يمكنك تخطي التأمين، لكن ننصح بشدة باختيار باقة مناسبة لحماية حقوقك.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              boxShadow: const [],
            ),
            child: Column(
              children: [
                if (_selectedInsurance != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تكلفة التأمين:',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        '${InsuranceService.calculateInsuranceCost(_selectedInsurance!, widget.rentalPrice).toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.textSecondary),
                        ),
                        child: const Text('تخطي'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedInsurance == null
                            ? null
                            : () => Navigator.pop(context, _selectedInsurance),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('متابعة',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceCard(String insuranceType) {
    final insurance = InsuranceService.insuranceTypes[insuranceType]!;
    final isSelected = _selectedInsurance == insuranceType;
    final cost = InsuranceService.calculateInsuranceCost(
        insuranceType, widget.rentalPrice);

    return GestureDetector(
      onTap: () => setState(() => _selectedInsurance = insuranceType),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insurance['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        insurance['description'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primaryColor, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التغطية',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      'حتى ${insurance['coverage']} ج.م',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('التكلفة',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '${cost.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
