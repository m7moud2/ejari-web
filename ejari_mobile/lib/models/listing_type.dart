/// نوع الإعلان: إيجار أو بيع.
enum ListingType {
  rent,
  sale,
}

extension ListingTypeX on ListingType {
  String get arabicLabel {
    switch (this) {
      case ListingType.rent:
        return 'للإيجار';
      case ListingType.sale:
        return 'إعلان بيع';
    }
  }

  /// شارة إعلان البيع — للعرض فقط بدون وساطة.
  String get saleAdBadge => 'إعلان — للعرض فقط';

  String get value {
    switch (this) {
      case ListingType.rent:
        return 'rent';
      case ListingType.sale:
        return 'for_sale';
    }
  }
}

ListingType listingTypeFromProperty(Map<String, dynamic> property) {
  final mode = (property['listingMode'] ?? property['listingType'] ?? 'rent')
      .toString()
      .toLowerCase();
  if (mode == 'for_sale' || mode == 'sale' || mode == 'بيع') {
    return ListingType.sale;
  }
  return ListingType.rent;
}

bool isSaleListing(Map<String, dynamic> property) =>
    listingTypeFromProperty(property) == ListingType.sale;

String listingPriceLabel(Map<String, dynamic> property) {
  if (isSaleListing(property)) return 'سعر البيع';
  final durations = property['supportedDurations'] as List?;
  if (durations != null && durations.contains('يوم')) return 'السعر / يوم';
  return 'الإيجار / شهر';
}

String listingPriceSuffix(Map<String, dynamic> property) {
  return isSaleListing(property) ? 'ج.م إجمالي' : 'ج.م / شهر';
}
