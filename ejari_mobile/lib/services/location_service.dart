import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final loc.Location _location = loc.Location();

  static Future<loc.LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return null;
      }
    }

    try {
      return await _location.getLocation();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  static Future<String?> getCityName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Provide a formatted string, preferring the subAdministrativeArea (like Maadi, Nasr City)
        // falling back to locality (Cairo)
        String area = place.subAdministrativeArea ?? place.locality ?? '';
        String city = place.administrativeArea ?? '';

        if (area.isNotEmpty && city.isNotEmpty && area != city) {
          return '$area، $city';
        } else if (area.isNotEmpty) {
          return area;
        } else if (city.isNotEmpty) {
          return city;
        }
      }
    } catch (e) {
      debugPrint('Error getting city name: $e');
    }
    return null;
  }
}
