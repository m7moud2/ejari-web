import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_status.dart';
import 'data_service.dart';
import 'wallet_service.dart';

/// تسجيل الدخول/الخروج وإطلاق العربون.
class CheckInOutService {
  CheckInOutService._();

  /// تسجيل دخول المستأجر.
  static Future<Map<String, dynamic>> checkIn(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    final status = BookingStatus.normalize(booking['status']?.toString());
    if (status != BookingStatus.approved &&
        status != BookingStatus.paid &&
        status != BookingStatus.active &&
        status != BookingStatus.confirmed) {
      return {
        'success': false,
        'message': 'لا يمكن تسجيل الدخول — الحجز غير مؤكد',
      };
    }

    if (booking['checkedInAt'] != null) {
      return {'success': false, 'message': 'تم تسجيل الدخول مسبقاً'};
    }

    final now = DateTime.now().toIso8601String();
    await DataService.updateBookingFields(bookingId, {
      'checkedInAt': now,
      'status': BookingStatus.active,
    });

    await DataService.addNotificationToUser(
      booking['ownerEmail']?.toString() ?? 'owner@ejari.app',
      'تسجيل دخول مستأجر 🏠',
      'قام ${booking['tenantName'] ?? 'المستأجر'} بتسجيل الدخول',
      type: 'check_in',
      refId: bookingId,
    );

    return {
      'success': true,
      'message': 'تم تسجيل الدخول بنجاح ✓',
      'checkedInAt': now,
    };
  }

  /// تسجيل خروج المستأجر — يطلق العربون إذا لم يكن هناك مطالبة أضرار.
  static Future<Map<String, dynamic>> checkOut(
    String bookingId, {
    bool damageClaimed = false,
  }) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    if (booking['checkedInAt'] == null) {
      return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
    }

    if (booking['checkedOutAt'] != null) {
      return {'success': false, 'message': 'تم تسجيل الخروج مسبقاً'};
    }

    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'checkedOutAt': now,
    };

    if (damageClaimed || booking['damageClaim'] == true) {
      updates['status'] = BookingStatus.disputed;
      updates['damageClaim'] = true;
      await DataService.updateBookingFields(bookingId, updates);
      await DataService.addNotificationToUser(
        booking['ownerEmail']?.toString() ?? '',
        'مطالبة أضرار — العربون محجوز ⚠️',
        'المستأجر سجّل خروجاً مع مطالبة أضرار — راجع الصور',
        type: 'damage_claim',
        refId: bookingId,
      );
      return {
        'success': true,
        'message': 'تم تسجيل الخروج — العربون محجوز لمراجعة الأضرار',
        'depositReleased': false,
        'checkedOutAt': now,
      };
    }

    updates['status'] = BookingStatus.completed;
    await DataService.updateBookingFields(bookingId, updates);

    final deposit = _parseDeposit(booking);
    if (deposit > 0) {
      await WalletService.releaseBookingDeposit(
        title: 'إطلاق عربون — ${booking['title'] ?? bookingId}',
        amount: deposit,
        bookingId: bookingId,
        ownerId: booking['ownerEmail']?.toString() ??
            booking['ownerId']?.toString() ??
            'owner@ejari.app',
        tenantId: booking['tenantEmail']?.toString(),
      );
    }

    await DataService.addNotificationToUser(
      booking['ownerEmail']?.toString() ?? '',
      'خروج مستأجر — تم إطلاق العربون ✓',
      'تم إطلاق ${deposit.toStringAsFixed(0)} ج.م للمحفظة',
      type: 'check_out',
      refId: bookingId,
    );

    return {
      'success': true,
      'message': 'تم تسجيل الخروج وإطلاق العربون ✓',
      'depositReleased': true,
      'depositAmount': deposit,
      'checkedOutAt': now,
    };
  }

  /// مطالبة أضرار من المالك مع صور قبل/بعد.
  static Future<Map<String, dynamic>> submitDamageClaim({
    required String bookingId,
    required String ownerEmail,
    required List<String> beforePhotos,
    required List<String> afterPhotos,
    required String description,
    double? claimAmount,
  }) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    final prefs = await SharedPreferences.getInstance();
    const key = 'damage_claims_v1';
    final claims = prefs.getStringList(key) ?? [];
    final claim = {
      'bookingId': bookingId,
      'ownerEmail': ownerEmail,
      'tenantEmail': booking['tenantEmail'],
      'beforePhotos': beforePhotos,
      'afterPhotos': afterPhotos,
      'description': description,
      'claimAmount': claimAmount ?? _parseDeposit(booking),
      'status': 'pending_review',
      'createdAt': DateTime.now().toIso8601String(),
    };
    claims.add(jsonEncode(claim));
    await prefs.setStringList(key, claims);

    await DataService.updateBookingFields(bookingId, {
      'damageClaim': true,
      'damageClaimData': claim,
      'status': BookingStatus.disputed,
    });

    await DataService.addNotificationToUser(
      booking['tenantEmail']?.toString() ?? '',
      'مطالبة أضرار من المالك ⚠️',
      description,
      type: 'damage_claim',
      refId: bookingId,
    );

    return {'success': true, 'message': 'تم تقديم مطالبة الأضرار', 'claim': claim};
  }

  /// حالة الدخول/الخروج للحجز.
  static Future<Map<String, dynamic>> getStatus(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) return {'found': false};

    return {
      'found': true,
      'checkedInAt': booking['checkedInAt'],
      'checkedOutAt': booking['checkedOutAt'],
      'canCheckIn': booking['checkedInAt'] == null &&
          _canCheckInStatus(booking['status']?.toString()),
      'canCheckOut': booking['checkedInAt'] != null &&
          booking['checkedOutAt'] == null,
      'damageClaim': booking['damageClaim'] == true,
      'depositReleased': booking['checkedOutAt'] != null &&
          booking['damageClaim'] != true,
    };
  }

  static bool _canCheckInStatus(String? status) {
    final s = BookingStatus.normalize(status);
    return s == BookingStatus.approved ||
        s == BookingStatus.paid ||
        s == BookingStatus.active ||
        s == BookingStatus.confirmed;
  }

  static double _parseDeposit(Map<String, dynamic> booking) {
    final d = booking['depositAmount'] ?? booking['securityDeposit'];
    if (d is num) return d.toDouble();
    if (d is String) {
      return double.tryParse(d.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 500;
    }
    return 500;
  }
}
