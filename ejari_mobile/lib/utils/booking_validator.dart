import '../models/booking_status.dart';
import '../models/rental_duration_tier.dart';
import '../models/rental_pricing_tier.dart';
import 'rental_pricing.dart';
import 'rental_rules.dart';

/// Server-side validation for booking requests in demo mode.
class BookingValidator {
  BookingValidator._();

  static double parsePrice(dynamic raw) {
    return double.tryParse(
          raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
        ) ??
        0;
  }

  /// Recalculate expected totals from property base rent — prevents tampering.
  static Map<String, dynamic> resolvePricing({
    required double baseMonthlyRent,
    required String durationType,
    required int durationCount,
    double adminFeeRate = 0.05,
    double profitRate = 0.10,
    double insurance = 0,
  }) {
    final pricing = RentalPricing.calculate(
      monthlyRent: baseMonthlyRent,
      durationType: durationType,
      durationCount: durationCount,
    );
    final totalPrice = pricing.totalRent;

    final adminFees = totalPrice * adminFeeRate;
    final profit = totalPrice * profitRate;
    final currentMonthTotal = totalPrice + adminFees + profit + insurance;
    final tier = RentalRules.resolveTier(durationType, durationCount);
    final depositRate = RentalRules.advanceDepositRate(tier);
    var deposit = (currentMonthTotal * depositRate).roundToDouble();
    if (deposit < 500) deposit = 500;
    if (deposit > currentMonthTotal) deposit = currentMonthTotal;
    final remaining = (currentMonthTotal - deposit).clamp(0, currentMonthTotal);

    return {
      'monthlyRent': baseMonthlyRent,
      'totalPrice': totalPrice,
      'currentAmount': currentMonthTotal,
      'depositAmount': deposit,
      'remainingAmount': remaining,
      'leaseTotal': totalPrice,
      'rentalTier': tier.name,
      'rentalTierLabel': tier.arabicLabel,
      'pricingTier': pricing.tier.name,
      'pricingTierLabel': pricing.tier.arabicLabel,
      'effectiveDailyRate': pricing.effectiveDailyRate,
      'premiumDailyRate': pricing.premiumDailyRate,
      'savingsVsPremiumDaily': pricing.savingsVsPremiumDaily,
      'totalDays': pricing.totalDays,
      'requiresIncomeProof': RentalRules.requiresIncomeProof(tier),
      'requiresAdvanceDeposit': RentalRules.requiresAdvanceDeposit(tier),
      'showInstallments': RentalRules.showMonthlyInstallments(tier),
    };
  }

  static bool datesOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  static bool hasDateConflict({
    required List<Map<String, dynamic>> existingBookings,
    required String propertyId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBookingId,
  }) {
    const blocking = {
      BookingStatus.depositPaid,
      BookingStatus.viewingScheduled,
      BookingStatus.approved,
      BookingStatus.confirmed,
      BookingStatus.paid,
      BookingStatus.active,
      BookingStatus.corporatePending,
      BookingStatus.pending,
      BookingStatus.submitted,
    };

    for (final b in existingBookings) {
      final id = b['id']?.toString() ?? b['_id']?.toString();
      if (excludeBookingId != null && id == excludeBookingId) continue;

      final propId = b['propertyId']?.toString() ?? '';
      if (propId != propertyId) continue;

      final status = BookingStatus.normalize(b['status']?.toString());
      if (!blocking.contains(status)) continue;

      final bStart = DateTime.tryParse(
            b['leaseStartDate']?.toString() ??
                b['startDate']?.toString() ??
                b['checkInDate']?.toString() ??
                '',
          ) ??
          DateTime.now();
      final bEnd = DateTime.tryParse(
            b['leaseEndDate']?.toString() ??
                b['endDate']?.toString() ??
                '',
          ) ??
          bStart.add(const Duration(days: 30));

      if (datesOverlap(startDate, endDate, bStart, bEnd)) return true;
    }
    return false;
  }

  static bool isValidDateRange(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return false;
    if (start.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  static Map<String, dynamic>? validateDocuments({
    required RentalDurationTier tier,
    required Map<String, dynamic>? verification,
    bool corporateMode = false,
  }) {
    if (corporateMode) return null;
    if (!RentalRules.requiresIncomeProof(tier)) return null;

    final v = verification ?? {};
    final hasIncome = v['incomeLetter'] != null && v['bankStatement'] != null;
    final hasEmployment = v['employmentLetter'] != null;
    final hasId = v['idFront'] != null && v['idBack'] != null;

    if (!hasId) {
      return {'valid': false, 'message': 'يرجى إرفاق الهوية (وجهان)'};
    }
    if (!hasIncome || !hasEmployment) {
      return {
        'valid': false,
        'message': 'للإيجار ٦ شهور فأكثر: مستندات الدخل وعقد العمل مطلوبة',
      };
    }
    return null;
  }

  static Map<String, dynamic> validateRequest({
    required Map<String, dynamic> request,
    required List<Map<String, dynamic>> existingBookings,
    Map<String, dynamic>? property,
  }) {
    final propertyId =
        request['propertyId']?.toString() ?? request['id']?.toString() ?? '';
    if (propertyId.isEmpty) {
      return {'valid': false, 'message': 'معرّف العقار مطلوب'};
    }

    final start = DateTime.tryParse(
          request['leaseStartDate']?.toString() ??
              request['startDate']?.toString() ??
              request['checkInDate']?.toString() ??
              '',
        ) ??
        DateTime.now().add(const Duration(days: 3));
    final end = DateTime.tryParse(
          request['leaseEndDate']?.toString() ??
              request['endDate']?.toString() ??
              '',
        ) ??
        start.add(const Duration(days: 30));

    if (!isValidDateRange(start, end)) {
      return {'valid': false, 'message': 'تواريخ الحجز غير صالحة'};
    }

    if (hasDateConflict(
      existingBookings: existingBookings,
      propertyId: propertyId,
      startDate: start,
      endDate: end,
      excludeBookingId: request['id']?.toString(),
    )) {
      return {
        'valid': false,
        'message': 'الوحدة محجوزة في هذه الفترة — اختر تواريخاً أخرى',
      };
    }

    if (property != null) {
      final baseRent = parsePrice(property['price']);
      if (baseRent > 0) {
        final durationType =
            request['durationType']?.toString() ?? 'شهر';
        final durationCount =
            int.tryParse(request['durationCount']?.toString() ?? '') ??
                int.tryParse(request['leaseMonths']?.toString() ?? '') ??
                1;
        final expected = resolvePricing(
          baseMonthlyRent: baseRent,
          durationType: durationType,
          durationCount: durationCount,
          insurance: parsePrice(request['insuranceCost']),
        );

        final clientDeposit = parsePrice(request['depositAmount']);
        final clientMonthly = parsePrice(request['monthlyRent'] ?? request['price']);
        final tolerance = 50.0;

        if ((clientMonthly - baseRent).abs() > tolerance) {
          return {
            'valid': false,
            'message': 'سعر الإيجار لا يطابق سعر العقار — تم رفض الطلب',
            'corrected': expected,
          };
        }
        if ((clientDeposit - (expected['depositAmount'] as double)).abs() >
            tolerance) {
          return {
            'valid': false,
            'message': 'مبلغ العربون لا يطابق السعر المعتمد',
            'corrected': expected,
          };
        }
      }
    }

    final tierName = request['rentalTier']?.toString();
    if (tierName != null) {
      try {
        final tier = RentalDurationTier.values
            .firstWhere((t) => t.name == tierName);
        final docError = validateDocuments(
          tier: tier,
          verification: request['verification'] as Map<String, dynamic>?,
          corporateMode: request['bookingMode'] == 'corporate',
        );
        if (docError != null) return docError;
      } catch (_) {}
    }

    return {'valid': true};
  }
}
