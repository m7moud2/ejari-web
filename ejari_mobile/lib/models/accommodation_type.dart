/// نوع الوحدة المؤجرة: شقة كاملة، غرفة مشتركة، أو سرير.
enum AccommodationType {
  fullUnit,
  sharedRoom,
  bed,
}

extension AccommodationTypeX on AccommodationType {
  String get value {
    switch (this) {
      case AccommodationType.fullUnit:
        return 'full_unit';
      case AccommodationType.sharedRoom:
        return 'shared_room';
      case AccommodationType.bed:
        return 'bed';
    }
  }

  String get arabicLabel {
    switch (this) {
      case AccommodationType.fullUnit:
        return 'شقة كاملة';
      case AccommodationType.sharedRoom:
        return 'غرفة مشتركة';
      case AccommodationType.bed:
        return 'سرير';
    }
  }

  String get filterLabel {
    switch (this) {
      case AccommodationType.fullUnit:
        return 'شقق';
      case AccommodationType.sharedRoom:
        return 'غرف مشتركة';
      case AccommodationType.bed:
        return 'أسرّة';
    }
  }
}

AccommodationType accommodationTypeFromValue(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'shared_room':
    case 'shared':
      return AccommodationType.sharedRoom;
    case 'bed':
      return AccommodationType.bed;
    case 'full_unit':
    case 'full':
    default:
      return AccommodationType.fullUnit;
  }
}

AccommodationType accommodationTypeFromProperty(Map<String, dynamic> property) {
  final raw = property['accommodationType'] ??
      property['unitListingType'] ??
      property['listingType'];
  if (raw == 'rent' || raw == 'for_sale' || raw == 'sale') {
    return AccommodationType.fullUnit;
  }
  return accommodationTypeFromValue(raw?.toString());
}

bool isSharedAccommodation(Map<String, dynamic> property) {
  final t = accommodationTypeFromProperty(property);
  return t == AccommodationType.sharedRoom || t == AccommodationType.bed;
}

String accommodationPriceSuffix(Map<String, dynamic> property) {
  final t = accommodationTypeFromProperty(property);
  switch (t) {
    case AccommodationType.bed:
      return 'ج.م / سرير / شهر';
    case AccommodationType.sharedRoom:
      return 'ج.م / غرفة / شهر';
    case AccommodationType.fullUnit:
      return 'ج.م / شهر';
  }
}
