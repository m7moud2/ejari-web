import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/firestore_property_service.dart';
import '../utils/rental_schedule_utils.dart';
import '../models/home_stats_model.dart';

class HomeRepository {
  Future<HomeStatsModel> fetchHomeStats(String role) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    Map<String, dynamic> tenantStats = {
      'userName': 'أحمد محمود',
      'verificationStatus': 'موثق',
      'activeBooking': false,
      'nextInstallmentDays': 0,
      'nextInstallmentAmount': 0,
      'savedCount': 0,
      'recommendedProperties': <Map<String, dynamic>>[],
      'featuredProperties': <Map<String, dynamic>>[],
      'quickActions': [
        {'title': 'احجز عقار', 'icon': 'home'},
        {'title': 'ادفع الإيجار', 'icon': 'pay'},
        {'title': 'اطلب صيانة', 'icon': 'build'},
        {'title': 'تواصل مع الدعم', 'icon': 'support'},
        {'title': 'عقودي', 'icon': 'contract'},
        {'title': 'محفظتي', 'icon': 'wallet'},
      ],
      'activeMaintenance': 0,
      'unreadNotifications': 0,
      'offers': 'استكشف العقارات المتاحة الآن',
    };

    try {
      final user = await AuthService.getCurrentUser();
      if (user?['name'] != null) {
        tenantStats['userName'] = user!['name'];
      }

      final catalog = await FirestorePropertyService.getAllProperties();
      final rentProps = catalog
          .where((p) => p['listingMode'] != 'for_sale')
          .take(6)
          .map((p) => {
                'id': p['id'],
                'title': p['title'],
                'location': p['location'] ?? p['governorate'] ?? '',
                'price': p['price'],
                'image': p['image'],
                'governorate': p['governorate'],
              })
          .toList();
      final featured = catalog
          .where((p) => p['isFeatured'] == true || p['listingMode'] == 'for_sale')
          .take(4)
          .map((p) => {
                'id': p['id'],
                'title': p['title'],
                'location': p['location'] ?? p['governorate'] ?? '',
                'price': p['price'],
                'image': p['image'],
                'listingMode': p['listingMode'],
              })
          .toList();
      tenantStats['recommendedProperties'] = rentProps;
      tenantStats['featuredProperties'] =
          featured.isNotEmpty ? featured : rentProps.take(3).toList();

      final bookings = await DataService.getBookings();
      final activeBookings = bookings
          .where((b) =>
              (b['status'] ?? '').toString() != 'deposit_refunded' &&
              (b['status'] ?? '').toString() != 'rejected')
          .toList();

      if (activeBookings.isNotEmpty) {
        final booking = activeBookings.first;
        final snapshot = RentalScheduleUtils.buildLeaseSnapshot(booking);
        final nextDueDate = snapshot['nextDueDate'] as DateTime?;
        final nextDueDays = nextDueDate == null
            ? 0
            : nextDueDate.difference(DateTime.now()).inDays;

        tenantStats = {
          ...tenantStats,
          'activeBooking': true,
          'bookingId': booking['id']?.toString() ?? '',
          'bookingTitle': booking['title']?.toString() ?? 'حجز إيجار',
          'bookingImage': booking['image']?.toString() ?? '',
          'bookingStatus': booking['status']?.toString() ?? 'pending',
          'nextInstallmentDays': nextDueDays < 0 ? 0 : nextDueDays,
          'nextInstallmentAmount':
              (snapshot['nextDueAmount'] as num?)?.toDouble() ?? 0.0,
          'monthlyRent': (snapshot['monthlyRent'] as num?)?.toDouble() ?? 0.0,
          'depositAmount':
              (snapshot['depositAmount'] as num?)?.toDouble() ?? 0.0,
          'remainingAmount':
              (snapshot['remainingAmount'] as num?)?.toDouble() ?? 0.0,
          'leaseMonths': (snapshot['leaseMonths'] as num?)?.toInt() ?? 1,
          'paidMonths': (booking['paidMonths'] is num)
              ? (booking['paidMonths'] as num).toInt()
              : int.tryParse((booking['paidMonths'] ?? '0').toString()) ?? 0,
          'remainingMonths':
              (snapshot['remainingMonths'] as num?)?.toInt() ?? 0,
          'nextDueDate': nextDueDate?.toIso8601String() ?? '',
          'tenantBookingsCount': activeBookings.length,
          'savedCount': (await DataService.getFavorites()).length,
          'recommendedProperties': rentProps.isNotEmpty
              ? rentProps
              : tenantStats['recommendedProperties'],
          'featuredProperties': featured.isNotEmpty
              ? featured
              : tenantStats['featuredProperties'],
          'offers': 'عندك حجز قائم: راجع القسط التالي أو استكمل الدفع من هنا',
          'recentActivities': [
            {
              'icon': 'payments',
              'title': 'قسط مستحق قريب',
              'subtitle':
                  'متبقي $nextDueDays أيام على ${snapshot['nextDueAmount']} ج.م',
            },
            {
              'icon': 'contract',
              'title': 'عقد نشط',
              'subtitle': 'عندك ${activeBookings.length} حجز/عقد متابع حالياً.',
            },
            {
              'icon': 'favorite',
              'title': 'عقارات محفوظة',
              'subtitle': 'استمر في مقارنة العقارات قبل القرار النهائي.',
            },
          ],
        };
      }
    } catch (_) {
      // keep demo fallback if local data is unavailable
    }

    final baseTenant = {
      ...tenantStats,
      'recentActivities': tenantStats['recentActivities'] ??
          [
            {
              'icon': 'search',
              'title': 'ابحث عن عقار',
              'subtitle': 'ابدأ رحلة البحث من الصفحة الرئيسية.',
            },
            {
              'icon': 'notifications',
              'title': 'تابع التنبيهات',
              'subtitle': 'الإشعارات المهمة تظهر هنا أولاً.',
            },
          ],
    };

    final baseOwner = await _loadOwnerStats();

    final baseTech = {
      'userName': 'مصطفى حسن',
      'verificationStatus': 'موثق',
      'availability': 'متاح',
      'newRequests': 4,
      'nearbyRequests': 2,
      'activeJobs': 2,
      'completedJobs': 18,
      'todayEarnings': 450,
      'monthlyEarnings': 8500,
      'availableBalance': 3200,
      'rating': 4.9,
      'reviewsCount': 45,
      'urgentRequests': 1,
      'banner': 'أكمل تخصصك أو حسّن بياناتك لزيادة فرص ظهورك',
    };

    final baseAdmin = {
      'userName': 'الأدمن',
      'totalUsers': 1205,
      'tenantsCount': 840,
      'ownersCount': 210,
      'techniciansCount': 155,
      'pendingVerifications': 12,
      'pendingProperties': 15,
      'activeBookings': 45,
      'pendingPayments': 8,
      'escrowBalance': 150000,
      'openDisputes': 3,
      'activeMaintenance': 8,
      'platformRevenue': 85000,
      'todayTransactions': 24000,
      'systemAlerts': 2,
    };

    // In production, this queries Firebase Collections based on role using limits
    return HomeStatsModel(
      tenantStats: baseTenant,
      ownerStats: baseOwner,
      techStats: baseTech,
      adminStats: baseAdmin,
    );
  }

  Future<Map<String, dynamic>> _loadOwnerStats() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ??
        user?['uid']?.toString() ??
        'owner@ejari.app';
    final properties = await DataService.getOwnerProperties(ownerId);
    final requests = await DataService.getOwnerRequests(ownerId);
    final sub = await SubscriptionService.getSubscriptionSummary();
    final pending = requests
        .where((r) =>
            r['status'] == 'viewing_scheduled' ||
            r['status'] == 'deposit_paid' ||
            r['status'] == 'pending')
        .length;

    return {
      'userName': user?['name'] ?? 'المالك',
      'verificationStatus': 'موثق',
      'propertiesCount': properties.length,
      'approvedProperties':
          properties.where((p) => p['status'] == 'approved').length,
      'pendingProperties':
          properties.where((p) => p['status'] == 'pending').length,
      'pendingBookings': pending,
      'monthlyRevenue': 0,
      'escrowBalance': 0,
      'availableToWithdraw': 0,
      'pendingInstallments': 0,
      'lateInstallments': 0,
      'newRequests': pending,
      'activeMaintenance': 0,
      'topProperty': properties.isNotEmpty
          ? properties.first['title']
          : 'لا توجد عقارات بعد',
      'topPropertyViews': 0,
      'subscriptionPlan': sub['plan_name'],
      'subscriptionLimit': sub['properties_limit'],
      'subscriptionUsed': sub['properties_used'],
      'canFeature': sub['can_feature'],
      'banner':
          'باقتك: ${sub['plan_name']} — ${sub['properties_used']}/${sub['properties_limit'] == -1 ? '∞' : sub['properties_limit']} عقار',
    };
  }
}
