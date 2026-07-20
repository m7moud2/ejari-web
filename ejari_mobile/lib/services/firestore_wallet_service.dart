import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../utils/date_utils.dart';

/// أرصدة ومعاملات المحفظة على Firestore (الإنتاج فقط).
///
/// مسار المستند: `wallets/{userKey}` + فرع `transactions/{txId}`.
/// [userKey] عادةً البريد (كما تستخدمه WalletService اليوم).
class FirestoreWalletService {
  FirestoreWalletService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _collection = 'wallets';
  static const _txLimit = 200;

  static String docIdFor(String userId) => userId.trim().toLowerCase();

  static DocumentReference<Map<String, dynamic>> _walletRef(String userId) =>
      _db.collection(_collection).doc(docIdFor(userId));

  /// يحمّل الرصيد + آخر المعاملات. يعيد null إن لم يوجد مستند بعد.
  static Future<Map<String, dynamic>?> loadWallet(String userId) async {
    if (AppConfig.demoMode || userId.trim().isEmpty) return null;
    try {
      final ref = _walletRef(userId);
      final doc = await ref.get().timeout(AppConfig.authTimeout);
      if (!doc.exists) return null;

      final data = Map<String, dynamic>.from(doc.data() ?? {});
      final txSnap = await ref
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(_txLimit)
          .get()
          .timeout(AppConfig.authTimeout);

      final transactions = txSnap.docs.map((d) {
        final tx = Map<String, dynamic>.from(d.data());
        tx['id'] = d.id;
        return _normalize(tx);
      }).toList();

      return {
        'balance': (data['balance'] as num?)?.toDouble() ?? 0.0,
        'pending': (data['pending'] as num?)?.toDouble() ?? 0.0,
        'escrow': (data['escrow'] as num?)?.toDouble() ?? 0.0,
        'transactions': transactions,
      };
    } on TimeoutException {
      throw 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
    } catch (e) {
      debugPrint('Firestore loadWallet error: $e');
      if (e is String) rethrow;
      throw 'تعذر تحميل المحفظة. تحقق من الاتصال وحاول مرة أخرى';
    }
  }

  /// يحدّث أرصدة المحفظة ويكتب المعاملات المتغيّرة فقط.
  static Future<void> saveWallet({
    required String userId,
    required double balance,
    required double pending,
    required double escrow,
    required List<Map<String, dynamic>> dirtyTransactions,
  }) async {
    if (AppConfig.demoMode || userId.trim().isEmpty) return;
    try {
      final ref = _walletRef(userId);
      await ref
          .set({
            'userId': userId.trim(),
            'balance': balance,
            'pending': pending,
            'escrow': escrow,
            'currency': 'ج.م',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(AppConfig.authTimeout);

      if (dirtyTransactions.isEmpty) return;

      // Firestore batch max 500 ops; leave headroom.
      const chunk = 400;
      for (var i = 0; i < dirtyTransactions.length; i += chunk) {
        final slice = dirtyTransactions.skip(i).take(chunk);
        final batch = _db.batch();
        for (final tx in slice) {
          final id = (tx['id'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          final payload = Map<String, dynamic>.from(tx)..remove('id');
          payload['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(
            ref.collection('transactions').doc(id),
            payload,
            SetOptions(merge: true),
          );
        }
        await batch.commit().timeout(AppConfig.authTimeout);
      }
    } on TimeoutException {
      throw 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى';
    } catch (e) {
      debugPrint('Firestore saveWallet error: $e');
      if (e is String) rethrow;
      throw 'تعذر حفظ المحفظة. تحقق من الاتصال وحاول مرة أخرى';
    }
  }

  /// كل المعاملات عبر كل المحافظ (لوحة الأدمن).
  static Future<List<Map<String, dynamic>>> getAllTransactions() async {
    if (AppConfig.demoMode) return [];
    try {
      final wallets =
          await _db.collection(_collection).get().timeout(AppConfig.authTimeout);
      final all = <Map<String, dynamic>>[];
      for (final w in wallets.docs) {
        final txs = await w.reference
            .collection('transactions')
            .get()
            .timeout(AppConfig.authTimeout);
        for (final t in txs.docs) {
          final tx = _normalize(Map<String, dynamic>.from(t.data()));
          tx['id'] = t.id;
          tx['userId'] = w.data()['userId']?.toString() ?? w.id;
          all.add(tx);
        }
      }
      all.sort((a, b) {
        final dateA =
            DateParsing.parse(a['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            DateParsing.parse(b['date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return all;
    } catch (e) {
      debugPrint('Firestore getAllTransactions error: $e');
      throw 'تعذر تحميل معاملات المحافظ. تحقق من الاتصال';
    }
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
