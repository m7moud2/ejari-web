import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'signature_screen.dart';

class ContractScreen extends StatefulWidget {
  final String? contractId;
  final String ownerName;
  final String tenantName;
  final String propertyTitle;
  final String price;
  final String startDate;
  final String duration;
  final String? address;
  final String? deposit;
  final bool signedByOwner;
  final bool signedByTenant;
  final bool isOwner;
  final String itemLabel; // 'العقار' or 'السيارة'

  const ContractScreen({
    super.key,
    this.contractId,
    required this.ownerName,
    required this.tenantName,
    required this.propertyTitle,
    required this.price,
    required this.startDate,
    required this.duration,
    this.address,
    this.deposit,
    this.signedByOwner = false,
    this.signedByTenant = false,
    this.isOwner = false,
    this.itemLabel = 'العقار',
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _isAgreed = false;
  bool _isElectronicSigned = false; // Electronic (Tap/Token)
  List<Offset?> _manualSignaturePoints = []; // Manual (Handwritten)

  bool get _isFullySigned =>
      _isElectronicSigned && _manualSignaturePoints.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Pre-fill signature state if already signed
    if ((widget.isOwner && widget.signedByOwner) ||
        (!widget.isOwner && widget.signedByTenant)) {
      _isElectronicSigned = true;
      // We assume manual signature is already done if signed (simulation)
      // For now we won't restore points as we don't save them in this demo flow yet,
      // but we can set a dummy point to satisfy validation if viewing history.
      // But typically this screen is for Signing.
      _isAgreed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('توقيع العقد الإلكتروني ✍️'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(
                      icon: Icons.gavel,
                      title: 'عقد ملزم وواضح',
                      message:
                          'هذا العقد يحفظ حقوق الطرفين ويعرض البنود الأساسية بشكل واضح قبل الاعتماد.',
                    ),
                    const SizedBox(height: 14),
                    _buildInfoBanner(
                      icon: Icons.shield_rounded,
                      title: 'كيو كوسيط منظم',
                      message:
                          'نوضح المال، التوقيع، والمتابعة في مسار واحد حتى تكون الخطوة التالية مفهومة.',
                      filled: true,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.backgroundColor),
                      ),
                      child: Column(
                        children: [
                          const Text('ملخص العقد',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildSummaryChip('الطرف الأول', widget.ownerName),
                              _buildSummaryChip(
                                  'الطرف الثاني', widget.tenantName),
                              _buildSummaryChip('النوع', widget.itemLabel),
                              _buildSummaryChip('المدة', widget.duration),
                              _buildSummaryChip('البدء', widget.startDate),
                              _buildSummaryChip('القيمة', '${widget.price} ج.م'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.backgroundColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Column(
                              children: [
                                Text('عقد إيجار إلكتروني موثق',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary)),
                                SizedBox(height: 4),
                                Text(
                                    'وفقاً لقوانين وزارة الإسكان والمرافق والمجتمعات العمرانية',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primaryColor)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          _buildContractRow(
                              'الطرف الأول (المؤجر):', widget.ownerName),
                          _buildContractRow(
                              'الطرف الثاني (المستأجر):', widget.tenantName),
                          const Divider(),
                          _buildContractRow(
                              '${widget.itemLabel}:', widget.propertyTitle),
                          _buildContractRow('مدة الإيجار:', widget.duration),
                          _buildContractRow('تاريخ البدء:', widget.startDate),
                          _buildContractRow(
                              'القيمة الكيوة:', '${widget.price} ج.م'),
                          if (widget.deposit != null) ...[
                            _buildContractRow(
                                'العربون:', '${widget.deposit} ج.م'),
                          ],
                          const Divider(),
                          const SizedBox(height: 10),
                          const Text('البنود القانونية الملزمة:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          const SizedBox(height: 12),
                          Text(
                            'المادة الأولى: يقر الطرف الثاني بمعاينة ${widget.itemLabel} المعاينة التامة النافية للجهالة وقبوله بالحالة التي عليها.\n'
                            'المادة الثانية: يلتزم الطرف الثاني بسداد القيمة المتفق عليها عبر منصة كيو في المواعيد المحددة.\n'
                            'المادة الثالثة: منصة كيو هي الوسيط التكنولوجي والضامن المالي، ويعد التوقيع الإلكتروني عبرها بمثابة توقيع رسمي موثق داخل المنصة.\n'
                            'المادة الرابعة: يلتزم الطرف الأول بصيانة الأجزاء الهيكلية والمرافق الأساسية للوحدة لضمان انتفاع الطرف الثاني بها.\n'
                            'المادة الخامسة: في حالة الإخلال بأي بند، يحق للمنصة اتخاذ الإجراءات اللازمة لاسترداد الحقوق وفق السياسة المعتمدة.',
                            style: const TextStyle(
                                height: 1.8,
                                fontSize: 12,
                                color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('قبل الاعتماد',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          SizedBox(height: 10),
                          Text(
                            '• اقرأ البنود الأساسية جيداً.\n'
                            '• تأكد من الاسم والمدة والقيمة.\n'
                            '• بعد الاعتماد، ستنتقل للخطوة التالية في المتابعة.',
                            style: TextStyle(
                              height: 1.7,
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                      value: _isAgreed,
                      onChanged: (value) =>
                          setState(() => _isAgreed = value ?? false),
                      title: const Text(
                          'أوافق على الشروط والأحكام وأقر بصحة البيانات.'),
                      activeColor: AppTheme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.draw, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('1. التوقيع اليدوي (مطلوب)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignatureScreen(
                              onSigned: (points) {
                                setState(() => _manualSignaturePoints = points);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: _manualSignaturePoints.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CustomPaint(
                                  painter: SignaturePainter(
                                      _manualSignaturePoints),
                                  size: Size.infinite,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.touch_app,
                                      color: AppTheme.primaryColor, size: 40),
                                  SizedBox(height: 8),
                                  Text('اضغط هنا لرسم توقيعك',
                                      style: TextStyle(
                                          color: AppTheme.primaryColor)),
                                ],
                              ),
                      ),
                    ),
                    if (_manualSignaturePoints.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('تم التوقيع اليدوي بنجاح ✅',
                            style: TextStyle(
                                color: AppTheme.primaryColor, fontSize: 12)),
                      ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Icon(Icons.fingerprint, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text('2. التوقيع الإلكتروني (مطلوب)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        if (!_isAgreed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('يجب الموافقة على الشروط أولاً')),
                          );
                          return;
                        }
                        setState(
                            () => _isElectronicSigned = !_isElectronicSigned);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isElectronicSigned
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fingerprint,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isElectronicSigned
                                      ? 'تم التوقيع الإلكتروني'
                                      : 'اضغط للتوقيع الإلكتروني',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isElectronicSigned
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                if (_isElectronicSigned)
                                  Text(
                                    'Signed by: ${widget.tenantName}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.8)),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            if (_isElectronicSigned)
                              const Icon(Icons.check_circle,
                                  color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isAgreed && _isFullySigned)
                            ? () => Navigator.pop(context, true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('اعتماد العقد والمتابعة',
                            style: TextStyle(
                                fontSize: 18, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String title,
    required String message,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: filled
            ? AppTheme.primaryColor.withOpacity(0.06)
            : AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContractRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
