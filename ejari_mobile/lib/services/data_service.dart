import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import '../utils/date_utils.dart';
import '../utils/rental_rules.dart';
import 'mock_data_seeder.dart';

class DataService {
  static const String _bookingsKey = 'bookings'; // For tenants
  static const String _requestsKey = 'requests'; // For owners (incoming)
  static const String _favoritesKey = 'favorites';
  static const String _propertiesKey = 'properties';
  static const String _providerRequestsKey = 'provider_requests';
  static const String _manualPaymentsKey = 'manual_payments';
  static const String _appFeedbackKey = 'app_feedback';
  static const String _currentUserKey = 'current_user_email';

  static Future<void> saveAppFeedback(Map<String, dynamic> feedback) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_appFeedbackKey) ?? [];
    feedback['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    feedback['createdAt'] = DateTime.now().toIso8601String();
    list.add(jsonEncode(feedback));
    await prefs.setStringList(_appFeedbackKey, list);

    // Notify admin
    await addNotificationToUser('admin@ejari.app', 'تقييم جديد للتطبيق ⭐',
        'قام أحد المستخدمين بتقييم التطبيق بـ ${feedback['rating']} نجوم.');
  }

  static Future<String?> _getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  // High quality default image for fallbacks
  static const String defaultPropertyImage = 'assets/images/home1.jpg';
  static const String defaultCarImage = 'assets/images/car.jpg';

  static String getSafeImagePath(String? path, {String? type}) {
    if (path == null || path.isEmpty) {
      return type == 'car' ? defaultCarImage : defaultPropertyImage;
    }

    // List of known broken/empty placeholders from our research
    final brokenAssets = [
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
    ];

    if (brokenAssets.contains(path)) {
      return type == 'car' ? defaultCarImage : defaultPropertyImage;
    }
    return path;
  }

  // --- Properties (Dynamic) ---

  static const String _propsVersionKey = 'properties_version';
  static const int _currentPropsVersion =
      7; // bumped — merge Egyptian governorate demo catalog

  static Future<void> initProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_propsVersionKey) ?? 0;
    // Force reload if version is old
    if (savedVersion >= _currentPropsVersion) return;
    await prefs.setInt(_propsVersionKey, _currentPropsVersion);

    // =====================================================================
    // Default property dataset — mirrors backend seeder (keyo/Egypt)
    // Categories: شقق | فلل | استوديو طلاب | مكاتب | شاليهات | فندقي | للبيع
    // =====================================================================
    final List<Map<String, dynamic>> defaults = [
      // ===== 🏢 شقق إيجاري =====
      {
        'id': 'b1',
        'title': 'شقة فاخرة منطقة الفلل — إطلالة نيلية',
        'price': '9,000',
        'location': 'منطقة الفلل، إيجاري',
        'image': 'assets/images/home1.jpg',
        'beds': '3',
        'baths': '2',
        'area': '180',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': [
          'تكييف مركزى',
          'أمن 24/7',
          'أسانسير',
          'إطلالة نيلية',
          'حارس أمن'
        ],
        'furnished': true,
        'listingMode': 'rent',
        'isVerified': true,
        'isFeatured': true,
        'phone': '01280083336',
        'financialAccount': '01069813210',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'b2',
        'title': 'شقة تشطيب ألترا مودرن — فريد ندا',
        'price': '6,500',
        'location': 'شارع فريد ندا، إيجاري',
        'image': 'assets/images/home2.jpg',
        'beds': '2',
        'baths': '1',
        'area': '150',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['تشطيب سوبر لوكس', 'غاز طبيعي', 'أسانسير'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'b3',
        'title': 'شقة دور أرضي — المنشية',
        'price': '2,500',
        'location': 'المنشية، إيجاري',
        'image': 'assets/images/home7.jpg',
        'beds': '2',
        'baths': '1',
        'area': '110',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['عداد كهرباء قديم', 'غاز طبيعي'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'b4',
        'title': 'شقة لقطة 200م — بطا',
        'price': '3,000',
        'location': 'بطا، إيجاري',
        'image': 'assets/images/home1.jpg',
        'beds': '3',
        'baths': '2',
        'area': '200',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['إطلالة نيلية هادئة', 'هدوء تام'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'b5',
        'title': 'شقة ريفية مريحة — الرملة',
        'price': '1,200',
        'location': 'الرملة، إيجاري',
        'image': 'assets/images/home5.jpg',
        'beds': '2',
        'baths': '1',
        'area': '90',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['هدوء تام', 'قريب من المواصلات'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
        'bookedDates': [
          DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String()
              .substring(0, 10),
          DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String()
              .substring(0, 10),
        ],
      },
      {
        'id': 'b6',
        'title': 'شقة بنتهاوس — مجمع النخبة',
        'price': '18,000',
        'location': 'مجمع النخبة، إيجاري',
        'image': 'assets/images/home2.jpg',
        'beds': '4',
        'baths': '3',
        'area': '280',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': [
          'سطح خاص',
          'جاكوزي',
          'تكييف مركزي',
          'جراج مخصص',
          'أمن 24/7'
        ],
        'furnished': true,
        'listingMode': 'rent',
        'isVerified': true,
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'b7',
        'title': 'شقة كومباوند مسورة — إيجاري فيو',
        'price': '8,500',
        'location': 'إيجاري فيو كومباوند',
        'image': 'assets/images/home3.jpg',
        'beds': '3',
        'baths': '2',
        'area': '160',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['حمام سباحة', 'جيم', 'مولد كهرباء', 'أمن ذكي', 'حديقة'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 🏡 فلل وقصور =====
      {
        'id': 'c1',
        'title': 'فيلا مستقلة للبيع — منطقة الفلل',
        'price': '3,900,000',
        'location': 'الفلل، إيجاري',
        'image': 'assets/images/home3.jpg',
        'beds': '5',
        'baths': '4',
        'area': '300',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['حمام سباحة', 'حديقة', 'أمن', 'جلسة خارجية'],
        'furnished': false,
        'listingMode': 'for_sale',
        'saleCommission': '2',
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'c2',
        'title': 'فيلا تاون هاوس للإيجار — إيجاري جاردنز',
        'price': '22,000',
        'location': 'إيجاري جاردنز',
        'image': 'assets/images/home3.jpg',
        'beds': '4',
        'baths': '3',
        'area': '250',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['حديقة خاصة', 'منزل ذكي', 'جراجين', 'كاميرات'],
        'furnished': true,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'c3',
        'title': 'قصر للبيع — ضفة النيل',
        'price': '15,000,000',
        'location': 'ضفة النيل، إيجاري',
        'image': 'assets/images/home1.jpg',
        'beds': '7',
        'baths': '6',
        'area': '600',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['إطلالة نيلية', 'حمام سباحة مزدوج', 'ملعب تنس', 'مصعد'],
        'furnished': true,
        'listingMode': 'for_sale',
        'saleCommission': '2.5',
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'c4',
        'title': 'دوبلكس عائلي — حي الياسمين',
        'price': '14,000',
        'location': 'حي الياسمين، إيجاري',
        'image': 'assets/images/home3.jpg',
        'beds': '5',
        'baths': '3',
        'area': '300',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['حديقة أمامية', 'جراج', 'تشطيب مودرن', 'طابقين'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 🎓 إسكان طلاب =====
      {
        'id': 'd1',
        'title': 'استوديو طالبات — بجوار كلية الطب',
        'price': '3,500',
        'location': 'بجوار كلية طب، إيجاري',
        'image': 'assets/images/home1.jpg',
        'beds': '1',
        'baths': '1',
        'area': '65',
        'ownerId': 'admin',
        'type': 'استوديو',
        'amenities': [
          'إنترنت فائق',
          'أمن نسائي',
          'قريب من الجامعة',
          'مفروش كامل'
        ],
        'furnished': true,
        'listingMode': 'rent',
        'isVerified': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'd2',
        'title': 'غرفة مشتركة للطلاب — شارع الجامعة',
        'price': '1,800',
        'location': 'شارع الجامعة، إيجاري',
        'image': 'assets/images/home5.jpg',
        'beds': '1',
        'baths': '1',
        'area': '35',
        'ownerId': 'admin',
        'type': 'استوديو',
        'amenities': ['إنترنت', 'مطبخ مشترك', 'ماء وكهرباء شامل'],
        'furnished': true,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'd3',
        'title': 'شقة طلابية كاملة — المدينة الجامعية',
        'price': '4,500',
        'location': 'المدينة الجامعية، إيجاري',
        'image': 'assets/images/home4.jpg',
        'beds': '3',
        'baths': '1',
        'area': '120',
        'ownerId': 'admin',
        'type': 'استوديو',
        'amenities': ['غسالة', 'ثلاجة', 'إنترنت', 'قريبة جامعة'],
        'furnished': true,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 🏢 مكاتب ومحلات =====
      {
        'id': 'e1',
        'title': 'محل تجاري — إيجاري الجديدة',
        'price': '12,000',
        'location': 'إيجاري الجديدة، إيجاري',
        'image': 'assets/images/home4.jpg',
        'beds': '0',
        'baths': '1',
        'area': '80',
        'ownerId': 'admin',
        'type': 'مكاتب',
        'amenities': ['واجهة زجاجية', 'تكييف مركزي'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'e2',
        'title': 'مكتب إداري راقي — برج الأعمال',
        'price': '25,000',
        'location': 'برج الأعمال، إيجاري',
        'image': 'assets/images/home4.jpg',
        'beds': '0',
        'baths': '2',
        'area': '120',
        'ownerId': 'admin',
        'type': 'مكاتب',
        'amenities': ['قاعة اجتماعات', 'استقبال', 'جراج', 'إنترنت', 'أمن 24/7'],
        'furnished': true,
        'listingMode': 'rent',
        'isVerified': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'e3',
        'title': 'محل تجاري أرضي — الشارع الرئيسي',
        'price': '8,000',
        'location': 'الشارع الرئيسي، إيجاري',
        'image': 'assets/images/home4.jpg',
        'beds': '0',
        'baths': '1',
        'area': '45',
        'ownerId': 'admin',
        'type': 'مكاتب',
        'amenities': ['واجهة عريضة', 'مرور عالي', 'شارع رئيسي'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'e4',
        'title': 'وحدة إدارية — مجمع إيجاري بيزنس',
        'price': '18,000',
        'location': 'إيجاري بيزنس بارك',
        'image': 'assets/images/home4.jpg',
        'beds': '0',
        'baths': '2',
        'area': '200',
        'ownerId': 'admin',
        'type': 'مكاتب',
        'amenities': ['إنترنت مدمج', 'تكييف ذكي', 'صالة مؤتمرات', 'كافيتيريا'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 🏨 إقامة فندقية وشاليهات =====
      {
        'id': 'f1',
        'title': 'شاليه نيلي بالشاطئ الخاص — سيدي كرير',
        'price': '15,000',
        'location': 'سيدي كرير، إيجاري',
        'image': 'assets/images/home3.jpg',
        'beds': '4',
        'baths': '2',
        'area': '200',
        'ownerId': 'admin',
        'type': 'شاليهات',
        'amenities': ['شاطئ خاص', 'إطلالة نيلية', 'مطبخ كامل', 'واي فاي'],
        'furnished': true,
        'listingMode': 'rent',
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'f2',
        'title': 'جناح فندقي بالخدمات — فندق إيجاري بالاس',
        'price': '6,000',
        'location': 'فندق إيجاري بالاس',
        'image': 'assets/images/home2.jpg',
        'beds': '1',
        'baths': '1',
        'area': '55',
        'ownerId': 'admin',
        'type': 'فندقي',
        'amenities': [
          'خدمة غرف',
          'إفطار يومي',
          'حمام سباحة',
          'جيم',
          'تنظيف يومي'
        ],
        'furnished': true,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 🏘️ منازل مستقلة =====
      {
        'id': 'g1',
        'title': 'منزل كامل للإيجار — كفر الجزار',
        'price': '5,000',
        'location': 'كفر الجزار، إيجاري',
        'image': 'assets/images/home3.jpg',
        'beds': '4',
        'baths': '2',
        'area': '220',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['حديقة خاصة', 'قريب من المواصلات', 'مستقل'],
        'furnished': false,
        'listingMode': 'rent',
        'status': 'approved',
        'isDemo': true,
      },

      // ===== 💰 للبيع — تمليك =====
      {
        'id': 'h1',
        'title': 'شقة تمليك 160م — شارع الإشارة',
        'price': '2,200,000',
        'location': 'الإشارة، إيجاري',
        'image': 'assets/images/home2.jpg',
        'beds': '3',
        'baths': '2',
        'area': '160',
        'ownerId': 'owner@ejari.app',
        'type': 'شقق',
        'amenities': ['أسانسير', 'جراج', 'سوبر لوكس'],
        'furnished': false,
        'listingMode': 'for_sale',
        'governorate': 'القاهرة',
        'saleCommission': '1.5',
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'h2',
        'title': 'شقة تمليك 90م — حي الهنا',
        'price': '950,000',
        'location': 'حي الهنا، إيجاري',
        'image': 'assets/images/home5.jpg',
        'beds': '2',
        'baths': '1',
        'area': '90',
        'ownerId': 'admin',
        'type': 'شقق',
        'amenities': ['تسليم فوري', 'أسانسير'],
        'furnished': false,
        'listingMode': 'for_sale',
        'saleCommission': '1',
        'status': 'approved',
        'isDemo': true,
      },
      {
        'id': 'h3',
        'title': 'فيلا تمليك مودرن — هايد بارك',
        'price': '8,500,000',
        'location': 'هايد بارك، إيجاري',
        'image': 'assets/images/home3.jpg',
        'beds': '5',
        'baths': '4',
        'area': '380',
        'ownerId': 'admin',
        'type': 'فلل',
        'amenities': ['حمام سباحة', 'جراجين', 'حديقة منسقة', 'ضمان 10 سنوات'],
        'furnished': false,
        'listingMode': 'for_sale',
        'saleCommission': '2',
        'isFeatured': true,
        'status': 'approved',
        'isDemo': true,
      },
    ];

    final merged = _mergePropertyCatalog(
      defaults,
      MockDataSeeder.getEgyptianProperties(),
    );
    await prefs.setStringList(
        _propertiesKey, merged.map((e) => jsonEncode(e)).toList());
  }

  static List<Map<String, dynamic>> _mergePropertyCatalog(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> supplemental,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final property in [...primary, ...supplemental]) {
      final id = property['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = {...byId[id] ?? {}, ...property};
    }
    return byId.values.toList();
  }

  static Map<String, dynamic> _normalizeProperty(Map<String, dynamic> p) {
    final features = p['features'] as Map<String, dynamic>? ?? {};
    final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
    final locationData = p['location'];
    String locationStr = '';
    if (locationData is Map) {
      locationStr = locationData['address']?.toString() ?? '';
    } else {
      locationStr = locationData?.toString() ?? '';
    }

    final imagesList = p['images'] as List<dynamic>?;
    String imageStr = 'assets/images/home1.jpg';
    if (imagesList != null && imagesList.isNotEmpty) {
      imageStr = imagesList[0].toString();
    } else if (p['image'] != null) {
      imageStr = p['image'].toString();
    }

    return {
      ...p,
      'id': id,
      'title': p['title'] ?? '',
      'price': (p['price'] ?? '0').toString(),
      'location': locationStr,
      'image': imageStr,
      'beds': (features['bedrooms'] ?? p['beds'] ?? 0).toString(),
      'baths': (features['bathrooms'] ?? p['baths'] ?? 0).toString(),
      'area': (features['area'] ?? p['area'] ?? 0).toString(),
      'type': p['type'] ?? 'apartment',
      'status': p['status'] ?? 'available',
      'amenities': p['amenities'] ?? [],
      'furnished': features['furnished'] ?? p['furnished'] ?? false,
      'listingMode': p['listingMode'] ?? 'rent',
      'isDemo': p['isDemo'] ?? false,
      'isVerified': p['isVerified'] ?? false,
      'isFeatured': p['isFeatured'] ?? false,
      'phone': p['phone']?.toString() ?? '',
      'financialAccount': p['financialAccount']?.toString() ?? '',
      'governorate': p['governorate'] ?? '',
      'ownerId': p['ownerId']?.toString() ?? p['ownerEmail']?.toString() ?? '',
      'supportedDurations': p['supportedDurations'] ?? [],
      'corporateEligible': p['corporateEligible'] ?? false,
      'lat': p['lat'],
      'lng': p['lng'],
    };
  }

  static Future<List<Map<String, dynamic>>> getAllProperties(
      {bool approvedOnly = true}) async {
    // 1. Try to fetch from backend API
    try {
      final response = await ApiClient.get('/properties');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final List<dynamic> rawList = decoded['data'] ?? [];
          final List<Map<String, dynamic>> properties = rawList
              .map((p) => _normalizeProperty(p as Map<String, dynamic>))
              .toList();

          // Sync into SharedPreferences cache for offline usage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
            _propertiesKey,
            properties.map((e) => jsonEncode(e)).toList(),
          );

          if (approvedOnly) {
            return properties
                .where((p) =>
                    p['status'] == 'approved' ||
                    p['status'] == 'متاح' ||
                    p['isDemo'] == true)
                .toList();
          }
          return properties;
        }
      }
    } catch (e) {
      debugPrint(
          'GetAllProperties API Error: $e. Falling back to local cache.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    await initProperties(); // Ensure defaults exist
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];
    var list = props
        .map((item) =>
            _normalizeProperty(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    list = _mergePropertyCatalog(list, MockDataSeeder.getEgyptianProperties())
        .reversed
        .toList();

    if (approvedOnly) {
      return list
          .where((p) =>
              p['status'] == 'approved' ||
              p['status'] == 'متاح' ||
              p['isDemo'] == true)
          .toList();
    }
    return list;
  }

  static Future<List<Map<String, dynamic>>> getPendingProperties() async {
    final list = await getAllProperties(approvedOnly: false);
    return list.where((p) => p['status'] == 'pending').toList();
  }

  static Future<void> addProperty(Map<String, dynamic> property) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];

    property['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    property['status'] = 'pending'; // All new properties must be reviewed
    property['createdAt'] = DateTime.now().toIso8601String();
    props.add(jsonEncode(property));

    await prefs.setStringList(_propertiesKey, props);

    // Notify admin? (In this local demo, we just add it)
    await addNotificationToUser('admin@ejari.app', 'طلب إضافة عقار جديد',
        'لديك طلب جديد لإضافة عقار (${property['title']}) ينتظر المراجعة.');
  }

  static Future<void> updatePropertyStatus(String id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];

    String? ownerEmail;
    String? title;

    List<String> updated = props.map((p) {
      Map<String, dynamic> data = jsonDecode(p);
      if (data['id'].toString() == id) {
        data['status'] = status;
        ownerEmail = data['ownerId'];
        title = data['title'];
      }
      return jsonEncode(data);
    }).toList();

    await prefs.setStringList(_propertiesKey, updated);

    if (ownerEmail != null && title != null) {
      if (status == 'approved') {
        await addNotificationToUser(ownerEmail!, 'تمت الموافقة على عقارك! 🎉',
            'تمت مراجعة عقار ($title) بنجاح وهو الآن متاح للجميع على التطبيق.');
      } else if (status == 'rejected') {
        await addNotificationToUser(ownerEmail!, 'تم رفض طلب إضافة العقار ❌',
            'عذراً، لم نتمكن من الموافقة على عقار ($title) لمخالفته لبعض شروط النشر.');
      }
    }
  }

  static Future<void> addNotificationToUser(
      String email, String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    final note = {
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'read': false,
      'userEmail': email,
    };
    list.add(jsonEncode(note));
    await prefs.setStringList(_notificationsKey, list);
  }

  static Future<void> deleteProperty(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];
    props.removeWhere((p) => jsonDecode(p)['id'].toString() == id);
    await prefs.setStringList(_propertiesKey, props);
  }

  static Future<void> toggleVerifyProperty(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];
    List<String> updated = props.map((p) {
      Map<String, dynamic> data = jsonDecode(p);
      if (data['id'].toString() == id) {
        bool current = data['isVerified'] ?? false;
        data['isVerified'] = !current;
      }
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_propertiesKey, updated);
  }

  static Future<void> toggleFeatureProperty(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];
    List<String> updated = props.map((p) {
      Map<String, dynamic> data = jsonDecode(p);
      if (data['id'].toString() == id) {
        bool current = data['isFeatured'] ?? false;
        data['isFeatured'] = !current;
      }
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_propertiesKey, updated);
  }

  static Future<List<Map<String, dynamic>>> getOwnerProperties(
      String ownerId) async {
    List<Map<String, dynamic>> all = await getAllProperties(approvedOnly: false);
    return all
        .where((p) =>
            p['ownerId']?.toString() == ownerId ||
            p['ownerEmail']?.toString() == ownerId)
        .toList();
  }

  static Future<bool> isPropertyAvailable(
      String propertyId, DateTime start, DateTime end) async {
    final allProps = await getAllProperties(approvedOnly: false);
    final prop = allProps.firstWhere((p) => p['id'].toString() == propertyId,
        orElse: () => {});
    if (prop.isEmpty) return false;

    final bookedDates = List<String>.from(prop['bookedDates'] ?? []);

    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final dateStr =
          start.add(Duration(days: i)).toIso8601String().substring(0, 10);
      if (bookedDates.contains(dateStr)) return false;
    }
    return true;
  }

  // --- Bookings & Requests Flow ---

  static const String _notificationsKey = 'notifications';

  // --- Notifications ---

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();

    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    if (list.isEmpty) {
      return [
        {
          'title': 'مرحباً بك في إيجاري! 👋',
          'body': 'استكشف مئات العقارات المتاحة الآن.',
          'date': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'read': false,
        }
      ];
    }

    final allNotes =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    // Filter by user if email is present in note (or show all if not set for backward compat)
    return allNotes
        .where((n) => n['userEmail'] == null || n['userEmail'] == currentEmail)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> addNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();

    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    final note = {
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'read': false,
      'userEmail': currentEmail, // Targeted notification
    };
    list.add(jsonEncode(note));
    await prefs.setStringList(_notificationsKey, list);
  }

  static Future<void> markNotificationAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    if (index >= 0 && index < list.length) {
      // Note: index in _notifications list is reversed from storage list
      int actualIndex = list.length - 1 - index;
      Map<String, dynamic> note = jsonDecode(list[actualIndex]);
      note['read'] = true;
      list[actualIndex] = jsonEncode(note);
      await prefs.setStringList(_notificationsKey, list);
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    List<String> updated = list.map((e) {
      Map<String, dynamic> note = jsonDecode(e);
      note['read'] = true;
      return jsonEncode(note);
    }).toList();
    await prefs.setStringList(_notificationsKey, updated);
  }

  // --- Bookings & Requests Flow ---

  static Map<String, dynamic> _normalizeBooking(Map<String, dynamic> b) {
    final prop = b['property'] as Map<String, dynamic>? ?? {};
    final user = b['user'] as Map<String, dynamic>? ?? {};

    // Map Arabic status from backend database to Flutter UI status
    String status = b['status']?.toString() ?? 'pending';
    if (status == 'معلق') {
      status = 'pending';
    } else if (status == 'موعد معاينة') {
      status = 'viewing_scheduled';
    } else if (status == 'مؤكد') {
      status = 'approved';
    } else if (status == 'مدفوع') {
      status = 'paid';
    } else if (status == 'عربون') {
      status = 'deposit_paid';
    } else if (status == 'مكتمل') {
      status = 'completed';
    } else if (status == 'مسترد') {
      status = 'deposit_refunded';
    } else if (status == 'ملغي') {
      status = 'rejected';
    }

    String title = prop['title'] ?? b['propertyTitle'] ?? 'طلب حجز وحدة';
    String price =
        (b['totalPrice'] ?? b['price'] ?? prop['price'] ?? '0').toString();
    final leaseMonths =
        (b['leaseMonths'] ?? b['duration'] ?? 1).toString();

    final imagesList = prop['images'] as List<dynamic>?;
    String imageStr = 'assets/images/home1.jpg';
    if (imagesList != null && imagesList.isNotEmpty) {
      imageStr = imagesList[0].toString();
    } else if (b['image'] != null) {
      imageStr = b['image'].toString();
    }

    return {
      ...b,
      'id': b['_id']?.toString() ?? b['id']?.toString() ?? '',
      'propertyId': prop['_id']?.toString() ??
          b['propertyId']?.toString() ??
          b['property']?.toString() ??
          '',
      'title': title,
      'price': price,
      'image': imageStr,
      'duration': b['duration'] ?? b['leaseDuration'] ?? '',
      'durationUnit': b['durationUnit'] ?? '',
      'durationCount': b['durationCount'] ?? '',
      'durationLabel': b['durationLabel'] ?? b['duration'] ?? '',
      'startDate': b['startDate'] ?? b['date'] ?? '',
      'endDate': b['endDate'] ?? '',
      'leaseStartDate': b['leaseStartDate'] ?? b['startDate'] ?? '',
      'leaseEndDate': b['leaseEndDate'] ?? b['endDate'] ?? '',
      'leaseMonths': leaseMonths,
      'remainingMonths': b['remainingMonths'] ?? '',
      'paidMonths': b['paidMonths'] ?? '',
      'nextDueDate': b['nextDueDate'] ?? '',
      'nextDueAmount': b['nextDueAmount'] ?? '',
      'paymentSchedule': b['paymentSchedule'] ?? '',
      'requestDate': b['createdAt'] ?? b['requestDate'] ?? '',
      'status': status,
      'tenantEmail': user['email'] ?? b['tenantEmail'] ?? '',
      'tenantName': user['name'] ?? b['tenantName'] ?? '',
      'contractNumber': b['contractNumber'] ?? '',
    };
  }

  static const String _corporateStateKey = 'corporate_booking_state';

  static Future<List<Map<String, dynamic>>> getCorporateEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_corporateStateKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCorporateEmployees(
      List<Map<String, dynamic>> employees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_corporateStateKey, jsonEncode(employees));
  }

  /// إلغاء حجز مع تطبيق قاعدة الاسترداد (٤٨ ساعة).
  static Future<Map<String, dynamic>> cancelBookingWithRefund({
    required String bookingId,
    required DateTime checkInDate,
    required double depositAmount,
    DateTime? cancelDate,
  }) async {
    final effectiveCancel = cancelDate ?? DateTime.now();
    final refundable = RentalRules.isRefundable(
      checkInDate: checkInDate,
      cancelDate: effectiveCancel,
    );
    final refundAmount = refundable ? depositAmount : 0.0;

    if (refundable) {
      await refundBookingDeposit(bookingId);
    } else {
      await updateRequestStatus(bookingId, 'rejected');
      await addNotification(
        'إلغاء بدون استرداد ❌',
        'تم إلغاء الحجز وفق السياسة: لا استرداد خلال ٤٨ ساعة من الاستلام.',
      );
    }

    return {
      'refundable': refundable,
      'refundAmount': refundAmount,
      'daysBeforeCheckIn': checkInDate.difference(effectiveCancel).inDays,
      'status': refundable ? 'deposit_refunded' : 'rejected',
    };
  }

  // Tenant sends a request
  static Future<void> sendBookingRequest(Map<String, dynamic> request) async {
    // 1. Try backend API
    try {
      final body = {
        'property': request['propertyId'] ?? request['id'] ?? '',
        'startDate': request['startDate'] ?? DateTime.now().toIso8601String(),
        'endDate': request['endDate'] ??
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'price': request['price'],
        'monthlyRent': request['monthlyRent'],
        'leaseTotal': request['leaseTotal'],
        'currentAmount': request['currentAmount'],
        'depositAmount': request['depositAmount'],
        'remainingAmount': request['remainingAmount'],
        'leaseMonths': request['leaseMonths'],
        'leaseStartDate': request['leaseStartDate'],
        'leaseEndDate': request['leaseEndDate'],
        'nextDueDate': request['nextDueDate'],
        'nextDueAmount': request['nextDueAmount'],
        'paidMonths': request['paidMonths'],
        'remainingMonths': request['remainingMonths'],
        'durationUnit': request['durationUnit'],
        'durationCount': request['durationCount'],
        'durationLabel': request['durationLabel'],
        'paymentSchedule': request['paymentSchedule'],
        'duration': request['duration'],
        'status': request['status'],
        'paymentStatus': request['paymentStatus'],
        'paymentPhase': request['paymentPhase'],
      };

      final response = await ApiClient.post('/bookings', body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final serverBooking = decoded['data'] as Map<String, dynamic>;
          final normalized = _normalizeBooking(serverBooking);

          final prefs = await SharedPreferences.getInstance();
          final List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
          bookings.add(jsonEncode(normalized));
          await prefs.setStringList(_bookingsKey, bookings);
          return;
        }
      }
    } catch (e) {
      debugPrint(
          'SendBookingRequest API Error: $e. Falling back to local storage.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();

    request['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    request['status'] = request['status'] ?? 'pending';
    request['requestDate'] = DateTime.now().toIso8601String();
    request['tenantEmail'] = currentEmail; // Record who made the request
    request['leaseMonths'] = request['leaseMonths'] ?? request['duration'];
    request['leaseStartDate'] =
        request['leaseStartDate'] ?? request['startDate'];
    request['leaseEndDate'] = request['leaseEndDate'] ?? request['endDate'];
    request['paidMonths'] = request['paidMonths'] ?? 0;
    request['remainingMonths'] = request['remainingMonths'];
    request['durationLabel'] = request['durationLabel'] ?? request['duration'];

    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    bookings.add(jsonEncode(request));
    await prefs.setStringList(_bookingsKey, bookings);

    List<String> requests = prefs.getStringList(_requestsKey) ?? [];
    requests.add(jsonEncode(request));
    await prefs.setStringList(_requestsKey, requests);
  }

  // Owner gets their requests
  static Future<List<Map<String, dynamic>>> getOwnerRequests(
      String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> requests = prefs.getStringList(_requestsKey) ?? [];
    List<Map<String, dynamic>> allRequests = requests
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    // Filter requests for this owner
    return allRequests
        .where((r) =>
            r['ownerId']?.toString() == ownerId ||
            r['ownerEmail']?.toString() == ownerId)
        .toList()
        .reversed
        .toList();
  }

  // Owner updates status (Accept/Reject)
  static Future<void> updateRequestStatus(
      String requestId, String newStatus) async {
    // 1. Try backend API update
    String backendStatus = newStatus;
    if (newStatus == 'viewing_scheduled') {
      backendStatus = 'موعد معاينة';
    } else if (newStatus == 'deposit_paid') {
      backendStatus = 'عربون';
    } else if (newStatus == 'completed') {
      backendStatus = 'مكتمل';
    } else if (newStatus == 'deposit_refunded') {
      backendStatus = 'مسترد';
    }
    if (newStatus == 'paid') {
      backendStatus = 'مدفوع';
    } else if (newStatus == 'approved') {
      backendStatus = 'مؤكد';
    } else if (newStatus == 'rejected') {
      backendStatus = 'ملغي';
    }

    try {
      final response = await ApiClient.put('/bookings/$requestId/status', {
        'status': backendStatus,
      });
      if (response.statusCode == 200) {
        debugPrint('Booking status updated on backend successfully.');
      }
    } catch (e) {
      debugPrint('UpdateRequestStatus API Error: $e. Syncing locally.');
    }

    // 2. Local fallback sync
    final prefs = await SharedPreferences.getInstance();

    // Helper to update status in a list
    List<String> updateList(List<String> list) {
      return list.map((item) {
        Map<String, dynamic> data = jsonDecode(item);
        if (data['id'] == requestId || data['_id'] == requestId) {
          data['status'] = newStatus;
          if (newStatus == 'rejected') {
            data['rejectedAt'] = DateTime.now().toIso8601String();
          } else if (newStatus == 'approved') {
            data['approvedAt'] = DateTime.now().toIso8601String();
          } else if (newStatus == 'viewing_scheduled') {
            data['viewingScheduledAt'] = DateTime.now().toIso8601String();
          } else if (newStatus == 'deposit_paid') {
            data['depositPaidAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'deposit_paid';
            data['paymentPhase'] = 'deposit';
          } else if (newStatus == 'completed') {
            data['completedAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'paid';
            data['paymentPhase'] = 'completed';
          } else if (newStatus == 'deposit_refunded') {
            data['refundedAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'refunded';
            data['paymentPhase'] = 'refunded';
          }
        }
        return jsonEncode(data);
      }).toList();
    }

    List<String> requests = prefs.getStringList(_requestsKey) ?? [];
    await prefs.setStringList(_requestsKey, updateList(requests));

    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    await prefs.setStringList(_bookingsKey, updateList(bookings));

    // Add Notification based on status
    if (newStatus == 'approved') {
      await addNotification('تمت الموافقة على طلبك! 🎉',
          'وافق المالك على طلب حجز الوحدة. يمكنك الآن إتمام الدفع.');
    } else if (newStatus == 'rejected') {
      await addNotification(
          'تم رفض الطلب ❌', 'عذراً، تم رفض طلب حجز الوحدة من قبل المالك.');
    } else if (newStatus == 'deposit_paid') {
      await addNotification('تم حجز عربون المعاينة ✅',
          'تم استلام العربون، ويمكنك متابعة تفاصيل الزيارة ثم إكمال الصفقة عند الموافقة.');
    } else if (newStatus == 'viewing_scheduled') {
      await addNotification('تم تحديد موعد المعاينة',
          'تم تسجيل طلبك ويمكنك متابعة تفاصيل الزيارة من حجوزاتي.');
    } else if (newStatus == 'paid') {
      await addNotification('تم الدفع بنجاح! ✅',
          'تم استلام المبلغ وتوثيق العقد الإلكتروني. مبروك وحدتك الجديدة!');
    } else if (newStatus == 'completed') {
      await addNotification('تم استكمال الصفقة 🎉',
          'تم سداد باقي المبلغ وتحديث حالة الحجز بنجاح.');
    } else if (newStatus == 'deposit_refunded') {
      await addNotification(
          'تم استرداد العربون', 'تم تنفيذ الاسترداد وفق حالة الحجز الحالية.');
    }
  }

  // Owner gets their bookings
  static Future<List<Map<String, dynamic>>> getOwnerBookings(
      String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    List<Map<String, dynamic>> allBookings = bookings
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    // In a real app, you would filter by property ownerId.
    // Assuming bookings have property info including ownerId, or we join with properties.
    // For demo simplicity, we return all bookings if ownerId matches a specific demo owner,
    // or return a filtered list based on the demo properties we know belong to 'admin'/'owner123'.
    if (ownerId == 'owner123') {
      // Return some demo bookings if none exist
      if (allBookings.isEmpty) {
        return [
          {
            'id': 'b1',
            'propertyTitle': 'شقة فاخرة بالمعادي',
            'tenantName': 'أحمد محمد',
            'date': DateTime.now().toIso8601String(),
            'amount': '12,000 ج.م',
            'status': 'active',
            'revenue': 12000.0,
          },
          {
            'id': 'b2',
            'propertyTitle': 'فيلا بالتجمع الخامس',
            'tenantName': 'سارة علي',
            'date': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'amount': '25,000 ج.م',
            'status': 'active',
            'revenue': 25000.0,
          },
          {
            'id': 'b3',
            'propertyTitle': 'استوديو نصر',
            'tenantName': 'محمود حسن',
            'date': DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            'amount': '8,000 ج.م',
            'status': 'completed',
            'revenue': 8000.0,
          },
        ];
      }
    }
    return allBookings.reversed.toList();
  }

  // Calculate Owner Revenue
  static Future<double> getOwnerRevenue(String ownerId) async {
    List<Map<String, dynamic>> bookings = await getOwnerBookings(ownerId);
    double total = 0.0;
    for (var booking in bookings) {
      // Parse revenue securely
      var rev = booking['revenue'];
      if (rev is num) {
        total += rev;
      } else if (rev is String) {
        // Try to parse "12,000 ج.م"
        String clean = rev.replaceAll(RegExp(r'[^0-9.]'), '');
        total += double.tryParse(clean) ?? 0.0;
      }
    }
    return total;
  }

  // Get Wallet Data
  static Future<Map<String, dynamic>> getWalletData(String ownerId) async {
    final revenue = await getOwnerRevenue(ownerId);
    return {
      'totalBalance': revenue,
      'available': revenue * 0.8, // 80% available
      'escrow': revenue * 0.2, // 20% in escrow
      'currency': 'ج.م',
    };
  }

  // Get Wallet Transactions
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
      String ownerId) async {
    final bookings = await getOwnerBookings(ownerId);
    List<Map<String, dynamic>> transactions = [];

    for (var b in bookings) {
      // Extract numeric revenue for formatting
      double rev = 0.0;
      if (b['revenue'] is num) {
        rev = (b['revenue'] as num).toDouble();
      } else if (b['amount'] is String) {
        String clean =
            (b['amount'] as String).replaceAll(RegExp(r'[^0-9.]'), '');
        rev = double.tryParse(clean) ?? 0.0;
      }

      transactions.add({
        'title': 'إيداع إيجار',
        'reason': 'حجز ${b['propertyTitle'] ?? 'عقار'}',
        'amount': '+${rev.toStringAsFixed(0)}',
        'date': DateParsing.parse(b['date']) ?? DateTime.now(),
        'type': 'deposit',
        'status': 'completed',
      });
    }

    // Add a dummy withdrawal for realism if there are earnings
    if (transactions.isNotEmpty) {
      transactions.add({
        'title': 'سحب أرباح',
        'reason': 'تحويل بنكي - البنك الأهلي',
        'amount': '-1,000',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'type': 'withdraw',
        'status': 'completed',
      });
    }

    // Sort descending by date
    transactions.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return transactions;
  }

  // Get Revenue Chart Data
  static Future<List<double>> getRevenueChartData(String ownerId) async {
    // Generate realistic fluctuating data based on total revenue
    final revenue = await getOwnerRevenue(ownerId);
    if (revenue == 0) return [0, 0, 0, 0, 0, 0];

    return [
      revenue * 0.3,
      revenue * 0.5,
      revenue * 0.4,
      revenue * 0.7,
      revenue * 0.9,
      revenue, // Current month
    ];
  }

  // Tenant pays for booking
  static Future<void> payForBooking(String bookingId) async {
    await updateRequestStatus(bookingId, 'deposit_paid');
  }

  static Future<void> completeBookingPayment(String bookingId) async {
    await updateRequestStatus(bookingId, 'completed');
  }

  static Future<void> refundBookingDeposit(String bookingId) async {
    await updateRequestStatus(bookingId, 'deposit_refunded');
  }

  // Tenant gets their bookings
  static Future<List<Map<String, dynamic>>> getBookings() async {
    // 1. Try backend API
    try {
      final response = await ApiClient.get('/bookings');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final List<dynamic> rawList = decoded['data'] ?? [];
          final List<Map<String, dynamic>> bookings = rawList
              .map((b) => _normalizeBooking(b as Map<String, dynamic>))
              .toList();

          // Sync into SharedPreferences cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
            _bookingsKey,
            bookings.map((e) => jsonEncode(e)).toList(),
          );

          return bookings.reversed.toList();
        }
      }
    } catch (e) {
      debugPrint('GetBookings API Error: $e. Falling back to local cache.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();

    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    final allBookings = bookings
        .map((item) =>
            _normalizeBooking(jsonDecode(item) as Map<String, dynamic>))
        .toList();

    return allBookings
        .where((b) => b['tenantEmail'] == currentEmail)
        .toList()
        .reversed
        .toList();
  }

  // --- Favorites ---

  static Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();
    if (currentEmail == null) return;

    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    // Default folder if not specified
    if (!item.containsKey('folder') || item['folder'] == null) {
      item['folder'] = 'عام';
    }

    // Check if exists based on title and user email
    int index = favorites.indexWhere((element) {
      Map<String, dynamic> decoded = jsonDecode(element);
      return decoded['title'] == item['title'] &&
          decoded['userEmail'] == currentEmail;
    });

    if (index != -1) {
      favorites.removeAt(index); // Remove if exists
    } else {
      item['userEmail'] = currentEmail;
      favorites.add(jsonEncode(item)); // Add if not exists
    }

    await prefs.setStringList(_favoritesKey, favorites);
  }

  static Future<bool> isFavorite(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();
    if (currentEmail == null) return false;

    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    return favorites.any((element) {
      Map<String, dynamic> decoded = jsonDecode(element);
      return decoded['title'] == title && decoded['userEmail'] == currentEmail;
    });
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();
    if (currentEmail == null) return [];

    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    return favorites
        .map((item) {
          var decoded = jsonDecode(item) as Map<String, dynamic>;
          if (!decoded.containsKey('folder') || decoded['folder'] == null) {
            decoded['folder'] = 'عام'; // Fallback for old favorites
          }
          return decoded;
        })
        .where((f) => f['userEmail'] == currentEmail)
        .toList()
        .reversed
        .toList();
  }

  // --- Folders Management ---
  static const String _foldersKey = 'favorite_folders';

  static Future<List<String>> getFavoriteFolders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> folders = prefs.getStringList(_foldersKey) ??
        ['عام', 'شقق للإيجار', 'فلل للعطلات'];
    return folders;
  }

  static Future<void> addFavoriteFolder(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> folders = await getFavoriteFolders();
    if (!folders.contains(folderName)) {
      folders.add(folderName);
      await prefs.setStringList(_foldersKey, folders);
    }
  }

  // --- Reviews & Ratings ---

  static String _getReviewsKey(String propertyId) => 'reviews_$propertyId';

  /// Load all reviews for a specific property
  static Future<List<Map<String, dynamic>>> getReviewsForProperty(
      String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getReviewsKey(propertyId);
    final raw = prefs.getString(key);

    if (raw != null) {
      try {
        final parsed = jsonDecode(raw) as List<dynamic>? ?? [];
        return parsed.cast<Map<String, dynamic>>();
      } catch (_) {
        return [];
      }
    }

    // First load: create demo reviews
    final demoReviews = _getDemoReviews();
    await prefs.setString(key, jsonEncode(demoReviews));
    return demoReviews;
  }

  /// Generate demo reviews for demo purposes
  static List<Map<String, dynamic>> _getDemoReviews() {
    return [
      {
        'userName': 'أحمد محمد',
        'rating': 5.0,
        'comment': 'عقار ممتاز والمالك متعاون جداً. أنصح بالتعامل معه.',
        'date':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'userName': 'سارة علي',
        'rating': 4.0,
        'comment': 'العقار جيد لكن يحتاج بعض الصيانة البسيطة.',
        'date':
            DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'userName': 'محمد حسن',
        'rating': 5.0,
        'comment': 'موقع ممتاز وقريب من كل الخدمات.',
        'date':
            DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
    ];
  }

  /// Add a new review for a property
  static Future<void> addReview(
      String propertyId, Map<String, dynamic> review) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getReviewsKey(propertyId);

    // Load existing reviews
    List<Map<String, dynamic>> reviews =
        await getReviewsForProperty(propertyId);

    // Add timestamp if not present
    review['date'] ??= DateTime.now().toIso8601String();

    // Insert at beginning (newest first)
    reviews.insert(0, review);

    // Save back to storage
    await prefs.setString(key, jsonEncode(reviews));
  }

  /// Get average rating for a property
  static Future<Map<String, dynamic>> getReviewStats(String propertyId) async {
    final reviews = await getReviewsForProperty(propertyId);

    if (reviews.isEmpty) {
      return {'average': 0.0, 'count': 0};
    }

    double sum = 0;
    for (var review in reviews) {
      sum += (review['rating'] ?? 0).toDouble();
    }

    double average = double.parse((sum / reviews.length).toStringAsFixed(1));

    return {'average': average, 'count': reviews.length};
  }

  /// Delete all reviews for a property (for testing/reset)
  static Future<void> clearReviewsForProperty(String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getReviewsKey(propertyId);
    await prefs.remove(key);
  }

  // --- Merchant Logic ---
  static const String _merchantRequestsKey = 'merchant_requests';

  static Future<void> submitMerchantRequest(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_merchantRequestsKey) ?? [];
    data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    list.add(jsonEncode(data));
    await prefs.setStringList(_merchantRequestsKey, list);
  }

  static Future<List<Map<String, dynamic>>> getMerchantRequests() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_merchantRequestsKey) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> approveMerchantRequest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_merchantRequestsKey) ?? [];
    List<Map<String, dynamic>> decoded =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final index = decoded.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      decoded[index]['status'] = 'approved';
      await prefs.setStringList(
          _merchantRequestsKey, decoded.map((e) => jsonEncode(e)).toList());
    }
  }

  static Future<void> rejectMerchantRequest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_merchantRequestsKey) ?? [];
    List<Map<String, dynamic>> decoded =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    final index = decoded.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      decoded[index]['status'] = 'rejected';
      await prefs.setStringList(
          _merchantRequestsKey, decoded.map((e) => jsonEncode(e)).toList());
    }
  }

  static Future<List<Map<String, dynamic>>> getAppFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_appFeedbackKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<Map<String, dynamic>> getAdminGlobalStats() async {
    final users = await SharedPreferences.getInstance()
        .then((p) => p.getStringList('users_list') ?? []);
    final properties = await getAllProperties(approvedOnly: false);
    final bookings = await SharedPreferences.getInstance()
        .then((p) => p.getStringList(_bookingsKey) ?? []);
    final feedback = await getAppFeedback();

    double totalRevenue = 0;
    for (var b in bookings) {
      final data = jsonDecode(b);
      if (data['status'] == 'paid' || data['status'] == 'approved') {
        String clean =
            data['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
        totalRevenue += double.tryParse(clean) ?? 0;
      }
    }

    return {
      'totalUsers': users.length,
      'totalProperties': properties.length,
      'activeBookings': bookings.length,
      'totalRevenue': totalRevenue,
      'pendingVerifications':
          properties.where((p) => p['status'] == 'pending').length,
      'newFeedbackCount': feedback.length,
      'offer100Progress':
          users.length / 100, // Progress towards the 100 client offer
    };
  }

  static Future<Map<String, List<double>>> getAdminChartData() async {
    final stats = await getAdminGlobalStats();
    final revenue = (stats['totalRevenue'] as num).toDouble();
    final users = stats['totalUsers'] as int;

    return {
      'userGrowth': [
        users * 0.2,
        users * 0.4,
        users * 0.5,
        users * 0.7,
        users * 0.9,
        users.toDouble(),
      ],
      'revenueGrowth': [
        revenue * 0.1,
        revenue * 0.3,
        revenue * 0.2,
        revenue * 0.6,
        revenue * 0.8,
        revenue,
      ],
    };
  }

  static Future<bool> activateMerchantAccount(
      String phone, String password) async {
    final requests = await getMerchantRequests();
    final req = requests.firstWhere(
        (r) => r['phone'] == phone && r['status'] == 'approved',
        orElse: () => {});

    if (req.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'email': phone, // Use phone as ID
      'password': password,
      'name': req['companyName'],
      'role': 'merchant',
      'phone': phone,
    };

    // Save user data
    // Note: This relies on AuthService internal keys. Ideally AuthService should expose a 'createUser' method.
    // But duplicating logic here for simplicity in this file-constraint environment.
    await prefs.setString('user_$phone', jsonEncode(userData));

    List<String> users = prefs.getStringList('users_list') ?? [];
    if (!users.contains(phone)) {
      users.add(phone);
      await prefs.setStringList('users_list', users);
    }

    return true;
  }

  // --- Provider / Technician Logic ---

  static Future<List<Map<String, dynamic>>> getProviderRequests(
      String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_providerRequestsKey) ?? [];

    if (list.isEmpty) {
      // Demo requests for the technician
      final demo = [
        {
          'id': 'PR001',
          'service': 'صيانة تكييف',
          'customer': 'محمود عبد القوي',
          'phone': '01012345678',
          'date': DateTime.now().toIso8601String(),
          'address': 'المعادي، شقة 12',
          'status': 'pending',
          'price': 250.0,
          'notes': 'التكييف لا يبرد بشكل جيد والشحنة تحتاج فحص',
          'customerPhone': '+201012345678',
          'lat': 29.9602,
          'lng': 31.2569,
        },
        {
          'id': 'PR002',
          'service': 'إصلاح كهرباء طوارئ',
          'customer': 'أستاذ ياسر غنيم',
          'phone': '01122334455',
          'date': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'address': 'التجمع الخامس، فيلا 5، شارع التسعين',
          'status': 'completed',
          'price': 150.0,
          'notes': 'عطل في لوحة الكهرباء الرئيسية أدى لانقطاع التيار',
          'customerPhone': '+201122334455',
          'lat': 30.0131,
          'lng': 31.4360,
        },
      ];
      await prefs.setStringList(
          _providerRequestsKey, demo.map((e) => jsonEncode(e)).toList());
      return demo;
    }

    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> updateProviderRequestStatus(
      String requestId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_providerRequestsKey) ?? [];
    List<Map<String, dynamic>> requests =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    int index = requests.indexWhere((r) => r['id'] == requestId);
    if (index != -1) {
      requests[index]['status'] = newStatus;
      if (newStatus == 'completed') {
        requests[index]['completedAt'] = DateTime.now().toIso8601String();
      }
      await prefs.setStringList(
          _providerRequestsKey, requests.map((e) => jsonEncode(e)).toList());

      // Notify customer if status changes
      if (newStatus == 'accepted') {
        await addNotification('تم قبول طلب الخدمة ✅',
            'وافق الفني على طلب الصيانة وهو في الطريق إليك.');
      } else if (newStatus == 'completed') {
        await addNotification(
            'اكتملت الخدمة ✨', 'تم إنهاء طلب الصيانة بنجاح. يرجى تقييم الفني.');
      }
    }
  }

  static Future<Map<String, dynamic>> getProviderStats(
      String providerId) async {
    final requests = await getProviderRequests(providerId);
    double totalEarnings = 0.0;
    int completedJobs = 0;

    for (var r in requests) {
      if (r['status'] == 'completed') {
        totalEarnings += (r['price'] as num).toDouble();
        completedJobs++;
      }
    }

    return {
      'earnings': totalEarnings,
      'completedCount': completedJobs,
      'rating': 4.8, // Demo rating
      'activeJobs': requests
          .where(
              (r) => r['status'] == 'accepted' || r['status'] == 'in_progress')
          .length,
    };
  }

  static Future<Map<String, dynamic>?> getActiveProviderJob(
      String providerId) async {
    final requests = await getProviderRequests(providerId);
    try {
      return requests.firstWhere(
          (r) => r['status'] == 'accepted' || r['status'] == 'in_progress');
    } catch (_) {
      // If no accepted job, show the latest pending one as a "Potential" job
      try {
        return requests.firstWhere((r) => r['status'] == 'pending');
      } catch (_) {
        return null;
      }
    }
  }

  // === Zero-Cost Payments (Manual Receipts) ===

  static Future<void> submitManualPayment(
      Map<String, dynamic> paymentData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_manualPaymentsKey) ?? [];

    final newPayment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending',
      ...paymentData,
    };

    list.add(jsonEncode(newPayment));
    await prefs.setStringList(_manualPaymentsKey, list);

    await addNotification('تم إرسال إيصال الدفع 💸',
        'جاري مراجعة التحويل للمبلغ ${paymentData['amount']} ج.م. سيتم التفعيل فور التأكد.');
  }

  static Future<List<Map<String, dynamic>>> getManualPayments() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_manualPaymentsKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  // === Ejari Intelligence (Market Trends) ===

  static Future<List<Map<String, dynamic>>> getMarketTrends(
      String location) async {
    // Simulated market trend data for Ejari users
    await Future.delayed(const Duration(milliseconds: 500));

    final bool isUp = location.contains('التجمع') || location.contains('زايد');

    return [
      {'month': 'Jan', 'value': isUp ? 20000 : 15000},
      {'month': 'Feb', 'value': isUp ? 21500 : 15200},
      {'month': 'Mar', 'value': isUp ? 23000 : 14800},
      {'month': 'Apr', 'value': isUp ? 24500 : 15500},
      {'month': 'May', 'value': isUp ? 26000 : 16000},
      {'month': 'Jun', 'value': isUp ? 28500 : 16500},
    ];
  }

  // === Property Verification ===

  static bool isPropertyVerified(String propertyId) {
    // Demo: Specific IDs are verified for 'Ejari' status
    final verifiedIds = ['1', '3', '5', '7', '10', '15', '20', '27'];
    return verifiedIds.contains(propertyId);
  }
}
