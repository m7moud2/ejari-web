import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_status.dart';
import 'data_service.dart';

/// توليد والتحقق من QR لكل حجز — demo بدون API خارجي.
///
/// دورة الاستلام:
/// 1) المستأجر يعرض QR بعد اكتمال الدفع (`paid` / `confirmed`)
/// 2) المالك يمسح/يتحقق من الرمز
/// 3) المالك يؤكد الاستلام → تسجيل دخول (`active`)
class BookingQrService {
  BookingQrService._();

  static const String _qrKey = 'booking_qr_codes_v1';

  /// QR جاهز عندما اكتمل الدفع ولم يُسجَّل دخول بعد.
  static bool isQrReady(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    if (booking['checkedInAt'] != null) return false;
    return status == BookingStatus.paid ||
        status == BookingStatus.confirmed ||
        status == BookingStatus.active;
  }

  /// يمكن تأكيد الاستلام (handover) بعد تحقق QR صالح.
  static bool canConfirmHandover(Map<String, dynamic> booking) {
    final status = BookingStatus.normalize(booking['status']?.toString());
    if (booking['checkedInAt'] != null) return false;
    return status == BookingStatus.paid || status == BookingStatus.confirmed;
  }

  static Future<Map<String, dynamic>> generateForBooking(
    Map<String, dynamic> booking,
  ) async {
    final id = booking['id']?.toString() ?? '';
    final tenant = booking['tenantEmail']?.toString() ?? '';
    final property = booking['propertyId']?.toString() ?? '';
    final checkIn = booking['checkInDate']?.toString() ??
        booking['leaseStartDate']?.toString() ??
        booking['startDate']?.toString() ??
        '';

    final payload = 'EJARI|$id|$tenant|$property|$checkIn';
    final hash = _demoHash(payload);
    final qrData = '$payload|$hash';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_qrKey);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    final existing = map[id] is Map
        ? Map<String, dynamic>.from(map[id] as Map)
        : <String, dynamic>{};
    map[id] = {
      ...existing,
      'qrData': qrData,
      'hash': hash,
      'generatedAt':
          existing['generatedAt'] ?? DateTime.now().toIso8601String(),
      'verified': existing['verified'] == true,
    };
    await prefs.setString(_qrKey, jsonEncode(map));

    return {
      'bookingId': id,
      'qrData': qrData,
      'hash': hash,
      'displayCode': _formatDisplayCode(hash),
      'title': booking['title'] ?? 'حجز',
      'tenantName': booking['tenantName'] ?? tenant,
      'checkInDate': checkIn,
      'qrReady': isQrReady(booking),
      'canConfirmHandover': canConfirmHandover(booking),
    };
  }

  static Future<Map<String, dynamic>> verifyQrCode(String scannedData) async {
    final trimmed = scannedData.trim();
    final parts = trimmed.split('|');
    if (parts.length < 6 || parts[0] != 'EJARI') {
      return _invalid('رمز QR غير صالح — تأكد من لصق الرمز كاملاً');
    }

    final bookingId = parts[1];
    final providedHash = parts.last;
    final payload = parts.sublist(0, parts.length - 1).join('|');
    final expectedHash = _demoHash(payload);

    if (providedHash != expectedHash) {
      return _invalid('رمز التحقق غير مطابق — قد يكون الرمز مزوراً');
    }

    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return _invalid('الحجز غير موجود في النظام');
    }

    return _buildValidationResult(booking, bookingId, markVerified: true);
  }

  static Future<Map<String, dynamic>> verifyByBookingId(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) {
      return _invalid('أدخل معرّف الحجز');
    }

    final booking = await DataService.findBookingById(id);
    if (booking == null) {
      return _invalid('الحجز غير موجود — جرّب demo_req_1 أو demo_bed_booking');
    }

    final qr = await generateForBooking(booking);
    final verify = await verifyQrCode(qr['qrData'] as String);
    return verify;
  }

  static Future<Map<String, dynamic>> _buildValidationResult(
    Map<String, dynamic> booking,
    String bookingId, {
    bool markVerified = false,
  }) async {
    final checkInRaw = booking['checkInDate']?.toString() ??
        booking['leaseStartDate']?.toString() ??
        booking['startDate']?.toString() ??
        '';
    final checkIn = DateTime.tryParse(checkInRaw);
    final now = DateTime.now();
    final isExpired = checkIn != null && checkIn.isBefore(now.subtract(const Duration(days: 1)));
    final status = booking['status']?.toString() ?? 'unknown';
    final paymentStatus = _paymentStatusLabel(booking);
    final bedLabel = booking['bedLabel']?.toString();
    final propertyTitle = booking['title']?.toString() ?? '—';
    final tenantName = booking['tenantName']?.toString() ?? '—';
    final duration = booking['durationLabel']?.toString() ??
        booking['duration']?.toString() ??
        '—';

    if (isExpired) {
      return {
        'valid': false,
        'expired': true,
        'status': 'expired',
        'message': 'انتهت صلاحية الحجز ✗',
        'booking': booking,
        'bookingId': bookingId,
        'tenantName': tenantName,
        'propertyTitle': propertyTitle,
        'bedLabel': bedLabel,
        'checkInDate': checkInRaw,
        'duration': duration,
        'paymentStatus': paymentStatus,
        'bookingStatus': status,
      };
    }

    if (markVerified) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_qrKey);
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (map.containsKey(bookingId)) {
          map[bookingId]['verified'] = true;
          map[bookingId]['verifiedAt'] = DateTime.now().toIso8601String();
          await prefs.setString(_qrKey, jsonEncode(map));
        }
      }
    }

    final alreadyCheckedIn = booking['checkedInAt'] != null;
    final handoverReady = canConfirmHandover(booking);
    String message;
    if (alreadyCheckedIn) {
      message = 'تم التحقق — الاستلام مسجّل مسبقاً ✓';
    } else if (handoverReady) {
      message = 'تم التحقق بنجاح ✓ — أكّد الاستلام لتسجيل دخول المستأجر';
    } else if (!isQrReady(booking) &&
        BookingStatus.normalize(status) == BookingStatus.approved) {
      message =
          'الرمز صالح لكن الدفع غير مكتمل — يجب على المستأجر إكمال الدفع أولاً';
    } else {
      message = 'تم التحقق بنجاح ✓';
    }

    return {
      'valid': true,
      'expired': false,
      'status': 'valid',
      'message': message,
      'booking': booking,
      'bookingId': bookingId,
      'tenantName': tenantName,
      'propertyTitle': propertyTitle,
      'bedLabel': bedLabel,
      'checkInDate': checkInRaw,
      'duration': duration,
      'paymentStatus': paymentStatus,
      'bookingStatus': status,
      'bookingStatusLabel': BookingStatus.arabicLabel(status),
      'alreadyCheckedIn': alreadyCheckedIn,
      'canConfirmHandover': handoverReady,
      'qrReady': isQrReady(booking),
    };
  }

  static Map<String, dynamic> _invalid(String message) => {
        'valid': false,
        'expired': false,
        'status': 'invalid',
        'message': message,
      };

  static String _paymentStatusLabel(Map<String, dynamic> booking) {
    final raw = booking['paymentStatus']?.toString() ?? '';
    final status = BookingStatus.normalize(booking['status']?.toString());
    if (raw == 'paid' ||
        raw == 'pre_entry_paid' ||
        status == BookingStatus.paid ||
        status == BookingStatus.confirmed ||
        status == BookingStatus.active ||
        status == BookingStatus.completed) {
      return 'مدفوع بالكامل';
    }
    if (raw == 'deposit_paid' || status == BookingStatus.depositPaid) {
      return 'تم دفع العربون';
    }
    if (status == BookingStatus.approved) {
      return 'موافقة المالك — بانتظار إكمال الدفع';
    }
    if (status == BookingStatus.submitted ||
        status == BookingStatus.pending ||
        status == BookingStatus.corporatePending) {
      return 'بانتظار الدفع';
    }
    return raw.isNotEmpty ? raw : 'غير محدد';
  }

  static String _demoHash(String input) {
    var h = 5381;
    for (final c in input.codeUnits) {
      h = ((h << 5) + h + c) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0').substring(0, 8);
  }

  static String _formatDisplayCode(String hash) {
    return hash.toUpperCase().replaceAllMapped(
          RegExp(r'.{4}'),
          (m) => '${m.group(0)} ',
        ).trim();
  }
}
