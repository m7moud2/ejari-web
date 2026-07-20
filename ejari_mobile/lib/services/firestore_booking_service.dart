import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Real Firestore bookings for production (Spark free tier).
class FirestoreBookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// حالات حساب الضمان على مستند الحجز.
  static const escrowNone = 'none';
  static const escrowHeld = 'held';
  static const escrowReleased = 'released';
  static const escrowRefunded = 'refunded';
  static const escrowDisputed = 'disputed';

  static Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> request,
  ) async {
    if (AppConfig.demoMode) {
      throw StateError('FirestoreBookingService is for real mode only');
    }

    final current = await AuthService.getCurrentUser();
    final tenantId = (current?['uid'] ?? current?['id'] ?? current?['_id'])
        ?.toString()
        .trim();
    if (tenantId == null || tenantId.isEmpty) {
      throw 'يجب تسجيل الدخول لإنشاء حجز';
    }

    final propertyId =
        (request['propertyId'] ?? request['property'] ?? '').toString().trim();
    final ownerIdRaw = (request['ownerId'] ?? '').toString().trim();
    final ownerEmailRaw = (request['ownerEmail'] ?? '').toString().trim();
    final ownerId = ownerIdRaw.isNotEmpty ? ownerIdRaw : ownerEmailRaw;
    if (propertyId.isEmpty || ownerId.isEmpty) {
      throw 'بيانات العقار غير مكتملة';
    }

    final tenantEmail =
        (current?['email'] ?? request['tenantEmail'] ?? '').toString().trim();

    final payload = <String, dynamic>{
      'tenantId': tenantId,
      if (tenantEmail.isNotEmpty) 'tenantEmail': tenantEmail,
      'ownerId': ownerId,
      if (ownerEmailRaw.isNotEmpty) 'ownerEmail': ownerEmailRaw,
      if (ownerEmailRaw.isEmpty && ownerId.contains('@')) 'ownerEmail': ownerId,
      'propertyId': propertyId,
      'status': 'pending',
      'paymentStatus': 'pending',
      'escrowStatus': escrowNone,
      'contractStatus': 'none',
      'paidAmount': 0,
      'title': request['title'] ?? '',
      'tenantName': current?['name'] ?? request['tenantName'] ?? '',
      'price': request['price'],
      'monthlyRent': request['monthlyRent'],
      'depositAmount': request['depositAmount'],
      'startDate': request['startDate'] ?? request['leaseStartDate'],
      'endDate': request['endDate'] ?? request['leaseEndDate'],
      'leaseMonths': request['leaseMonths'] ?? request['duration'],
      'durationLabel': request['durationLabel'] ?? request['duration'],
      'specialRequests': request['specialRequests'],
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref = await _db
          .collection('bookings')
          .add(payload)
          .timeout(AppConfig.authTimeout);
      return {'success': true, 'id': ref.id};
    } on TimeoutException {
      throw 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
    } catch (e) {
      debugPrint('Firestore createBooking error: $e');
      if (e is String) rethrow;
      throw 'تعذر إنشاء الحجز. تحقق من الاتصال وحاول مرة أخرى';
    }
  }

  static Future<List<Map<String, dynamic>>> getBookingsForCurrentUser() async {
    if (AppConfig.demoMode) return [];
    final current = await AuthService.getCurrentUser();
    final keys = AuthService.identityKeysFrom(current);
    if (keys.isEmpty) return [];

    try {
      final byId = <String, Map<String, dynamic>>{};
      for (final key in keys) {
        for (final field in [
          'tenantId',
          'tenantEmail',
          'ownerId',
          'ownerEmail',
        ]) {
          final snap = await _db
              .collection('bookings')
              .where(field, isEqualTo: key)
              .get()
              .timeout(AppConfig.authTimeout);
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            byId[doc.id] = _normalize(data);
          }
        }
      }
      final list = byId.values.toList();
      list.sort((a, b) {
        final aDate = a['createdAt']?.toString() ?? '';
        final bDate = b['createdAt']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });
      return list;
    } catch (e) {
      debugPrint('Firestore getBookings error: $e');
      throw 'تعذر تحميل الحجوزات. تحقق من الاتصال';
    }
  }

  static Future<List<Map<String, dynamic>>> getOwnerBookings(
    String ownerId,
  ) async {
    if (AppConfig.demoMode) return [];
    final keys = await AuthService.identityKeysFor(ownerId);
    if (keys.isEmpty) return [];
    try {
      final byId = <String, Map<String, dynamic>>{};
      for (final key in keys) {
        for (final field in ['ownerId', 'ownerEmail']) {
          final snap = await _db
              .collection('bookings')
              .where(field, isEqualTo: key)
              .get()
              .timeout(AppConfig.authTimeout);
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            byId[doc.id] = _normalize(data);
          }
        }
      }
      return byId.values.toList();
    } catch (e) {
      debugPrint('Firestore getOwnerBookings error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    if (AppConfig.demoMode || bookingId.trim().isEmpty) return null;
    try {
      final doc = await _db
          .collection('bookings')
          .doc(bookingId)
          .get()
          .timeout(AppConfig.authTimeout);
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] = doc.id;
      return _normalize(data);
    } catch (e) {
      debugPrint('Firestore getBookingById error: $e');
      return null;
    }
  }

  /// Updates booking status + payment fields in Firestore.
  static Future<bool> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? note,
    Map<String, dynamic>? extraFields,
  }) async {
    if (AppConfig.demoMode || bookingId.trim().isEmpty) return false;
    try {
      final payload = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'statusNote': note,
        ...?extraFields,
      };
      await _db
          .collection('bookings')
          .doc(bookingId)
          .set(payload, SetOptions(merge: true))
          .timeout(AppConfig.authTimeout);
      return true;
    } catch (e) {
      debugPrint('Firestore updateBookingStatus error: $e');
      return false;
    }
  }

  /// Merge arbitrary booking fields (check-in/out, handover, etc.).
  static Future<bool> patchBooking(
    String bookingId,
    Map<String, dynamic> fields,
  ) async {
    if (AppConfig.demoMode || bookingId.trim().isEmpty || fields.isEmpty) {
      return false;
    }
    try {
      await _db
          .collection('bookings')
          .doc(bookingId)
          .set({
            ...fields,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(AppConfig.authTimeout);
      return true;
    } catch (e) {
      debugPrint('Firestore patchBooking error: $e');
      return false;
    }
  }

  /// يحدّث [escrowStatus] والمبالغ/الطوابع الزمنية على مستند الحجز.
  static Future<bool> syncEscrowStatus(
    String bookingId,
    String escrowStatus, {
    double? escrowAmount,
    Map<String, dynamic>? extraFields,
  }) async {
    if (AppConfig.demoMode || bookingId.trim().isEmpty) return false;
    final nowIso = DateTime.now().toIso8601String();
    final fields = <String, dynamic>{
      'escrowStatus': escrowStatus,
      if (escrowAmount != null) 'escrowAmount': escrowAmount,
      ...?extraFields,
    };
    switch (escrowStatus) {
      case escrowHeld:
        fields['escrowHeldAt'] = nowIso;
        break;
      case escrowReleased:
        fields['escrowReleasedAt'] = nowIso;
        break;
      case escrowRefunded:
        fields['escrowRefundedAt'] = nowIso;
        break;
      case escrowDisputed:
        fields['escrowDisputedAt'] = nowIso;
        break;
    }
    return patchBooking(bookingId, fields);
  }

  static Future<bool> recordPayment({
    required String bookingId,
    required String status,
    required double paidAmount,
    required String paymentPhase,
    String? paymentStatus,
    String? method,
  }) async {
    return updateBookingStatus(
      bookingId,
      status,
      extraFields: {
        'paidAmount': paidAmount,
        'paymentPhase': paymentPhase,
        'paymentStatus': paymentStatus ?? paymentPhase,
        if (method != null) 'lastPaymentMethod': method,
        'lastPaidAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        out[key] = value.toDate().toIso8601String();
      } else if (value is FieldValue) {
        // skip
      } else {
        out[key] = value;
      }
    });
    return out;
  }
}
