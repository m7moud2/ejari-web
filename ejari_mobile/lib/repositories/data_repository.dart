import '../config/app_config.dart';
import '../services/data_service.dart';
import '../services/firestore_booking_service.dart';
import '../services/firestore_property_service.dart';

/// Abstraction over local demo data vs Firebase Firestore.
abstract class DataRepository {
  Future<List<Map<String, dynamic>>> getAllProperties({bool approvedOnly = true});
  Future<Map<String, dynamic>?> findPropertyById(String id);
  Future<List<Map<String, dynamic>>> getBookings();
  Future<List<Map<String, dynamic>>> getOwnerProperties(String ownerId);
  Future<Map<String, dynamic>> exportAdminDailyReport();
  Future<Map<String, dynamic>> exportOwnerMonthlyReport(String ownerId);
  Future<List<Map<String, dynamic>>> getTenantUpcomingPayments();
  Future<int> getUnreadNotificationCount();

  static DataRepository get instance =>
      AppConfig.demoMode ? DemoDataRepository() : FirestoreDataRepository();
}

/// Demo / local SharedPreferences implementation.
class DemoDataRepository implements DataRepository {
  @override
  Future<List<Map<String, dynamic>>> getAllProperties(
          {bool approvedOnly = true}) =>
      DataService.getAllProperties(approvedOnly: approvedOnly);

  @override
  Future<Map<String, dynamic>?> findPropertyById(String id) =>
      DataService.findPropertyById(id);

  @override
  Future<List<Map<String, dynamic>>> getBookings() => DataService.getBookings();

  @override
  Future<List<Map<String, dynamic>>> getOwnerProperties(String ownerId) =>
      DataService.getOwnerProperties(ownerId);

  @override
  Future<Map<String, dynamic>> exportAdminDailyReport() =>
      DataService.exportAdminDailyReport();

  @override
  Future<Map<String, dynamic>> exportOwnerMonthlyReport(String ownerId) =>
      DataService.exportOwnerMonthlyReport(ownerId);

  @override
  Future<List<Map<String, dynamic>>> getTenantUpcomingPayments() =>
      DataService.getTenantUpcomingPayments();

  @override
  Future<int> getUnreadNotificationCount() =>
      DataService.getUnreadNotificationCount();
}

/// Production path: Firestore for properties + bookings; reports stay local/hybrid.
class FirestoreDataRepository implements DataRepository {
  @override
  Future<List<Map<String, dynamic>>> getAllProperties(
          {bool approvedOnly = true}) =>
      FirestorePropertyService.getAllProperties(approvedOnly: approvedOnly);

  @override
  Future<Map<String, dynamic>?> findPropertyById(String id) async {
    final all = await getAllProperties(approvedOnly: false);
    try {
      return all.firstWhere((p) => p['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBookings() =>
      FirestoreBookingService.getBookingsForCurrentUser();

  @override
  Future<List<Map<String, dynamic>>> getOwnerProperties(String ownerId) async {
    final all = await getAllProperties(approvedOnly: false);
    return all
        .where((p) => p['ownerId']?.toString() == ownerId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> exportAdminDailyReport() =>
      DataService.exportAdminDailyReport();

  @override
  Future<Map<String, dynamic>> exportOwnerMonthlyReport(String ownerId) =>
      DataService.exportOwnerMonthlyReport(ownerId);

  @override
  Future<List<Map<String, dynamic>>> getTenantUpcomingPayments() async {
    final bookings = await getBookings();
    return bookings
        .where((b) =>
            b['paymentStatus'] == 'pending' ||
            b['status'] == 'pending' ||
            b['nextDueDate'] != null)
        .toList();
  }

  @override
  Future<int> getUnreadNotificationCount() =>
      DataService.getUnreadNotificationCount();
}
