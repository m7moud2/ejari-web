import '../config/app_config.dart';
import '../services/data_service.dart';

/// Abstraction over local demo data — swap for Firebase/API later.
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
      AppConfig.demoMode ? DemoDataRepository() : DemoDataRepository();
}

/// Demo / local SharedPreferences implementation (current production path).
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
