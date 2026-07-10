import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'data_service.dart';
import 'activity_log_service.dart';

/// نقاط الولاء والإحالات والكوبونات — مخزنة لكل مستخدم.
class LoyaltyService {
  static const String _pointsKeyPrefix = 'loyalty_points_';
  static const String _referralsKeyPrefix = 'loyalty_referrals_';
  static const String _redeemedKeyPrefix = 'loyalty_redeemed_';
  static const String _couponsKeyPrefix = 'loyalty_coupons_';
  static const String _seededKeyPrefix = 'loyalty_seeded_';

  static const List<Map<String, dynamic>> defaultCoupons = [
    {
      'code': 'WELCOME20',
      'discount': '20%',
      'title': 'خصم ترحيبي',
      'description': 'خصم 20% على أول حجز',
      'expiry': '2026-12-31',
      'minAmount': '1000',
      'isUsed': false,
      'type': 'percentage',
    },
    {
      'code': 'SUMMER50',
      'discount': '50 ج.م',
      'title': 'عرض الصيف',
      'description': 'خصم 50 جنيه على أي حجز',
      'expiry': '2026-08-31',
      'minAmount': '500',
      'isUsed': false,
      'type': 'fixed',
    },
    {
      'code': 'FRIEND100',
      'discount': '100 ج.م',
      'title': 'إحالة صديق',
      'description': 'خصم 100 جنيه عند إحالة صديق',
      'expiry': '2026-12-31',
      'minAmount': '1000',
      'isUsed': false,
      'type': 'fixed',
    },
  ];

  static Future<String> _userId() async {
    final user = await AuthService.getCurrentUser();
    return user?['email']?.toString() ?? 'guest';
  }

  static Future<void> _ensureSeeded(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    final prefs = await SharedPreferences.getInstance();
    final seededKey = '$_seededKeyPrefix$userId';
    if (prefs.getBool(seededKey) == true) return;

    final bookings = await DataService.getUserBookings(userId);
    final receipts = await DataService.getReceiptsForUser(userId);
    final basePoints = (bookings.length * 150) + (receipts.length * 75) + 250;
    await prefs.setInt('$_pointsKeyPrefix$userId', basePoints);
    await prefs.setInt('$_referralsKeyPrefix$userId', bookings.isNotEmpty ? 2 : 0);
    await prefs.setStringList(
      '$_couponsKeyPrefix$userId',
      defaultCoupons.map(jsonEncode).toList(),
    );
    await prefs.setBool(seededKey, true);
  }

  static Future<int> getPoints([String? userId]) async {
    final id = userId ?? await _userId();
    await _ensureSeeded(id);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_pointsKeyPrefix$id') ?? 0;
  }

  static Future<int> getReferralCount([String? userId]) async {
    final id = userId ?? await _userId();
    await _ensureSeeded(id);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_referralsKeyPrefix$id') ?? 0;
  }

  static Future<int> getEarnedFromReferrals([String? userId]) async {
    final count = await getReferralCount(userId);
    return count * 100;
  }

  static Future<bool> redeemPoints({
    required int cost,
    required String rewardTitle,
    String? userId,
  }) async {
    final id = userId ?? await _userId();
    final current = await getPoints(id);
    if (current < cost) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_pointsKeyPrefix$id', current - cost);

    final redeemed = prefs.getStringList('$_redeemedKeyPrefix$id') ?? [];
    redeemed.add(jsonEncode({
      'title': rewardTitle,
      'cost': cost,
      'code': 'EJARI-${DateTime.now().millisecondsSinceEpoch}',
      'date': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('$_redeemedKeyPrefix$id', redeemed);

    await ActivityLogService.append(
      userId: id,
      action: 'redeem_points',
      detail: 'استبدال $cost نقطة: $rewardTitle',
      category: 'loyalty',
    );
    return true;
  }

  static Future<List<Map<String, dynamic>>> getRedeemedRewards(
      [String? userId]) async {
    final id = userId ?? await _userId();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_redeemedKeyPrefix$id') ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> getCoupons([String? userId]) async {
    final id = userId ?? await _userId();
    await _ensureSeeded(id);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_couponsKeyPrefix$id');
    if (list == null || list.isEmpty) {
      return List<Map<String, dynamic>>.from(defaultCoupons);
    }
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> applyCoupon(String code,
      [String? userId]) async {
    final id = userId ?? await _userId();
    final coupons = await getCoupons(id);
    final normalized = code.trim().toUpperCase();
    final index = coupons.indexWhere(
      (c) => c['code']?.toString().toUpperCase() == normalized,
    );
    if (index < 0) {
      return {'ok': false, 'message': 'كود الكوبون غير صحيح'};
    }
    if (coupons[index]['isUsed'] == true) {
      return {'ok': false, 'message': 'تم استخدام هذا الكوبون مسبقاً'};
    }

    coupons[index]['isUsed'] = true;
    coupons[index]['usedAt'] = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_couponsKeyPrefix$id',
      coupons.map(jsonEncode).toList(),
    );

    await ActivityLogService.append(
      userId: id,
      action: 'apply_coupon',
      detail: 'تفعيل كوبون $normalized',
      category: 'loyalty',
      refId: normalized,
    );

    return {
      'ok': true,
      'message': 'تم تفعيل الكوبون بنجاح',
      'coupon': coupons[index],
    };
  }

  static Future<void> addPoints({
    required int amount,
    required String reason,
    String? userId,
  }) async {
    final id = userId ?? await _userId();
    final current = await getPoints(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_pointsKeyPrefix$id', current + amount);
    await ActivityLogService.append(
      userId: id,
      action: 'earn_points',
      detail: reason,
      category: 'loyalty',
    );
  }
}
