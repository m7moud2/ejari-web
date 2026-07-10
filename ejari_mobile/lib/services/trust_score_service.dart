import 'data_service.dart';
import 'maintenance_service.dart';
import 'auth_service.dart';
import '../models/booking_status.dart';

/// درجة الثقة — مؤشر موثوقية المستخدم من الحجوزات والتوثيق والنزاعات.
class TrustScoreService {
  TrustScoreService._();

  static const List<({int min, String label, String badge})> _levels = [
    (min: 80, label: 'ذهبي', badge: '🏆'),
    (min: 60, label: 'مميز', badge: '⭐'),
    (min: 40, label: 'موثوق', badge: '✓'),
    (min: 20, label: 'نشط', badge: '●'),
    (min: 0, label: 'مبتدئ', badge: '○'),
  ];

  static Future<Map<String, dynamic>> computeForUser(String userEmail) async {
    if (userEmail.isEmpty) {
      return _emptyResult();
    }

    final verification =
        await DataService.getIdentityVerificationStatus(userEmail);
    final isVerified = verification['status'] == 'approved' ||
        (verification['label']?.toString().contains('موثق') ?? false);

    final bookings = await _userBookings(userEmail);
    final completed = bookings
        .where((b) =>
            BookingStatus.normalize(b['status']?.toString()) ==
            BookingStatus.completed)
        .length;
    final disputed = bookings
        .where((b) =>
            BookingStatus.normalize(b['status']?.toString()) ==
            BookingStatus.disputed)
        .length;

    final maintenance = await MaintenanceService.getAllRequests();
    final maintDisputes = maintenance
        .where((r) =>
            (r['tenantEmail']?.toString() == userEmail ||
                r['ownerEmail']?.toString() == userEmail) &&
            MaintenanceStatus.normalize(r['status']?.toString()) ==
                MaintenanceStatus.disputed)
        .length;

    final totalDisputes = disputed + maintDisputes;
    final activeBookings = bookings
        .where((b) {
          final st = BookingStatus.normalize(b['status']?.toString());
          return st != BookingStatus.cancelled &&
              st != BookingStatus.rejected &&
              st != BookingStatus.depositRefunded &&
              st != BookingStatus.completed;
        })
        .length;

    var score = 10;
    final breakdown = <Map<String, dynamic>>[];

    if (isVerified) {
      score += 30;
      breakdown.add({'factor': 'توثيق الهوية', 'points': 30, 'max': 30});
    } else {
      breakdown.add({'factor': 'توثيق الهوية', 'points': 0, 'max': 30});
    }

    final bookingPts = (completed * 12).clamp(0, 30);
    score += bookingPts;
    breakdown.add({
      'factor': 'حجوزات مكتملة ($completed)',
      'points': bookingPts,
      'max': 30,
    });

    if (totalDisputes == 0) {
      score += 20;
      breakdown.add({'factor': 'بدون نزاعات', 'points': 20, 'max': 20});
    } else {
      final penalty = (totalDisputes * 10).clamp(0, 20);
      score -= penalty;
      breakdown.add({
        'factor': 'نزاعات ($totalDisputes)',
        'points': -penalty,
        'max': 0,
      });
    }

    final reviewPts = await _reviewPoints(userEmail);
    score += reviewPts;
    breakdown.add({
      'factor': 'تقييمات إيجابية',
      'points': reviewPts,
      'max': 20,
    });

    score = score.clamp(0, 100);
    final level = _resolveLevel(score);

    return {
      'score': score,
      'level': level.label,
      'badge': level.badge,
      'isVerified': isVerified,
      'completedBookings': completed,
      'activeBookings': activeBookings,
      'disputes': totalDisputes,
      'breakdown': breakdown,
      'summary': _summaryArabic(score, level.label, isVerified, totalDisputes),
    };
  }

  static Future<Map<String, dynamic>> computeForCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? '';
    return computeForUser(email);
  }

  static Future<List<Map<String, dynamic>>> _userBookings(String email) async {
    final tenantBookings = await DataService.getBookings();
    final ownerRequests = await DataService.getOwnerRequests(email);
    final all = <Map<String, dynamic>>[...tenantBookings, ...ownerRequests];
    return all
        .where((b) =>
            b['tenantEmail']?.toString() == email ||
            b['ownerEmail']?.toString() == email ||
            b['userId']?.toString() == email)
        .toList();
  }

  static Future<int> _reviewPoints(String email) async {
    final users = await AuthService.getAllUsers();
    final user = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['email']?.toString() == email,
          orElse: () => null,
        );
    final rating = (user?['rating'] as num?)?.toDouble();
    if (rating == null) return 5;
    if (rating >= 4.5) return 20;
    if (rating >= 4.0) return 15;
    if (rating >= 3.5) return 10;
    return 5;
  }

  static ({String label, String badge}) _resolveLevel(int score) {
    for (final level in _levels) {
      if (score >= level.min) {
        return (label: level.label, badge: level.badge);
      }
    }
    final last = _levels.last;
    return (label: last.label, badge: last.badge);
  }

  static String _summaryArabic(
    int score,
    String level,
    bool verified,
    int disputes,
  ) {
    if (disputes > 0) {
      return 'درجة $score — $level. يُنصح بحل النزاعات المفتوحة لرفع الثقة.';
    }
    if (!verified) {
      return 'درجة $score — $level. وثّق هويتك لرفع درجة الثقة بسرعة.';
    }
    return 'درجة $score — $level. سجلك موثوق على منصة إيجاري.';
  }

  static Map<String, dynamic> _emptyResult() => {
        'score': 0,
        'level': 'مبتدئ',
        'badge': '○',
        'isVerified': false,
        'completedBookings': 0,
        'activeBookings': 0,
        'disputes': 0,
        'breakdown': <Map<String, dynamic>>[],
        'summary': 'سجّل دخولك لعرض درجة الثقة.',
      };
}
