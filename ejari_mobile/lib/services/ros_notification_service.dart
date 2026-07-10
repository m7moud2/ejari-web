import 'data_service.dart';
import 'bed_hierarchy_service.dart';
import 'smart_pricing_service.dart';

/// تنبيهات ذكية — شاغر 7 أيام، حجز قريب، دفع متأخر.
class RosNotificationService {
  RosNotificationService._();

  /// فحص وإرسال التنبيهات للمالك والمستأجر (demo).
  static Future<int> runSmartChecks(String userEmail, String role) async {
    var sent = 0;
    if (role == 'owner') {
      sent += await _checkVacantBeds(userEmail);
      sent += await _checkUpcomingBookingsOwner(userEmail);
    } else {
      sent += await _checkApproachingBookings(userEmail);
      sent += await _checkOverduePayments(userEmail);
    }
    return sent;
  }

  static Future<int> _checkVacantBeds(String ownerId) async {
    final vacant =
        await BedHierarchyService.getVacantBedsSinceDays(ownerId, 7);
    var sent = 0;
    for (final bed in vacant.take(3)) {
      await DataService.addNotificationToUser(
        ownerId,
        'سرير شاغر منذ ${bed['vacantDays']} أيام 🛏️',
        '${bed['bedLabel']} في ${bed['propertyTitle']} — فكّر بتخفيض',
        type: 'vacant_bed',
        refId: bed['bedId']?.toString(),
      );
      sent++;
    }

    final discount = await SmartPricingService.suggestVacancyDiscount(ownerId);
    if (discount != null) {
      await DataService.addNotificationToUser(
        ownerId,
        'اقتراح تخفيض تلقائي 💡',
        discount['reason']?.toString() ?? 'سرير شاغر غداً',
        type: 'auto_discount',
        refId: discount['bedId']?.toString(),
      );
      sent++;
    }
    return sent;
  }

  static Future<int> _checkApproachingBookings(String tenantEmail) async {
    final bookings = await DataService.getBookings();
    var sent = 0;
    for (final b in bookings) {
      if (b['tenantEmail']?.toString() != tenantEmail) continue;
      final checkIn =
          DateTime.tryParse(b['checkInDate']?.toString() ?? '');
      if (checkIn == null) continue;
      final days = checkIn.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 3) {
        await DataService.addNotificationToUser(
          tenantEmail,
          'حجزك قريب 📅',
          '${b['title']} — الدخول خلال $days أيام',
          type: 'booking_reminder',
          refId: b['id']?.toString(),
        );
        sent++;
      }
    }
    return sent;
  }

  static Future<int> _checkUpcomingBookingsOwner(String ownerId) async {
    final requests = await DataService.getOwnerRequests(ownerId);
    var sent = 0;
    for (final r in requests) {
      final checkIn =
          DateTime.tryParse(r['checkInDate']?.toString() ?? '');
      if (checkIn == null) continue;
      final days = checkIn.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 2) {
        await DataService.addNotificationToUser(
          ownerId,
          'استلام مستأجر قريب 🏠',
          '${r['tenantName']} — ${r['title']} خلال $days أيام',
          type: 'check_in_reminder',
          refId: r['id']?.toString(),
        );
        sent++;
      }
    }
    return sent;
  }

  static Future<int> _checkOverduePayments(String userEmail) async {
    final bookings = await DataService.getBookings();
    var sent = 0;
    for (final b in bookings) {
      final email = b['tenantEmail']?.toString();
      final owner = b['ownerEmail']?.toString();
      if (b['paymentOverdue'] == true) {
        if (email == userEmail) {
          await DataService.addNotificationToUser(
            userEmail,
            'دفعة متأخرة 💳',
            'يرجى سداد ${b['title']} في أقرب وقت',
            type: 'payment_overdue',
            refId: b['id']?.toString(),
          );
          sent++;
        }
        if (owner != null) {
          await DataService.addNotificationToUser(
            owner,
            'مستأجر متأخر في الدفع ⚠️',
            '${b['tenantName']} — ${b['title']}',
            type: 'payment_overdue',
            refId: b['id']?.toString(),
          );
        }
      }
    }
    return sent;
  }
}
