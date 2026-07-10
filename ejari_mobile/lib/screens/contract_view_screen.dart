import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/contract_service.dart';
import '../services/pdf_export_service.dart';
import '../utils/date_utils.dart';
import '../utils/rental_schedule_utils.dart';
import 'signature_screen.dart';

class ContractViewScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ContractViewScreen({super.key, required this.bookingDetails});

  @override
  State<ContractViewScreen> createState() => _ContractViewScreenState();
}

class _ContractViewScreenState extends State<ContractViewScreen> {
  bool _isSigned = false;
  late String _contractText;
  Map<String, dynamic> _leaseSnapshot = {};

  int _parseLeaseMonths(String? duration) {
    final text = duration ?? '';
    final numberMatch = RegExp(r'(\d+)').firstMatch(text);
    final count = int.tryParse(numberMatch?.group(1) ?? '') ?? 1;

    if (text.contains('سنة')) return count * 12;
    if (text.contains('شهر')) return count;
    if (text.contains('أسبوع')) {
      return ((count * 7) / 30).ceil().clamp(1, 12).toInt();
    }
    if (text.contains('يوم')) {
      return (count / 30).ceil().clamp(1, 12).toInt();
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _generateContract();
  }

  void _generateContract() {
    final monthlyValue = double.tryParse(
            widget.bookingDetails['monthlyRent']?.toString() ??
                widget.bookingDetails['price']?.toString() ??
                '0') ??
        0.0;
    final leaseMonths =
        _parseLeaseMonths(widget.bookingDetails['duration']?.toString());
    final depositValue = double.tryParse(
        widget.bookingDetails['depositAmount']?.toString() ?? '');
    final remainingValue = double.tryParse(
        widget.bookingDetails['remainingAmount']?.toString() ?? '');
    final durationLabel =
        widget.bookingDetails['durationLabel']?.toString() ??
            widget.bookingDetails['duration']?.toString() ??
            '$leaseMonths شهر';
    final paymentSchedule =
        widget.bookingDetails['paymentSchedule']?.toString() ?? 'شهري';
    final durationUnit = widget.bookingDetails['durationUnit']?.toString();
    final durationCount = int.tryParse(
            widget.bookingDetails['durationCount']?.toString() ?? '') ??
        leaseMonths;
    _contractText = ContractService.generateContract(
      tenantName: widget.bookingDetails['tenantName'] ?? 'المستأجر',
      tenantId: '1234567890', // Should come from profile
      ownerName: widget.bookingDetails['ownerName'] ?? 'المالك',
      propertyTitle: widget.bookingDetails['title'] ?? 'العقار',
      propertyAddress: 'القاهرة، مصر', // Should come from property details
      price: monthlyValue,
      startDate: DateParsing.parse(widget.bookingDetails['startDate']) ??
          DateTime.now(),
      endDate: DateParsing.parse(widget.bookingDetails['endDate']) ??
          DateTime.now().add(const Duration(days: 1)),
      monthlyRent: monthlyValue,
      leaseMonths: leaseMonths,
      durationLabel: durationLabel,
      durationUnit: durationUnit,
      durationCount: durationCount,
      paymentSchedule: paymentSchedule,
      currentDueAmount: double.tryParse(
              widget.bookingDetails['currentAmount']?.toString() ??
                  monthlyValue.toString()) ??
          monthlyValue,
      depositAmount: depositValue,
      remainingAmount: remainingValue,
    );
    _leaseSnapshot = RentalScheduleUtils.buildLeaseSnapshot(widget.bookingDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العقد الإلكتروني 📜'),
        centerTitle: true,
        actions: [
          if (_isSigned)
            IconButton(
              tooltip: 'تحميل نسخة PDF',
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                try {
                  await PdfExportService.shareContractPdf(
                    contractText: _contractText,
                    contractNumber: widget.bookingDetails['contractNumber']
                            ?.toString() ??
                        widget.bookingDetails['id']?.toString() ??
                        'CTR',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تعذّر إنشاء PDF: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        border: Border.all(color: AppTheme.primaryColor),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'هذه المعاينة تساعدك تراجع الحقوق والالتزامات بشكل واضح قبل الاعتماد النهائي.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLeaseTransparencyCard(),
                            const SizedBox(height: 16),
                            Text(
                              _contractText,
                              style: const TextStyle(fontSize: 14, height: 1.9),
                            ),
                            if (_isSigned) ...[
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AppTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'تم التوقيع إلكترونياً بواسطة المستأجر',
                                    style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'بتاريخ: ${DateTime.now().toString().split('.')[0]}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
                        Row(
                          children: [
                            Checkbox(
                                value: _isSigned,
                                onChanged: null), // Checked when signed
                            const Expanded(
                              child: Text(
                                'أقر بأنني قرأت كافة الشروط والأحكام وأوافق عليها.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSigned
                                ? () {
                                    Navigator.pop(context, true);
                                  }
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignatureScreen(
                                          onSigned: (points) {
                                            setState(() => _isSigned = true);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _isSigned ? 'إتمام وتأكيد' : 'اضغط للتوقيع (تجريبي)',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description_rounded,
              color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مراجعة العقد قبل الاعتماد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تأكد من البيانات الأساسية ثم أكمل التوقيع بثقة.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseTransparencyCard() {
    final totalMonths = (_leaseSnapshot['leaseMonths'] as num? ?? 1).toInt();
    final remainingMonths =
        (_leaseSnapshot['remainingMonths'] as num? ?? 0).toInt();
    final elapsedMonths =
        (_leaseSnapshot['elapsedMonths'] as num? ?? 0).toInt();
    final progress = ((_leaseSnapshot['progress'] as num?) ?? 0.0)
        .toDouble()
        .clamp(0.0, 1.0)
        .toDouble();
    final monthlyRent = (_leaseSnapshot['monthlyRent'] as num? ?? 0).toDouble();
    final nextDueAmount =
        (_leaseSnapshot['nextDueAmount'] as num? ?? 0).toDouble();
    final nextDueDate = DateParsing.display(
      _leaseSnapshot['nextDueDate'],
      fallback: 'قريباً',
      pattern: 'dd/MM/yyyy',
    );
    final durationLabel =
        widget.bookingDetails['durationLabel']?.toString() ??
            widget.bookingDetails['duration']?.toString() ??
            'شهر';
    final paymentSchedule =
        widget.bookingDetails['paymentSchedule']?.toString() ?? 'شهري';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_outlined,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'ملخص السداد الشفاف',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أنقضى $elapsedMonths من $totalMonths شهر • المتبقي $remainingMonths شهر',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المدة المختارة: $durationLabel • دورية السداد: $paymentSchedule',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _leaseChip('القسط الشهري', '${monthlyRent.toStringAsFixed(0)} ج.م'),
              _leaseChip('أقرب قسط', '${nextDueAmount.toStringAsFixed(0)} ج.م'),
              _leaseChip('موعد القسط', nextDueDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaseChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
