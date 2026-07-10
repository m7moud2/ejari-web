import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_status.dart';
import 'booking_qr_service.dart';
import 'check_in_out_service.dart';
import 'data_service.dart';
import 'wallet_service.dart';

/// تدفق حجز تجريبي متصل — من البحث حتى تقييم المالك.
class DemoFlowService {
  DemoFlowService._();

  static const String bookingId = 'demo_flow_bed_1';
  static const String propertyId = 'shared_egy1';
  static const String tenantEmail = 'user@ejari.app';
  static const String ownerEmail = 'owner@ejari.app';
  static const String _bannerDismissedKey = 'demo_flow_banner_dismissed';

  static const List<Map<String, String>> stepDefs = [
    {'id': 'search', 'title': 'البحث عن إقامة مشتركة', 'icon': 'search'},
    {'id': 'book', 'title': 'حجز سرير — shared_egy1', 'icon': 'bed'},
    {'id': 'pay', 'title': 'دفع العربون + الإيجار', 'icon': 'payment'},
    {'id': 'approve', 'title': 'موافقة المالك', 'icon': 'check'},
    {'id': 'qr', 'title': 'استلام رمز QR', 'icon': 'qr'},
    {'id': 'checkin', 'title': 'تسجيل الدخول', 'icon': 'login'},
    {'id': 'checkout', 'title': 'تسجيل الخروج', 'icon': 'logout'},
    {'id': 'deposit', 'title': 'إطلاق العربون', 'icon': 'wallet'},
    {'id': 'rate', 'title': 'تقييم المالك', 'icon': 'star'},
  ];

  static Future<bool> isBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bannerDismissedKey) ?? false;
  }

  static Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bannerDismissedKey, true);
  }

  static Future<void> resetBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bannerDismissedKey);
  }

  /// يضمن وجود حجز تجريبي للتدفق.
  static Future<Map<String, dynamic>> ensureFlowBooking() async {
    await DataService.initDemoBookings();
    var booking = await DataService.findBookingById(bookingId);
    if (booking != null) return booking;

    final checkIn = DateTime.now().add(const Duration(days: 3));
    final request = {
      'id': bookingId,
      'contractNumber': 'CTR-FLOW-001',
      'propertyId': propertyId,
      'title': 'إقامة مشتركة — المعادي (تدفق تجريبي)',
      'image': 'assets/images/home3.jpg',
      'price': '2500',
      'monthlyRent': '2500',
      'tenantName': 'مستأجر تجريبي',
      'tenantEmail': tenantEmail,
      'ownerId': ownerEmail,
      'ownerEmail': ownerEmail,
      'status': BookingStatus.submitted,
      'selectedBedId': 'bed_2',
      'bedLabel': 'سرير 2 — غرفة A',
      'accommodationType': 'bed',
      'requestDate': DateTime.now().toIso8601String(),
      'checkInDate': checkIn.toIso8601String(),
      'startDate': checkIn.toIso8601String(),
      'leaseStartDate': checkIn.toIso8601String(),
      'durationLabel': '1 شهر',
      'duration': '1 شهر',
      'durationType': 'شهر',
      'durationCount': 1,
      'depositAmount': '500',
      'securityDeposit': 500,
      'rentAmount': 2500,
      'rentalTier': 'monthly',
      'rentalTierLabel': 'شهري',
      'tenantType': 'individual',
      'tenantTypeLabel': 'فرد',
      'demoFlow': true,
      'statusHistory': [
        {
          'status': BookingStatus.submitted,
          'label': 'إرسال الطلب',
          'at': DateTime.now().toIso8601String(),
          'note': 'بانتظار الدفع',
        },
      ],
    };
    await DataService.sendBookingRequest(request);
    return (await DataService.findBookingById(bookingId)) ?? request;
  }

  static Future<List<Map<String, dynamic>>> getSteps() async {
    final booking = await DataService.findBookingById(bookingId);
    await ensureFlowBooking();
    final b = booking ?? await DataService.findBookingById(bookingId);
    final status = BookingStatus.normalize(b?['status']?.toString());

    int doneUntil = 0;
    if (b != null) {
      doneUntil = 1; // search always done on guide
      doneUntil = 2; // book exists
      if (status == BookingStatus.depositPaid ||
          status == BookingStatus.approved ||
          status == BookingStatus.paid ||
          status == BookingStatus.active ||
          status == BookingStatus.completed) {
        doneUntil = 3;
      }
      if ([
        BookingStatus.approved,
        BookingStatus.paid,
        BookingStatus.active,
        BookingStatus.completed,
      ].contains(status)) {
        doneUntil = 4;
      }
      if (b['qrCode'] != null || b['qrGenerated'] == true) doneUntil = 5;
      if (b['checkedInAt'] != null) doneUntil = 6;
      if (b['checkedOutAt'] != null) doneUntil = 7;
      if (status == BookingStatus.completed && b['depositReleased'] == true) {
        doneUntil = 8;
      }
      if (b['ownerRated'] == true) doneUntil = 9;
    }

    return stepDefs.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final def = entry.value;
      final state = i < doneUntil
          ? 'done'
          : i == doneUntil
              ? 'current'
              : 'pending';
      return {
        ...def,
        'index': i,
        'state': state,
        'statusAr': _statusLabel(state),
      };
    }).toList();
  }

  static String _statusLabel(String state) => switch (state) {
        'done' => 'مكتمل ✓',
        'current' => 'الخطوة الحالية',
        _ => 'قادم',
      };

  static Future<Map<String, dynamic>> advanceStep(String stepId) async {
    await ensureFlowBooking();
    switch (stepId) {
      case 'search':
        return {'success': true, 'message': 'تم — ابحث عن إقامة مشتركة في المعادي'};
      case 'book':
        return {'success': true, 'message': 'تم إنشاء طلب حجز السرير'};
      case 'pay':
        return _simulatePayment();
      case 'approve':
        return _simulateOwnerApproval();
      case 'qr':
        return _generateQr();
      case 'checkin':
        return CheckInOutService.checkIn(bookingId);
      case 'checkout':
        return CheckInOutService.checkOut(bookingId);
      case 'deposit':
        return _confirmDepositRelease();
      case 'rate':
        return _simulateOwnerRating();
      default:
        return {'success': false, 'message': 'خطوة غير معروفة'};
    }
  }

  static Future<Map<String, dynamic>> _simulatePayment() async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }
    await WalletService.init(userId: tenantEmail);
    await DataService.updateRequestStatus(
      bookingId,
      BookingStatus.depositPaid,
      note: 'دفع العربون + الإيجار (تجريبي)',
    );
    await DataService.updateBookingFields(bookingId, {
      'paymentStatus': 'deposit_paid',
      'depositPaidAt': DateTime.now().toIso8601String(),
      'rentPaidAt': DateTime.now().toIso8601String(),
    });
    await DataService.addNotificationToUser(
      tenantEmail,
      'تم الدفع بنجاح 💳',
      'عربون 500 ج.م + إيجار 2500 ج.م — بانتظار موافقة المالك',
      type: 'payment',
      refId: bookingId,
    );
    return {'success': true, 'message': 'تم دفع العربون والإيجار — بانتظار موافقة المالك'};
  }

  static Future<Map<String, dynamic>> _simulateOwnerApproval() async {
    final ok = await DataService.updateRequestStatus(
      bookingId,
      BookingStatus.approved,
      note: 'موافقة المالك (تجريبي)',
    );
    if (!ok) {
      return {'success': false, 'message': 'تأكد من دفع العربون أولاً'};
    }
    await DataService.addNotificationToUser(
      tenantEmail,
      'تمت الموافقة على حجزك ✅',
      'المالك وافق — يمكنك الآن استلام رمز QR',
      type: 'booking',
      refId: bookingId,
    );
    return {'success': true, 'message': 'وافق المالك على الحجز'};
  }

  static Future<Map<String, dynamic>> _generateQr() async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }
    final status = BookingStatus.normalize(booking['status']?.toString());
    if (status != BookingStatus.approved &&
        status != BookingStatus.paid &&
        status != BookingStatus.active) {
      return {'success': false, 'message': 'الحجز لم يُوافق عليه بعد'};
    }
    final qrResult = await BookingQrService.generateForBooking(booking);
    await DataService.updateBookingFields(bookingId, {
      'qrCode': qrResult['qrData'],
      'qrGenerated': true,
      'qrGeneratedAt': DateTime.now().toIso8601String(),
    });
    return {
      'success': true,
      'message': 'تم إنشاء رمز QR — اعرضه عند تسجيل الدخول',
      'qrPayload': qrResult['qrData'],
    };
  }

  static Future<Map<String, dynamic>> _confirmDepositRelease() async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking?['checkedOutAt'] == null) {
      return {'success': false, 'message': 'سجّل الخروج أولاً'};
    }
    await DataService.updateBookingFields(bookingId, {
      'depositReleased': true,
      'depositReleasedAt': DateTime.now().toIso8601String(),
    });
    await DataService.addNotificationToUser(
      tenantEmail,
      'تم إطلاق العربون 🔓',
      '500 ج.م عادت إلى محفظتك بعد تسجيل الخروج',
      type: 'refund',
      refId: bookingId,
    );
    return {'success': true, 'message': 'تم إطلاق العربون إلى محفظتك'};
  }

  static Future<Map<String, dynamic>> _simulateOwnerRating() async {
    await DataService.updateBookingFields(bookingId, {
      'ownerRated': true,
      'ownerRating': 5,
      'ownerRatingAt': DateTime.now().toIso8601String(),
    });
    return {'success': true, 'message': 'شكراً — اكتمل التدفق التجريبي ⭐'};
  }

  static Future<Map<String, dynamic>> resetFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final requests = prefs.getStringList('requests') ?? [];
    final bookings = prefs.getStringList('bookings') ?? [];
    final filteredReq =
        requests.where((e) => !e.contains('"id":"$bookingId"')).toList();
    final filteredBk =
        bookings.where((e) => !e.contains('"id":"$bookingId"')).toList();
    await prefs.setStringList('requests', filteredReq);
    await prefs.setStringList('bookings', filteredBk);
    await resetBanner();
    await ensureFlowBooking();
    return {'success': true, 'message': 'تم إعادة ضبط التدفق التجريبي'};
  }

  static Future<bool> isFlowComplete() async {
    final steps = await getSteps();
    return steps.every((s) => s['state'] == 'done');
  }
}
