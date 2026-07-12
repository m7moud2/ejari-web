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

  Future<void> loadHomeData(String role) async {
    isLoading = true;
    hasError = false;

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
      if (cached == null) {
        hasError = true;
        errorMessage = e.toString();
      }
    } finally {
      isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }
}
