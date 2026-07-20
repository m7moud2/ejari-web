import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Real Firestore bookings for production (Spark free tier).
class FirestoreBookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    final ownerId = (request['ownerId'] ?? request['ownerEmail'] ?? '')
        .toString()
        .trim();
    if (propertyId.isEmpty || ownerId.isEmpty) {
      throw 'بيانات العقار غير مكتملة';
    }

    final payload = <String, dynamic>{
      'tenantId': tenantId,
      'ownerId': ownerId,
      'propertyId': propertyId,
      'status': 'pending',
      'paymentStatus': 'pending',
      'escrowStatus': 'none',
      'contractStatus': 'none',
      'paidAmount': 0,
      'title': request['title'] ?? '',
      'tenantName': current?['name'] ?? request['tenantName'] ?? '',
      'tenantEmail': current?['email'] ?? request['tenantEmail'] ?? '',
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
    final uid = (current?['uid'] ?? current?['id'] ?? current?['_id'])
        ?.toString()
        .trim();
    if (uid == null || uid.isEmpty) return [];

    try {
      final tenantSnap = await _db
          .collection('bookings')
          .where('tenantId', isEqualTo: uid)
          .get()
          .timeout(AppConfig.authTimeout);
      final ownerSnap = await _db
          .collection('bookings')
          .where('ownerId', isEqualTo: uid)
          .get()
          .timeout(AppConfig.authTimeout);

      final byId = <String, Map<String, dynamic>>{};
      for (final doc in [...tenantSnap.docs, ...ownerSnap.docs]) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        byId[doc.id] = _normalize(data);
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
    try {
      final snap = await _db
          .collection('bookings')
          .where('ownerId', isEqualTo: ownerId)
          .get()
          .timeout(AppConfig.authTimeout);
      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _normalize(data);
      }).toList();
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
