import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

/// تتبع no-shows والإلغاءات المتكررة — يؤثر على درجة المستأجر.
class AntiFraudService {
  AntiFraudService._();

  static const String _profileKey = 'anti_fraud_profiles_v1';

  /// تسجيل no-show.
  static Future<void> recordNoShow({
    required String userEmail,
    required String bookingId,
    String? reason,
  }) async {
    await _appendEvent(userEmail, 'no_show', bookingId, reason);
    await DataService.addNotificationToUser(
      userEmail,
      'تسجيل no-show ⚠️',
      'لم تحضر للحجز $bookingId — يؤثر على درجتك',
      type: 'fraud_warning',
      refId: bookingId,
    );
  }

  /// تسجيل إلغاء.
  static Future<void> recordCancellation({
    required String userEmail,
    required String bookingId,
    bool lateCancel = false,
  }) async {
    await _appendEvent(
      userEmail,
      lateCancel ? 'late_cancel' : 'cancel',
      bookingId,
      null,
    );
  }

  /// ملف المستخدم المضاد للاحتيال.
  static Future<Map<String, dynamic>> getProfile(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    final all = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};

    final profile = Map<String, dynamic>.from(
      all[userEmail] as Map? ?? _emptyProfile(),
    );

    final noShows = (profile['noShows'] as num?)?.toInt() ?? 0;
    final cancellations = (profile['cancellations'] as num?)?.toInt() ?? 0;
    final lateCancels = (profile['lateCancels'] as num?)?.toInt() ?? 0;

    final flags = <String>[];
    if (noShows >= 2) flags.add('no_show_repeat');
    if (cancellations >= 5) flags.add('excessive_cancellations');
    if (lateCancels >= 3) flags.add('late_cancel_pattern');

    return {
      'userEmail': userEmail,
      'noShows': noShows,
      'cancellations': cancellations,
      'lateCancels': lateCancels,
      'events': profile['events'] ?? [],
      'flags': flags,
      'isFlagged': flags.isNotEmpty,
      'riskLevel': _riskLevel(noShows, cancellations, lateCancels),
      'summary': _summary(noShows, cancellations, flags),
    };
  }

  /// فحص تلقائي عند إلغاء حجز.
  static Future<void> onBookingCancelled(
    Map<String, dynamic> booking,
  ) async {
    final email = booking['tenantEmail']?.toString() ?? '';
    if (email.isEmpty) return;

    final checkIn = DateTime.tryParse(booking['checkInDate']?.toString() ?? '');
    final lateCancel = checkIn != null &&
        checkIn.difference(DateTime.now()).inHours < 48;

    await recordCancellation(
      userEmail: email,
      bookingId: booking['id']?.toString() ?? '',
      lateCancel: lateCancel,
    );
  }

  /// بذر بيانات تجريبية.
  static Future<void> seedDemoProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('anti_fraud_seeded')) return;

    await recordCancellation(
      userEmail: 'tenant.demo@ejari.app',
      bookingId: 'demo_cancel_1',
    );
    await recordCancellation(
      userEmail: 'tenant.demo@ejari.app',
      bookingId: 'demo_cancel_2',
      lateCancel: true,
    );
    await recordNoShow(
      userEmail: 'tenant.demo@ejari.app',
      bookingId: 'demo_noshow_1',
      reason: 'لم يحضر',
    );
    await recordNoShow(
      userEmail: 'tenant.demo@ejari.app',
      bookingId: 'demo_noshow_2',
      reason: 'لم يحضر مرة ثانية',
    );
    await prefs.setBool('anti_fraud_seeded', true);
  }

  static Future<void> _appendEvent(
    String email,
    String type,
    String bookingId,
    String? reason,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    final all = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};

    final profile = Map<String, dynamic>.from(
      all[email] as Map? ?? _emptyProfile(),
    );
    final events = List<Map<String, dynamic>>.from(
      profile['events'] as List? ?? [],
    );
    events.add({
      'type': type,
      'bookingId': bookingId,
      'reason': reason,
      'at': DateTime.now().toIso8601String(),
    });
    profile['events'] = events;

    if (type == 'no_show') {
      profile['noShows'] = ((profile['noShows'] as num?)?.toInt() ?? 0) + 1;
    } else if (type == 'cancel') {
      profile['cancellations'] =
          ((profile['cancellations'] as num?)?.toInt() ?? 0) + 1;
    } else if (type == 'late_cancel') {
      profile['cancellations'] =
          ((profile['cancellations'] as num?)?.toInt() ?? 0) + 1;
      profile['lateCancels'] =
          ((profile['lateCancels'] as num?)?.toInt() ?? 0) + 1;
    }

    all[email] = profile;
    await prefs.setString(_profileKey, jsonEncode(all));
  }

  static Map<String, dynamic> _emptyProfile() => {
        'noShows': 0,
        'cancellations': 0,
        'lateCancels': 0,
        'events': <Map<String, dynamic>>[],
      };

  static String _riskLevel(int noShows, int cancels, int lateCancels) {
    if (noShows >= 2 || cancels >= 5) return 'high';
    if (noShows >= 1 || lateCancels >= 2) return 'medium';
    return 'low';
  }

  static String _summary(int noShows, int cancels, List<String> flags) {
    if (flags.isEmpty) return 'سجل نظيف';
    if (flags.contains('no_show_repeat')) {
      return 'تحذير: $noShows no-show — راجع قبل القبول';
    }
    if (flags.contains('excessive_cancellations')) {
      return 'تحذير: $cancels إلغاء — نمط مشبوه';
    }
    return 'مراقبة — سجل يحتاج انتباه';
  }
}
