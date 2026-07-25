/// Supported operating regions for Ejari (Middle East launch set).
enum AppRegion {
  egypt,
  saudiArabia,
  uae,
}

extension AppRegionX on AppRegion {
  String get countryCode {
    switch (this) {
      case AppRegion.egypt:
        return 'EG';
      case AppRegion.saudiArabia:
        return 'SA';
      case AppRegion.uae:
        return 'AE';
    }
  }

  /// ISO 4217 currency code.
  String get currencyCode {
    switch (this) {
      case AppRegion.egypt:
        return 'EGP';
      case AppRegion.saudiArabia:
        return 'SAR';
      case AppRegion.uae:
        return 'AED';
    }
  }

  /// Local currency symbol (RTL-safe Arabic abbreviations).
  String get currencySymbol {
    switch (this) {
      case AppRegion.egypt:
        return 'ج.م';
      case AppRegion.saudiArabia:
        return 'ر.س';
      case AppRegion.uae:
        return 'د.إ';
    }
  }

  /// Fraction digits for display (Gulf often shows 2; Egypt UI historically 0).
  int get currencyDecimals {
    switch (this) {
      case AppRegion.egypt:
        return 0;
      case AppRegion.saudiArabia:
      case AppRegion.uae:
        return 2;
    }
  }

  String get nameAr {
    switch (this) {
      case AppRegion.egypt:
        return 'مصر';
      case AppRegion.saudiArabia:
        return 'السعودية';
      case AppRegion.uae:
        return 'الإمارات';
    }
  }

  String get nameEn {
    switch (this) {
      case AppRegion.egypt:
        return 'Egypt';
      case AppRegion.saudiArabia:
        return 'Saudi Arabia';
      case AppRegion.uae:
        return 'United Arab Emirates';
    }
  }

  String displayName({required bool arabic}) => arabic ? nameAr : nameEn;

  /// Demo cities shown when browsing this region.
  List<String> get demoCitiesAr {
    switch (this) {
      case AppRegion.egypt:
        return ['القاهرة', 'الجيزة', 'الإسكندرية', 'الساحل الشمالي'];
      case AppRegion.saudiArabia:
        return ['الرياض', 'جدة'];
      case AppRegion.uae:
        return ['دبي', 'أبوظبي'];
    }
  }

  List<String> get demoCitiesEn {
    switch (this) {
      case AppRegion.egypt:
        return ['Cairo', 'Giza', 'Alexandria', 'North Coast'];
      case AppRegion.saudiArabia:
        return ['Riyadh', 'Jeddah'];
      case AppRegion.uae:
        return ['Dubai', 'Abu Dhabi'];
    }
  }

  /// Payment corridor label for UI copy.
  String get paymentCorridorLabel {
    switch (this) {
      case AppRegion.egypt:
        return 'Paymob';
      case AppRegion.saudiArabia:
      case AppRegion.uae:
        return 'Gulf';
    }
  }

  static AppRegion fromCountryCode(String? code) {
    switch ((code ?? '').trim().toUpperCase()) {
      case 'SA':
      case 'KSA':
        return AppRegion.saudiArabia;
      case 'AE':
      case 'UAE':
        return AppRegion.uae;
      case 'EG':
      default:
        return AppRegion.egypt;
    }
  }

  static AppRegion? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim().toLowerCase();
    for (final r in AppRegion.values) {
      if (r.name.toLowerCase() == v ||
          r.countryCode.toLowerCase() == v ||
          r.currencyCode.toLowerCase() == v) {
        return r;
      }
    }
    return fromCountryCode(raw);
  }
}
