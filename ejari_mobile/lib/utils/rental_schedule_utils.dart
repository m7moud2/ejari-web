import 'dart:math' as math;

import 'date_utils.dart';

class RentalScheduleUtils {
  static double _toDouble(dynamic raw, {double fallback = 0}) {
    if (raw == null) return fallback;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? fallback;
  }

  static int parseLeaseMonths(dynamic raw, {int fallback = 1}) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return fallback;

    final numberMatch = RegExp(r'(\d+)').firstMatch(text);
    final count = int.tryParse(numberMatch?.group(1) ?? '') ?? fallback;

    if (text.contains('سنة')) return math.max(1, count * 12);
    if (text.contains('شهر')) return math.max(1, count);
    if (text.contains('أسبوع')) return math.max(1, ((count * 7) / 30).ceil());
    if (text.contains('يوم')) return math.max(1, (count / 30).ceil());

    return math.max(1, count);
  }

  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day, date.hour,
        date.minute, date.second, date.millisecond, date.microsecond);
  }

  static int elapsedMonths(DateTime start, DateTime now) {
    final years = now.year - start.year;
    final months = now.month - start.month;
    var total = years * 12 + months;
    if (now.day < start.day) total -= 1;
    return math.max(0, total);
  }

  static Map<String, dynamic> buildLeaseSnapshot(
    Map<String, dynamic> booking, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthlyRent = _toDouble(
      booking['monthlyRent'] ?? booking['price'] ?? booking['amount'],
      fallback: 0,
    );
    final leaseMonths = parseLeaseMonths(
      booking['leaseMonths'] ?? booking['duration'],
      fallback: 1,
    );
    final startDate =
        DateParsing.parse(booking['leaseStartDate'] ?? booking['startDate']) ??
            current;
    final endDate =
        DateParsing.parse(booking['leaseEndDate'] ?? booking['endDate']) ??
            addMonths(startDate, leaseMonths);
    final elapsed = math.min(leaseMonths, elapsedMonths(startDate, current));
    final remaining = math.max(leaseMonths - elapsed, 0);
    final nextDueDate = current.isBefore(startDate)
        ? startDate
        : addMonths(startDate, math.min(elapsed + 1, leaseMonths));
    final phase = (booking['paymentPhase'] ?? '').toString();
    final isFirstMonthPending = phase == 'deposit' ||
        booking['status'] == 'viewing_scheduled' ||
        booking['status'] == 'deposit_paid';
    final nextDueAmount = isFirstMonthPending
        ? _toDouble(
            booking['remainingAmount'] ?? monthlyRent,
            fallback: monthlyRent,
          )
        : monthlyRent;

    return {
      'monthlyRent': monthlyRent,
      'leaseMonths': leaseMonths,
      'startDate': startDate,
      'endDate': endDate,
      'elapsedMonths': elapsed,
      'remainingMonths': remaining,
      'progress': leaseMonths == 0 ? 0.0 : elapsed / leaseMonths,
      'nextDueDate': nextDueDate,
      'nextDueAmount': nextDueAmount,
      'depositAmount': _toDouble(booking['depositAmount'], fallback: 0),
      'remainingAmount': _toDouble(
        booking['remainingAmount'],
        fallback: monthlyRent > 0
            ? math.max(monthlyRent - _toDouble(booking['depositAmount']),
                0)
            : 0,
      ),
    };
  }
}
