/// Resolves a working property image path from raw data and listing type.
class PropertyImageResolver {
  static const String defaultImage = 'assets/images/properties/default.jpg';

  static const String apartment = 'assets/images/properties/apartment.jpg';
  static const String villa = 'assets/images/properties/villa.jpg';
  static const String studio = 'assets/images/properties/studio.jpg';
  static const String sharedBed = 'assets/images/properties/shared_bed.jpg';
  static const String sale = 'assets/images/properties/sale.jpg';
  static const String chalet = 'assets/images/properties/chalet.jpg';
  static const String duplex = 'assets/images/properties/duplex.jpg';
  static const String office = 'assets/images/properties/office.jpg';
  static const String hotel = 'assets/images/properties/hotel.jpg';

  static const Set<String> _brokenAssets = {
    'assets/images/car_coupe1.jpg',
    'assets/images/car_coupe2.jpg',
    'assets/images/car_hatchback1.jpg',
    'assets/images/car_hatchback2.jpg',
    'assets/images/car_sedan1.jpg',
    'assets/images/car_sedan2.jpg',
    'assets/images/car_sedan3.jpg',
    'assets/images/car_suv1.jpg',
    'assets/images/car_suv2.jpg',
    'assets/images/car_suv3.jpg',
  };

  /// Returns a non-empty, validated image path for [property].
  static String resolve(Map<String, dynamic>? property) {
    final raw = _extractRaw(property);
    if (_isUsable(raw)) return raw;
    return _byType(property);
  }

  /// Validates [path] or falls back using optional [property] context.
  static String resolvePath(String? path, {Map<String, dynamic>? property}) {
    final trimmed = path?.trim() ?? '';
    if (_isUsable(trimmed)) return trimmed;
    return property != null ? _byType(property) : defaultImage;
  }

  static String _extractRaw(Map<String, dynamic>? property) {
    if (property == null) return '';
    final images = property['images'];
    if (images is List && images.isNotEmpty) {
      return images.first.toString().trim();
    }
    return property['image']?.toString().trim() ?? '';
  }

  static bool _isUsable(String path) {
    if (path.isEmpty || path == 'null') return false;
    if (_brokenAssets.contains(path)) return false;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.tryParse(path)?.host.isNotEmpty == true;
    }
    return path.startsWith('assets/');
  }

  static String _byType(Map<String, dynamic>? property) {
    if (property == null) return defaultImage;

    final listingMode = property['listingMode']?.toString() ?? 'rent';
    if (listingMode == 'for_sale') return sale;

    final accommodation = property['accommodationType']?.toString() ?? '';
    if (accommodation == 'bed') return sharedBed;

    final type = property['type']?.toString() ?? '';
    if (type.contains('سكن مشترك') || type.contains('مشترك')) {
      return sharedBed;
    }
    if (type.contains('فل') || type.contains('قصر') || type.contains('منزل')) {
      return villa;
    }
    if (type.contains('استوديو') || type.contains('طلاب')) return studio;
    if (type.contains('دوبلكس')) return duplex;
    if (type.contains('شاليه') || type.contains('شاطئ')) return chalet;
    if (type.contains('فند') || type.contains('جناح')) return hotel;
    if (type.contains('مكت') || type.contains('محل') || type.contains('تجاري')) {
      return office;
    }
    if (type.contains('شق')) return apartment;

    return defaultImage;
  }
}
