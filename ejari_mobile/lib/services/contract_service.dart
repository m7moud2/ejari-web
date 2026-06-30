import 'package:intl/intl.dart';

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
    final leaseTotal = monthlyValue * monthsValue;
    final dueNow = currentDueAmount ?? monthlyValue;
    final bookingDeposit = depositAmount ?? (price * 0.10);
    final bookingRemaining = remainingAmount ??
        (dueNow - bookingDeposit).clamp(0, dueNow).toDouble();

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

رابعاً: قيمة العربون والرصيد المتبقي
اتفق الطرفان على أن تكون القيمة الإيجارية الشهرية مبلغ وقدره ${monthlyValue.toStringAsFixed(0)} ج.م.
ويبلغ إجمالي مدة التعاقد التقديري ($monthsValue شهر/شهور) مبلغ ${leaseTotal.toStringAsFixed(0)} ج.م.
تم سداد عربون المعاينة المبدئي بقيمة ${bookingDeposit.toStringAsFixed(0)} ج.م عبر منصة "إيجاري".
ويتبقى مبلغ ${bookingRemaining.toStringAsFixed(0)} ج.م يتم سداده لاستكمال دفعة الشهر الأول فقط، ثم تستمر الدفعات شهرياً وفق العقد.

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
}
