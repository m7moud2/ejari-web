import 'package:flutter/material.dart';
import '../repositories/home_repository.dart';
import '../models/home_stats_model.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository = HomeRepository();
  
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  HomeStatsModel stats = HomeStatsModel.empty();

  Future<void> loadHomeData(String role) async {
    isLoading = true;
    hasError = false;
    if (hasListeners) notifyListeners();

    try {
      stats = await _repository.fetchHomeStats(role);
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }
}
