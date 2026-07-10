import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

/// توليد والتحقق من QR لكل حجز — demo بدون API خارجي.
class BookingQrService {
  BookingQrService._();

  static const String _qrKey = 'booking_qr_codes_v1';

  /// توليد payload QR للحجز.
  static Future<Map<String, dynamic>> generateForBooking(
    Map<String, dynamic> booking,
  ) async {
    final id = booking['id']?.toString() ?? '';
    final tenant = booking['tenantEmail']?.toString() ?? '';
    final property = booking['propertyId']?.toString() ?? '';
    final checkIn = booking['checkInDate']?.toString() ?? '';

    final payload = 'EJARI|$id|$tenant|$property|$checkIn';
    final hash = _demoHash(payload);
    final qrData = '$payload|$hash';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_qrKey);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    map[id] = {
      'qrData': qrData,
      'hash': hash,
      'generatedAt': DateTime.now().toIso8601String(),
      'verified': false,
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
    };
  }

  /// التحقق من QR من قبل المالك.
  static Future<Map<String, dynamic>> verifyQrCode(String scannedData) async {
    final parts = scannedData.split('|');
    if (parts.length < 6 || parts[0] != 'EJARI') {
      return {'valid': false, 'message': 'رمز QR غير صالح'};
    }

    final bookingId = parts[1];
    final providedHash = parts.last;
    final payload = parts.sublist(0, parts.length - 1).join('|');
    final expectedHash = _demoHash(payload);

    if (providedHash != expectedHash) {
      return {'valid': false, 'message': 'رمز التحقق غير مطابق'};
    }

    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'valid': false, 'message': 'الحجز غير موجود'};
    }

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

    return {
      'valid': true,
      'message': 'تم التحقق بنجاح ✓',
      'booking': booking,
      'bookingId': bookingId,
      'tenantName': booking['tenantName'] ?? parts[2],
      'propertyTitle': booking['title'],
    };
  }

  /// التحقق بالمعرّف يدوياً (بديل للمسح).
  static Future<Map<String, dynamic>> verifyByBookingId(String bookingId) async {
    final booking = await DataService.findBookingById(bookingId);
    if (booking == null) {
      return {'valid': false, 'message': 'الحجز غير موجود'};
    }
    final qr = await generateForBooking(booking);
    return verifyQrCode(qr['qrData'] as String);
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
