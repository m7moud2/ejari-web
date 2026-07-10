import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'anti_fraud_service.dart';

/// تقييم المستأجر متعدد الأبعاد — يظهر للمالك عند قبول الحجز.
class TenantScoreService {
  TenantScoreService._();

  static const String _scoresKey = 'tenant_dimension_scores_v1';
  static const int minStaysForAggregate = 2;

  static const dimensions = [
    ('punctuality', 'الالتزام بالمواعيد'),
    ('payment', 'الدفع'),
    ('cleanliness', 'النظافة'),
    ('respect', 'الاحترام'),
  ];

  /// تقييم المستأجر من المالك بعد الإقامة.
  static Future<Map<String, dynamic>> rateTenant({
    required String tenantEmail,
    required String ownerEmail,
    required double punctuality,
    required double payment,
    required double cleanliness,
    required double respect,
    String? bookingId,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scoresKey) ?? [];
    final entry = {
      'tenantEmail': tenantEmail,
      'ownerEmail': ownerEmail,
      'bookingId': bookingId,
      'punctuality': punctuality.clamp(1.0, 5.0),
      'payment': payment.clamp(1.0, 5.0),
      'cleanliness': cleanliness.clamp(1.0, 5.0),
      'respect': respect.clamp(1.0, 5.0),
      'notes': notes ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    entry['average'] = _averageDimensions(entry);
    raw.add(jsonEncode(entry));
    await prefs.setStringList(_scoresKey, raw);

    await DataService.rateTenant(
      tenantEmail: tenantEmail,
      rating: entry['average'] as double,
      paymentReliability: payment,
      notes: notes,
      bookingId: bookingId,
      ownerEmail: ownerEmail,
    );
    return entry;
  }

  /// تقييم المالك من المستأجر (تقييم ثنائي).
  static Future<Map<String, dynamic>> rateOwner({
    required String ownerEmail,
    required String tenantEmail,
    required double accuracy,
    required double priceHonesty,
    required double respect,
    String? bookingId,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'owner_dimension_scores_v1';
    final raw = prefs.getStringList(key) ?? [];
    final entry = {
      'ownerEmail': ownerEmail,
      'tenantEmail': tenantEmail,
      'bookingId': bookingId,
      'accuracy': accuracy.clamp(1.0, 5.0),
      'priceHonesty': priceHonesty.clamp(1.0, 5.0),
      'respect': respect.clamp(1.0, 5.0),
      'notes': notes ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    entry['average'] =
        ((accuracy + priceHonesty + respect) / 3).clamp(1.0, 5.0);
    raw.add(jsonEncode(entry));
    await prefs.setStringList(key, raw);
    return entry;
  }

  /// ملخص درجة المستأجر للعرض على شاشة قبول الحجز.
  static Future<Map<String, dynamic>> getTenantScore(String tenantEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scoresKey) ?? [];
    final ratings = raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .where((r) => r['tenantEmail']?.toString() == tenantEmail)
        .toList();

    final fraud = await AntiFraudService.getProfile(tenantEmail);
    final legacy = await DataService.getTenantRating(tenantEmail);

    if (ratings.isEmpty) {
      return {
        'tenantEmail': tenantEmail,
        'aggregateScore': 0.0,
        'displayScore': '—',
        'count': 0,
        'hasEnoughStays': false,
        'dimensions': <String, double>{},
        'dimensionLabels': dimensions.map((d) => d.$2).toList(),
        'level': 'جديد',
        'badge': '🆕',
        'fraudFlags': fraud['flags'] ?? [],
        'isFlagged': fraud['isFlagged'] == true,
        'legacyRating': legacy,
        'summary': 'مستأجر جديد — لا توجد تقييمات سابقة',
      };
    }

    final dimAvgs = <String, double>{};
    for (final (key, _) in dimensions) {
      final vals = ratings
          .map((r) => (r[key] as num?)?.toDouble() ?? 0)
          .where((v) => v > 0)
          .toList();
      dimAvgs[key] =
          vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;
    }

    final aggregate =
        dimAvgs.values.where((v) => v > 0).fold(0.0, (a, b) => a + b) /
            dimAvgs.values.where((v) => v > 0).length;

    final count = ratings.length;
    final hasEnough = count >= minStaysForAggregate;
    final level = _resolveLevel(aggregate, fraud['isFlagged'] == true);

    return {
      'tenantEmail': tenantEmail,
      'aggregateScore': aggregate,
      'displayScore': hasEnough ? aggregate.toStringAsFixed(1) : '—',
      'count': count,
      'hasEnoughStays': hasEnough,
      'dimensions': dimAvgs,
      'dimensionLabels': {
        for (final (k, l) in dimensions) k: l,
      },
      'level': level.$1,
      'badge': level.$2,
      'fraudFlags': fraud['flags'] ?? [],
      'isFlagged': fraud['isFlagged'] == true,
      'noShows': fraud['noShows'] ?? 0,
      'cancellations': fraud['cancellations'] ?? 0,
      'legacyRating': legacy,
      'summary': hasEnough
          ? 'درجة ${aggregate.toStringAsFixed(1)}/5 — ${level.$1} (${count} إقامة)'
          : 'يحتاج ${minStaysForAggregate - count} إقامة إضافية لحساب الدرجة',
    };
  }

  static Future<Map<String, dynamic>> getOwnerScore(String ownerEmail) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'owner_dimension_scores_v1';
    final raw = prefs.getStringList(key) ?? [];
    final ratings = raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .where((r) => r['ownerEmail']?.toString() == ownerEmail)
        .toList();

    if (ratings.isEmpty) {
      return {
        'aggregateScore': 0.0,
        'count': 0,
        'dimensions': <String, double>{},
        'level': 'غير مقيّم',
      };
    }

    double avg(String field) {
      final vals = ratings.map((r) => (r[field] as num?)?.toDouble() ?? 0);
      return vals.reduce((a, b) => a + b) / ratings.length;
    }

    final aggregate = (avg('accuracy') + avg('priceHonesty') + avg('respect')) / 3;
    return {
      'aggregateScore': aggregate,
      'count': ratings.length,
      'dimensions': {
        'accuracy': avg('accuracy'),
        'priceHonesty': avg('priceHonesty'),
        'respect': avg('respect'),
      },
      'level': _resolveLevel(aggregate, false).$1,
    };
  }

  static double _averageDimensions(Map<String, dynamic> entry) {
    return ((entry['punctuality'] as num) +
            (entry['payment'] as num) +
            (entry['cleanliness'] as num) +
            (entry['respect'] as num)) /
        4;
  }

  static (String, String) _resolveLevel(double score, bool flagged) {
    if (flagged) return ('تحذير — سجل مشبوه', '⚠️');
    if (score >= 4.5) return ('ممتاز', '🏆');
    if (score >= 4.0) return ('جيد جداً', '⭐');
    if (score >= 3.5) return ('جيد', '✓');
    if (score >= 3.0) return ('متوسط', '●');
    if (score > 0) return ('منخفض', '⚠️');
    return ('جديد', '🆕');
  }

  /// بذر تقييمات تجريبية للعرض.
  static Future<void> seedDemoScores() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('tenant_scores_seeded')) return;

    await rateTenant(
      tenantEmail: 'user@ejari.app',
      ownerEmail: 'owner@ejari.app',
      punctuality: 4.5,
      payment: 4.8,
      cleanliness: 4.2,
      respect: 4.6,
      bookingId: 'demo_req_1',
      notes: 'مستأجر موثوق — دفع في الموعد',
    );
    await rateTenant(
      tenantEmail: 'tenant.demo@ejari.app',
      ownerEmail: 'owner@ejari.app',
      punctuality: 3.0,
      payment: 2.5,
      cleanliness: 3.5,
      respect: 3.0,
      bookingId: 'demo_bed_booking',
      notes: 'تأخر في الدفع مرة واحدة',
    );
    await prefs.setBool('tenant_scores_seeded', true);
  }
}
