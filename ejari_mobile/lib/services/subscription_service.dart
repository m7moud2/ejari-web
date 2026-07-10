import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'data_service.dart';
import '../utils/safe_parse.dart';

class SubscriptionService {
  static const String _legacySubscriptionKeyPrefix = 'user_subscription_';
  static const String _ownerSubscriptionKeyPrefix = 'owner_subscription_';

  static const double commissionRent = 0.10;
  static const double commissionSale = 0.025;

  static const Map<String, Map<String, dynamic>> ownerPlans = {
    'free': {
      'name': 'مجاني',
      'price': 0,
      'properties_limit': 2,
      'requests_limit': 5,
      'commission': true,
      'priority': false,
      'featured': false,
      'analytics': 'none',
    },
    'bronze': {
      'name': 'برونزي',
      'price': 99,
      'properties_limit': 5,
      'commission': false,
      'priority': false,
      'featured': false,
      'analytics': 'basic',
      'support': false,
    },
    'silver': {
      'name': 'فضي',
      'price': 249,
      'properties_limit': 15,
      'commission': false,
      'priority': true,
      'reels': true,
      'featured': true,
      'analytics': 'full',
    },
    'gold': {
      'name': 'ذهبي',
      'price': 499,
      'properties_limit': -1,
      'commission': false,
      'priority': true,
      'reels': true,
      'featured': true,
      'analytics': 'full',
    },
    'commission': {
      'name': 'نظام العمولة',
      'price': 0,
      'properties_limit': -1,
      'commission': true,
      'priority': false,
      'featured': false,
      'analytics': 'none',
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

  static Future<String?> _resolveOwnerEmail([String? ownerEmail]) async {
    if (ownerEmail != null && ownerEmail.isNotEmpty) return ownerEmail;
    final user = await AuthService.getCurrentUser();
    return user?['email']?.toString();
  }

  static String _ownerStorageKey(String email) =>
      '$_ownerSubscriptionKeyPrefix$email';

  static String _legacyStorageKey(String id) =>
      '$_legacySubscriptionKeyPrefix$id';

  static Future<String> _storageKeyForUser(String userType) async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? '';
    if (userType == 'owner' && email.isNotEmpty) {
      return _ownerStorageKey(email);
    }
    final id = email.isNotEmpty
        ? email
        : user?['uid']?.toString() ??
            user?['id']?.toString() ??
            'guest';
    return _legacyStorageKey(id);
  }

  /// Persists owner plan to SharedPreferences under owner_subscription_{email}.
  static Future<Map<String, dynamic>> activatePlan(
    String ownerEmail,
    String planId, {
    String userType = 'owner',
  }) async {
    final normalized = normalizePlanId(planId, userType);
    final change = await canChangePlan(normalized, userType);
    if (change['allowed'] != true) {
      throw StateError(change['message']?.toString() ?? 'تغيير الباقة غير مسموح');
    }

    final prefs = await SharedPreferences.getInstance();
    final subscription = {
      'plan': normalized,
      'type': userType,
      'owner_email': ownerEmail,
      'start_date': DateTime.now().toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'active': true,
    };

    if (userType == 'owner' && ownerEmail.isNotEmpty) {
      await prefs.setString(
        _ownerStorageKey(ownerEmail),
        jsonEncode(subscription),
      );
    }

    final legacyKey = await _storageKeyForUser(userType);
    await prefs.setString(legacyKey, jsonEncode(subscription));
    return subscription;
  }

  static Future<Map<String, dynamic>?> _readStoredSubscription(
    String userType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final email = await _resolveOwnerEmail();

    if (userType == 'owner' && email != null && email.isNotEmpty) {
      final ownerRaw = prefs.getString(_ownerStorageKey(email));
      if (ownerRaw != null) {
        return jsonDecode(ownerRaw) as Map<String, dynamic>;
      }
      final legacyId = email;
      final legacyRaw = prefs.getString(_legacyStorageKey(legacyId));
      if (legacyRaw != null) {
        final sub = jsonDecode(legacyRaw) as Map<String, dynamic>;
        await prefs.setString(_ownerStorageKey(email), legacyRaw);
        return sub;
      }
    }

    final key = await _storageKeyForUser(userType);
    final raw = prefs.getString(key);
    if (raw != null) {
      return jsonDecode(raw) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>> getCurrentSubscription() async {
    final role = await AuthService.getUserRole();
    final userType = role == 'tenant' ? 'tenant' : 'owner';
    final stored = await _readStoredSubscription(userType);

    if (stored != null) {
      return stored;
    }

    return {
      'plan': 'free',
      'type': userType,
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
    final email = await _resolveOwnerEmail() ?? '';
    await activatePlan(email, planId, userType: userType);
  }

  static Map<String, dynamic>? getPlanDetails(String planId, String userType) {
    final normalized = normalizePlanId(planId, userType);
    return userType == 'owner'
        ? ownerPlans[normalized]
        : tenantPlans[normalized];
  }

  static List<String> planFeatureLabels(String planId) {
    final plan = ownerPlans[normalizePlanId(planId, 'owner')] ??
        ownerPlans['free']!;
    final limit = safeInt(plan['properties_limit'], -1);
    final listings = limit == -1 ? 'إعلانات غير محدودة' : 'حتى $limit إعلان';
    final featured = plan['featured'] == true ? 'تمييز الإعلانات' : null;
    final analytics = plan['analytics']?.toString() ?? 'none';
    final analyticsLabel = switch (analytics) {
      'full' => 'تحليلات متقدمة',
      'basic' => 'تحليلات أساسية',
      _ => null,
    };
    final priority = plan['priority'] == true ? 'أولوية في الظهور' : null;
    return [
      listings,
      if (featured != null) featured,
      if (analyticsLabel != null) analyticsLabel,
      if (priority != null) priority,
      if (plan['commission'] == true) 'عمولة 10% على الإيجار' else 'بدون عمولة',
    ];
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

    final planId =
        normalizePlanId(sub['plan']?.toString() ?? 'free', 'tenant');
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
      'analytics': plan['analytics'] ?? 'none',
      'commission_rate_rent': commissionRent,
      'commission_rate_sale': commissionSale,
      'is_active': sub['active'] != false,
      'end_date': sub['end_date'],
      'features': planFeatureLabels(planId),
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
      'plan_id': planId,
      'properties_used': ability['current_count'],
      'properties_limit': ability['limit'],
      'can_feature': ability['can_feature'],
      'has_priority': ability['has_priority'],
      'analytics': ability['analytics'],
      'features': ability['features'],
    };
  }
}
