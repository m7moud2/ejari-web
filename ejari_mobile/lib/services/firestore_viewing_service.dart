import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/viewing_appointment.dart';
import 'auth_service.dart';

/// مواعيد المعاينة على Firestore (الإنتاج فقط).
class FirestoreViewingService {
  FirestoreViewingService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _collection = 'viewings';

  static Future<List<ViewingAppointment>> getAll() async {
    if (AppConfig.demoMode) return [];
    try {
      final snap =
          await _db.collection(_collection).get().timeout(AppConfig.authTimeout);
      final list = snap.docs.map(_fromDoc).toList();
      list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return list;
    } catch (e) {
      debugPrint('Firestore getAll viewings error: $e');
      throw 'تعذر تحميل مواعيد المعاينة. تحقق من الاتصال';
    }
  }

  static Future<ViewingAppointment?> getById(String id) async {
    if (AppConfig.demoMode || id.trim().isEmpty) return null;
    try {
      final doc = await _db
          .collection(_collection)
          .doc(id)
          .get()
          .timeout(AppConfig.authTimeout);
      if (!doc.exists) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('Firestore getById viewing error: $e');
      return null;
    }
  }

  static Future<List<ViewingAppointment>> getForTenant(String hint) async {
    if (AppConfig.demoMode) return [];
    final keys = await AuthService.identityKeysFor(hint);
    if (keys.isEmpty) return [];
    try {
      final byId = <String, ViewingAppointment>{};
      for (final key in keys) {
        for (final field in ['tenantEmail', 'tenantId']) {
          final snap = await _db
              .collection(_collection)
              .where(field, isEqualTo: key)
              .get()
              .timeout(AppConfig.authTimeout);
          for (final doc in snap.docs) {
            byId[doc.id] = _fromDoc(doc);
          }
        }
      }
      final list = byId.values.toList();
      list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return list;
    } catch (e) {
      debugPrint('Firestore getForTenant viewings error: $e');
      throw 'تعذر تحميل مواعيد المعاينة. تحقق من الاتصال';
    }
  }

  static Future<List<ViewingAppointment>> getForOwner(String hint) async {
    if (AppConfig.demoMode) return [];
    final keys = await AuthService.identityKeysFor(hint);
    if (keys.isEmpty) return [];
    try {
      final byId = <String, ViewingAppointment>{};
      for (final key in keys) {
        for (final field in ['ownerEmail', 'ownerId']) {
          final snap = await _db
              .collection(_collection)
              .where(field, isEqualTo: key)
              .get()
              .timeout(AppConfig.authTimeout);
          for (final doc in snap.docs) {
            byId[doc.id] = _fromDoc(doc);
          }
        }
      }
      final list = byId.values.toList();
      list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return list;
    } catch (e) {
      debugPrint('Firestore getForOwner viewings error: $e');
      throw 'تعذر تحميل مواعيد المعاينة. تحقق من الاتصال';
    }
  }

  static Future<ViewingAppointment> create(
    ViewingAppointment appointment,
  ) async {
    if (AppConfig.demoMode) {
      throw StateError('FirestoreViewingService is for real mode only');
    }
    final payload = _toFirestore(appointment);
    payload['createdAt'] = FieldValue.serverTimestamp();
    payload['updatedAt'] = FieldValue.serverTimestamp();
    try {
      if (appointment.id.isNotEmpty && !appointment.id.startsWith('view_')) {
        await _db
            .collection(_collection)
            .doc(appointment.id)
            .set(payload, SetOptions(merge: true))
            .timeout(AppConfig.authTimeout);
        return appointment;
      }
      final ref = await _db
          .collection(_collection)
          .add(payload)
          .timeout(AppConfig.authTimeout);
      return appointment.copyWith(id: ref.id);
    } on TimeoutException {
      throw 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
    } catch (e) {
      debugPrint('Firestore create viewing error: $e');
      if (e is String) rethrow;
      throw 'تعذر إنشاء موعد المعاينة. تحقق من الاتصال وحاول مرة أخرى';
    }
  }

  static Future<bool> update(ViewingAppointment appointment) async {
    if (AppConfig.demoMode || appointment.id.trim().isEmpty) return false;
    try {
      final payload = _toFirestore(appointment);
      payload['updatedAt'] = FieldValue.serverTimestamp();
      await _db
          .collection(_collection)
          .doc(appointment.id)
          .set(payload, SetOptions(merge: true))
          .timeout(AppConfig.authTimeout);
      return true;
    } catch (e) {
      debugPrint('Firestore update viewing error: $e');
      return false;
    }
  }

  static Future<List<ViewingAppointment>> listForConflictCheck(
    String propertyId,
  ) async {
    if (AppConfig.demoMode || propertyId.isEmpty) return [];
    try {
      final snap = await _db
          .collection(_collection)
          .where('propertyId', isEqualTo: propertyId)
          .get()
          .timeout(AppConfig.authTimeout);
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('Firestore conflict viewings error: $e');
      return [];
    }
  }

  static ViewingAppointment _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return ViewingAppointment.fromJson(_normalize(data));
  }

  static Map<String, dynamic> _toFirestore(ViewingAppointment a) {
    final json = a.toJson();
    // Prefer ISO strings for client round-trip; server timestamps for audit.
    return json;
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
