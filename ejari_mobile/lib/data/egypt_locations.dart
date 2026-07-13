/// Complete Egyptian governorates with major cities for cascading filters.
class EgyptLocations {
  EgyptLocations._();

  static const List<String> allGovernorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'الشرقية',
    'القليوبية',
    'كفر الشيخ',
    'الغربية',
    'المنوفية',
    'البحيرة',
    'الإسماعيلية',
    'بورسعيد',
    'السويس',
    'شمال سيناء',
    'جنوب سيناء',
    'مطروح',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'الوادي الجديد',
    'دمياط',
  ];

  /// Alias keys used in older seed / coastal data.
  static const Map<String, String> governorateAliases = {
    'الغردقة': 'البحر الأحمر',
    'شرم الشيخ': 'جنوب سيناء',
    'الساحل الشمالي': 'مطروح',
  };

  static const Map<String, List<String>> citiesByGovernorate = {
    'القاهرة': [
      'مدينة نصر',
      'المعادي',
      'مصر الجديدة',
      'التجمع الخامس',
      'وسط البلد',
      'الزمالك',
      'شبرا',
      'حلوان',
      'عين شمس',
      'المقطم',
    ],
    'الجيزة': [
      'الدقي',
      'المهندسين',
      'الهرم',
      '٦ أكتوبر',
      'الشيخ زايد',
      'فيصل',
      'العجوزة',
      'أوسيم',
      'البساتين',
    ],
    'الإسكندرية': [
      'سموحة',
      'جليم',
      'ستانلي',
      'المنتزه',
      'ميامي',
      'سيدي جابر',
      'العجمي',
      'محرم بك',
    ],
    'الدقهلية': ['المنصورة', 'طلخا', 'ميت غمر', 'بلقاس', 'أجا'],
    'الشرقية': ['الزقازيق', 'العاشر من رمضان', 'بلبيس', 'فاقوس', 'منيا القمح'],
    'القليوبية': ['بنها', 'شبرا الخيمة', 'قليوب', 'الخانكة', 'العبور'],
    'كفر الشيخ': ['كفر الشيخ', 'دسوق', 'بلطيم', 'فوه', 'سيدي سالم'],
    'الغربية': ['طنطا', 'المحلة الكبرى', 'زفتى', 'كفر الزيات', 'سمنود'],
    'المنوفية': ['شبين الكوم', 'منوف', 'قويسنا', 'أشمون', 'سرس الليان'],
    'البحيرة': ['دمنهور', 'كفر الدوار', 'رشيد', 'إدكو', 'وادي النطرون'],
    'الإسماعيلية': ['الإسماعيلية', 'فايد', 'القنطرة شرق', 'التل الكبير'],
    'بورسعيد': ['بورسعيد', 'بور فؤاد', 'حي الزهور'],
    'السويس': ['السويس', 'الأربعين', 'فيصل'],
    'شمال سيناء': ['العريش', 'الشيخ زويد', 'رفح', 'بئر العبد'],
    'جنوب سيناء': ['شرم الشيخ', 'نبق', 'دهب', 'نويبع', 'طابا', 'طور سيناء'],
    'مطروح': [
      'مرسى مطروح',
      'سيدي عبدالرحمن',
      'العلمين',
      'الساحل الشمالي',
      'النجيلة',
      'سيوة',
      'الحمام',
    ],
    'الفيوم': ['الفيوم', 'سنورس', 'طامية', 'إطسا'],
    'بني سويف': ['بني سويف', 'الواسطى', 'ناصر', 'الفشن'],
    'المنيا': ['المنيا', 'ملوي', 'بني مزار', 'مغاغة'],
    'أسيوط': ['أسيوط', 'ديروط', 'منفلوط', 'أبو تيج'],
    'سوهاج': ['سوهاج', 'جرجا', 'طهطا', 'أخميم'],
    'قنا': ['قنا', 'نجع حمادي', 'قفط', 'دشنا'],
    'الأقصر': ['الأقصر', 'الكرنك', 'إسنا', 'الزينية'],
    'أسوان': ['أسوان', 'كوم أمبو', 'إدفو', 'أبو سمبل'],
    'البحر الأحمر': ['الغردقة', 'الجونة', 'سفاجا', 'القصير', 'مرسى علم'],
    'الوادي الجديد': ['الخارجة', 'الداخلة', 'الفرافرة', 'باريس'],
    'دمياط': ['دمياط', 'رأس البر', 'فارسكور', 'الزرقا'],
  };

  /// Approximate governorate center for reverse-geocode fallback ranking.
  static const Map<String, (double, double)> governorateCenters = {
    'القاهرة': (30.0444, 31.2357),
    'الجيزة': (30.0131, 31.2089),
    'الإسكندرية': (31.2001, 29.9187),
    'الدقهلية': (31.0409, 31.3785),
    'الشرقية': (30.5877, 31.5020),
    'القليوبية': (30.4660, 31.1849),
    'كفر الشيخ': (31.1107, 30.9388),
    'الغربية': (30.7865, 31.0004),
    'المنوفية': (30.5972, 30.9876),
    'البحيرة': (30.8481, 30.3436),
    'الإسماعيلية': (30.5965, 32.2715),
    'بورسعيد': (31.2653, 32.3019),
    'السويس': (29.9668, 32.5498),
    'شمال سيناء': (31.1313, 33.7984),
    'جنوب سيناء': (28.2360, 33.6220),
    'مطروح': (31.3525, 27.2373),
    'الفيوم': (29.3084, 30.8428),
    'بني سويف': (29.0661, 31.0994),
    'المنيا': (28.1099, 30.7503),
    'أسيوط': (27.1809, 31.1837),
    'سوهاج': (26.5560, 31.6948),
    'قنا': (26.1551, 32.7163),
    'الأقصر': (25.6872, 32.6396),
    'أسوان': (24.0889, 32.8998),
    'البحر الأحمر': (27.2579, 33.8116),
    'الوادي الجديد': (25.4510, 30.5460),
    'دمياط': (31.4165, 31.8133),
  };

  static String normalizeGovernorate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final t = raw.trim();
    return governorateAliases[t] ?? t;
  }

  static List<String> citiesFor(String? governorate) {
    final key = normalizeGovernorate(governorate);
    return List<String>.from(citiesByGovernorate[key] ?? const []);
  }

  static bool matchesCity(String haystack, String city) {
    return haystack.contains(city);
  }

  /// Best-effort match of admin area strings from geocoding to our list.
  static String? matchGovernorateFromPlacemark({
    String? administrativeArea,
    String? locality,
    String? subAdministrativeArea,
  }) {
    final hay = [
      administrativeArea,
      locality,
      subAdministrativeArea,
    ].whereType<String>().join(' ');

    for (final entry in governorateAliases.entries) {
      if (hay.contains(entry.key)) return entry.value;
    }
    for (final g in allGovernorates) {
      if (hay.contains(g) || hay.contains(g.replaceAll('ال', ''))) {
        return g;
      }
    }
    // English fallbacks common on web geocoding
    final lower = hay.toLowerCase();
    const en = {
      'cairo': 'القاهرة',
      'giza': 'الجيزة',
      'alexandria': 'الإسكندرية',
      'matruh': 'مطروح',
      'matrouh': 'مطروح',
      'red sea': 'البحر الأحمر',
      'hurghada': 'البحر الأحمر',
      'south sinai': 'جنوب سيناء',
      'sharm': 'جنوب سيناء',
      'dakahlia': 'الدقهلية',
      'sharqia': 'الشرقية',
      'qalyubia': 'القليوبية',
      'damietta': 'دمياط',
      'port said': 'بورسعيد',
      'suez': 'السويس',
      'ismailia': 'الإسماعيلية',
      'fayoum': 'الفيوم',
      'asyut': 'أسيوط',
      'assiut': 'أسيوط',
      'minya': 'المنيا',
      'sohag': 'سوهاج',
      'qena': 'قنا',
      'luxor': 'الأقصر',
      'aswan': 'أسوان',
      'beheira': 'البحيرة',
      'gharbia': 'الغربية',
      'monufia': 'المنوفية',
      'kafr el sheikh': 'كفر الشيخ',
      'beni suef': 'بني سويف',
      'new valley': 'الوادي الجديد',
      'north sinai': 'شمال سيناء',
    };
    for (final e in en.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return null;
  }

  static String? matchCityFromHaystack(String hay, String? governorate) {
    final cities = citiesFor(governorate);
    for (final c in cities) {
      if (hay.contains(c)) return c;
    }
    return null;
  }
}
