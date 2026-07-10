import 'package:intl/intl.dart';

import '../utils/rental_pricing.dart';

class ContractService {
  static String generateContract({
    required String tenantName,
    required String tenantId,
    required String ownerName,
    required String propertyTitle,
    required String propertyAddress,
    required double price,
    required DateTime startDate,
    required DateTime endDate,
    String? durationLabel,
    String? durationUnit,
    int? durationCount,
    String? paymentSchedule,
    double? monthlyRent,
    int? leaseMonths,
    double? currentDueAmount,
    double? depositAmount,
    double? remainingAmount,
  }) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);
    final today = dateFormat.format(DateTime.now());
    final monthlyValue = monthlyRent ?? price;
    final monthsValue = leaseMonths ?? 1;
    final unit = durationUnit ?? 'شهر';
    final countValue = durationCount ?? monthsValue;
    double leaseTotal;
    double dueNow;

    if (unit.contains('يوم') || unit.contains('أسبوع')) {
      leaseTotal = RentalPricing.calculate(
        monthlyRent: monthlyValue,
        durationType: unit.contains('أسبوع') ? 'أسبوع' : 'يوم',
        durationCount: countValue,
      ).totalRent;
      dueNow = currentDueAmount ?? leaseTotal;
    } else if (unit.contains('سنة')) {
      leaseTotal = monthlyValue * 12 * countValue;
      dueNow = currentDueAmount ?? (monthlyValue * 12);
    } else {
      leaseTotal = monthlyValue * monthsValue;
      dueNow = currentDueAmount ?? monthlyValue;
    }

    final bookingDeposit = depositAmount ?? (dueNow * 0.10);
    final bookingRemaining = remainingAmount ??
        (dueNow - bookingDeposit).clamp(0, dueNow).toDouble();
    final chosenDuration = durationLabel ??
        '$countValue $unit';
    final cycleText = paymentSchedule ?? 'شهري';
    final rentLabel = unit.contains('يوم') || unit.contains('أسبوع')
        ? 'القيمة الإيجارية'
        : 'القيمة الإيجارية الشهرية';

    final continuationText = cycleText == 'شهري'
        ? 'ثم تستمر الدفعات شهرياً وفق العقد.'
        : 'ثم تستمر الدفعات وفق دورية السداد المختارة أعلاه.';

    return '''
عقد إيجار إلكتروني موثق
رقم العقد: ${DateTime.now().millisecondsSinceEpoch}
تاريخ التحريـر: $today

أولاً: أطراف العقد
1. الطرف الأول (المؤجر): $ownerName
2. الطرف الثاني (المستأجر): $tenantName - هوية رقم: $tenantId

ثانياً: موضوع العقد
أجر الطرف الأول للطرف الثاني القابل لذلك:
الوحدة: $propertyTitle
العنوان: $propertyAddress

ثالثاً: مدة الإيجار
تبدأ من تاريخ: $startStr
وتنتهي في تاريخ: $endStr
المدة المختارة: $chosenDuration
دورية السداد: $cycleText

رابعاً: قيمة العربون والرصيد المتبقي
اتفق الطرفان على أن تكون $rentLabel مبلغ وقدره ${monthlyValue.toStringAsFixed(0)} ج.م.
ويبلغ إجمالي مدة التعاقد التقديري ($monthsValue شهر/شهور) مبلغ ${leaseTotal.toStringAsFixed(0)} ج.م.
تم سداد عربون المعاينة المبدئي بقيمة ${bookingDeposit.toStringAsFixed(0)} ج.م عبر منصة "إيجاري".
ويتبقى مبلغ ${bookingRemaining.toStringAsFixed(0)} ج.م يتم سداده لاستكمال الدفعة التالية فقط، $continuationText

خامساً: التزامات الأطراف
1. يلتزم المستأجر بالمحافظة على العين المؤجرة واستخدامها في الغرض المخصص لها.
2. يلتزم المؤجر بتسليم العين المؤجرة في التاريخ المحدد وبحالة صالحة للاستخدام.
3. يظل العربون قابلاً للاسترداد إذا لم يتم الاتفاق النهائي أو لم تكتمل الصفقة وفق الشروط المتفق عليها.
4. منصة "إيجاري" تدير مسار الدفع بشكل واضح، وتحفظ التتبع المالي إلى حين الحسم النهائي.

سادساً: أحكام عامة
يخضع هذا العقد لقوانين الدولة، ويعتبر التوقيع الإلكتروني أدناه ملزماً للطرفين قانونياً.

----------------------------------------
توقيع الطرف الأول (المؤجر):                  توقيع الطرف الثاني (المستأجر):
[بانتظار التوقيع]                            [بانتظار التوقيع]
''';
  }

  /// HTML قابل للطباعة / تصدير PDF demo.
  static String generatePrintableHtml({
    required String contractText,
    required String contractNumber,
  }) {
    final escaped = contractText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br/>');
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8"/>
  <title>عقد إيجاري — $contractNumber</title>
  <style>
    body { font-family: Tajawal, Arial, sans-serif; padding: 40px; line-height: 1.8; }
    h1 { color: #0F3A30; border-bottom: 2px solid #B58D3D; padding-bottom: 12px; }
    .footer { margin-top: 40px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <h1>عقد إيجار إلكتروني — إيجاري</h1>
  <p><strong>رقم العقد:</strong> $contractNumber</p>
  <div>$escaped</div>
  <div class="footer">تم إنشاؤه عبر منصة إيجاري — نسخة demo للطباعة</div>
</body>
</html>''';
  }
}
