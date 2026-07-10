import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'data_service.dart';
import '../utils/safe_parse.dart';

class SubscriptionService {
  static const String _subscriptionKeyPrefix = 'user_subscription_';

  static const double commissionRent = 0.10;
  static const double commissionSale = 0.025;

  static const Map<String, Map<String, dynamic>> ownerPlans = {
    'free': {
      'name': 'مجاني',
      'price': 0,
      'properties_limit': 1,
      'requests_limit': 5,
      'commission': true,
      'priority': false,
      'featured': false,
    },
    'bronze': {
      'name': 'برونزي',
      'price': 299,
      'properties_limit': 5,
      'commission': false,
      'priority': false,
      'featured': false,
      'support': false,
    },
    'silver': {
      'name': 'فضي',
      'price': 599,
      'properties_limit': 15,
      'commission': false,
      'priority': true,
      'reels': true,
      'featured': false,
    },
    'gold': {
      'name': 'ذهبي (Ejari)',
      'price': 1299,
      'properties_limit': -1,
      'commission': false,
      'priority': true,
      'reels': true,
      'featured': true,
    },
    'commission': {
      'name': 'نظام العمولة',
      'price': 0,
      'properties_limit': -1,
      'commission': true,
      'priority': false,
      'featured': false,
    },
  };

  static const Map<String, Map<String, dynamic>> tenantPlans = {
    'free': {
      'name': 'مجاني',
      'price': 0,
      'bookings_limit': 3,
      'notifications': false,
    },
    'plus': {
      'name': 'بلس',
      'price': 99,
      'bookings_limit': 10,
      'notifications': true,
      'priority': false,
    },
    'premium': {
      'name': 'بريميوم',
      'price': 199,
      'bookings_limit': -1,
      'notifications': true,
      'priority': true,
    },
  };

  /// Legacy plan ids from older UI screens.
  static const Map<String, String> _ownerPlanAliases = {
    'basic': 'bronze',
    'pro': 'silver',
    'premium': 'gold',
  };

  static const Map<String, String> _tenantPlanAliases = {
    'plus': 'plus',
    'premium': 'premium',
  };

  static String normalizePlanId(String planId, String userType) {
    if (userType == 'owner') {
      return _ownerPlanAliases[planId] ?? planId;
    }
    return _tenantPlanAliases[planId] ?? planId;
  }

  static int _planRank(String planId, String userType) {
    final normalized = normalizePlanId(planId, userType);
    final plans = userType == 'tenant' ? tenantPlans : ownerPlans;
    final keys = plans.keys.toList();
    final idx = keys.indexOf(normalized);
    return idx >= 0 ? idx : 0;
  }

  static Future<String> _ownerKey() async {
    final user = await AuthService.getCurrentUser();
    final id = user?['email']?.toString() ??
        user?['uid']?.toString() ??
        user?['id']?.toString() ??
        'guest';
    return '$_subscriptionKeyPrefix$id';
  }

  static Future<Map<String, dynamic>> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ownerKey();
    final subJson = prefs.getString(key);

    if (subJson != null) {
      return jsonDecode(subJson) as Map<String, dynamic>;
    }

    final role = await AuthService.getUserRole();
    return {
      'plan': 'free',
      'type': role == 'tenant' ? 'tenant' : 'owner',
      'start_date': DateTime.now().toIso8601String(),
      'active': true,
    };
  }

  static Future<Map<String, dynamic>> canChangePlan(
    String newPlanId,
    String userType,
  ) async {
    final normalized = normalizePlanId(newPlanId, userType);
    final sub = await getCurrentSubscription();
    final currentId =
        normalizePlanId(sub['plan']?.toString() ?? 'free', userType);
    final isDowngrade = _planRank(normalized, userType) <
        _planRank(currentId, userType);

    if (userType == 'owner' && isDowngrade) {
      final plan = ownerPlans[normalized] ?? ownerPlans['free']!;
      final limit = safeInt(plan['properties_limit'], -1);
      if (limit != -1) {
        final count = await getOwnerPropertyCount();
        if (count > limit) {
          return {
            'allowed': false,
            'message':
                'لا يمكن التخفيض: لديك $count عقار/ات والباقة تسمح بـ $limit فقط',
            'current_count': count,
            'limit': limit,
          };
        }
      }
    }

    return {'allowed': true, 'plan_id': normalized};
  }

  static Future<void> subscribe(String planId, String userType) async {
    final normalized = normalizePlanId(planId, userType);
    final change = await canChangePlan(normalized, userType);
    if (change['allowed'] != true) {
      throw StateError(change['message']?.toString() ?? 'تغيير الباقة غير مسموح');
    }

    final prefs = await SharedPreferences.getInstance();
    final key = await _ownerKey();
    final subscription = {
      'plan': normalized,
      'type': userType,
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'active': true,
    };
    await prefs.setString(key, jsonEncode(subscription));
  }

  static Map<String, dynamic>? getPlanDetails(String planId, String userType) {
    final normalized = normalizePlanId(planId, userType);
    return userType == 'owner'
        ? ownerPlans[normalized]
        : tenantPlans[normalized];
  }

  static Future<int> getTenantMonthlyBookingCount() async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? '';
    if (email.isEmpty) return 0;

    final bookings = await DataService.getBookings();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    return bookings.where((b) {
      final raw = b['requestDate']?.toString() ??
          b['createdAt']?.toString() ??
          b['leaseStartDate']?.toString() ??
          '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return false;
      return !dt.isBefore(monthStart);
    }).length;
  }

  static Future<Map<String, dynamic>> checkBookingAbility() async {
    final sub = await getCurrentSubscription();
    final userType = sub['type']?.toString() ?? 'owner';
    if (userType != 'tenant') {
      return {'can_book': true};
    }

    final planId = normalizePlanId(sub['plan']?.toString() ?? 'free', 'tenant');
    final plan = tenantPlans[planId] ?? tenantPlans['free']!;
    final limit = safeInt(plan['bookings_limit'], -1);
    if (limit == -1) {
      return {'can_book': true, 'plan_id': planId, 'limit': limit};
    }

    final used = await getTenantMonthlyBookingCount();
    if (used >= limit) {
      return {
        'can_book': false,
        'plan_id': planId,
        'plan_name': plan['name'],
        'used': used,
        'limit': limit,
        'message':
            'وصلت حد الحجوزات ($used/$limit) — ترقّ إلى باقة أعلى للمتابعة',
      };
    }

    return {
      'can_book': true,
      'plan_id': planId,
      'used': used,
      'limit': limit,
    };
  }

  static Future<int> getOwnerPropertyCount([String? ownerId]) async {
    final user = await AuthService.getCurrentUser();
    final id = ownerId ??
        user?['email']?.toString() ??
        user?['uid']?.toString() ??
        '';
    final props = await DataService.getOwnerProperties(id);
    return props.length;
  }

  static Future<Map<String, dynamic>> checkListingAbility({String? ownerId}) async {
    final sub = await getCurrentSubscription();
    final planId =
        normalizePlanId(sub['plan']?.toString() ?? 'free', 'owner');
    final plan = ownerPlans[planId] ?? ownerPlans['free']!;
    final currentCount = await getOwnerPropertyCount(ownerId);
    final limit = safeInt(plan['properties_limit'], -1);
    final hasPackageRoom = limit == -1 || currentCount < limit;

    return {
      'can_list_via_package': hasPackageRoom,
      'current_plan': plan['name'],
      'plan_id': planId,
      'current_count': currentCount,
      'limit': limit,
      'must_pay_commission': plan['commission'] == true && !hasPackageRoom,
      'can_feature': plan['featured'] == true,
      'has_priority': plan['priority'] == true,
      'commission_rate_rent': commissionRent,
      'commission_rate_sale': commissionSale,
      'is_active': sub['active'] != false,
      'end_date': sub['end_date'],
    };
  }

  static Future<bool> canAddProperty({String? ownerId}) async {
    final ability = await checkListingAbility(ownerId: ownerId);
    return ability['can_list_via_package'] == true;
  }

  static Future<bool> shouldAutoFeature() async {
    final ability = await checkListingAbility();
    return ability['can_feature'] == true;
  }

  static Future<Map<String, dynamic>> getSubscriptionSummary() async {
    final sub = await getCurrentSubscription();
    final planId = sub['plan']?.toString() ?? 'free';
    final userType = sub['type']?.toString() ?? 'owner';
    final plan = getPlanDetails(planId, userType) ?? ownerPlans['free']!;
    final ability = await checkListingAbility();

    return {
      ...sub,
      'plan_name': plan['name'],
      'properties_used': ability['current_count'],
      'properties_limit': ability['limit'],
      'can_feature': ability['can_feature'],
    };
  }
}
