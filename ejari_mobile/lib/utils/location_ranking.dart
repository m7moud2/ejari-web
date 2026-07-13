import 'dart:math' as math;

import '../data/egypt_locations.dart';

/// Proximity band used for «قربك الآن» labels and ranking.
enum LocationProximityBand {
  nearby,
  sameCity,
  sameGovernorate,
  elsewhere,
}

class RankedProperty {
  final Map<String, dynamic> property;
  final LocationProximityBand band;
  final double? distanceKm;

  const RankedProperty({
    required this.property,
    required this.band,
    this.distanceKm,
  });

  String get arabicDistanceLabel {
    switch (band) {
      case LocationProximityBand.nearby:
        if (distanceKm == null) return 'قربك';
        final km = distanceKm!;
        if (km < 1) return 'أقل من كم';
        final rounded = km < 10 ? km.round() : km.round();
        return _arabicKm(rounded);
      case LocationProximityBand.sameCity:
        return 'في حيّك';
      case LocationProximityBand.sameGovernorate:
        return 'في محافظتك';
      case LocationProximityBand.elsewhere:
        return 'مصر';
    }
  }

  static String _arabicKm(int km) {
    const digits = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    final raw = '$km';
    final ar = raw.split('').map((c) => digits[c] ?? c).join();
    return '$ar كم';
  }
}

/// Location-first ranking for tenant discovery feeds.
class LocationRanking {
  LocationRanking._();

  /// Nearby micro-area radius in km (step 1 of ranking).
  static const double nearbyRadiusKm = 8;

  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static (double?, double?) coordsOf(Map<String, dynamic> property) {
    final lat = _asDouble(property['lat'] ?? property['latitude']);
    final lng = _asDouble(property['lng'] ?? property['longitude']);
    if (lat == null || lng == null) return (null, null);
    return (lat, lng);
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static String propertyGovernorate(Map<String, dynamic> property) {
    return EgyptLocations.normalizeGovernorate(
      property['governorate']?.toString(),
    );
  }

  static String propertyCityHaystack(Map<String, dynamic> property) {
    return [
      property['location'],
      property['address'],
      property['city'],
      property['district'],
      property['region'],
      property['title'],
    ].map((e) => e?.toString() ?? '').join(' ');
  }

  static LocationProximityBand classify({
    required Map<String, dynamic> property,
    double? userLat,
    double? userLng,
    String? userGovernorate,
    String? userCity,
    double nearbyKm = nearbyRadiusKm,
  }) {
    final coords = coordsOf(property);
    if (userLat != null &&
        userLng != null &&
        coords.$1 != null &&
        coords.$2 != null) {
      final km = haversineKm(userLat, userLng, coords.$1!, coords.$2!);
      if (km <= nearbyKm) return LocationProximityBand.nearby;
    }

    final pGov = propertyGovernorate(property);
    final uGov = EgyptLocations.normalizeGovernorate(userGovernorate);
    final hay = propertyCityHaystack(property);

    if (userCity != null &&
        userCity.isNotEmpty &&
        EgyptLocations.matchesCity(hay, userCity)) {
      return LocationProximityBand.sameCity;
    }

    if (uGov.isNotEmpty && pGov.isNotEmpty && uGov == pGov) {
      // Same governorate but no city match → district/city band if text overlaps lightly
      final cities = EgyptLocations.citiesFor(uGov);
      for (final c in cities) {
        if (hay.contains(c) &&
            userCity != null &&
            userCity.isNotEmpty &&
            (userCity == c || hay.contains(userCity))) {
          return LocationProximityBand.sameCity;
        }
      }
      return LocationProximityBand.sameGovernorate;
    }

    return LocationProximityBand.elsewhere;
  }

  static RankedProperty rankOne({
    required Map<String, dynamic> property,
    double? userLat,
    double? userLng,
    String? userGovernorate,
    String? userCity,
    double nearbyKm = nearbyRadiusKm,
  }) {
    final coords = coordsOf(property);
    double? km;
    if (userLat != null &&
        userLng != null &&
        coords.$1 != null &&
        coords.$2 != null) {
      km = haversineKm(userLat, userLng, coords.$1!, coords.$2!);
    }
    final band = classify(
      property: property,
      userLat: userLat,
      userLng: userLng,
      userGovernorate: userGovernorate,
      userCity: userCity,
      nearbyKm: nearbyKm,
    );
    return RankedProperty(property: property, band: band, distanceKm: km);
  }

  /// Sort: nearby → same city → same governorate → rest; within band by distance then price.
  static List<RankedProperty> rankProperties(
    List<Map<String, dynamic>> properties, {
    double? userLat,
    double? userLng,
    String? userGovernorate,
    String? userCity,
    double nearbyKm = nearbyRadiusKm,
    String sortMode = 'nearest', // nearest | cheapest | newest | rating
  }) {
    final ranked = properties
        .map(
          (p) => rankOne(
            property: p,
            userLat: userLat,
            userLng: userLng,
            userGovernorate: userGovernorate,
            userCity: userCity,
            nearbyKm: nearbyKm,
          ),
        )
        .toList();

    int bandOrder(LocationProximityBand b) {
      switch (b) {
        case LocationProximityBand.nearby:
          return 0;
        case LocationProximityBand.sameCity:
          return 1;
        case LocationProximityBand.sameGovernorate:
          return 2;
        case LocationProximityBand.elsewhere:
          return 3;
      }
    }

    double priceOf(Map<String, dynamic> p) {
      final s = (p['price'] ?? p['dailyPrice'] ?? '0')
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(s) ?? double.infinity;
    }

    double ratingOf(Map<String, dynamic> p) {
      final r = p['rating'] ?? p['avgRating'] ?? 0;
      if (r is num) return r.toDouble();
      return double.tryParse(r.toString()) ?? 0;
    }

    DateTime? createdOf(Map<String, dynamic> p) {
      final raw = p['createdAt'] ?? p['updatedAt'];
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    ranked.sort((a, b) {
      if (sortMode == 'cheapest') {
        final c = priceOf(a.property).compareTo(priceOf(b.property));
        if (c != 0) return c;
      } else if (sortMode == 'newest') {
        final ca = createdOf(a.property);
        final cb = createdOf(b.property);
        if (ca != null && cb != null) {
          final c = cb.compareTo(ca);
          if (c != 0) return c;
        } else if (ca != null) {
          return -1;
        } else if (cb != null) {
          return 1;
        }
      } else if (sortMode == 'rating') {
        final c = ratingOf(b.property).compareTo(ratingOf(a.property));
        if (c != 0) return c;
      }

      final bandCmp = bandOrder(a.band).compareTo(bandOrder(b.band));
      if (bandCmp != 0) return bandCmp;

      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      final distCmp = da.compareTo(db);
      if (distCmp != 0) return distCmp;

      return priceOf(a.property).compareTo(priceOf(b.property));
    });

    return ranked;
  }

  /// Filter map helpers for advanced search.
  static bool matchesCityFilter(
    Map<String, dynamic> property,
    String? city,
  ) {
    if (city == null || city.isEmpty || city == 'الكل') return true;
    return EgyptLocations.matchesCity(propertyCityHaystack(property), city);
  }

  static bool matchesAudience(
    Map<String, dynamic> property,
    String? audience,
  ) {
    if (audience == null || audience.isEmpty || audience == 'الكل') return true;
    final raw = property['suitableFor'];
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    final hay = [
      ...list,
      property['audience']?.toString() ?? '',
      ...(property['amenities'] is List
          ? (property['amenities'] as List).map((e) => e.toString())
          : const <String>[]),
      property['title']?.toString() ?? '',
    ].join(' ');

    switch (audience) {
      case 'أفراد':
        return list.contains('أفراد') ||
            hay.contains('أفراد') ||
            hay.contains('فرد');
      case 'عائلات':
        return list.contains('عائلات') ||
            hay.contains('عائلات') ||
            property['familyFriendly'] == true;
      case 'طلاب':
        return list.contains('طلاب') || hay.contains('طلاب');
      case 'عمال':
        return list.contains('عمال') || hay.contains('عمال');
      case 'شركات':
        return list.contains('شركات') ||
            property['corporateEligible'] == true ||
            hay.contains('شركات');
      default:
        return list.contains(audience) || hay.contains(audience);
    }
  }

  static bool matchesFinish(
    Map<String, dynamic> property,
    String? finish,
  ) {
    if (finish == null || finish.isEmpty || finish == 'الكل') return true;
    final f = property['finishStatus']?.toString() ?? '';
    final amenities = property['amenities'] is List
        ? (property['amenities'] as List).map((e) => e.toString()).join(' ')
        : '';
    final furnished =
        property['furnished'] == true || property['isFurnished'] == true;
    switch (finish) {
      case 'مفروش':
        return furnished || f == 'مفروش' || amenities.contains('مفروش');
      case 'على التشطيب':
        return f == 'على التشطيب' ||
            amenities.contains('تشطيب') ||
            property['onFinish'] == true;
      case 'جديد':
        return f == 'جديد' ||
            amenities.contains('جديد') ||
            property['isNew'] == true;
      default:
        return f == finish;
    }
  }

  static bool matchesOfferType(
    Map<String, dynamic> property,
    String? offerType,
  ) {
    if (offerType == null || offerType.isEmpty || offerType == 'الكل') {
      return true;
    }
    if (offerType == 'إعلان بيع') {
      return property['listingMode'] == 'for_sale';
    }
    if (property['listingMode'] == 'for_sale') return false;

    final durations = property['supportedDurations'];
    final d = durations is List
        ? durations.map((e) => e.toString()).toSet()
        : <String>{};

    switch (offerType) {
      case 'إيجار يومي':
        return d.contains('يوم') ||
            d.contains('ليلة') ||
            property['dailyPrice'] != null ||
            property['shortStay'] == true;
      case 'أسبوعي':
        return d.contains('أسبوع') || property['shortStay'] == true;
      case 'شهري':
        return d.contains('شهر') || d.isEmpty;
      case 'طويل':
        return d.contains('سنة') ||
            d.contains('طويل') ||
            property['longTerm'] == true;
      default:
        return true;
    }
  }

  static bool matchesMinBedsCount(
    Map<String, dynamic> property,
    int? minBedsCount,
  ) {
    if (minBedsCount == null || minBedsCount <= 0) return true;
    final beds = int.tryParse(property['beds']?.toString() ?? '') ?? 0;
    final bedCount =
        int.tryParse(property['bedsCount']?.toString() ?? '') ?? beds;
    return bedCount >= minBedsCount;
  }
}
