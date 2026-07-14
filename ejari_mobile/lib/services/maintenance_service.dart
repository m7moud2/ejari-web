import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import '../utils/safe_parse.dart';
import 'data_service.dart';
import 'financial_service.dart';
import 'wallet_service.dart';

/// حالات دورة حياة طلب الصيانة الموحّدة.
class MaintenanceStatus {
  static const submitted = 'submitted';
  static const assigned = 'assigned';
  static const enRoute = 'en_route';
  static const arrived = 'arrived';
  static const inProgress = 'in_progress';
  static const pendingClientConfirm = 'pending_client_confirm';
  static const completed = 'completed';
  static const paid = 'paid';
  static const cancelled = 'cancelled';
  static const rejected = 'rejected';
  static const disputed = 'disputed';

  static const ordered = [
    submitted,
    assigned,
    enRoute,
    arrived,
    inProgress,
    pendingClientConfirm,
    completed,
    paid,
  ];

  /// خطوات التتبع للمستأجر (8 مراحل بالعربية).
  static const trackingStepsAr = [
    'تم استلام الطلب',
    'تم التعيين للفني',
    'الفني في الطريق',
    'وصل الفني',
    'جاري التنفيذ',
    'اكتملت الخدمة — أكّد',
    'الدفع',
    'تم الإغلاق',
  ];

  static String normalize(String? raw) {
    final s = (raw ?? submitted).toString().trim().toLowerCase();
    const map = {
      'pending': submitted,
      'معلق': submitted,
      'quote_received': submitted,
      'accepted': assigned,
      'assigned': assigned,
      'en_route': enRoute,
      'في_الطريق': enRoute,
      'arrived': arrived,
      'وصل': arrived,
      'on_site': arrived,
      'in_progress': inProgress,
      'قيد_المعالجة': inProgress,
      'pending_client_confirm': pendingClientConfirm,
      'waiting_for_confirmation': pendingClientConfirm,
      'completed': completed,
      'مكتمل': completed,
      'paid': paid,
      'مدفوع': paid,
      'cancelled': cancelled,
      'ملغي': cancelled,
      'rejected': rejected,
      'مرفوض': rejected,
      'disputed': disputed,
      'نزاع': disputed,
    };
    return map[s] ?? s;
  }

  static String labelAr(String status) {
    return switch (normalize(status)) {
      submitted => 'مُرسَل',
      assigned => 'مُعيَّن',
      enRoute => 'في الطريق',
      arrived => 'وصل الفني',
      inProgress => 'قيد التنفيذ',
      pendingClientConfirm => 'بانتظار تأكيدك',
      completed => 'بانتظار الدفع',
      paid => 'تم الإغلاق',
      cancelled => 'ملغي',
      rejected => 'مرفوض',
      disputed => 'نزاع',
      _ => status,
    };
  }

  static int stepIndex(String status) {
    final n = normalize(status);
    final idx = ordered.indexOf(n);
    return idx < 0 ? 0 : idx;
  }

  /// فهرس خطوة التتبع (0–7) لواجهة المستأجر.
  static int trackingStepIndex(String status) => stepIndex(status);

  /// مدة SLA حسب الأولوية (24h/48h للعاجل/مرتفع).
  static Duration slaDuration(String priority) {
    return switch (priority) {
      'urgent' => const Duration(hours: 2),
      'high' => const Duration(hours: 24),
      'medium' => const Duration(hours: 48),
      _ => const Duration(days: 7),
    };
  }

  static DateTime slaDeadlineFor(Map<String, dynamic> request) {
    final created = DateTime.tryParse(request['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final stored = request['slaDeadline']?.toString();
    if (stored != null) {
      final parsed = DateTime.tryParse(stored);
      if (parsed != null) return parsed;
    }
    final priority = request['priority']?.toString() ?? 'medium';
    return created.add(slaDuration(priority));
  }

  static bool isSlaOverdue(Map<String, dynamic> request) {
    final status = normalize(request['status']?.toString());
    if ([completed, paid, cancelled, rejected].contains(status)) {
      return false;
    }
    return DateTime.now().isAfter(slaDeadlineFor(request));
  }

  static String slaRemainingLabelAr(Map<String, dynamic> request) {
    if (isSlaOverdue(request)) return 'تجاوز SLA ⚠️';
    final deadline = slaDeadlineFor(request);
    final remaining = deadline.difference(DateTime.now());
    if (remaining.inHours >= 24) {
      return 'متبقي ${remaining.inHours ~/ 24} يوم';
    }
    if (remaining.inHours >= 1) {
      return 'متبقي ${remaining.inHours} ساعة';
    }
    return 'متبقي ${remaining.inMinutes} دقيقة';
  }
}

class MaintenanceService {
  static const String _requestsKey = 'maintenance_requests';

  static const List<Map<String, dynamic>> categories = [
    {'id': 'plumbing', 'name': 'سباكة', 'icon': '🚰'},
    {'id': 'electrical', 'name': 'كهرباء', 'icon': '⚡'},
    {'id': 'ac', 'name': 'تكييف', 'icon': '❄️'},
    {'id': 'cleaning', 'name': 'نظافة', 'icon': '🧹'},
    {'id': 'painting', 'name': 'دهانات', 'icon': '🎨'},
    {'id': 'carpentry', 'name': 'نجارة', 'icon': '🔨'},
    {'id': 'other', 'name': 'أخرى', 'icon': '🔧'},
  ];

  static const Map<String, Map<String, dynamic>> priorities = {
    'urgent': {'name': 'عاجل', 'color': 0xFFA65F57, 'responseTime': '2 ساعة'},
    'high': {'name': 'مرتفع', 'color': 0xFFB58D3D, 'responseTime': '24 ساعة'},
    'medium': {'name': 'متوسط', 'color': 0xFF47736E, 'responseTime': '3 أيام'},
    'low': {'name': 'منخفض', 'color': 0xFF0F3A30, 'responseTime': '7 أيام'},
  };

  static Map<String, dynamic> _normalizeRequest(Map<String, dynamic> r) {
    final status = MaintenanceStatus.normalize(r['status']?.toString());
    String priority = r['priority']?.toString() ?? r['urgency']?.toString() ?? 'medium';
    if (priority == 'عاجل') priority = 'urgent';
    if (priority == 'مرتفع') priority = 'high';
    if (priority == 'متوسط') priority = 'medium';
    if (priority == 'منخفض') priority = 'low';

    final timeline = r['timeline'];
    List<Map<String, dynamic>> events = [];
    if (timeline is List) {
      events = timeline
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return {
      'id': r['_id']?.toString() ?? r['id']?.toString() ?? '',
      'userId': r['user']?.toString() ?? r['userId']?.toString() ?? r['tenantId']?.toString() ?? '',
      'tenantId': r['tenantId']?.toString() ?? r['userId']?.toString() ?? r['user']?.toString() ?? '',
      'ownerId': r['ownerId']?.toString() ?? '',
      'propertyId': r['property']?.toString() ?? r['propertyId']?.toString() ?? '',
      'technicianId': r['technicianId']?.toString() ?? r['assignedTo']?.toString() ?? '',
      'assignedTo': r['assignedTo']?.toString() ?? r['technicianId']?.toString() ?? '',
      'category': r['type'] ?? r['category'] ?? 'other',
      'priority': priority,
      'urgency': priority,
      'title': safeStr(
        r['title'] ?? r['description']?.toString().split('\n').first,
        'طلب صيانة',
      ),
      'description': safeStr(r['description']),
      'status': status,
      'createdAt': r['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': r['updatedAt'] ?? DateTime.now().toIso8601String(),
      'scheduledAt': r['scheduledAt'],
      'completedAt': r['completedAt'],
      'estimatedCost': double.tryParse((r['estimatedCost'] ?? r['quotePrice'] ?? '0').toString()) ?? 0.0,
      'finalCost': double.tryParse((r['finalCost'] ?? r['actualCost'] ?? '0').toString()) ?? 0.0,
      'actualCost': double.tryParse((r['actualCost'] ?? r['finalCost'] ?? '0').toString()) ?? 0.0,
      'budgetCap': double.tryParse((r['budgetCap'] ?? '0').toString()) ?? 0.0,
      'clientConfirmed': r['clientConfirmed'] == true,
      'paymentStatus': r['paymentStatus']?.toString() ?? 'unpaid',
      'rejectReason': r['rejectReason']?.toString(),
      'disputeReason': r['disputeReason']?.toString(),
      'images': safeStrList(r['images']),
      'userName': r['userName']?.toString() ??
          r['tenantName']?.toString() ??
          r['tenantId']?.toString() ??
          '',
      'customerPhone': r['customerPhone']?.toString() ??
          r['tenantPhone']?.toString() ??
          '',
      'lat': r['lat'],
      'lng': r['lng'],
      'rating': r['rating'],
      'feedback': r['feedback'],
      'timeline': events,
      'propertyTitle': r['propertyTitle']?.toString() ?? '',
      'tenantName': r['tenantName']?.toString() ?? '',
      'tenantPhone': r['tenantPhone']?.toString() ?? '',
      'techAccepted': r['techAccepted'] == true,
    };
  }

  static Future<void> _persist(List<Map<String, dynamic>> requests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_requestsKey, jsonEncode(requests));
  }

  static Future<String?> _resolveOwnerId(String propertyId) async {
    if (propertyId.isEmpty) return 'owner@ejari.app';
    try {
      final bookings = await DataService.getBookings();
      for (final b in bookings) {
        if (b['propertyId']?.toString() == propertyId ||
            b['id']?.toString() == propertyId) {
          return b['ownerEmail']?.toString() ?? b['ownerId']?.toString();
        }
      }
      final props = await DataService.getAllProperties();
      for (final p in props) {
        if (p['id']?.toString() == propertyId) {
          return p['ownerId']?.toString() ?? p['ownerEmail']?.toString() ?? 'owner@ejari.app';
        }
      }
    } catch (_) {}
    return 'owner@ejari.app';
  }

  static Future<void> _notifyParties(
    Map<String, dynamic> request, {
    required String title,
    required String body,
    String? actorEmail,
  }) async {
    final tenantId = request['tenantId']?.toString() ?? '';
    final ownerId = request['ownerId']?.toString() ?? '';
    final techId = request['technicianId']?.toString() ?? '';
    final refId = request['id']?.toString() ?? '';
    const adminId = 'admin@ejari.app';

    if (tenantId.isNotEmpty && tenantId != actorEmail) {
      await DataService.addNotificationToUser(
        tenantId, title, body,
        type: 'maintenance', refId: refId,
      );
    }
    if (ownerId.isNotEmpty && ownerId != actorEmail && ownerId != tenantId) {
      await DataService.addNotificationToUser(
        ownerId, title, body,
        type: 'maintenance', refId: refId,
      );
    }
    if (techId.isNotEmpty && techId != actorEmail) {
      await DataService.addNotificationToUser(
        techId, title, body,
        type: 'maintenance', refId: refId,
      );
    }
    if (adminId != actorEmail) {
      await DataService.addNotificationToUser(
        adminId, title, body,
        type: 'maintenance', refId: refId, adminFeed: true,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_requestsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((r) => _normalizeRequest(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _addTimelineEvent(
    List<Map<String, dynamic>> requests,
    int index,
    String status, {
    String? note,
    String? actor,
  }) async {
    final events = List<Map<String, dynamic>>.from(
      (requests[index]['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    events.add({
      'status': MaintenanceStatus.normalize(status),
      'label': MaintenanceStatus.labelAr(status),
      'note': note ?? '',
      'actor': actor ?? '',
      'at': DateTime.now().toIso8601String(),
    });
    requests[index]['timeline'] = events;
  }

  static Future<bool> _transition(
    String requestId,
    String newStatus, {
    Map<String, dynamic> extra = const {},
    String? note,
    String? actor,
    bool notify = true,
  }) async {
    final requests = await getAllRequests();
    final index = requests.indexWhere((r) => r['id'] == requestId);
    if (index == -1) return false;

    final normalized = MaintenanceStatus.normalize(newStatus);
    requests[index]['status'] = normalized;
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();
    requests[index].addAll(extra);

    if (normalized == MaintenanceStatus.completed ||
        normalized == MaintenanceStatus.paid) {
      requests[index]['completedAt'] ??= DateTime.now().toIso8601String();
    }

    await _addTimelineEvent(requests, index, normalized, note: note, actor: actor);
    await _persist(requests);

    if (notify) {
      await _notifyParties(
        requests[index],
        title: 'تحديث طلب صيانة',
        body: '${MaintenanceStatus.labelAr(normalized)} — ${requests[index]['title']}',
        actorEmail: actor,
      );
    }
    return true;
  }

  static Future<void> initDemoRequests() async {
    final prefs = await SharedPreferences.getInstance();
    const seedKey = 'demo_maintenance_seeded_v3';
    if (prefs.getBool(seedKey) == true) return;

    final existing = await getAllRequests();
    if (existing.isNotEmpty) {
      await prefs.setBool(seedKey, true);
      return;
    }

    final now = DateTime.now();
    final demo = [
      {
        'id': 'MNT-DEMO-001',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'egy1',
        'propertyTitle': 'شقة المعادي الفاخرة',
        'category': 'ac',
        'priority': 'high',
        'slaDeadline': now.add(const Duration(hours: 8)).toIso8601String(),
        'title': 'صيانة تكييف',
        'description': 'التكييف لا يبرد بشكل جيد والشحنة تحتاج فحص',
        'status': MaintenanceStatus.inProgress,
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'technicianId': 'tech@ejari.app',
        'assignedTo': 'tech@ejari.app',
        'estimatedCost': 250.0,
        'finalCost': 0.0,
        'paymentStatus': 'unpaid',
        'timeline': [
          {'status': MaintenanceStatus.submitted, 'label': 'مُرسَل', 'at': now.subtract(const Duration(days: 1)).toIso8601String()},
          {'status': MaintenanceStatus.assigned, 'label': 'مُعيَّن', 'at': now.subtract(const Duration(hours: 20)).toIso8601String()},
          {'status': MaintenanceStatus.inProgress, 'label': 'قيد التنفيذ', 'at': now.subtract(const Duration(hours: 4)).toIso8601String()},
        ],
      },
      {
        'id': 'MNT-DEMO-002',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'egy2',
        'propertyTitle': 'فيلا التجمع الخامس',
        'category': 'plumbing',
        'priority': 'medium',
        'slaDeadline': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'title': 'تسريب مياه',
        'description': 'تسريب بسيط في الحمام الرئيسي',
        'status': MaintenanceStatus.submitted,
        'createdAt': now.subtract(const Duration(hours: 52)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(hours: 52)).toIso8601String(),
        'estimatedCost': 150.0,
        'paymentStatus': 'unpaid',
        'timeline': [
          {'status': MaintenanceStatus.submitted, 'label': 'مُرسَل', 'at': now.subtract(const Duration(hours: 52)).toIso8601String()},
        ],
      },
      {
        'id': 'MNT-DEMO-OVERDUE',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'shared_egy1',
        'propertyTitle': 'إقامة مشتركة — المعادي',
        'category': 'electrical',
        'priority': 'high',
        'slaDeadline': now.subtract(const Duration(hours: 12)).toIso8601String(),
        'title': 'عطل كهربائي — متأخر SLA',
        'description': 'انقطاع التيار في الغرفة المشتركة',
        'status': MaintenanceStatus.submitted,
        'createdAt': now.subtract(const Duration(hours: 30)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(hours: 30)).toIso8601String(),
        'estimatedCost': 200.0,
        'paymentStatus': 'unpaid',
        'timeline': [
          {'status': MaintenanceStatus.submitted, 'label': 'مُرسَل', 'at': now.subtract(const Duration(hours: 30)).toIso8601String()},
        ],
      },
      {
        'id': 'MNT-DEMO-003',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'egy1',
        'propertyTitle': 'شقة المعادي الفاخرة',
        'category': 'cleaning',
        'priority': 'low',
        'title': 'تنظيف شامل',
        'description': 'تنظيف شامل بعد الانتقال',
        'status': MaintenanceStatus.paid,
        'createdAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'technicianId': 'tech@ejari.app',
        'assignedTo': 'tech@ejari.app',
        'estimatedCost': 300.0,
        'finalCost': 300.0,
        'actualCost': 300.0,
        'completedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'clientConfirmed': true,
        'paymentStatus': 'paid',
        'rating': 5,
        'technicianRating': 5,
        'feedback': 'خدمة ممتازة',
        'timeline': [
          {'status': MaintenanceStatus.submitted, 'label': 'مُرسَل', 'at': now.subtract(const Duration(days: 5)).toIso8601String()},
          {'status': MaintenanceStatus.paid, 'label': 'مدفوع', 'at': now.subtract(const Duration(days: 2)).toIso8601String()},
        ],
      },
    ];

    await _persist(demo.map(_normalizeRequest).toList());
    await prefs.setBool(seedKey, true);
  }

  /// Ensures the technician demo account always has visible arrived / in-progress
  /// work after maintenance-status updates (ef11b96+).
  static Future<void> ensureTechnicianHomeDemo() async {
    final prefs = await SharedPreferences.getInstance();
    const patchKey = 'demo_tech_home_patch_v1';
    if (prefs.getBool(patchKey) == true) return;

    final requests = await getAllRequests();
    final now = DateTime.now();
    var changed = false;

    final hasActive = requests.any((r) {
      final tech = r['technicianId']?.toString() ?? r['assignedTo']?.toString();
      if (tech != 'tech@ejari.app') return false;
      final s = MaintenanceStatus.normalize(r['status']);
      return s == MaintenanceStatus.inProgress ||
          s == MaintenanceStatus.arrived ||
          s == MaintenanceStatus.enRoute ||
          (s == MaintenanceStatus.assigned && r['techAccepted'] == true);
    });

    if (!hasActive) {
      requests.add(_normalizeRequest({
        'id': 'MNT-DEMO-ARRIVED',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'egy1',
        'propertyTitle': 'شقة المعادي الفاخرة',
        'category': 'plumbing',
        'priority': 'high',
        'title': 'إصلاح صنبور — وصل الفني',
        'description': 'تسريب في المطبخ — الفني وصل للموقع',
        'status': MaintenanceStatus.arrived,
        'createdAt': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'technicianId': 'tech@ejari.app',
        'assignedTo': 'tech@ejari.app',
        'techAccepted': true,
        'estimatedCost': 180.0,
        'paymentStatus': 'unpaid',
        'timeline': [
          {
            'status': MaintenanceStatus.submitted,
            'label': 'مُرسَل',
            'at': now.subtract(const Duration(hours: 6)).toIso8601String(),
          },
          {
            'status': MaintenanceStatus.assigned,
            'label': 'مُعيَّن',
            'at': now.subtract(const Duration(hours: 4)).toIso8601String(),
          },
          {
            'status': MaintenanceStatus.arrived,
            'label': 'وصل الفني',
            'at': now.subtract(const Duration(minutes: 20)).toIso8601String(),
          },
        ],
      }));
      changed = true;
    }

    final hasNew = requests.any((r) {
      final tech = r['technicianId']?.toString() ?? r['assignedTo']?.toString();
      return tech == 'tech@ejari.app' &&
          MaintenanceStatus.normalize(r['status']) == MaintenanceStatus.assigned &&
          r['techAccepted'] != true;
    });
    if (!hasNew) {
      requests.add(_normalizeRequest({
        'id': 'MNT-DEMO-NEW',
        'tenantId': 'user@ejari.app',
        'userId': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'propertyId': 'egy2',
        'propertyTitle': 'فيلا التجمع الخامس',
        'category': 'electrical',
        'priority': 'medium',
        'title': 'فحص لوحة كهرباء',
        'description': 'طلب جديد بانتظار قبول الفني',
        'status': MaintenanceStatus.assigned,
        'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'technicianId': 'tech@ejari.app',
        'assignedTo': 'tech@ejari.app',
        'techAccepted': false,
        'estimatedCost': 220.0,
        'paymentStatus': 'unpaid',
        'timeline': [
          {
            'status': MaintenanceStatus.submitted,
            'label': 'مُرسَل',
            'at': now.subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'status': MaintenanceStatus.assigned,
            'label': 'مُعيَّن',
            'at': now.subtract(const Duration(hours: 1)).toIso8601String(),
          },
        ],
      }));
      changed = true;
    }

    if (changed) await _persist(requests);
    await prefs.setBool(patchKey, true);
  }

  static Future<String> createRequest({
    required String userId,
    required String propertyId,
    required String category,
    required String priority,
    required String title,
    required String description,
    String? propertyTitle,
    String? scheduledAt,
    double? lat,
    double? lng,
    List<String>? images,
  }) async {
    final requestId = 'MNT${DateTime.now().millisecondsSinceEpoch}';
    final ownerId = await _resolveOwnerId(propertyId);
    final now = DateTime.now().toIso8601String();

    // الديمو يعتمد SharedPreferences — نحفظ محلياً أولاً لضمان عمل إنشاء الطلب.
    final request = _normalizeRequest({
      'id': requestId,
      'tenantId': userId,
      'userId': userId,
      'ownerId': ownerId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle ?? '',
      'category': category,
      'priority': priority,
      'title': title,
      'description': description,
      'images': images ?? [],
      'lat': lat ?? 30.0444,
      'lng': lng ?? 31.2357,
      'status': MaintenanceStatus.submitted,
      'createdAt': now,
      'updatedAt': now,
      'scheduledAt': scheduledAt,
      'estimatedCost': FinancialService.generateTechnicianQuote(
        safeStr(
          categories
              .firstWhere((c) => c['id'] == category,
                  orElse: () => {'name': 'أخرى'})['name'],
          'أخرى',
        ),
      ),
      'paymentStatus': 'unpaid',
      'timeline': [
        {'status': MaintenanceStatus.submitted, 'label': 'مُرسَل', 'note': 'تم إرسال الطلب', 'at': now},
      ],
    });

    final requests = await getAllRequests();
    requests.add(request);
    await _persist(requests);

    await DataService.addNotificationToUser(
      'admin@ejari.app',
      'طلب صيانة جديد 🔧',
      '$title — أولوية ${priorities[priority]?['name'] ?? priority}',
      type: 'maintenance',
      refId: requestId,
      adminFeed: true,
    );
    if (ownerId != null && ownerId.isNotEmpty) {
      await DataService.addNotificationToUser(
        ownerId,
        'طلب صيانة على عقارك',
        '$title — بانتظار الموافقة والتعيين',
        type: 'maintenance',
        refId: requestId,
      );
    }
    await DataService.addNotificationToUser(
      userId,
      'تم إرسال طلب الصيانة ✅',
      'سيتم مراجعته وتعيين فني قريباً',
      type: 'maintenance',
      refId: requestId,
    );

    return requestId;
  }

  static Future<void> submitRequest(Map<String, dynamic> application) async {
    await createRequest(
      userId: application['email'] ?? 'unknown',
      propertyId: 'none',
      category: application['service'] ?? 'other',
      priority: 'medium',
      title: application['service'] ?? 'Registration',
      description: 'Experience: ${application['experience']}\nNotes: ${application['notes']}',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllRequests() async {
    final local = await _readLocal();
    try {
      final response = await ApiClient.get('/maintenance');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final rawList = decoded['data'] as List? ?? [];
          final requests = rawList
              .map((r) => _normalizeRequest(r as Map<String, dynamic>))
              .toList();
          // لا نستبدل التخزين المحلي بنتيجة فارغة من الـ API (وضع الديمو).
          if (requests.isEmpty && local.isNotEmpty) return local;
          await _persist(requests);
          return requests;
        }
      }
    } catch (e) {
      debugPrint('GetAllRequests API Error: $e. Using local cache.');
    }
    return local;
  }

  static Future<List<Map<String, dynamic>>> getUserRequests(String userId) async {
    final all = await getAllRequests();
    return all.where((r) => r['tenantId'] == userId || r['userId'] == userId).toList();
  }

  static Future<List<Map<String, dynamic>>> getOwnerRequests(String ownerId) async {
    final all = await getAllRequests();
    return all.where((r) => r['ownerId'] == ownerId).toList();
  }

  static Future<List<Map<String, dynamic>>> getTechnicianRequests(String techId) async {
    final all = await getAllRequests();
    return all
        .where((r) =>
            r['technicianId'] == techId ||
            r['assignedTo'] == techId ||
            (MaintenanceStatus.normalize(r['status']) == MaintenanceStatus.assigned &&
                (r['technicianId'] == null || r['technicianId'].toString().isEmpty)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getPendingForTechnician(String techId) async {
    final all = await getAllRequests();
    return all
        .where((r) =>
            MaintenanceStatus.normalize(r['status']) == MaintenanceStatus.assigned &&
            (r['technicianId'] == techId || r['assignedTo'] == techId))
        .toList();
  }

  static Future<Map<String, dynamic>?> getRequest(String requestId) async {
    final requests = await getAllRequests();
    try {
      return requests.firstWhere((r) => r['id'] == requestId);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateStatus(
    String requestId,
    String status, {
    String? assignedTo,
    double? estimatedCost,
    String? actor,
  }) async {
    final extra = <String, dynamic>{};
    if (assignedTo != null) {
      extra['assignedTo'] = assignedTo;
      extra['technicianId'] = assignedTo;
    }
    if (estimatedCost != null) extra['estimatedCost'] = estimatedCost;
    return _transition(requestId, status, extra: extra, actor: actor);
  }

  static Future<bool> assignTechnician(
    String requestId,
    String technicianId, {
    String? actor,
    double? estimatedCost,
  }) async {
    final ok = await _transition(
      requestId,
      MaintenanceStatus.assigned,
      extra: {
        'technicianId': technicianId,
        'assignedTo': technicianId,
        if (estimatedCost != null) 'estimatedCost': estimatedCost,
      },
      note: 'تم تعيين الفني',
      actor: actor,
    );
    if (ok) {
      final req = await getRequest(requestId);
      await DataService.addNotificationToUser(
        technicianId,
        'مهمة صيانة جديدة 🔧',
        '${req?['title'] ?? 'طلب صيانة'} — بانتظار قبولك',
        type: 'maintenance',
        refId: requestId,
      );
    }
    return ok;
  }

  static Future<bool> approveBudget(
    String requestId, {
    required String ownerId,
    required double budgetCap,
  }) async {
    return _transition(
      requestId,
      MaintenanceStatus.submitted,
      extra: {'budgetCap': budgetCap, 'ownerApproved': true},
      note: 'وافق المالك على ميزانية بحد $budgetCap ج.م',
      actor: ownerId,
    );
  }

  static Future<bool> acceptJob(String requestId, String techId) async {
    return _transition(
      requestId,
      MaintenanceStatus.assigned,
      extra: {'technicianId': techId, 'assignedTo': techId, 'techAccepted': true},
      note: 'قبل الفني المهمة',
      actor: techId,
    );
  }

  static Future<bool> rejectJob(String requestId, String techId, String reason) async {
    return _transition(
      requestId,
      MaintenanceStatus.rejected,
      extra: {'rejectReason': reason, 'technicianId': null, 'assignedTo': null},
      note: reason,
      actor: techId,
    );
  }

  static Future<bool> markEnRoute(String requestId, String techId) async {
    final ok = await _transition(
      requestId,
      MaintenanceStatus.enRoute,
      note: 'الفني في الطريق',
      actor: techId,
    );
    if (ok) {
      final req = await getRequest(requestId);
      final tenantId = req?['tenantId']?.toString() ?? '';
      if (tenantId.isNotEmpty) {
        await DataService.addNotificationToUser(
          tenantId,
          'الفني في الطريق 🚗',
          'فني الصيانة متجه إلى موقعك الآن',
          type: 'maintenance',
          refId: requestId,
        );
      }
    }
    return ok;
  }

  static Future<bool> markArrived(String requestId, String techId) async {
    final ok = await _transition(
      requestId,
      MaintenanceStatus.arrived,
      note: 'وصل الفني إلى موقع العميل',
      actor: techId,
    );
    if (ok) {
      final req = await getRequest(requestId);
      final tenantId = req?['tenantId']?.toString() ?? '';
      if (tenantId.isNotEmpty) {
        await DataService.addNotificationToUser(
          tenantId,
          'وصل الفني 📍',
          'فني الصيانة وصل إلى موقعك',
          type: 'maintenance',
          refId: requestId,
        );
      }
    }
    return ok;
  }

  static Future<bool> startJob(String requestId, String techId) async {
    return _transition(
      requestId,
      MaintenanceStatus.inProgress,
      note: 'بدأ الفني العمل',
      actor: techId,
    );
  }

  /// تأكيد المستأجر لإتمام الخدمة (قبل الدفع).
  static Future<bool> confirmCompletion(
    String requestId,
    String tenantId,
  ) async {
    final req = await getRequest(requestId);
    if (req == null) return false;
    if (MaintenanceStatus.normalize(req['status']?.toString()) !=
        MaintenanceStatus.pendingClientConfirm) {
      return false;
    }
    return _transition(
      requestId,
      MaintenanceStatus.completed,
      extra: {'clientConfirmed': true},
      note: 'أكد العميل إتمام الخدمة',
      actor: tenantId,
    );
  }

  static Future<bool> completeJob(
    String requestId,
    String techId,
    double finalCost,
  ) async {
    final ok = await _transition(
      requestId,
      MaintenanceStatus.pendingClientConfirm,
      extra: {'finalCost': finalCost, 'actualCost': finalCost},
      note: 'أنهى الفني العمل — التكلفة النهائية $finalCost ج.م',
      actor: techId,
    );
    if (ok) {
      final req = await getRequest(requestId);
      final tenantId = req?['tenantId']?.toString() ?? '';
      if (tenantId.isNotEmpty) {
        await DataService.addNotificationToUser(
          tenantId,
          'أكد إتمام الصيانة ✋',
          'يرجى تأكيد إتمام العمل أو فتح نزاع',
          type: 'maintenance',
          refId: requestId,
        );
      }
    }
    return ok;
  }

  /// دفع من محفظة المستأجر بعد التأكيد (أو تأكيد+دفع معاً للتوافق).
  static Future<Map<String, dynamic>> confirmAndPay({
    required String requestId,
    required String tenantId,
    bool useWallet = true,
    String method = 'wallet',
    bool confirmIfNeeded = true,
  }) async {
    var req = await getRequest(requestId);
    if (req == null) return {'success': false, 'message': 'الطلب غير موجود'};

    var status = MaintenanceStatus.normalize(req['status']?.toString());

    if (confirmIfNeeded && status == MaintenanceStatus.pendingClientConfirm) {
      final confirmed = await confirmCompletion(requestId, tenantId);
      if (!confirmed) {
        return {'success': false, 'message': 'تعذّر تأكيد إتمام الخدمة'};
      }
      req = await getRequest(requestId);
      if (req == null) return {'success': false, 'message': 'الطلب غير موجود'};
      status = MaintenanceStatus.normalize(req['status']?.toString());
    }

    if (status != MaintenanceStatus.completed) {
      return {
        'success': false,
        'message': status == MaintenanceStatus.pendingClientConfirm
            ? 'يرجى تأكيد إتمام الخدمة أولاً'
            : 'الطلب ليس بانتظار الدفع',
      };
    }

    final amount = (req['finalCost'] as num?)?.toDouble() ??
        (req['estimatedCost'] as num?)?.toDouble() ??
        0.0;
    if (amount <= 0) {
      return {'success': false, 'message': 'التكلفة غير محددة'};
    }

    final result = await DataService.payForMaintenanceService(
      requestId,
      amount: amount,
      tenantId: tenantId,
      technicianId: req['technicianId']?.toString() ?? 'tech@ejari.app',
      ownerId: req['ownerId']?.toString(),
      title: req['title']?.toString() ?? 'صيانة',
      useWallet: useWallet,
      method: method,
    );

    if (result['success'] != true) return result;

    await _transition(
      requestId,
      MaintenanceStatus.paid,
      extra: {'paymentStatus': 'paid', 'clientConfirmed': true},
      note: 'تم الدفع وإغلاق الطلب',
      actor: tenantId,
    );

    return result;
  }

  static Future<bool> disputeCompletion(
    String requestId,
    String tenantId,
    String reason,
  ) async {
    final ok = await _transition(
      requestId,
      MaintenanceStatus.disputed,
      extra: {'disputeReason': reason},
      note: reason,
      actor: tenantId,
    );
    if (ok) {
      await DataService.addNotificationToUser(
        'admin@ejari.app',
        'نزاع صيانة ⚠️',
        reason,
        type: 'maintenance',
        refId: requestId,
        adminFeed: true,
      );
    }
    return ok;
  }

  static Future<bool> resolveDispute(
    String requestId,
    String resolution, {
    String? actor,
  }) async {
    switch (resolution) {
      case 'reassign':
        return _transition(
          requestId,
          MaintenanceStatus.submitted,
          extra: {
            'technicianId': null,
            'assignedTo': null,
            'disputeReason': null,
            'techAccepted': false,
          },
          note: 'تم إعادة فتح الطلب بعد النزاع',
          actor: actor,
        );
      case 'close':
        return _transition(
          requestId,
          MaintenanceStatus.completed,
          extra: {'disputeReason': null},
          note: 'تم إغلاق النزاع من الإدارة',
          actor: actor,
        );
      case 'approve_refund':
        return _transition(
          requestId,
          MaintenanceStatus.cancelled,
          extra: {'disputeReason': null, 'refundApproved': true},
          note: 'تم حل النزاع — استرداد للعميل',
          actor: actor,
        );
      default:
        return false;
    }
  }

  static Future<bool> attachDemoPhotos(String requestId) async {
    final requests = await getAllRequests();
    final index = requests.indexWhere((r) => r['id']?.toString() == requestId);
    if (index == -1) return false;
    requests[index]['photos'] = [
      'assets/images/home1.jpg',
      'assets/images/home2.jpg',
    ];
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();
    await _persist(requests);
    return true;
  }

  static Future<bool> cancelRequest(
    String requestId, {
    String? reason,
    String? actor,
  }) async {
    return _transition(
      requestId,
      MaintenanceStatus.cancelled,
      note: reason ?? 'تم الإلغاء',
      actor: actor,
    );
  }

  static Future<bool> addFeedback(String requestId, int rating, String feedback) async {
    try {
      await ApiClient.post('/maintenance/$requestId/rating', {
        'rating': rating,
        'comment': feedback,
      });
    } catch (e) {
      debugPrint('AddFeedback API Error: $e');
    }

    final requests = await getAllRequests();
    final index = requests.indexWhere((r) => r['id'] == requestId);
    if (index == -1) return false;

    requests[index]['rating'] = rating;
    requests[index]['technicianRating'] = rating;
    requests[index]['feedback'] = feedback;
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();
    await _persist(requests);
    return true;
  }

  /// تقييم الفني بعد إتمام العمل.
  static Future<bool> rateTechnician(
    String requestId,
    int rating, {
    String feedback = '',
  }) =>
      addFeedback(requestId, rating, feedback);

  static Future<List<Map<String, dynamic>>> getOverdueSlaRequests() async {
    final all = await getAllRequests();
    return all.where(MaintenanceStatus.isSlaOverdue).toList();
  }

  static Future<Map<String, int>> getStatistics(String userId) async {
    final userRequests = await getUserRequests(userId);
    int count(String s) =>
        userRequests.where((r) => MaintenanceStatus.normalize(r['status']) == s).length;

    return {
      'total': userRequests.length,
      'submitted': count(MaintenanceStatus.submitted),
      'pending': count(MaintenanceStatus.submitted) + count(MaintenanceStatus.assigned),
      'in_progress': count(MaintenanceStatus.inProgress) +
          count(MaintenanceStatus.enRoute) +
          count(MaintenanceStatus.assigned),
      'completed': count(MaintenanceStatus.completed) + count(MaintenanceStatus.paid),
      'pending_confirm': count(MaintenanceStatus.pendingClientConfirm),
    };
  }

  static Future<Map<String, dynamic>> getTechnicianStats(String techId) async {
    final jobs = await getTechnicianRequests(techId);
    double earnings = 0;
    int completed = 0;
    int active = 0;
    int urgent = 0;
    int newRequests = 0;

    for (final j in jobs) {
      final st = MaintenanceStatus.normalize(j['status']);
      if (st == MaintenanceStatus.paid) {
        earnings += (j['finalCost'] as num?)?.toDouble() ?? 0;
        completed++;
      }
      if ([
        MaintenanceStatus.assigned,
        MaintenanceStatus.enRoute,
        MaintenanceStatus.arrived,
        MaintenanceStatus.inProgress,
      ].contains(st)) {
        active++;
      }
      if (st == MaintenanceStatus.assigned) newRequests++;
      if (j['priority'] == 'urgent' &&
          ![MaintenanceStatus.paid, MaintenanceStatus.cancelled, MaintenanceStatus.rejected]
              .contains(st)) {
        urgent++;
      }
    }

    final balance = await WalletService.getBalance(userId: techId);

    return {
      'earnings': earnings,
      'completedCount': completed,
      'completedJobs': completed,
      'activeJobs': active,
      'newRequests': newRequests,
      'urgentRequests': urgent,
      'rating': 4.8,
      'todayEarnings': earnings > 0 ? (earnings * 0.1).round() : 0,
      'monthlyEarnings': earnings,
      'availableBalance': balance,
    };
  }

  /// تحويل طلب صيانة لعرض الفني (توافق مع الشاشات القديمة).
  static Map<String, dynamic> toProviderView(Map<String, dynamic> r) {
    final cat = categories.firstWhere(
      (c) => c['id'] == r['category'],
      orElse: () => {'name': r['category'] ?? 'صيانة'},
    );
    return {
      'id': r['id'],
      'service': r['title'] ?? cat['name'],
      'customer': r['tenantName']?.toString().isNotEmpty == true
          ? r['tenantName']
          : r['tenantId'] ?? 'عميل',
      'phone': r['tenantPhone'] ?? '',
      'customerPhone': r['tenantPhone'] ?? '',
      'date': r['scheduledAt'] ?? r['createdAt'],
      'address': r['propertyTitle']?.toString().isNotEmpty == true
          ? r['propertyTitle']
          : r['propertyId'] ?? 'موقع العميل',
      'status': _providerStatusMap(r['status']),
      'price': (r['finalCost'] as num?)?.toDouble() ??
          (r['estimatedCost'] as num?)?.toDouble() ??
          0.0,
      'notes': r['description'] ?? '',
      'lat': r['lat'],
      'lng': r['lng'],
      'raw': r,
    };
  }

  static String _providerStatusMap(dynamic status) {
    final n = MaintenanceStatus.normalize(status?.toString());
    if (n == MaintenanceStatus.assigned) return 'pending';
    if (n == MaintenanceStatus.enRoute ||
        n == MaintenanceStatus.arrived ||
        n == MaintenanceStatus.inProgress) {
      return 'in_progress';
    }
    if (n == MaintenanceStatus.pendingClientConfirm) return 'in_progress';
    if (n == MaintenanceStatus.completed) return 'completed';
    if (n == MaintenanceStatus.paid) return 'completed';
    if (n == MaintenanceStatus.rejected || n == MaintenanceStatus.cancelled) {
      return 'cancelled';
    }
    return n;
  }

  static Future<bool> updateProviderJobStatus(String jobId, String legacyStatus) async {
    final req = await getRequest(jobId);
    if (req == null) return false;
    final techId = req['technicianId']?.toString() ?? 'tech@ejari.app';

    return switch (legacyStatus) {
      'accepted' => acceptJob(jobId, techId),
      'cancelled' => rejectJob(jobId, techId, 'رفض من الفني'),
      'en_route' => markEnRoute(jobId, techId),
      'arrived' => markArrived(jobId, techId),
      'in_progress' => startJob(jobId, techId),
      'completed' => completeJob(
          jobId,
          techId,
          (req['estimatedCost'] as num?)?.toDouble() ?? 150,
        ),
      _ => updateStatus(jobId, legacyStatus, actor: techId),
    };
  }
}
