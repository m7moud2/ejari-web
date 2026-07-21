import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/booking_status.dart';
import 'booking_qr_service.dart';
import 'data_service.dart';
import 'firestore_booking_service.dart';
import 'wallet_service.dart';

/// تسجيل الدخول/الخروج وإطلاق العربون.
///
/// الاستلام (handover): المالك يتحقق من QR ثم يستدعي [confirmHandover]
/// → يُسجَّل [checkedInAt] والحالة `active`.
/// العربون يبقى محجوزاً أثناء `active` ويُفرَج عند `completed` (بدون نزاع).
class CheckInOutService {
  CheckInOutService._();

  /// تأكيد استلام المالك بعد مسح/تحقق QR ناجح.
  static Future<Map<String, dynamic>> confirmHandover(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    if (!BookingQrService.canConfirmHandover(booking)) {
      final status = BookingStatus.normalize(booking['status']?.toString());
      if (booking['checkedInAt'] != null) {
        return {
          'success': false,
          'message': 'تم تسجيل الاستلام مسبقاً',
          'alreadyCheckedIn': true,
        };
      }
      if (status == BookingStatus.approved) {
        return {
          'success': false,
          'message':
              'لا يمكن تأكيد الاستلام قبل إكمال المستأجر للدفع المتبقي',
        };
      }
      return {
        'success': false,
        'message': 'الحجز غير جاهز للاستلام — يجب اكتمال الدفع أولاً',
      };
    }

    final result = await checkIn(bookingId);
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      const key = 'booking_qr_codes_v1';
      final raw = prefs.getString(key);
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (map.containsKey(bookingId)) {
          map[bookingId]['handoverConfirmed'] = true;
          map[bookingId]['handoverAt'] = result['checkedInAt'];
          await prefs.setString(key, jsonEncode(map));
        }
      }
      return {
        ...result,
        'message': 'تم تأكيد الاستلام وتسجيل الدخول ✓',
        'handover': true,
      };
    }
    return result;
  }

  /// تسجيل دخول المستأجر (بعد دفع كامل — عادة عبر تأكيد استلام المالك).
  static Future<Map<String, dynamic>> checkIn(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    final status = BookingStatus.normalize(booking['status']?.toString());
    if (!_canCheckInStatus(status)) {
      if (status == BookingStatus.approved) {
        return {
          'success': false,
          'message':
              'لا يمكن تسجيل الدخول قبل إكمال الدفع — ادفع المتبقي أولاً',
        };
      }
      return {
        'success': false,
        'message': 'لا يمكن تسجيل الدخول — الحجز غير مؤكد أو غير مدفوع',
      };
    }

    if (booking['checkedInAt'] != null) {
      return {'success': false, 'message': 'تم تسجيل الدخول مسبقاً'};
    }

    final now = DateTime.now().toIso8601String();
    final updated = await DataService.updateBookingFields(bookingId, {
      'checkedInAt': now,
      'status': BookingStatus.active,
      'handoverConfirmedAt': now,
    });
    if (!updated) {
      return {
        'success': false,
        'message': 'تعذر حفظ تسجيل الدخول. تحقق من الاتصال وحاول مرة أخرى',
      };
    }

    // الاستلام لا يُفرج العربون — يبقى محجوزاً حتى الخروج.
    if (!AppConfig.demoMode) {
      final deposit = _parseDeposit(booking);
      final currentEscrow = booking['escrowStatus']?.toString();
      if (currentEscrow == null ||
          currentEscrow == FirestoreBookingService.escrowNone ||
          currentEscrow.isEmpty) {
        await FirestoreBookingService.syncEscrowStatus(
          bookingId,
          FirestoreBookingService.escrowHeld,
          escrowAmount: deposit > 0 ? deposit : null,
        );
      }
    }

    await DataService.addNotificationToUser(
      booking['ownerEmail']?.toString() ?? 'owner@ejari.app',
      'تسجيل دخول مستأجر 🏠',
      'قام ${booking['tenantName'] ?? 'المستأجر'} بتسجيل الدخول',
      type: 'check_in',
      refId: bookingId,
    );

    await DataService.addNotificationToUser(
      booking['tenantEmail']?.toString() ?? '',
      'تم الاستلام ✓',
      'تم تأكيد استلام الوحدة — إقامة سعيدة',
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
    final deposit = _parseDeposit(booking);
    final updates = <String, dynamic>{
      'checkedOutAt': now,
    };

    if (damageClaimed || booking['damageClaim'] == true) {
      updates['status'] = BookingStatus.disputed;
      updates['damageClaim'] = true;
      updates['escrowStatus'] = FirestoreBookingService.escrowDisputed;
      await DataService.updateBookingFields(bookingId, updates);
      if (!AppConfig.demoMode) {
        await FirestoreBookingService.syncEscrowStatus(
          bookingId,
          FirestoreBookingService.escrowDisputed,
          escrowAmount: deposit > 0 ? deposit : null,
        );
      }
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
    updates['escrowStatus'] = FirestoreBookingService.escrowReleased;
    await DataService.updateBookingFields(bookingId, updates);

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

    if (!AppConfig.demoMode) {
      await FirestoreBookingService.syncEscrowStatus(
        bookingId,
        FirestoreBookingService.escrowReleased,
        escrowAmount: deposit > 0 ? deposit : null,
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
      'escrowStatus': FirestoreBookingService.escrowDisputed,
    });

    if (!AppConfig.demoMode) {
      await FirestoreBookingService.syncEscrowStatus(
        bookingId,
        FirestoreBookingService.escrowDisputed,
        escrowAmount: _parseDeposit(booking),
      );
    }

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
      'escrowStatus': booking['escrowStatus']?.toString() ?? 'none',
    };
  }

  static bool _canCheckInStatus(String? status) {
    final s = BookingStatus.normalize(status);
    // يتطلب اكتمال الدفع قبل الاستلام (ليس مجرد موافقة المالك).
    return s == BookingStatus.paid ||
        s == BookingStatus.confirmed ||
        s == BookingStatus.active;
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
