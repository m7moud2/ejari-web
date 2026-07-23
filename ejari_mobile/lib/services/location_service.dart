import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/egypt_locations.dart';
import '../theme/app_theme.dart';

/// Persisted user location for tenant discovery ranking.
class UserLocationSnapshot {
  final double? lat;
  final double? lng;
  final String? governorate;
  final String? city;
  final String? displayLabel;
  final bool permissionGranted;
  final bool isManual;

  const UserLocationSnapshot({
    this.lat,
    this.lng,
    this.governorate,
    this.city,
    this.displayLabel,
    this.permissionGranted = false,
    this.isManual = false,
  });

  bool get hasCoords => lat != null && lng != null;

  bool get hasArea =>
      (governorate != null && governorate!.isNotEmpty) ||
      (city != null && city!.isNotEmpty);

  String get label {
    if (displayLabel != null && displayLabel!.isNotEmpty) return displayLabel!;
    if (city != null &&
        city!.isNotEmpty &&
        governorate != null &&
        governorate!.isNotEmpty) {
      return '$city، $governorate';
    }
    return city ?? governorate ?? 'مصر';
  }

  factory UserLocationSnapshot.fromPrefs(SharedPreferences prefs) {
    return UserLocationSnapshot(
      lat: prefs.getDouble(_kLat),
      lng: prefs.getDouble(_kLng),
      governorate: prefs.getString(_kGov),
      city: prefs.getString(_kCity),
      displayLabel: prefs.getString(_kLabel),
      permissionGranted: prefs.getBool(_kGranted) ?? false,
      isManual: prefs.getBool(_kManual) ?? false,
    );
  }
}

const _kLat = 'user_loc_lat';
const _kLng = 'user_loc_lng';
const _kGov = 'user_loc_governorate';
const _kCity = 'user_loc_city';
const _kLabel = 'user_loc_label';
const _kGranted = 'user_loc_granted';
const _kManual = 'user_loc_manual';
const _kAskedSession = 'user_loc_asked_session';
const _kDeniedForever = 'user_loc_denied_forever';

/// Location for tenant discovery. Uses [location] (mobile + web geolocation)
/// and [permission_handler] on native platforms.
class LocationService {
  static final loc.Location _location = loc.Location();

  static Future<UserLocationSnapshot> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return UserLocationSnapshot.fromPrefs(prefs);
  }

  static Future<void> saveSnapshot(UserLocationSnapshot snap) async {
    final prefs = await SharedPreferences.getInstance();
    if (snap.lat != null) {
      await prefs.setDouble(_kLat, snap.lat!);
    } else {
      await prefs.remove(_kLat);
    }
    if (snap.lng != null) {
      await prefs.setDouble(_kLng, snap.lng!);
    } else {
      await prefs.remove(_kLng);
    }
    await prefs.setString(_kGov, snap.governorate ?? '');
    await prefs.setString(_kCity, snap.city ?? '');
    await prefs.setString(_kLabel, snap.displayLabel ?? snap.label);
    await prefs.setBool(_kGranted, snap.permissionGranted);
    await prefs.setBool(_kManual, snap.isManual);
  }

  static Future<void> saveManualSelection({
    required String governorate,
    String? city,
  }) async {
    final center = EgyptLocations.governorateCenters[
        EgyptLocations.normalizeGovernorate(governorate)];
    final snap = UserLocationSnapshot(
      lat: center?.$1,
      lng: center?.$2,
      governorate: EgyptLocations.normalizeGovernorate(governorate),
      city: city,
      displayLabel: city != null && city.isNotEmpty
          ? '$city، $governorate'
          : governorate,
      permissionGranted: false,
      isManual: true,
    );
    await saveSnapshot(snap);
  }

  static Future<bool> shouldPromptForLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = UserLocationSnapshot.fromPrefs(prefs);
    if (saved.permissionGranted && saved.hasCoords) return false;
    if (saved.isManual && saved.hasArea) return false;
    final asked = prefs.getBool(_kAskedSession) ?? false;
    if (asked && prefs.getBool(_kDeniedForever) == true) return false;
    return !asked;
  }

  static Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAskedSession, true);
  }

  static Future<UserLocationSnapshot?> requestAndResolve() async {
    try {
      await markPromptShown();

      if (!kIsWeb) {
        final status = await Permission.locationWhenInUse.request();
        if (status.isPermanentlyDenied) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_kDeniedForever, true);
          return null;
        }
        if (!status.isGranted && !status.isLimited) {
          return null;
        }
      }

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }

      var permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      if (permission != loc.PermissionStatus.granted &&
          permission != loc.PermissionStatus.grantedLimited) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kDeniedForever, true);
        return null;
      }

      final data = await _location.getLocation().timeout(
        const Duration(seconds: 12),
        onTimeout: () => loc.LocationData.fromMap(const {}),
      );
      final lat = data.latitude;
      final lng = data.longitude;
      if (lat == null || lng == null) return null;

      final area = await reverseGeocode(lat, lng);
      final snap = UserLocationSnapshot(
        lat: lat,
        lng: lng,
        governorate: area.governorate,
        city: area.city,
        displayLabel: area.label,
        permissionGranted: true,
        isManual: false,
      );
      await saveSnapshot(snap);
      return snap;
    } catch (e) {
      debugPrint('Location request failed: $e');
      return null;
    }
  }

  static Future<({String? governorate, String? city, String label})>
      reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return (governorate: null, city: null, label: 'موقعك الحالي');
      }
      final place = placemarks.first;
      final gov = EgyptLocations.matchGovernorateFromPlacemark(
        administrativeArea: place.administrativeArea,
        locality: place.locality,
        subAdministrativeArea: place.subAdministrativeArea,
      );
      final hay = [
        place.subAdministrativeArea,
        place.locality,
        place.thoroughfare,
        place.name,
      ].whereType<String>().join(' ');
      final city = EgyptLocations.matchCityFromHaystack(hay, gov) ??
          place.subAdministrativeArea ??
          place.locality;
      final labelParts = <String>[
        if (city != null && city.isNotEmpty) city,
        if (gov != null && gov.isNotEmpty) gov,
      ];
      return (
        governorate: gov,
        city: city,
        label: labelParts.isEmpty ? 'موقعك الحالي' : labelParts.join('، '),
      );
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
      String? nearest;
      var best = double.infinity;
      EgyptLocations.governorateCenters.forEach((g, c) {
        final dlat = (c.$1 - lat).abs();
        final dlng = (c.$2 - lng).abs();
        final score = dlat * dlat + dlng * dlng;
        if (score < best) {
          best = score;
          nearest = g;
        }
      });
      return (
        governorate: nearest,
        city: null,
        label: nearest ?? 'موقعك الحالي',
      );
    }
  }

  /// Returns lat/lng map for map / property sorting helpers.
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final snap = await requestAndResolve();
      if (snap?.lat == null || snap?.lng == null) return null;
      return {'latitude': snap!.lat!, 'longitude': snap.lng!};
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getCityName(double lat, double lng) async {
    final area = await reverseGeocode(lat, lng);
    return area.label;
  }

  static Future<UserLocationSnapshot?> showEnableLocationDialog(
    BuildContext context,
  ) async {
    await markPromptShown();
    if (!context.mounted) return null;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.near_me_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'فعّل الموقع',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'فعّل الموقع لعرض أقرب الوحدات المتاحة حولك',
            style: TextStyle(
              height: 1.5,
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'manual'),
              child: const Text('اختيار يدوي'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'enable'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('تفعيل الموقع'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return null;

    if (choice == 'enable') {
      final snap = await requestAndResolve();
      if (snap != null) return snap;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم نتمكن من الحصول على الموقع — يمكنك الاختيار يدوياً'),
          ),
        );
        return showManualPicker(context);
      }
      return null;
    }

    if (choice == 'manual') {
      return showManualPicker(context);
    }
    return null;
  }

  static Future<UserLocationSnapshot?> showManualPicker(
    BuildContext context,
  ) async {
    String? selectedGov;
    String? selectedCity;

    final result = await showModalBottomSheet<UserLocationSnapshot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final cities = EgyptLocations.citiesFor(selectedGov);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'اختر محافظتك ومدينة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'سنعرض أقرب الوحدات حسب اختيارك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedGov,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة',
                            border: OutlineInputBorder(),
                          ),
                          items: EgyptLocations.allGovernorates
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setModal(() {
                              selectedGov = v;
                              selectedCity = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCity,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'المدينة / الحي',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('كل المدن'),
                            ),
                            ...cities.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: selectedGov == null
                              ? null
                              : (v) => setModal(() => selectedCity = v),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: selectedGov == null
                              ? null
                              : () async {
                                  await saveManualSelection(
                                    governorate: selectedGov!,
                                    city: selectedCity,
                                  );
                                  final snap = await loadSaved();
                                  if (ctx.mounted) Navigator.pop(ctx, snap);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('حفظ وعرض الوحدات القريبة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }
}
