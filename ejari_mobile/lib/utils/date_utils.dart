import 'package:intl/intl.dart';

class DateParsing {
  static DateTime? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    final text = raw.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    final candidates = <String>{
      text,
      text.replaceAll('T', ' ').replaceAll('Z', ''),
      text.replaceAll('/', '-'),
      text.split(' - ').first.trim(),
    }.where((value) => value.isNotEmpty);

    const formats = <String>[
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy-MM-dd HH:mm',
      'yyyy/MM/dd HH:mm',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy-MM-dd hh:mm a',
      'yyyy/MM/dd hh:mm a',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm',
      'dd MMM yyyy',
      'dd MMM yyyy, hh:mm a',
      'dd MMM yyyy HH:mm',
    ];

    for (final candidate in candidates) {
      final direct = DateTime.tryParse(candidate);
      if (direct != null) return direct;

      for (final format in formats) {
        try {
          return DateFormat(format).parseLoose(candidate);
        } catch (_) {
          // Try next format.
        }
      }
    }

    return null;
  }

  static String display(
    dynamic raw, {
    String fallback = '—',
    String pattern = 'yyyy-MM-dd',
  }) {
    final parsed = parse(raw);
    if (parsed == null) return fallback;
    try {
      return DateFormat(pattern, 'ar').format(parsed);
    } catch (_) {
      return DateFormat(pattern).format(parsed);
    }
  }

  /// عرض عربي ودود للتواريخ (يوم/شهر/سنة + وقت اختياري).
  static String displayArabic(
    dynamic raw, {
    String fallback = '—',
    bool withTime = false,
  }) {
    final parsed = parse(raw);
    if (parsed == null) return fallback;
    final pattern = withTime ? 'd MMMM yyyy، HH:mm' : 'd MMMM yyyy';
    try {
      return DateFormat(pattern, 'ar').format(parsed.toLocal());
    } catch (_) {
      final d = parsed.toLocal();
      final base =
          '${d.day}/${d.month}/${d.year}';
      if (!withTime) return base;
      return '$base ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
  }

  static String toStorageIso(DateTime dt) => dt.toUtc().toIso8601String();

  /// يستخرج تاريخ الاستلام من حقول الحجز المترادفة.
  static DateTime? bookingCheckIn(Map<String, dynamic> booking) {
    return parse(
      booking['checkInDate'] ??
          booking['leaseStartDate'] ??
          booking['startDate'],
    );
  }

  /// يستخرج تاريخ المغادرة من حقول الحجز المترادفة.
  static DateTime? bookingCheckOut(Map<String, dynamic> booking) {
    return parse(
      booking['checkOutDate'] ??
          booking['leaseEndDate'] ??
          booking['endDate'],
    );
  }

  /// يوحّد حقول التواريخ على الحجز قبل الحفظ.
  static Map<String, dynamic> normalizeBookingDates(
    Map<String, dynamic> booking, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final created = parse(booking['createdAt'] ?? booking['requestDate']) ??
        current;
    final checkIn = bookingCheckIn(booking);
    final checkOut = bookingCheckOut(booking);

    booking['createdAt'] = toStorageIso(created);
    booking['requestDate'] =
        parse(booking['requestDate']) != null
            ? toStorageIso(parse(booking['requestDate'])!)
            : booking['createdAt'];

    if (checkIn != null) {
      final iso = toStorageIso(checkIn);
      booking['checkInDate'] = iso;
      booking['leaseStartDate'] = booking['leaseStartDate'] ?? iso;
      booking['startDate'] = booking['startDate'] ?? iso;
    }
    if (checkOut != null) {
      final iso = toStorageIso(checkOut);
      booking['checkOutDate'] = iso;
      booking['leaseEndDate'] = booking['leaseEndDate'] ?? iso;
      booking['endDate'] = booking['endDate'] ?? iso;
    }

    for (final key in [
      'approvedAt',
      'paidAt',
      'depositPaidAt',
      'cancelledAt',
      'rejectedAt',
      'completedAt',
      'refundedAt',
      'viewingScheduledAt',
      'activeAt',
      'checkedInAt',
      'checkedOutAt',
    ]) {
      final parsed = parse(booking[key]);
      if (parsed != null) {
        booking[key] = toStorageIso(parsed);
      } else if (booking[key] != null &&
          booking[key].toString().trim().isEmpty) {
        booking.remove(key);
      } else if (booking[key]?.toString().toLowerCase() == 'null') {
        booking.remove(key);
      }
    }

    return booking;
  }

  /// يبني تواريخ خطوات المسار زمنياً من الحجز.
  static Map<String, String?> timelineDatesForBooking(
    Map<String, dynamic> booking,
  ) {
    return {
      'submitted': displayArabic(
        booking['createdAt'] ?? booking['requestDate'],
        withTime: true,
      ),
      'deposit': displayArabic(
        booking['depositPaidAt'],
        withTime: true,
        fallback: '',
      ),
      'owner_approval': displayArabic(
        booking['approvedAt'] ?? booking['viewingScheduledAt'],
        withTime: true,
        fallback: '',
      ),
      'full_payment': displayArabic(
        booking['paidAt'],
        withTime: true,
        fallback: '',
      ),
      'contract': displayArabic(
        booking['paidAt'] ?? booking['approvedAt'],
        withTime: true,
        fallback: '',
      ),
      'qr': displayArabic(
        booking['paidAt'] ?? booking['confirmedAt'],
        withTime: true,
        fallback: '',
      ),
      'check_in': displayArabic(
        booking['checkedInAt'] ?? bookingCheckIn(booking),
        withTime: true,
        fallback: '',
      ),
      'stay': displayArabic(
        booking['checkedInAt'] ?? booking['activeAt'],
        withTime: true,
        fallback: '',
      ),
      'check_out': displayArabic(
        booking['checkedOutAt'] ?? bookingCheckOut(booking),
        withTime: true,
        fallback: '',
      ),
      'refund_rate': displayArabic(
        booking['refundedAt'] ?? booking['completedAt'],
        withTime: true,
        fallback: '',
      ),
      'rejected': displayArabic(
        booking['rejectedAt'],
        withTime: true,
        fallback: '',
      ),
      'cancelled': displayArabic(
        booking['cancelledAt'],
        withTime: true,
        fallback: '',
      ),
      'refund': displayArabic(
        booking['refundedAt'],
        withTime: true,
        fallback: '',
      ),
      'disputed': displayArabic(
        booking['disputedAt'],
        withTime: true,
        fallback: '',
      ),
    };
  }
}
