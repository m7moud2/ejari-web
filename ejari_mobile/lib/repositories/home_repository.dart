import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/firestore_property_service.dart';
import '../services/trust_score_service.dart';
import '../utils/rental_schedule_utils.dart';
import '../utils/account_id_service.dart';
import '../services/maintenance_service.dart';
import '../models/home_stats_model.dart';
import '../models/booking_status.dart';

class HomeRepository {
  Future<HomeStatsModel> fetchHomeStats(String role) async {
    await Future.delayed(const Duration(milliseconds: 300));

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
      final userEmail = user?['email']?.toString() ?? '';
      if (userEmail.isNotEmpty) {
        final verification =
            await DataService.getIdentityVerificationStatus(userEmail);
        tenantStats['verificationStatus'] = verification['label'] ?? 'غير موثق';
        if (verification['reason'] != null) {
          tenantStats['verificationReason'] = verification['reason'];
        }
        final trust = await TrustScoreService.computeForUser(userEmail);
        tenantStats['trustScore'] = trust['score'];
        tenantStats['trustLevel'] = trust['level'];
        tenantStats['trustData'] = trust;
      }
      tenantStats['accountId'] = user?['accountId']?.toString() ??
          AccountIdService.demoAccountIds[user?['email']?.toString() ?? ''] ??
          '';
      tenantStats['unreadNotifications'] =
          await DataService.getUnreadNotificationCount();

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
        final nextStep = BookingStatus.nextActionForBooking(booking);

        tenantStats = {
          ...tenantStats,
          'activeBooking': true,
          'bookingId': booking['id']?.toString() ?? '',
          'bookingTitle': booking['title']?.toString() ?? 'حجز إيجار',
          'bookingImage': booking['image']?.toString() ?? '',
          'bookingStatus': booking['status']?.toString() ?? 'pending',
          'bookingStatusLabel':
              BookingStatus.arabicLabel(booking['status']?.toString()),
          'nextActionLabel': nextStep?.$2,
          'nextActionKey': nextStep?.$3,
          'nextActionIcon': nextStep?.$1,
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
          'offers': nextStep != null
              ? 'التالي: ${nextStep.$2}'
              : 'عندك حجز قائم: راجع القسط التالي أو استكمل الدفع من هنا',
          'recentActivities': [
            if (nextStep != null)
              {
                'icon': 'booking',
                'title': 'التالي',
                'subtitle': nextStep.$2,
              },
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
      'contextualAction': _tenantContextualAction(tenantStats),
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

    final baseTech = await _loadTechStats();

    final baseAdmin = await DataService.getAdminDashboardStats();
    baseAdmin['userName'] = 'الأدمن';

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
    final daysUntilExpiry = await SubscriptionService.getDaysUntilExpiry();
    final subscriptionExpiringSoon =
        daysUntilExpiry != null && daysUntilExpiry <= 7;
    final revenue = await DataService.getOwnerRevenue(ownerId);
    final wallet = await DataService.getWalletData(ownerId);
    final pending = requests
        .where((r) =>
            r['status'] == 'viewing_scheduled' ||
            r['status'] == 'deposit_paid' ||
            r['status'] == 'pending' ||
            r['status'] == 'corporate_pending')
        .length;
    final verification =
        await DataService.getIdentityVerificationStatus(ownerId);
    final trust = await TrustScoreService.computeForUser(ownerId);

    final occupiedCount = requests
        .where((r) =>
            r['status'] == BookingStatus.active ||
            r['status'] == BookingStatus.approved ||
            r['status'] == BookingStatus.depositPaid)
        .length;
    final occupancyRate = properties.isEmpty
        ? 0.0
        : (occupiedCount / properties.length * 100).clamp(0, 100);

    final upcomingCheckIns = requests
        .where((r) {
          final checkIn = DateTime.tryParse(r['checkInDate']?.toString() ?? '');
          if (checkIn == null) return false;
          final diff = checkIn.difference(DateTime.now()).inDays;
          return diff >= 0 && diff <= 7;
        })
        .length;

    final subUsed = (sub['properties_used'] as num?)?.toInt() ?? 0;
    final subLimit = (sub['properties_limit'] as num?)?.toInt() ?? -1;
    final nearSubLimit = subLimit > 0 && subUsed >= subLimit - 1;
    final pendingCollection = await DataService.getPendingCollectionCount(ownerId);
    final vacantBeds = await DataService.getVacantBeds(ownerId);
    final overdue = await DataService.getOverduePayments(ownerId);
    final todayIncome = await DataService.getOwnerTodayIncome(ownerId);
    final bookingsThisMonth = await DataService.getOwnerBookingsThisMonth(ownerId);
    final avgStay = await DataService.getOwnerAvgStayDuration(ownerId);
    final propertyPerformance =
        await DataService.getOwnerPropertyPerformance(ownerId);
    final topPerf = propertyPerformance.isNotEmpty ? propertyPerformance.first : null;

    return {
      'userName': user?['name'] ?? 'المالك',
      'accountId': user?['accountId']?.toString() ??
          AccountIdService.demoAccountIds[ownerId] ??
          '',
      'verificationStatus': verification['label'] ?? 'غير موثق',
      if (verification['reason'] != null)
        'verificationReason': verification['reason'],
      'trustScore': trust['score'],
      'trustLevel': trust['level'],
      'trustData': trust,
      'propertiesCount': properties.length,
      'approvedProperties':
          properties.where((p) => p['status'] == 'approved').length,
      'pendingProperties':
          properties.where((p) => p['status'] == 'pending').length,
      'pendingBookings': pending,
      'monthlyRevenue': revenue,
      'todayIncome': todayIncome.round(),
      'smartPricingHint': properties.isNotEmpty
          ? {
              'propertyId': properties.first['id'],
              'price': double.tryParse(
                    properties.first['price']?.toString().replaceAll(',', '') ??
                        '2500',
                  ) ??
                  2500,
              'location': properties.first['location'] ??
                  properties.first['governorate'],
            }
          : null,
      'escrowBalance': wallet['escrow'] ?? 0,
      'availableToWithdraw': wallet['available'] ?? 0,
      'pendingPayouts': wallet['pending'] ?? 0,
      'occupancyRate': occupancyRate.round(),
      'bookingsThisMonth': bookingsThisMonth,
      'avgStayDuration': avgStay,
      'propertyPerformance': propertyPerformance,
      'revenueTrend': revenue > 0 ? 'up' : 'stable',
      'revenueForecast': (revenue * 1.08).round(),
      'upcomingCheckIns': upcomingCheckIns,
      'nearSubscriptionLimit': nearSubLimit,
      'pendingInstallments': requests
          .where((r) =>
              r['status'] == 'approved' || r['status'] == 'deposit_paid')
          .length,
      'lateInstallments': overdue.length,
      'pendingCollection': pendingCollection,
      'vacantBeds': vacantBeds,
      'overdueTenants': overdue,
      'newRequests': pending,
      'activeMaintenance': 0,
      'topProperty': topPerf?['title'] ??
          (properties.isNotEmpty ? properties.first['title'] : 'لا توجد عقارات بعد'),
      'topPropertyViews': topPerf?['views'] ?? (properties.length * 12),
      'subscriptionPlan': sub['plan_name'],
      'subscriptionPlanId': sub['plan_id'],
      'subscriptionLimit': sub['properties_limit'],
      'subscriptionUsed': sub['properties_used'],
      'subscriptionFeatures': sub['features'],
      'canFeature': sub['can_feature'],
      'subscriptionEndDate': sub['end_date'],
      'daysUntilSubscriptionExpiry': daysUntilExpiry,
      'subscriptionExpiringSoon': subscriptionExpiringSoon,
      'contextualAction': _ownerContextualAction(pending, nearSubLimit),
      'banner': nearSubLimit
          ? 'تنبيه: اقتربت من حد الباقة — ${sub['properties_used']}/${sub['properties_limit'] == -1 ? '∞' : sub['properties_limit']} عقار'
          : 'باقتك: ${sub['plan_name']}${sub['plan_id'] == 'gold' ? ' ⭐' : ''} — '
              '${sub['properties_used']}/${sub['properties_limit'] == -1 ? '∞' : sub['properties_limit']} إعلان',
    };
  }

  Map<String, dynamic>? _tenantContextualAction(Map<String, dynamic> stats) {
    if (stats['activeBooking'] == true) {
      final nextLabel = stats['nextActionLabel']?.toString();
      final statusLabel = stats['bookingStatusLabel']?.toString() ?? 'حجز نشط';
      final title = nextLabel != null && nextLabel.isNotEmpty
          ? 'التالي: $nextLabel'
          : 'تابع حجزك';
      return {
        'title': title,
        'subtitle': stats['bookingTitle'] ?? statusLabel,
        'icon': 'booking',
        'badge': stats['nextInstallmentDays'] ?? 0,
        'actionKey': stats['nextActionKey'],
      };
    }
    if ((stats['verificationStatus'] ?? '').toString().contains('غير موثق')) {
      return {
        'title': 'وثّق هويتك',
        'subtitle': 'ارفع مستنداتك للحجز بثقة',
        'icon': 'kyc',
      };
    }
    return null;
  }

  Map<String, dynamic>? _ownerContextualAction(int pending, bool nearLimit) {
    if (pending > 0) {
      return {
        'title': 'طلبات بانتظارك',
        'subtitle': '$pending حجز يحتاج مراجعتك',
        'icon': 'requests',
        'badge': pending,
      };
    }
    if (nearLimit) {
      return {
        'title': 'ترقية الباقة',
        'subtitle': 'اقتربت من حد الإعلانات',
        'icon': 'subscription',
      };
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadTechStats() async {
    final user = await AuthService.getCurrentUser();
    final techId = user?['email']?.toString() ?? 'tech@ejari.app';
    final stats = await MaintenanceService.getTechnicianStats(techId);
    return {
      'userName': user?['name'] ?? 'فني إيجاري',
      'verificationStatus': 'موثق',
      'availability': 'متاح',
      'newRequests': stats['newRequests'] ?? 0,
      'nearbyRequests': stats['activeJobs'] ?? 0,
      'activeJobs': stats['activeJobs'] ?? 0,
      'completedJobs': stats['completedJobs'] ?? 0,
      'todayEarnings': stats['todayEarnings'] ?? 0,
      'monthlyEarnings': stats['monthlyEarnings'] ?? 0,
      'availableBalance': stats['availableBalance'] ?? 0,
      'rating': stats['rating'] ?? 4.8,
      'reviewsCount': stats['completedCount'] ?? 0,
      'urgentRequests': stats['urgentRequests'] ?? 0,
      'banner': 'تابع مهامك من لوحة الفني',
    };
  }
}
