/// سجل إيصال دفع موثق — يُنشأ بعد كل عملية دفع ناجحة.
class PaymentReceipt {
  final String id;
  final double amount;
  final DateTime date;
  final String bookingRef;
  final String payer;
  final String payee;
  final String method;
  final String status;
  final String? title;

  const PaymentReceipt({
    required this.id,
    required this.amount,
    required this.date,
    required this.bookingRef,
    required this.payer,
    required this.payee,
    required this.method,
    this.status = 'completed',
    this.title,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'bookingRef': bookingRef,
        'payer': payer,
        'payee': payee,
        'method': method,
        'status': status,
        if (title != null) 'title': title,
      };

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) => PaymentReceipt(
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ??
            DateTime.now(),
        bookingRef: json['bookingRef']?.toString() ?? '',
        payer: json['payer']?.toString() ?? '',
        payee: json['payee']?.toString() ?? '',
        method: json['method']?.toString() ?? '',
        status: json['status']?.toString() ?? 'completed',
        title: json['title']?.toString(),
      );

  String get methodLabelAr {
    switch (method) {
      case 'wallet':
        return 'محفظة إيجاري';
      case 'card':
      case 'cards':
      case 'visa':
        return 'بطاقة بنكية';
      case 'vodafone':
        return 'Vodafone Cash';
      case 'instapay':
        return 'InstaPay';
      case 'fawry':
        return 'فوري';
      case 'orange':
        return 'Orange Cash';
      default:
        return method;
    }
  }
}
