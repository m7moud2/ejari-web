import 'location_ranking.dart';
import '../data/egypt_locations.dart';

/// اكتشاف الإقامات القصيرة والعروض — بديل منظم لإعلانات فيسبوك.
class ShortStayDurationIntent {
  final String id;
  final String label;
  final int days;
  final String durationType;
  final int durationCount;

  const ShortStayDurationIntent({
    required this.id,
    required this.label,
    required this.days,
    required this.durationType,
    required this.durationCount,
  });
}

class ShortStayDiscovery {
  ShortStayDiscovery._();

  static const List<ShortStayDurationIntent> durationIntents = [
    ShortStayDurationIntent(
      id: 'night',
      label: 'ليلة',
      days: 1,
      durationType: 'يوم',
      durationCount: 1,
    ),
    ShortStayDurationIntent(
      id: 'two_days',
      label: 'يومين',
      days: 2,
      durationType: 'يوم',
      durationCount: 2,
    ),
    ShortStayDurationIntent(
      id: 'three_days',
      label: '٣ أيام',
      days: 3,
      durationType: 'يوم',
      durationCount: 3,
    ),
    ShortStayDurationIntent(
      id: 'half_week',
      label: 'نصف أسبوع',
      days: 7,
      durationType: 'يوم',
      durationCount: 7,
    ),
    ShortStayDurationIntent(
      id: 'week',
      label: 'أسبوع',
      days: 7,
      durationType: 'أسبوع',
      durationCount: 1,
    ),
    ShortStayDurationIntent(
      id: 'month',
      label: 'شهر',
      days: 30,
      durationType: 'شهر',
      durationCount: 1,
    ),
  ];

  static const List<String> exploreGovernorates = [
    'الكل',
    'مطروح',
    'الساحل الشمالي',
    'الإسكندرية',
    'الغردقة',
    'شرم الشيخ',
    'القاهرة',
    'الجيزة',
    'القليوبية',
    'الشرقية',
  ];

  static const List<String> coastalKeywords = [
    'مطروح',
    'الساحل',
    'الساحل الشمالي',
    'الإسكندرية',
    'الغردقة',
    'شرم',
    'البحر',
    'شاطئ',
    'سيدي عبدالرحمن',
    'مرسى مطروح',
    'العلمين',
    'فيروز',
  ];

  /// مرافق اكتشاف الإقامة القصيرة (فلاتر واجهة).
  static const List<Map<String, dynamic>> vacationAmenityFilters = [
    {'name': 'قريب من البحر', 'iconName': 'beach', 'key': 'nearBeach'},
    {'name': 'سيارة متاحة', 'iconName': 'car', 'key': 'carAvailable'},
    {'name': 'مطبخ', 'iconName': 'kitchen', 'key': 'kitchen'},
    {'name': 'مناسب للعائلات', 'iconName': 'family', 'key': 'familyFriendly'},
    {'name': 'بيت مستقل', 'iconName': 'house', 'key': 'independentHouse'},
    {'name': 'مكيف', 'iconName': 'ac', 'key': 'ac'},
    {'name': 'واي فاي', 'iconName': 'wifi', 'key': 'wifi'},
    {'name': 'تشطيب لوكس', 'iconName': 'luxury', 'key': 'luxury'},
    {'name': 'سراير متعددة', 'iconName': 'beds', 'key': 'multiBeds'},
  ];

  static const List<String> offerFilterLabels = [
    'عرض ٣ أيام',
    'نصف أسبوع',
    'شقتين بسعر خاص',
  ];

  static ShortStayDurationIntent? intentById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final i in durationIntents) {
      if (i.id == id) return i;
    }
    return null;
  }

  static ShortStayDurationIntent? intentByLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final i in durationIntents) {
      if (i.label == label) return i;
    }
    return null;
  }

  static double parsePrice(dynamic raw) {
    final s = raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
    return double.tryParse(s) ?? 0;
  }

  /// تقدير السعر اليومي من الحقول المباشرة أو الإيجار الشهري.
  static double dailyRate(Map<String, dynamic> property) {
    final explicit = property['dailyPrice'] ?? property['pricePerDay'];
    if (explicit != null) {
      final v = parsePrice(explicit);
      if (v > 0) return v;
    }
    final offers = specialOffers(property);
    if (offers.isNotEmpty) {
      final first = offers.first['pricePerDay'];
      final v = parsePrice(first);
      if (v > 0) return v;
    }
    final monthly = parsePrice(property['price'] ?? property['monthlyRent']);
    if (monthly <= 0) return 0;
    // نفس منطق التسعير المتدرج تقريباً: ~5% من الشهر لليوم.
    return monthly * 0.05;
  }

  static List<Map<String, dynamic>> specialOffers(Map<String, dynamic> property) {
    final raw = property['specialOffers'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static List<String> amenitiesOf(Map<String, dynamic> property) {
    final raw = property['amenities'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static bool isCoastal(Map<String, dynamic> property) {
    final hay = [
      property['governorate'],
      property['location'],
      property['address'],
      property['title'],
      property['region'],
    ].map((e) => e?.toString() ?? '').join(' ');
    return coastalKeywords.any(hay.contains);
  }

  static bool isShortStayListing(Map<String, dynamic> property) {
    if (property['listingMode'] == 'for_sale') return false;
    if (property['shortStay'] == true) return true;
    final offers = specialOffers(property);
    if (offers.isNotEmpty) return true;
    if (property['packageHalfWeek'] != null) return true;
    final durations = property['supportedDurations'];
    if (durations is List) {
      final d = durations.map((e) => e.toString()).toList();
      if (d.contains('يوم') || d.contains('أسبوع')) return true;
    }
    return isCoastal(property);
  }

  static int? nearbyBeachMinutes(Map<String, dynamic> property) {
    final v = property['nearbyBeachMinutes'];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static bool flagTrue(Map<String, dynamic> property, String key) {
    final v = property[key];
    return v == true || v?.toString() == 'true';
  }

  /// شارات العرض الظاهرة على البطاقة/التفاصيل.
  static List<String> offerBadges(Map<String, dynamic> property) {
    final badges = <String>[];
    for (final o in specialOffers(property)) {
      final label = o['label']?.toString() ?? o['title']?.toString();
      if (label != null && label.isNotEmpty) badges.add(label);
    }
    final half = property['packageHalfWeek'];
    if (half != null && !badges.any((b) => b.contains('نصف'))) {
      badges.add('نصف أسبوع');
    }
    if (flagTrue(property, 'multiUnitDeal') &&
        !badges.any((b) => b.contains('شقتين'))) {
      badges.add('شقتين بسعر خاص');
    }
    return badges;
  }

  static bool matchesAmenityFilter(
    Map<String, dynamic> property,
    String amenityName,
  ) {
    final amenities = amenitiesOf(property);
    final joined = amenities.join(' ');

    switch (amenityName) {
      case 'قريب من البحر':
        final mins = nearbyBeachMinutes(property);
        return (mins != null && mins <= 15) ||
            joined.contains('بحر') ||
            joined.contains('شاطئ') ||
            flagTrue(property, 'nearBeach');
      case 'سيارة متاحة':
        return flagTrue(property, 'carAvailable') ||
            joined.contains('سيارة');
      case 'مطبخ':
        return joined.contains('مطبخ') || flagTrue(property, 'hasKitchen');
      case 'مناسب للعائلات':
        return flagTrue(property, 'familyFriendly') ||
            joined.contains('عائلات') ||
            joined.contains('عائلي');
      case 'بيت مستقل':
        return flagTrue(property, 'independentHouse') ||
            joined.contains('مستقل') ||
            (property['type']?.toString().contains('بيت') ?? false) ||
            (property['type']?.toString().contains('فلل') ?? false);
      case 'مكيف':
        return joined.contains('مكيف') ||
            joined.contains('تكييف') ||
            flagTrue(property, 'hasAc');
      case 'واي فاي':
        return joined.contains('واي') ||
            joined.contains('إنترنت') ||
            joined.contains('انترنت') ||
            flagTrue(property, 'hasWifi');
      case 'تشطيب لوكس':
        return joined.contains('لوكس') ||
            joined.contains('فاخر') ||
            joined.contains('luxury') ||
            flagTrue(property, 'luxuryFinish');
      case 'سراير متعددة':
        final beds = int.tryParse(property['beds']?.toString() ?? '') ?? 0;
        return beds >= 3 ||
            joined.contains('سراير') ||
            joined.contains('أسرّة') ||
            flagTrue(property, 'multiBeds');
      case 'مصعد':
        return joined.contains('مصعد') ||
            joined.contains('أسانسير') ||
            joined.contains('اسانسير') ||
            flagTrue(property, 'hasElevator');
      case 'موقف':
        return joined.contains('موقف') ||
            joined.contains('جراج') ||
            joined.contains('سيارات') ||
            flagTrue(property, 'hasParking');
      case 'غاز':
        return joined.contains('غاز') || flagTrue(property, 'hasGas');
      case 'بحر':
        return matchesAmenityFilter(property, 'قريب من البحر');
      default:
        return amenities.contains(amenityName) || joined.contains(amenityName);
    }
  }

  static bool matchesGovernorate(
    Map<String, dynamic> property,
    String governorate,
  ) {
    if (governorate == 'الكل') return true;
    final normalized = EgyptLocations.normalizeGovernorate(governorate);
    final pGov = EgyptLocations.normalizeGovernorate(
      property['governorate']?.toString(),
    );
    if (normalized.isNotEmpty && pGov.isNotEmpty && normalized == pGov) {
      return true;
    }
    final hay =
        '${property['governorate'] ?? ''} ${property['location'] ?? ''} ${property['region'] ?? ''} ${property['title'] ?? ''}';
    if (governorate == 'الساحل الشمالي' || normalized == 'مطروح') {
      if (governorate == 'الساحل الشمالي') {
        return hay.contains('الساحل') ||
            hay.contains('سيدي عبدالرحمن') ||
            hay.contains('العلمين') ||
            (hay.contains('مطروح') && isCoastal(property));
      }
    }
    if (governorate == 'شرم الشيخ' || normalized == 'جنوب سيناء') {
      if (governorate == 'شرم الشيخ' || hay.contains('شرم')) {
        return hay.contains('شرم') || pGov == 'جنوب سيناء';
      }
    }
    if (governorate == 'الغردقة' || normalized == 'البحر الأحمر') {
      if (governorate == 'الغردقة' || hay.contains('الغردقة')) {
        return hay.contains('الغردقة') ||
            hay.contains('الجونة') ||
            pGov == 'البحر الأحمر';
      }
    }
    return hay.contains(governorate) ||
        (normalized.isNotEmpty && hay.contains(normalized));
  }

  static bool matchesAnyGovernorate(
    Map<String, dynamic> property,
    List<String> governorates,
  ) {
    final selected = governorates.where((g) => g != 'الكل').toList();
    if (selected.isEmpty) return true;
    return selected.any((g) => matchesGovernorate(property, g));
  }

  static bool supportsDurationDays(
    Map<String, dynamic> property,
    int days,
  ) {
    final durations = property['supportedDurations'];
    if (durations is! List || durations.isEmpty) return true;
    final d = durations.map((e) => e.toString()).toSet();
    if (days <= 6) return d.contains('يوم') || d.contains('ليلة');
    if (days <= 13) {
      return d.contains('يوم') || d.contains('أسبوع') || d.contains('ليلة');
    }
    return d.contains('شهر') || d.contains('أسبوع') || d.contains('يوم');
  }

  static bool matchesOfferFilter(
    Map<String, dynamic> property,
    String offerLabel,
  ) {
    final badges = offerBadges(property);
    if (badges.any((b) => b.contains(offerLabel) || offerLabel.contains(b))) {
      return true;
    }
    final offers = specialOffers(property);
    switch (offerLabel) {
      case 'عرض ٣ أيام':
        return offers.any((o) {
          final days = int.tryParse(o['days']?.toString() ?? '') ?? 0;
          return days == 3 ||
              (o['label']?.toString().contains('٣') ?? false) ||
              (o['label']?.toString().contains('3') ?? false);
        });
      case 'نصف أسبوع':
        return property['packageHalfWeek'] != null ||
            offers.any((o) {
              final days = int.tryParse(o['days']?.toString() ?? '') ?? 0;
              return days == 7 ||
                  (o['label']?.toString().contains('نصف') ?? false);
            });
      case 'شقتين بسعر خاص':
        return flagTrue(property, 'multiUnitDeal') ||
            offers.any((o) =>
                (o['label']?.toString().contains('شقتين') ?? false) ||
                (o['title']?.toString().contains('شقتين') ?? false));
      default:
        return false;
    }
  }

  /// فلترة موحّدة لنتائج الاستكشاف/البحث المتقدم.
  static bool matchesFilters(
    Map<String, dynamic> property,
    Map<String, dynamic> filters,
  ) {
    if (filters['coastalOnly'] == true && !isCoastal(property)) {
      return false;
    }

    if (filters['shortStayOnly'] == true && !isShortStayListing(property)) {
      return false;
    }

    if (filters['specialOffersOnly'] == true) {
      if (specialOffers(property).isEmpty &&
          property['packageHalfWeek'] == null &&
          !flagTrue(property, 'multiUnitDeal')) {
        return false;
      }
    }

    if (!LocationRanking.matchesOfferType(
      property,
      filters['offerType']?.toString(),
    )) {
      return false;
    }

    if (!LocationRanking.matchesAudience(
      property,
      filters['suitableFor']?.toString() ?? filters['audience']?.toString(),
    )) {
      return false;
    }

    if (!LocationRanking.matchesFinish(
      property,
      filters['finishStatus']?.toString(),
    )) {
      return false;
    }

    final bedsCount = filters['bedsCount'] ?? filters['minBedsCount'];
    if (bedsCount is num) {
      if (!LocationRanking.matchesMinBedsCount(property, bedsCount.toInt())) {
        return false;
      }
    }

    final city = filters['city']?.toString();
    if (city != null && city.isNotEmpty && city != 'الكل') {
      if (!LocationRanking.matchesCityFilter(property, city)) return false;
    }

    final govList = filters['governorates'];
    if (govList is List && govList.isNotEmpty) {
      if (!matchesAnyGovernorate(
        property,
        govList.map((e) => e.toString()).toList(),
      )) {
        return false;
      }
    } else if (filters['governorate'] != null) {
      if (!matchesGovernorate(property, filters['governorate'].toString())) {
        return false;
      }
    }

    final intentId = filters['durationIntent']?.toString();
    final intent = intentById(intentId) ??
        intentByLabel(filters['durationLabel']?.toString());
    if (intent != null && !supportsDurationDays(property, intent.days)) {
      return false;
    }

    final minDaily = (filters['minDailyPrice'] as num?)?.toDouble();
    final maxDaily = (filters['maxDailyPrice'] as num?)?.toDouble();
    if (minDaily != null || maxDaily != null) {
      final daily = dailyRate(property);
      if (minDaily != null && daily < minDaily) return false;
      if (maxDaily != null && daily > maxDaily) return false;
    }

    // نطاق السعر الشهري التقليدي إن وُجد
    final minPrice = (filters['minPrice'] as num?)?.toDouble();
    final maxPrice = (filters['maxPrice'] as num?)?.toDouble();
    if (minPrice != null || maxPrice != null) {
      final price = parsePrice(property['price']);
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
    }

    final amenities = filters['amenities'];
    if (amenities is List && amenities.isNotEmpty) {
      for (final a in amenities) {
        if (!matchesAmenityFilter(property, a.toString())) return false;
      }
    }

    final offers = filters['offerFilters'];
    if (offers is List && offers.isNotEmpty) {
      for (final o in offers) {
        if (!matchesOfferFilter(property, o.toString())) return false;
      }
    }

    return true;
  }

  /// Apply sortMode from filters (`nearest` | `cheapest` | `newest` | `rating`).
  static List<Map<String, dynamic>> sortFiltered(
    List<Map<String, dynamic>> properties,
    Map<String, dynamic> filters, {
    double? userLat,
    double? userLng,
    String? userGovernorate,
    String? userCity,
  }) {
    final mode = filters['sortMode']?.toString() ?? 'nearest';
    return LocationRanking.rankProperties(
      properties,
      userLat: userLat,
      userLng: userLng,
      userGovernorate: userGovernorate,
      userCity: userCity,
      sortMode: mode,
    ).map((r) {
      final p = Map<String, dynamic>.from(r.property);
      p['distanceKm'] = r.distanceKm;
      p['proximityBand'] = r.band.name;
      p['proximityLabel'] = r.arabicDistanceLabel;
      return p;
    }).toList();
  }

  /// مدة الحجز المقترحة من عرض خاص.
  static Map<String, dynamic>? bookingPrefillFromOffer(
    Map<String, dynamic> offer,
  ) {
    final days = int.tryParse(offer['days']?.toString() ?? '') ?? 0;
    if (days <= 0) return null;
    if (days == 7) {
      return {
        'durationType': 'يوم',
        'durationCount': 7,
        'durationIntent': 'half_week',
      };
    }
    if (days % 7 == 0) {
      return {
        'durationType': 'أسبوع',
        'durationCount': days ~/ 7,
        'durationIntent': 'week',
      };
    }
    if (days >= 30 && days % 30 == 0) {
      return {
        'durationType': 'شهر',
        'durationCount': days ~/ 30,
        'durationIntent': 'month',
      };
    }
    return {
      'durationType': 'يوم',
      'durationCount': days,
      'durationIntent': days == 1
          ? 'night'
          : days == 2
              ? 'two_days'
              : days == 3
                  ? 'three_days'
                  : 'half_week',
    };
  }
}
