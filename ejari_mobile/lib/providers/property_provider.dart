import 'package:flutter/material.dart';
import '../services/firestore_property_service.dart';
import '../services/location_service.dart';
import 'package:latlong2/latlong.dart';

class PropertyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _rentProperties = [];
  List<Map<String, dynamic>> _saleProperties = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _userCity; // Stores the resolved city/neighborhood name

  List<Map<String, dynamic>> get rentProperties => _rentProperties;
  List<Map<String, dynamic>> get saleProperties => _saleProperties;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get userCity => _userCity;

  Future<void> fetchAllProperties() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final properties =
          await FirestorePropertyService.getAllProperties(approvedOnly: true);

      // Prefer persisted location; avoid re-prompting on every catalog fetch.
      final saved = await LocationService.loadSaved();
      final userLat = saved.lat;
      final userLng = saved.lng;
      if (userLat != null && userLng != null) {
        _userCity = saved.label;

        const Distance distance = Distance();

        for (var p in properties) {
          if (p['lat'] != null && p['lng'] != null) {
            final double pLat = (p['lat'] as num).toDouble();
            final double pLng = (p['lng'] as num).toDouble();
            final double distanceInMeters =
                distance(LatLng(userLat, userLng), LatLng(pLat, pLng));
            p['distanceMeters'] = distanceInMeters;
          } else {
            // Put very far away if no coordinates
            p['distanceMeters'] = 999999999.0;
          }
        }

        // Sort by distance (nearest first)
        properties.sort((a, b) => (a['distanceMeters'] as double)
            .compareTo(b['distanceMeters'] as double));
      } else {
        _userCity = null; // Could not get location
      }

      _rentProperties =
          properties.where((p) => p['listingMode'] != 'for_sale').toList();
      _saleProperties =
          properties.where((p) => p['listingMode'] == 'for_sale').toList();
    } catch (e) {
      _errorMessage = e is String
          ? e
          : 'تعذر تحميل العقارات. تحقق من الاتصال وحاول مرة أخرى';
      debugPrint('PropertyProvider: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> addProperty(Map<String, dynamic> property) async {
    await FirestorePropertyService.addProperty(property);
    await fetchAllProperties();
  }

  Future<void> deleteProperty(String id) async {
    await FirestorePropertyService.deleteProperty(id);
    await fetchAllProperties();
  }
}
