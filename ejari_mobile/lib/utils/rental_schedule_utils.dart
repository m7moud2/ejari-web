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

  static Map<String, dynamic> describeDuration(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    final numberMatch = RegExp(r'(\d+)').firstMatch(text);
    final count = int.tryParse(numberMatch?.group(1) ?? '') ?? 1;

    if (text.contains('يوم')) {
      return {
        'count': count,
        'unit': 'يوم',
        'cycle': 'يومي',
        'label': '$count يوم',
      };
    }
    if (text.contains('أسبوع')) {
      return {
        'count': count,
        'unit': 'أسبوع',
        'cycle': 'أسبوعي',
        'label': '$count أسبوع',
      };
    }
    if (text.contains('سنة')) {
      return {
        'count': count,
        'unit': 'سنة',
        'cycle': 'شهري',
        'label': '$count سنة',
      };
    }
    if (text.contains('شهر')) {
      return {
        'count': count,
        'unit': 'شهر',
        'cycle': 'شهري',
        'label': '$count شهر',
      };
    }
    return {
      'count': count,
      'unit': 'شهر',
      'cycle': 'شهري',
      'label': text.isEmpty ? '1 شهر' : text,
    };
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
    final durationMeta = describeDuration(
      booking['durationLabel'] ?? booking['duration'],
    );
    final durationUnit = durationMeta['unit']?.toString() ?? 'شهر';
    final durationCount = (durationMeta['count'] as num?)?.toInt() ?? 1;
    final startDate =
        DateParsing.parse(booking['leaseStartDate'] ?? booking['startDate']) ??
            current;
    final endDate =
        DateParsing.parse(booking['leaseEndDate'] ?? booking['endDate']) ??
            addMonths(startDate, leaseMonths);
    int totalUnits;
    int elapsed;
    int remaining;
    DateTime nextDueDate;

    if (durationUnit.contains('يوم')) {
      totalUnits = math.max(1, durationCount);
      elapsed = math.min(totalUnits, math.max(0, current.difference(startDate).inDays));
      remaining = math.max(totalUnits - elapsed, 0);
      nextDueDate = current.isBefore(startDate)
          ? startDate
          : startDate.add(Duration(days: math.min(elapsed + 1, totalUnits)));
    } else if (durationUnit.contains('أسبوع')) {
      totalUnits = math.max(1, durationCount);
      elapsed = math.min(
          totalUnits,
          math.max(0, (current.difference(startDate).inDays / 7).floor()));
      remaining = math.max(totalUnits - elapsed, 0);
      nextDueDate = current.isBefore(startDate)
          ? startDate
          : startDate.add(Duration(days: 7 * math.min(elapsed + 1, totalUnits)));
    } else {
      totalUnits = leaseMonths;
      elapsed = math.min(totalUnits, elapsedMonths(startDate, current));
      remaining = math.max(totalUnits - elapsed, 0);
      nextDueDate = current.isBefore(startDate)
          ? startDate
          : addMonths(startDate, math.min(elapsed + 1, totalUnits));
    }
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
      'durationUnit': durationUnit,
      'durationCount': durationCount,
      'startDate': startDate,
      'endDate': endDate,
      'elapsedMonths': elapsed,
      'remainingMonths': remaining,
      'totalUnits': totalUnits,
      'elapsedUnits': elapsed,
      'remainingUnits': remaining,
      'progress': totalUnits == 0 ? 0.0 : elapsed / totalUnits,
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
