import 'package:flutter/material.dart';
import '../repositories/home_repository.dart';
import '../models/home_stats_model.dart';
import '../services/home_stats_cache.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();
  
  bool isLoading = false;
  bool hasError = false;
  bool loadedFromCache = false;
  String errorMessage = '';
  HomeStatsModel stats = HomeStatsModel.empty();

  Future<void> loadHomeData(String role, {bool silent = false}) async {
    // Keep existing content on screen while refreshing so role home views
    // (especially technician) are not disposed mid-load.
    final showBlockingLoader = !silent && !_hasAnyStats;
    if (showBlockingLoader) {
      isLoading = true;
      hasError = false;
      if (hasListeners) notifyListeners();
    } else {
      hasError = false;
    }

    final cached = await HomeStatsCache.load(role);
    if (cached != null) {
      stats = cached;
      loadedFromCache = true;
      if (hasListeners) notifyListeners();
    }

    try {
      stats = await _repository.fetchHomeStats(role);
      loadedFromCache = false;
      await HomeStatsCache.save(role, stats);
    } catch (e) {
      if (cached == null && !_hasAnyStats) {
        hasError = true;
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }

  bool get _hasAnyStats =>
      stats.tenantStats.isNotEmpty ||
      stats.ownerStats.isNotEmpty ||
      stats.techStats.isNotEmpty ||
      stats.adminStats.isNotEmpty;
}
