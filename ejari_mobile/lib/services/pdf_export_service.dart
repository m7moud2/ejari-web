import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payment_receipt.dart';

/// تصدير إيصالات وعقود بصيغة PDF — مشاركة أو تحميل.
class PdfExportService {
  PdfExportService._();

  static pw.Font? _arabicFont;

  static Future<pw.Font> _loadArabicFont() async {
    _arabicFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'),
    );
    return _arabicFont!;
  }

  static pw.TextStyle _style(pw.Font font, {double size = 12, bool bold = false}) {
    return pw.TextStyle(
      font: font,
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  /// مشاركة إيصال دفع كملف PDF.
  static Future<void> shareReceiptPdf(PaymentReceipt receipt) async {
    final font = await _loadArabicFont();
    final dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(receipt.date);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('إيجاري — إيصال دفع', style: _style(font, size: 22, bold: true)),
              pw.SizedBox(height: 6),
              pw.Text('إيصال ديجيتال موثق', style: _style(font, size: 11)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              _pdfRow(font, 'رقم الإيصال', receipt.id),
              _pdfRow(font, 'المبلغ', '${receipt.amount.toStringAsFixed(0)} ج.م', bold: true),
              _pdfRow(font, 'التاريخ', dateStr),
              _pdfRow(font, 'مرجع الحجز', receipt.bookingRef),
              _pdfRow(font, 'الدافع', receipt.payer),
              _pdfRow(font, 'المستلم', receipt.payee),
              _pdfRow(font, 'وسيلة الدفع', receipt.methodLabelAr),
              if (receipt.title != null) _pdfRow(font, 'الوصف', receipt.title!),
              _pdfRow(
                font,
                'الحالة',
                receipt.status == 'completed' ? 'مكتمل' : receipt.status,
              ),
              pw.Spacer(),
              pw.Text(
                'هذا إيصال تجريبي — في الإنتاج يُربط ببوابة الدفع.',
                style: _style(font, size: 9),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ejari_receipt_${receipt.id}.pdf',
    );
  }

  /// مشاركة عقد إيجار كملف PDF.
  static Future<void> shareContractPdf({
    required String contractText,
    required String contractNumber,
    String title = 'عقد إيجار إيجاري',
  }) async {
    final font = await _loadArabicFont();
    final pdf = pw.Document();
    final lines = contractText.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Text(title, style: _style(font, size: 20, bold: true)),
          pw.SizedBox(height: 4),
          pw.Text('رقم العقد: $contractNumber', style: _style(font, size: 11)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                line.trim().isEmpty ? ' ' : line,
                style: _style(font, size: 11),
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'وثيقة تجريبية — للعرض والمراجعة فقط.',
            style: _style(font, size: 9),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ejari_contract_$contractNumber.pdf',
    );
  }

  /// مشاركة التقرير اليومي للإدارة كملف PDF.
  static Future<void> shareAdminDailyReportPdf(
    Map<String, dynamic> report,
  ) async {
    final font = await _loadArabicFont();
    final generatedAt = report['generatedAt']?.toString() ?? '';
    final dateLabel = generatedAt.length >= 10
        ? generatedAt.substring(0, 10)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'إيجاري — التقرير اليومي',
                style: _style(font, size: 22, bold: true),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                report['reportLabel']?.toString() ?? 'تقرير يومي — $dateLabel',
                style: _style(font, size: 11),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              pw.Text(
                'ملخص المنصة',
                style: _style(font, size: 14, bold: true),
              ),
              pw.SizedBox(height: 8),
              _pdfRow(font, 'إجمالي المستخدمين', '${report['totalUsers'] ?? 0}'),
              _pdfRow(
                font,
                'حجوزات اليوم',
                '${report['todayBookings'] ?? 0}',
                bold: true,
              ),
              _pdfRow(
                font,
                'إيراد المنصة',
                '${report['platformRevenue'] ?? 0} ج.م',
                bold: true,
              ),
              _pdfRow(font, 'نزاعات مفتوحة', '${report['openDisputes'] ?? 0}'),
              _pdfRow(
                font,
                'توثيقات KYC معلّقة',
                '${report['pendingVerifications'] ?? 0}',
              ),
              _pdfRow(
                font,
                'مدفوعات معلّقة',
                '${report['pendingPayments'] ?? 0}',
              ),
              _pdfRow(
                font,
                'تصعيدات البوت',
                '${report['botEscalations'] ?? 0}',
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'تفاصيل إضافية',
                style: _style(font, size: 14, bold: true),
              ),
              pw.SizedBox(height: 8),
              _pdfRow(font, 'مستأجرين', '${report['tenantsCount'] ?? 0}'),
              _pdfRow(font, 'ملاك', '${report['ownersCount'] ?? 0}'),
              _pdfRow(font, 'فنيين', '${report['techniciansCount'] ?? 0}'),
              _pdfRow(
                font,
                'رصيد الضمان',
                '${report['escrowBalance'] ?? 0} ج.م',
              ),
              _pdfRow(
                font,
                'صيانة جارية',
                '${report['activeMaintenance'] ?? 0}',
              ),
              pw.Spacer(),
              pw.Text(
                'تقرير تجريبي — يُولَّد تلقائياً من لوحة الإدارة.',
                style: _style(font, size: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'تاريخ التوليد: $generatedAt',
                style: _style(font, size: 9),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ejari_daily_report_$dateLabel.pdf',
    );
  }

  static pw.Widget _pdfRow(
    pw.Font font,
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(label, style: _style(font, size: 11)),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: _style(font, size: 11, bold: bold),
            ),
          ),
        ],
      ),
    );
  }
}
