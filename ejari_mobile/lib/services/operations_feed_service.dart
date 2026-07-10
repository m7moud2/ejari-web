import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'maintenance_service.dart';
import '../models/booking_status.dart';

/// بث العمليات الحي للإدارة — حجوزات، مدفوعات، توثيق، نزاعات.
class OperationsFeedService {
  OperationsFeedService._();

  static const String _feedKey = 'admin_operations_feed_v1';
  static const int _version = 1;
  static const String _versionKey = 'admin_operations_feed_version';

  static Future<void> initDemoFeed() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_versionKey) ?? 0) >= _version) return;

    final now = DateTime.now();
    final seed = [
      _event(
        type: 'kyc',
        title: 'طلب توثيق جديد',
        detail: 'مستأجر تجريبي — بانتظار مراجعة الكاميرا',
        refId: 'EJR-100002',
        at: now.subtract(const Duration(minutes: 12)),
        priority: 'high',
      ),
      _event(
        type: 'booking',
        title: 'حجز بعربون مدفوع',
        detail: 'شقة المعادي — ٣٥٠٠ ج.م في الضمان',
        refId: 'BK-DEMO-01',
        at: now.subtract(const Duration(minutes: 28)),
        priority: 'normal',
      ),
      _event(
        type: 'payment',
        title: 'دفعة إيجار مستلمة',
        detail: 'قسط شهري — ٨٠٠٠ ج.م للمالك (بعد عمولة المنصة)',
        refId: 'PAY-8842',
        at: now.subtract(const Duration(hours: 1)),
        priority: 'normal',
      ),
      _event(
        type: 'maintenance',
        title: 'طلب صيانة عاجل',
        detail: 'تسريب مياه — بانتظار تعيين فني',
        refId: 'MNT-441',
        at: now.subtract(const Duration(hours: 2)),
        priority: 'high',
      ),
      _event(
        type: 'dispute',
        title: 'نزاع مفتوح',
        detail: 'صيانة — المستأجر يعترض على جودة الإصلاح',
        refId: 'DSP-09',
        at: now.subtract(const Duration(hours: 5)),
        priority: 'critical',
      ),
      _event(
        type: 'corporate',
        title: 'حجز شركات متعدد المحافظات',
        detail: '٥ موظفين — القاهرة، الجيزة، الإسكندرية',
        refId: 'CORP-12',
        at: now.subtract(const Duration(hours: 8)),
        priority: 'normal',
      ),
    ];

    await prefs.setString(_feedKey, jsonEncode(seed));
    await prefs.setInt(_versionKey, _version);
  }

  static Map<String, dynamic> _event({
    required String type,
    required String title,
    required String detail,
    required String refId,
    required DateTime at,
    String priority = 'normal',
  }) {
    return {
      'id': 'EVT-${at.millisecondsSinceEpoch}-$refId',
      'type': type,
      'title': title,
      'detail': detail,
      'refId': refId,
      'at': at.toIso8601String(),
      'priority': priority,
      'read': false,
    };
  }

  static Future<void> appendEvent({
    required String type,
    required String title,
    required String detail,
    String? refId,
    String priority = 'normal',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedKey);
    final list = raw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    list.insert(
      0,
      _event(
        type: type,
        title: title,
        detail: detail,
        refId: refId ?? 'REF-${DateTime.now().millisecondsSinceEpoch}',
        at: DateTime.now(),
        priority: priority,
      ),
    );

    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setString(_feedKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getLiveFeed({int limit = 20}) async {
    await _syncFromLiveData();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedKey);
    if (raw == null) return [];
    final stored = (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    stored.sort((a, b) {
      final da = DateTime.tryParse(a['at']?.toString() ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['at']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return stored.take(limit).map(_enrichEvent).toList();
  }

  static Future<void> _syncFromLiveData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedKey);
    final existing = raw == null
        ? <String>{}
        : (jsonDecode(raw) as List)
            .map((e) => (e as Map)['refId']?.toString() ?? '')
            .toSet();

    final newEvents = <Map<String, dynamic>>[];

    final verifications = (await DataService.getAllIdentityVerifications())
        .where((v) => (v['status'] ?? 'pending') == 'pending')
        .toList();
    for (final v in verifications.take(3)) {
      final ref = v['userEmail']?.toString() ?? v['id']?.toString() ?? '';
      if (existing.contains(ref)) continue;
      newEvents.add(_event(
        type: 'kyc',
        title: 'توثيق بانتظار المراجعة',
        detail: v['userName']?.toString() ?? ref,
        refId: ref,
        at: DateTime.tryParse(v['submittedAt']?.toString() ?? '') ??
            DateTime.now(),
        priority: 'high',
      ));
    }

    final bookings = await DataService.getAdminBookingsOverview();
    for (final b in bookings.take(5)) {
      final ref = b['id']?.toString() ?? '';
      if (existing.contains(ref)) continue;
      final st = BookingStatus.normalize(b['status']?.toString());
      if (st == BookingStatus.depositPaid ||
          st == BookingStatus.corporatePending) {
        newEvents.add(_event(
          type: st == BookingStatus.corporatePending ? 'corporate' : 'booking',
          title: BookingStatus.arabicLabel(st),
          detail: b['title']?.toString() ?? 'حجز جديد',
          refId: ref,
          at: DateTime.tryParse(b['requestDate']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }
    }

    final maintenance = await MaintenanceService.getAllRequests();
    for (final m in maintenance.take(5)) {
      final ref = m['id']?.toString() ?? '';
      if (existing.contains(ref)) continue;
      final st = MaintenanceStatus.normalize(m['status']?.toString());
      if (st == MaintenanceStatus.disputed) {
        newEvents.add(_event(
          type: 'dispute',
          title: 'نزاع صيانة',
          detail: m['title']?.toString() ?? m['issue']?.toString() ?? ref,
          refId: ref,
          at: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
          priority: 'critical',
        ));
      } else if (st == MaintenanceStatus.submitted) {
        newEvents.add(_event(
          type: 'maintenance',
          title: 'طلب صيانة جديد',
          detail: m['title']?.toString() ?? ref,
          refId: ref,
          at: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
              DateTime.now(),
          priority: 'high',
        ));
      }
    }

    if (newEvents.isEmpty) return;

    final raw2 = prefs.getString(_feedKey);
    final list = raw2 == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw2) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    list.insertAll(0, newEvents);
    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setString(_feedKey, jsonEncode(list));
  }

  static Map<String, dynamic> _enrichEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? 'general';
    final icons = {
      'kyc': 'verified_user',
      'booking': 'event_available',
      'payment': 'payments',
      'maintenance': 'build',
      'dispute': 'gavel',
      'corporate': 'groups',
      'general': 'notifications',
    };
    final colors = {
      'kyc': 'accent',
      'booking': 'primary',
      'payment': 'success',
      'maintenance': 'info',
      'dispute': 'error',
      'corporate': 'primary',
      'general': 'secondary',
    };
    final at = DateTime.tryParse(event['at']?.toString() ?? '');
    return {
      ...event,
      'iconKey': icons[type] ?? icons['general'],
      'colorKey': colors[type] ?? colors['general'],
      'timeAgo': _timeAgo(at),
    };
  }

  static String _timeAgo(DateTime? at) {
    if (at == null) return 'الآن';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }

  static Future<int> getUnreadCount() async {
    final feed = await getLiveFeed();
    return feed.where((e) => e['read'] != true).length;
  }

  static Future<void> markRead(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final item in list) {
      if (item['id'] == eventId) item['read'] = true;
    }
    await prefs.setString(_feedKey, jsonEncode(list));
  }
}
