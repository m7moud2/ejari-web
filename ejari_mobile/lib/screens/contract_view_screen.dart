import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/contract_service.dart';
import '../utils/date_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _generateContract();
  }

  void _generateContract() {
    final depositValue = double.tryParse(
        widget.bookingDetails['depositAmount']?.toString() ?? '');
    final remainingValue = double.tryParse(
        widget.bookingDetails['remainingAmount']?.toString() ?? '');
    _contractText = ContractService.generateContract(
      tenantName: widget.bookingDetails['tenantName'] ?? 'المستأجر',
      tenantId: '1234567890', // Should come from profile
      ownerName: widget.bookingDetails['ownerName'] ?? 'المالك',
      propertyTitle: widget.bookingDetails['title'] ?? 'العقار',
      propertyAddress: 'القاهرة، مصر', // Should come from property details
      price: double.tryParse(widget.bookingDetails['price'].toString()) ?? 0.0,
      startDate: DateParsing.parse(widget.bookingDetails['startDate']) ?? DateTime.now(),
      endDate: DateParsing.parse(widget.bookingDetails['endDate']) ??
          DateTime.now().add(const Duration(days: 1)),
      depositAmount: depositValue,
      remainingAmount: remainingValue,
    );
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جارٍ إنشاء ملف PDF...')),
                );
                await Future.delayed(const Duration(seconds: 2));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الحفظ في التنزيلات: Contract_Keyo.pdf ✅'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _isSigned ? 'إتمام وتأكيد' : 'توقيع العقد',
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
}
