import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/listing_type.dart';
import '../models/viewing_appointment.dart';
import 'auth_service.dart';
import 'data_service.dart';
import 'live_sync_service.dart';

/// تخزين وإدارة مواعيد المعاينة مع صلاحيات الأدوار.
class ViewingAppointmentService {
  ViewingAppointmentService._();

  static const _storageKey = 'viewing_appointments_v1';
  static const _demoSeededKey = 'viewing_appointments_demo_v1';

  static Future<List<ViewingAppointment>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((e) {
          try {
            return ViewingAppointment.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ViewingAppointment>()
        .toList();
  }

  static Future<void> _saveAll(List<ViewingAppointment> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await LiveSyncService.bumpRevision();
  }

  static Future<void> ensureDemoSeed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_demoSeededKey) == true) return;
    final existing = await _loadAll();
    if (existing.isNotEmpty) {
      await prefs.setBool(_demoSeededKey, true);
      return;
    }

    final slot = DateTime.now().add(const Duration(days: 2, hours: 2));
    final demo = ViewingAppointment(
      id: 'view_demo_1',
      propertyId: 'egy1',
      propertyTitle: 'شقة فاخرة على النيل - المعادي',
      propertyImage: 'assets/images/home1.jpg',
      tenantEmail: 'user@ejari.app',
      tenantName: 'مستأجر تجريبي',
      ownerEmail: 'owner@ejari.app',
      scheduledAt: DateTime(slot.year, slot.month, slot.day, 16, 0),
      status: ViewingStatus.requested,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      note: 'معاينة تجريبية — بانتظار موافقة المالك',
    );
    await _saveAll([demo]);
    await prefs.setBool(_demoSeededKey, true);
  }

  static Future<List<ViewingAppointment>> getAll() async {
    await ensureDemoSeed();
    final all = await _loadAll();
    all.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return all;
  }

  static Future<ViewingAppointment?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<ViewingAppointment>> getForTenant(String email) async {
    final all = await getAll();
    final e = email.trim().toLowerCase();
    return all
        .where((v) => v.tenantEmail.trim().toLowerCase() == e)
        .toList();
  }

  static Future<List<ViewingAppointment>> getForOwner(String email) async {
    final all = await getAll();
    final e = email.trim().toLowerCase();
    return all
        .where((v) => v.ownerEmail.trim().toLowerCase() == e)
        .toList();
  }

  static Future<List<ViewingAppointment>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final all = await getAll();
    return all.where((v) {
      return v.id.toLowerCase().contains(q) ||
          v.propertyId.toLowerCase().contains(q) ||
          v.propertyTitle.toLowerCase().contains(q) ||
          v.tenantEmail.toLowerCase().contains(q) ||
          v.tenantName.toLowerCase().contains(q) ||
          v.ownerEmail.toLowerCase().contains(q) ||
          v.status.toLowerCase().contains(q) ||
          ViewingStatus.arabicLabel(v.status).contains(query.trim());
    }).toList();
  }

  /// تعارض اختياري: موعد آخر نشط لنفس العقار في نفس اليوم.
  static Future<bool> hasSameDayConflict({
    required String propertyId,
    required DateTime scheduledAt,
    String? excludeId,
  }) async {
    final all = await getAll();
    final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    return all.any((v) {
      if (excludeId != null && v.id == excludeId) return false;
      if (v.propertyId != propertyId) return false;
      if (!v.isActive && v.status != ViewingStatus.confirmed) return false;
      if (ViewingStatus.normalize(v.status) == ViewingStatus.rejected ||
          ViewingStatus.normalize(v.status) == ViewingStatus.cancelled ||
          ViewingStatus.normalize(v.status) == ViewingStatus.noShow) {
        return false;
      }
      final other = DateTime(
        v.scheduledAt.year,
        v.scheduledAt.month,
        v.scheduledAt.day,
      );
      return other == day &&
          (v.status == ViewingStatus.requested ||
              v.status == ViewingStatus.confirmed ||
              v.status == ViewingStatus.rescheduled);
    });
  }

  static String? validateSlot(DateTime scheduledAt) {
    final now = DateTime.now();
    if (!scheduledAt.isAfter(now)) {
      return 'لا يمكن حجز موعد في الماضي';
    }
    final hour = scheduledAt.hour;
    if (hour < 9 || hour > 20) {
      return 'مواعيد المعاينة متاحة من ٩ صباحاً حتى ٨ مساءً';
    }
    return null;
  }

  static Future<Map<String, dynamic>> requestViewing({
    required Map<String, dynamic> property,
    required DateTime scheduledAt,
    String? note,
  }) async {
    if (isSaleListing(property)) {
      return {
        'success': false,
        'message': 'المعاينة عبر المنصة متاحة لعقارات الإيجار فقط. تواصل مع المعلن مباشرة.',
      };
    }

    final slotError = validateSlot(scheduledAt);
    if (slotError != null) {
      return {'success': false, 'message': slotError};
    }

    final user = await AuthService.getCurrentUser();
    final role = await AuthService.getUserRole();
    if (role != 'tenant' && role != 'user') {
      return {
        'success': false,
        'message': 'طلب المعاينة متاح للمستأجر فقط',
      };
    }

    final tenantEmail = user?['email']?.toString() ?? '';
    if (tenantEmail.isEmpty) {
      return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
    }

    final propertyId =
        property['id']?.toString() ?? property['propertyId']?.toString() ?? '';
    if (propertyId.isEmpty) {
      return {'success': false, 'message': 'عقار غير صالح'};
    }

    final ownerEmail = property['ownerEmail']?.toString() ??
        property['ownerId']?.toString() ??
        'owner@ejari.app';

    final conflict = await hasSameDayConflict(
      propertyId: propertyId,
      scheduledAt: scheduledAt,
    );
    if (conflict) {
      return {
        'success': false,
        'message': 'يوجد موعد معاينة آخر لنفس العقار في هذا اليوم. اختر يوماً آخر.',
      };
    }

    final appointment = ViewingAppointment(
      id: 'view_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyTitle: property['title']?.toString() ?? 'عقار',
      propertyImage: property['image']?.toString() ??
          (property['images'] is List && (property['images'] as List).isNotEmpty
              ? (property['images'] as List).first.toString()
              : null),
      tenantEmail: tenantEmail,
      tenantName: user?['name']?.toString() ??
          user?['fullName']?.toString() ??
          'مستأجر',
      ownerEmail: ownerEmail,
      scheduledAt: scheduledAt.toUtc().isUtc
          ? scheduledAt
          : DateTime(
              scheduledAt.year,
              scheduledAt.month,
              scheduledAt.day,
              scheduledAt.hour,
              scheduledAt.minute,
            ),
      status: ViewingStatus.requested,
      createdAt: DateTime.now(),
      note: note,
    );

    final all = await _loadAll();
    all.add(appointment);
    await _saveAll(all);

    final when = _formatArabicSlot(appointment.scheduledAt);
    await DataService.addNotificationToUser(
      tenantEmail,
      'تم إرسال طلب المعاينة 📅',
      'طلب معاينة ${appointment.propertyTitle} — $when',
      type: 'viewing',
      refId: appointment.id,
    );
    await DataService.addNotificationToUser(
      ownerEmail,
      'طلب معاينة جديد 🔔',
      '${appointment.tenantName} يطلب معاينة ${appointment.propertyTitle} — $when',
      type: 'viewing',
      refId: appointment.id,
    );
    await DataService.addNotificationToUser(
      'admin@ejari.app',
      'طلب معاينة',
      '${appointment.propertyTitle} — ${appointment.tenantEmail}',
      type: 'viewing',
      refId: appointment.id,
      adminFeed: true,
    );

    return {'success': true, 'id': appointment.id, 'appointment': appointment.toJson()};
  }

  static Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String newStatus,
    DateTime? rescheduleAt,
    String? ownerNote,
    bool tenantConfirmAttendance = false,
    bool ownerMarkComplete = false,
    String? actorRole,
    String? actorEmail,
  }) async {
    final all = await _loadAll();
    final idx = all.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return {'success': false, 'message': 'موعد المعاينة غير موجود'};
    }

    var current = all[idx];
    final role = actorRole ?? await AuthService.getUserRole();
    final email = (actorEmail ??
            (await AuthService.getCurrentUser())?['email']?.toString() ??
            '')
        .trim()
        .toLowerCase();

    final isOwner = email == current.ownerEmail.trim().toLowerCase();
    final isTenant = email == current.tenantEmail.trim().toLowerCase();
    final isAdmin = role == 'admin';

    if (!isAdmin) {
      if (role == 'owner' && !isOwner) {
        return {'success': false, 'message': 'غير مصرح — هذا العقار ليس لك'};
      }
      if ((role == 'tenant' || role == 'user') && !isTenant) {
        return {'success': false, 'message': 'غير مصرح — هذا الطلب ليس لك'};
      }
    }

    final target = ViewingStatus.normalize(newStatus);
    if (!ViewingStatus.canTransition(current.status, target) &&
        !(target == ViewingStatus.completed &&
            (tenantConfirmAttendance || ownerMarkComplete))) {
      return {
        'success': false,
        'message':
            'انتقال غير مسموح من ${ViewingStatus.arabicLabel(current.status)} إلى ${ViewingStatus.arabicLabel(target)}',
      };
    }

    // Owner-only actions
    if ({
      ViewingStatus.confirmed,
      ViewingStatus.rejected,
      ViewingStatus.rescheduled,
      ViewingStatus.noShow,
    }.contains(target)) {
      if (!isOwner && !isAdmin) {
        return {'success': false, 'message': 'هذا الإجراء متاح للمالك فقط'};
      }
    }

    // Tenant cancel only from requested/confirmed
    if (target == ViewingStatus.cancelled && isTenant && !isAdmin) {
      if (current.status != ViewingStatus.requested &&
          current.status != ViewingStatus.confirmed &&
          current.status != ViewingStatus.rescheduled) {
        return {'success': false, 'message': 'لا يمكن الإلغاء في هذه الحالة'};
      }
    }

    DateTime? newSlot = current.scheduledAt;
    if (target == ViewingStatus.rescheduled) {
      if (rescheduleAt == null) {
        return {'success': false, 'message': 'حدد الموعد الجديد'};
      }
      final err = validateSlot(rescheduleAt);
      if (err != null) return {'success': false, 'message': err};
      final conflict = await hasSameDayConflict(
        propertyId: current.propertyId,
        scheduledAt: rescheduleAt,
        excludeId: id,
      );
      if (conflict) {
        return {
          'success': false,
          'message': 'تعارض مع موعد آخر في نفس اليوم',
        };
      }
      newSlot = rescheduleAt;
    }

    final now = DateTime.now();
    var updated = current.copyWith(
      status: target == ViewingStatus.rescheduled
          ? ViewingStatus.requested
          : target,
      scheduledAt: newSlot,
      ownerNote: ownerNote ?? current.ownerNote,
      confirmedAt: target == ViewingStatus.confirmed
          ? now
          : current.confirmedAt,
      completedAt: target == ViewingStatus.completed
          ? now
          : current.completedAt,
      cancelledAt: target == ViewingStatus.cancelled
          ? now
          : current.cancelledAt,
      rejectedAt: target == ViewingStatus.rejected ? now : current.rejectedAt,
      tenantAttended: tenantConfirmAttendance
          ? true
          : current.tenantAttended,
      ownerMarkedComplete: ownerMarkComplete
          ? true
          : current.ownerMarkedComplete,
    );

    // Complete when either party confirms after confirmed state
    if (target == ViewingStatus.completed ||
        ((tenantConfirmAttendance || ownerMarkComplete) &&
            ViewingStatus.normalize(current.status) == ViewingStatus.confirmed)) {
      updated = updated.copyWith(
        status: ViewingStatus.completed,
        completedAt: now,
        tenantAttended: tenantConfirmAttendance || updated.tenantAttended,
        ownerMarkedComplete: ownerMarkComplete || updated.ownerMarkedComplete,
      );
    }

    // After reschedule, notify as requested again
    if (target == ViewingStatus.rescheduled) {
      updated = updated.copyWith(
        status: ViewingStatus.requested,
        confirmedAt: null,
      );
    }

    all[idx] = updated;
    await _saveAll(all);
    await _notifyStatusChange(updated, previous: current);

    // Link booking status when viewing confirmed (if booking exists)
    if (updated.bookingId != null &&
        updated.bookingId!.isNotEmpty &&
        updated.status == ViewingStatus.confirmed) {
      try {
        await DataService.updateRequestStatus(
          updated.bookingId!,
          'viewing_scheduled',
          note: 'موعد معاينة ${_formatArabicSlot(updated.scheduledAt)}',
        );
      } catch (e) {
        debugPrint('Viewing→booking sync skipped: $e');
      }
    }

    return {
      'success': true,
      'appointment': updated.toJson(),
    };
  }

  static Future<void> _notifyStatusChange(
    ViewingAppointment appt, {
    required ViewingAppointment previous,
  }) async {
    final when = _formatArabicSlot(appt.scheduledAt);
    final title = appt.propertyTitle;
    String tenantTitle;
    String tenantBody;
    String ownerTitle;
    String ownerBody;

    switch (ViewingStatus.normalize(appt.status)) {
      case ViewingStatus.confirmed:
        tenantTitle = 'تم تأكيد موعد المعاينة ✅';
        tenantBody = 'معاينة $title مؤكدة — $when';
        ownerTitle = 'أكدت موعد المعاينة';
        ownerBody = 'موعد مع ${appt.tenantName} — $when';
        break;
      case ViewingStatus.rejected:
        tenantTitle = 'تم رفض طلب المعاينة';
        tenantBody = 'رفض المالك معاينة $title${appt.ownerNote != null ? ': ${appt.ownerNote}' : ''}';
        ownerTitle = 'رفضت طلب المعاينة';
        ownerBody = 'رفضت معاينة $title';
        break;
      case ViewingStatus.cancelled:
        tenantTitle = 'تم إلغاء موعد المعاينة';
        tenantBody = 'أُلغي موعد معاينة $title';
        ownerTitle = 'إلغاء موعد معاينة';
        ownerBody = 'أُلغي موعد معاينة $title مع ${appt.tenantName}';
        break;
      case ViewingStatus.completed:
        tenantTitle = 'اكتملت المعاينة 🏠';
        tenantBody = 'تمت معاينة $title. يمكنك المتابعة للحجز إن رغبت.';
        ownerTitle = 'اكتمال المعاينة';
        ownerBody = 'سُجّلت معاينة $title كمكتملة.';
        break;
      case ViewingStatus.noShow:
        tenantTitle = 'تسجيل عدم حضور';
        tenantBody = 'سجّل المالك عدم حضورك لمعاينة $title';
        ownerTitle = 'عدم حضور المستأجر';
        ownerBody = 'تم تسجيل عدم حضور لمعاينة $title';
        break;
      case ViewingStatus.requested:
        if (previous.scheduledAt != appt.scheduledAt) {
          tenantTitle = 'إعادة جدولة المعاينة';
          tenantBody = 'موعد جديد مقترح لـ $title — $when';
          ownerTitle = 'إعادة جدولة';
          ownerBody = 'موعد جديد لـ $title — $when';
        } else {
          return;
        }
        break;
      default:
        return;
    }

    await DataService.addNotificationToUser(
      appt.tenantEmail,
      tenantTitle,
      tenantBody,
      type: 'viewing',
      refId: appt.id,
    );
    await DataService.addNotificationToUser(
      appt.ownerEmail,
      ownerTitle,
      ownerBody,
      type: 'viewing',
      refId: appt.id,
    );
  }

  static String _formatArabicSlot(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} $h:$m';
  }
}
