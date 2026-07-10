import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_receipt.dart';
import '../utils/api_client.dart';
import '../utils/date_utils.dart';
import '../utils/safe_parse.dart';
import '../utils/rental_rules.dart';
import '../utils/booking_validator.dart';
import '../models/booking_status.dart';
import 'activity_log_service.dart';
import 'auth_service.dart';
import 'mock_data_seeder.dart';
import 'wallet_service.dart';
import 'financial_service.dart';
import 'maintenance_service.dart';
import 'subscription_service.dart';

class DataService {
  static const String _bookingsKey = 'bookings'; // For tenants
  static const String _requestsKey = 'requests'; // For owners (incoming)
  static const String _demoBookingsVersionKey = 'demo_bookings_version';
  static const int _currentDemoBookingsVersion = 4;
  static const String _demoReceiptsVersionKey = 'demo_receipts_version';
  static const int _currentDemoReceiptsVersion = 1;
  static const String _favoritesKey = 'favorites';
  static const String _propertiesKey = 'properties';
  static const String _manualPaymentsKey = 'manual_payments';
  static const String _appFeedbackKey = 'app_feedback';
  static const String _currentUserKey = 'current_user_email';
  static const String _receiptsKey = 'payment_receipts_v2';
  static const String _adminEmail = 'admin@ejari.app';

  static Future<void> saveAppFeedback(Map<String, dynamic> feedback) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_appFeedbackKey) ?? [];
    feedback['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    feedback['createdAt'] = DateTime.now().toIso8601String();
    list.add(jsonEncode(feedback));
    await prefs.setStringList(_appFeedbackKey, list);

    // Notify admin
    await addNotificationToUser('admin@ejari.app', 'تقييم جديد للتطبيق ⭐',
        'قام أحد المستخدمين بتقييم التطبيق بـ ${feedback['rating']} نجوم.',
        adminFeed: true);
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

  /// Seed cross-role demo bookings so owner dashboard shows real pending requests.
  static Future<void> initDemoBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_demoBookingsVersionKey) ?? 0;
    final existingRequests = prefs.getStringList(_requestsKey) ?? [];
    if (savedVersion >= _currentDemoBookingsVersion &&
        existingRequests.isNotEmpty) {
      return;
    }
    await prefs.setInt(_demoBookingsVersionKey, _currentDemoBookingsVersion);

    final checkIn = DateTime.now().add(const Duration(days: 7));
    final demoRequests = [
      {
        'id': 'demo_req_1',
        'contractNumber': 'CTR-DEMO-001',
        'propertyId': 'egy1',
        'title': 'شقة فاخرة على النيل - المعادي',
        'image': 'assets/images/home1.jpg',
        'price': '15000',
        'monthlyRent': '15000',
        'tenantName': 'مستأجر تجريبي',
        'tenantEmail': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'ownerEmail': 'owner@ejari.app',
        'status': BookingStatus.submitted,
        'requestDate': DateTime.now().toIso8601String(),
        'statusHistory': [
          {
            'status': BookingStatus.submitted,
            'label': 'إرسال الطلب',
            'at': DateTime.now().toIso8601String(),
            'note': 'بانتظار موافقة المالك',
          },
        ],
        'leaseStartDate': checkIn.toIso8601String(),
        'checkInDate': checkIn.toIso8601String(),
        'startDate': checkIn.toIso8601String(),
        'durationLabel': '6 شهر',
        'duration': '6 شهر',
        'leaseMonths': 6,
        'depositAmount': '3000',
        'rentalTier': 'medium',
        'rentalTierLabel': '٦+ شهور',
        'tenantType': 'family',
        'tenantTypeLabel': 'أسرة',
        'requiresIncomeProof': true,
        'showInstallments': true,
      },
      {
        'id': 'demo_req_2',
        'contractNumber': 'CTR-DEMO-002',
        'propertyId': 'egy2',
        'title': 'فيلا مستقلة التجمع الخامس',
        'image': 'assets/images/home2.jpg',
        'price': '45000',
        'monthlyRent': '45000',
        'tenantName': 'مستأجر تجريبي',
        'tenantEmail': 'user@ejari.app',
        'ownerId': 'owner@ejari.app',
        'ownerEmail': 'owner@ejari.app',
        'status': BookingStatus.depositPaid,
        'paymentStatus': 'deposit_paid',
        'requestDate':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'depositPaidAt':
            DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'statusHistory': [
          {
            'status': BookingStatus.submitted,
            'label': 'إرسال الطلب',
            'at': DateTime.now()
                .subtract(const Duration(hours: 6))
                .toIso8601String(),
          },
          {
            'status': BookingStatus.depositPaid,
            'label': 'دفع العربون',
            'at': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            'note': 'بانتظار موافقة المالك',
          },
        ],
        'leaseStartDate':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'checkInDate':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'startDate':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'durationLabel': '3 أسبوع',
        'duration': '3 أسبوع',
        'durationCount': 3,
        'durationUnit': 'أسبوع',
        'leaseMonths': 0,
        'depositAmount': '11250',
        'rentalTier': 'weekly',
        'rentalTierLabel': 'إيجار أسبوعي',
        'tenantType': 'individual',
        'tenantTypeLabel': 'فرد',
        'requiresAdvanceDeposit': true,
        'showInstallments': false,
      },
    ];

    final encoded = demoRequests.map(jsonEncode).toList();
    await prefs.setStringList(_requestsKey, encoded);

    final existingBookings = prefs.getStringList(_bookingsKey) ?? [];
    final mergedBookings = {...existingBookings, ...encoded}.toList();
    await prefs.setStringList(_bookingsKey, mergedBookings);
  }

  /// Seed demo payment receipts so admin global search can find receipt IDs.
  static Future<void> initDemoReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_demoReceiptsVersionKey) ?? 0;
    final existing = prefs.getStringList(_receiptsKey) ?? [];
    if (savedVersion >= _currentDemoReceiptsVersion && existing.isNotEmpty) {
      return;
    }
    await initDemoBookings();

    final receipts = [
      PaymentReceipt(
        id: 'RCP-DEMO-001',
        amount: 3000,
        date: DateTime.now().subtract(const Duration(days: 2)),
        bookingRef: 'demo_req_1',
        payer: 'user@ejari.app',
        payee: 'owner@ejari.app',
        method: 'محفظة إيجاري',
        title: 'عربون حجز — شقة المعادي',
      ),
      PaymentReceipt(
        id: 'RCP-DEMO-002',
        amount: 11250,
        date: DateTime.now().subtract(const Duration(hours: 5)),
        bookingRef: 'demo_req_2',
        payer: 'user@ejari.app',
        payee: 'owner@ejari.app',
        method: 'بطاقة',
        title: 'عربون حجز — فيلا التجمع',
      ),
    ];

    final encoded = receipts.map((r) => jsonEncode(r.toJson())).toList();
    final merged = {...existing, ...encoded}.toList();
    await prefs.setStringList(_receiptsKey, merged);
    await prefs.setInt(_demoReceiptsVersionKey, _currentDemoReceiptsVersion);
  }

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
        'financialAccount': '',
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
        'لديك طلب جديد لإضافة عقار (${property['title']}) ينتظر المراجعة.',
        adminFeed: true);
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
    String email,
    String title,
    String body, {
    String type = 'general',
    String? refId,
    bool adminFeed = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    final note = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'read': false,
      'userEmail': email,
      'type': type,
      if (refId != null) 'refId': refId,
      'feedType': adminFeed ? 'admin' : 'user',
    };
    list.add(jsonEncode(note));
    await prefs.setStringList(_notificationsKey, list);

    await ActivityLogService.append(
      userId: email,
      action: title,
      detail: body,
      category: type,
      refId: refId,
    );
  }

  static Future<void> _notifyBookingParties({
    required Map<String, dynamic> booking,
    required String tenantTitle,
    required String tenantBody,
    required String ownerTitle,
    required String ownerBody,
    String type = 'booking',
    bool notifyAdmin = false,
    String? adminTitle,
    String? adminBody,
  }) async {
    final tenantEmail = booking['tenantEmail']?.toString() ?? '';
    final ownerEmail = booking['ownerEmail']?.toString() ??
        booking['ownerId']?.toString() ??
        '';
    final refId = booking['id']?.toString();

    if (tenantEmail.isNotEmpty) {
      await addNotificationToUser(
        tenantEmail,
        tenantTitle,
        tenantBody,
        type: type,
        refId: refId,
      );
    }
    if (ownerEmail.isNotEmpty && ownerEmail != tenantEmail) {
      await addNotificationToUser(
        ownerEmail,
        ownerTitle,
        ownerBody,
        type: type,
        refId: refId,
      );
    }
    if (notifyAdmin) {
      await addNotificationToUser(
        _adminEmail,
        adminTitle ?? tenantTitle,
        adminBody ?? tenantBody,
        type: type,
        refId: refId,
        adminFeed: true,
      );
    }
  }

  static Future<Map<String, dynamic>?> _findBookingById(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_bookingsKey, _requestsKey]) {
      final list = prefs.getStringList(key) ?? [];
      for (final raw in list) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['id']?.toString() == bookingId ||
            data['_id']?.toString() == bookingId) {
          return data;
        }
      }
    }
    return null;
  }

  // --- Payment Receipts ---

  static Future<PaymentReceipt> createPaymentReceipt({
    required double amount,
    required String bookingRef,
    required String payer,
    required String payee,
    required String method,
    String? title,
  }) async {
    final receipt = PaymentReceipt(
      id: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      bookingRef: bookingRef,
      payer: payer,
      payee: payee,
      method: method,
      title: title,
    );
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_receiptsKey) ?? [];
    list.add(jsonEncode(receipt.toJson()));
    await prefs.setStringList(_receiptsKey, list);

    await addNotificationToUser(
      payer,
      'إيصال دفع جديد 🧾',
      'تم إصدار إيصال ${receipt.id} بمبلغ ${amount.toStringAsFixed(0)} ج.م',
      type: 'payment',
      refId: receipt.id,
    );
    return receipt;
  }

  static Future<List<PaymentReceipt>> getReceiptsForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_receiptsKey) ?? [];
    return list
        .map((e) => PaymentReceipt.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((r) => r.payer == email || r.payee == email)
        .toList()
        .reversed
        .toList();
  }

  static Future<PaymentReceipt?> getReceiptById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_receiptsKey) ?? [];
    for (final raw in list) {
      final receipt =
          PaymentReceipt.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  static Future<void> updatePropertyActive(String id, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> props = prefs.getStringList(_propertiesKey) ?? [];
    List<String> updated = props.map((p) {
      final data = jsonDecode(p) as Map<String, dynamic>;
      if (data['id'].toString() == id) {
        data['isActive'] = isActive;
      }
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_propertiesKey, updated);
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
    final isAdmin = currentEmail == _adminEmail;

    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    if (list.isEmpty) {
      if (currentEmail == null) return [];
      return [
        {
          'title': 'مرحباً بك في إيجاري! 👋',
          'body': 'استكشف مئات العقارات المتاحة الآن.',
          'date': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'read': false,
          'userEmail': currentEmail,
          'feedType': 'user',
        }
      ];
    }

    final allNotes =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    return allNotes.where((n) {
      final target = n['userEmail']?.toString();
      if (target == null || target.isEmpty) return false;
      if (target != currentEmail) return false;
      final feedType = n['feedType']?.toString() ?? 'user';
      if (isAdmin) return feedType == 'admin' || feedType == 'user';
      return feedType == 'user';
    }).toList().reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_notificationsKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((n) =>
            n['userEmail'] == _adminEmail && n['feedType'] == 'admin')
        .toList()
        .reversed
        .toList();
  }

  static Future<void> addNotification(String title, String body,
      {String type = 'general', String? refId}) async {
    final currentEmail = await _getCurrentUserEmail();
    if (currentEmail == null) return;
    await addNotificationToUser(
      currentEmail,
      title,
      body,
      type: type,
      refId: refId,
    );
  }

  static Future<void> markNotificationAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();
    final isAdmin = currentEmail == _adminEmail;
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];

    final visible = list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((n) {
          final target = n['userEmail']?.toString();
          if (target != currentEmail) return false;
          final feedType = n['feedType']?.toString() ?? 'user';
          if (isAdmin) return feedType == 'admin' || feedType == 'user';
          return feedType == 'user';
        })
        .toList()
        .reversed
        .toList();

    if (index < 0 || index >= visible.length) return;
    final targetNote = visible[index];
    final storageIndex = list.indexWhere((raw) {
      final n = jsonDecode(raw) as Map<String, dynamic>;
      return n['id'] == targetNote['id'] ||
          (n['title'] == targetNote['title'] &&
              n['date'] == targetNote['date'] &&
              n['userEmail'] == targetNote['userEmail']);
    });
    if (storageIndex < 0) return;
    final note = jsonDecode(list[storageIndex]) as Map<String, dynamic>;
    note['read'] = true;
    list[storageIndex] = jsonEncode(note);
    await prefs.setStringList(_notificationsKey, list);
  }

  static Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();
    final isAdmin = currentEmail == _adminEmail;
    List<String> list = prefs.getStringList(_notificationsKey) ?? [];
    List<String> updated = list.map((e) {
      Map<String, dynamic> note = jsonDecode(e);
      final target = note['userEmail']?.toString();
      final feedType = note['feedType']?.toString() ?? 'user';
      final matchesUser = target == currentEmail;
      final matchesFeed = isAdmin
          ? feedType == 'admin' || feedType == 'user'
          : feedType == 'user';
      if (matchesUser && matchesFeed) {
        note['read'] = true;
      }
      return jsonEncode(note);
    }).toList();
    await prefs.setStringList(_notificationsKey, updated);
  }

  // --- Bookings & Requests Flow ---

  static Map<String, dynamic> _normalizeBooking(Map<String, dynamic> b) {
    final prop = b['property'] as Map<String, dynamic>? ?? {};
    final user = b['user'] as Map<String, dynamic>? ?? {};

    // Map Arabic status from backend database to Flutter UI status
    String status = BookingStatus.normalize(b['status']?.toString());

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

  static Future<List<Map<String, dynamic>>> _getAllBookingsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList(_bookingsKey) ?? [];
    final requests = prefs.getStringList(_requestsKey) ?? [];
    final seen = <String>{};
    final all = <Map<String, dynamic>>[];

    for (final raw in [...bookings, ...requests]) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final id = data['id']?.toString() ?? data['_id']?.toString() ?? '';
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      all.add(data);
    }
    return all;
  }

  static List<Map<String, dynamic>> _appendStatusHistory(
    Map<String, dynamic> data,
    String newStatus, {
    String? note,
  }) {
    final history = <Map<String, dynamic>>[];
    final existing = data['statusHistory'];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          history.add(Map<String, dynamic>.from(item));
        }
      }
    }
    history.add({
      'status': BookingStatus.normalize(newStatus),
      'label': BookingStatus.arabicLabel(newStatus),
      'at': DateTime.now().toIso8601String(),
      if (note != null) 'note': note,
    });
    data['statusHistory'] = history;
    data['status'] = BookingStatus.normalize(newStatus);
    return history;
  }

  static Future<Map<String, dynamic>?> _findPropertyById(String id) async {
    final all = await getAllProperties(approvedOnly: false);
    for (final p in all) {
      if (p['id']?.toString() == id) return p;
    }
    return null;
  }

  /// Admin oversight — all bookings with normalized status.
  static Future<List<Map<String, dynamic>>> getAdminBookingsOverview() async {
    final all = await _getAllBookingsRaw();
    return all
        .map(_normalizeBooking)
        .map((b) => {
              ...b,
              'statusLabel': BookingStatus.arabicLabel(b['status']?.toString()),
            })
        .toList()
        .reversed
        .toList();
  }

  /// Validate a booking request before persistence (demo server-side rules).
  static Future<Map<String, dynamic>> validateBookingRequest(
    Map<String, dynamic> request,
  ) async {
    if (request['bookingMode'] != 'corporate') {
      final ability = await SubscriptionService.checkBookingAbility();
      if (ability['can_book'] != true) {
        return {
          'valid': false,
          'message': ability['message']?.toString() ??
              'تجاوزت حد الحجوزات في باقتك الحالية',
        };
      }
    }

    final existing = await _getAllBookingsRaw();
    final propertyId =
        request['propertyId']?.toString() ?? request['id']?.toString();
    final property =
        propertyId != null ? await _findPropertyById(propertyId) : null;
    return BookingValidator.validateRequest(
      request: request,
      existingBookings: existing,
      property: property,
    );
  }

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

  /// ملخص مركز قيادة الشركات — موظفون، إنفاق، محافظات.
  static Future<Map<String, dynamic>> getCorporateCommandSummary() async {
    final user = await AuthService.getCurrentUser();
    final email = user?['email']?.toString() ?? '';
    var employees = await getCorporateEmployees();

    if (employees.isEmpty) {
      employees = [
        {
          'id': 'emp1',
          'name': 'أحمد سالم',
          'role': 'مهندس ميداني',
          'governorate': 'القاهرة',
          'status': 'pending',
          'monthlyRent': 0.0,
        },
        {
          'id': 'emp2',
          'name': 'محمد حسن',
          'role': 'مشرف تشغيل',
          'governorate': 'الجيزة',
          'status': 'pending',
          'monthlyRent': 0.0,
        },
        {
          'id': 'emp3',
          'name': 'سارة إبراهيم',
          'role': 'محاسبة',
          'governorate': 'الإسكندرية',
          'status': 'pending',
          'monthlyRent': 0.0,
        },
        {
          'id': 'emp4',
          'name': 'خالد عمر',
          'role': 'فني صيانة',
          'governorate': 'الشرقية',
          'status': 'pending',
          'monthlyRent': 0.0,
        },
        {
          'id': 'emp5',
          'name': 'نورا محمود',
          'role': 'مديرة فرع',
          'governorate': 'القليوبية',
          'status': 'pending',
          'monthlyRent': 0.0,
        },
      ];
    }

    final bookings = await getBookings();
    final corporateBookings = bookings
        .where((b) =>
            b['bookingMode'] == 'corporate' ||
            b['status'] == BookingStatus.corporatePending)
        .toList();

    for (final emp in employees) {
      final match = corporateBookings.cast<Map<String, dynamic>?>().firstWhere(
            (b) =>
                b?['employeeId']?.toString() == emp['id']?.toString() ||
                b?['employeeName']?.toString() == emp['name']?.toString(),
            orElse: () => null,
          );
      if (match != null) {
        emp['status'] = match['status'] ?? emp['status'];
        emp['propertyTitle'] = match['title'];
        emp['propertyId'] = match['propertyId'] ?? match['id'];
        emp['monthlyRent'] = (match['monthlyRent'] as num?)?.toDouble() ??
            double.tryParse(match['monthlyRent']?.toString() ?? '') ??
            0;
      }
    }

    final governorates =
        employees.map((e) => e['governorate']?.toString()).toSet();
    final totalSpend = employees.fold<double>(
      0,
      (sum, e) => sum + ((e['monthlyRent'] as num?)?.toDouble() ?? 0),
    );
    final active = employees
        .where((e) =>
            e['status'] == 'approved' ||
            e['status'] == 'active' ||
            e['status'] == BookingStatus.depositPaid)
        .length;
    final pending = employees
        .where((e) =>
            e['status'] == 'pending' ||
            e['status'] == BookingStatus.corporatePending)
        .length;

    return {
      'companyName': user?['companyName'] ?? user?['name'] ?? 'شركة تجريبية',
      'tenantEmail': email,
      'employees': employees,
      'totalEmployees': employees.length,
      'activeBookings': active,
      'pendingBookings': pending,
      'governorateCount': governorates.length,
      'totalSpend': totalSpend.round(),
      'governorates': governorates.toList(),
    };
  }

  /// إلغاء حجز مع تطبيق قاعدة الاسترداد (٤٨ ساعة).
  static Future<Map<String, dynamic>> cancelBookingWithRefund({
    required String bookingId,
    required DateTime checkInDate,
    required double depositAmount,
    DateTime? cancelDate,
  }) async {
    final booking = await _findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود', 'refundable': false};
    }

    final current = BookingStatus.normalize(booking['status']?.toString());
    if (current == BookingStatus.depositRefunded ||
        current == BookingStatus.cancelled ||
        current == BookingStatus.completed) {
      return {
        'success': false,
        'message': 'لا يمكن إلغاء هذا الحجز في حالته الحالية',
        'refundable': false,
        'status': current,
      };
    }

    if (!BookingStatus.canTransition(current, BookingStatus.cancelled) &&
        !BookingStatus.canTransition(current, BookingStatus.depositRefunded)) {
      return {
        'success': false,
        'message': 'الإلغاء غير مسموح في هذه المرحلة',
        'refundable': false,
        'status': current,
      };
    }

    final effectiveCancel = cancelDate ?? DateTime.now();
    final refundable = RentalRules.isRefundable(
      checkInDate: checkInDate,
      cancelDate: effectiveCancel,
    );
    final refundAmount = refundable ? depositAmount : 0.0;

    if (refundable) {
      await refundBookingDeposit(bookingId, depositAmount: depositAmount);
    } else {
      await updateRequestStatus(bookingId, BookingStatus.cancelled,
          note: 'إلغاء بدون استرداد — أقل من ٤٨ ساعة قبل الاستلام');
      await addNotification(
        'إلغاء بدون استرداد ❌',
        'تم إلغاء الحجز وفق السياسة: لا استرداد خلال ٤٨ ساعة من الاستلام.',
      );
    }

    return {
      'success': true,
      'refundable': refundable,
      'refundAmount': refundAmount,
      'daysBeforeCheckIn': checkInDate.difference(effectiveCancel).inDays,
      'status': refundable ? BookingStatus.depositRefunded : BookingStatus.cancelled,
    };
  }

  // Tenant sends a request
  static Future<Map<String, dynamic>> sendBookingRequest(
      Map<String, dynamic> request) async {
    final validation = await validateBookingRequest(request);
    if (validation['valid'] != true) {
      return {
        'success': false,
        'message': validation['message']?.toString() ?? 'طلب حجز غير صالح',
      };
    }

    // Apply server-side price correction if property found
    final propertyId =
        request['propertyId']?.toString() ?? request['id']?.toString();
    if (propertyId != null) {
      final property = await _findPropertyById(propertyId);
      if (property != null) {
        final baseRent = BookingValidator.parsePrice(property['price']);
        if (baseRent > 0) {
          final durationType =
              request['durationType']?.toString() ?? 'شهر';
          final durationCount =
              int.tryParse(request['durationCount']?.toString() ?? '') ??
                  int.tryParse(request['leaseMonths']?.toString() ?? '') ??
                  1;
          final corrected = BookingValidator.resolvePricing(
            baseMonthlyRent: baseRent,
            durationType: durationType,
            durationCount: durationCount,
            insurance: BookingValidator.parsePrice(request['insuranceCost']),
          );
          request['monthlyRent'] =
              (corrected['monthlyRent'] as double).toStringAsFixed(0);
          request['price'] = request['monthlyRent'];
          request['depositAmount'] =
              (corrected['depositAmount'] as double).toStringAsFixed(0);
          request['remainingAmount'] =
              (corrected['remainingAmount'] as double).toStringAsFixed(0);
          request['currentAmount'] =
              (corrected['currentAmount'] as double).toStringAsFixed(0);
          request['leaseTotal'] =
              (corrected['leaseTotal'] as double).toStringAsFixed(0);
          request['rentalTier'] = corrected['rentalTier'];
          request['rentalTierLabel'] = corrected['rentalTierLabel'];
          request['requiresIncomeProof'] = corrected['requiresIncomeProof'];
          request['requiresAdvanceDeposit'] = corrected['requiresAdvanceDeposit'];
          request['showInstallments'] = corrected['showInstallments'];
        }
      }
    }

    final initialStatus = BookingStatus.normalize(
      request['status']?.toString() ??
          (request['paymentStatus'] == 'deposit_paid'
              ? BookingStatus.depositPaid
              : BookingStatus.submitted),
    );
    request['status'] = initialStatus;
    _appendStatusHistory(
      request,
      initialStatus,
      note: initialStatus == BookingStatus.depositPaid
          ? 'تم دفع العربون — بانتظار موافقة المالك'
          : 'تم إرسال الطلب — بانتظار المراجعة',
    );
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
          return {'success': true, 'id': normalized['id']?.toString()};
        }
      }
    } catch (e) {
      debugPrint(
          'SendBookingRequest API Error: $e. Falling back to local storage.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = await _getCurrentUserEmail();

    request['id'] = request['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    request['requestDate'] = DateTime.now().toIso8601String();
    request['tenantEmail'] = currentEmail;
    request['ownerEmail'] =
        request['ownerEmail'] ?? request['ownerId']?.toString() ?? '';
    request['leaseMonths'] = request['leaseMonths'] ?? request['duration'];
    request['leaseStartDate'] =
        request['leaseStartDate'] ?? request['startDate'];
    request['leaseEndDate'] = request['leaseEndDate'] ?? request['endDate'];
    request['checkInDate'] = request['checkInDate'] ??
        request['leaseStartDate'] ??
        request['startDate'];
    request['paidMonths'] = request['paidMonths'] ?? 0;
    request['remainingMonths'] = request['remainingMonths'];
    request['durationLabel'] = request['durationLabel'] ?? request['duration'];
    request['durationType'] =
        request['durationType'] ?? request['durationUnit'] ?? 'شهر';

    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    bookings.add(jsonEncode(request));
    await prefs.setStringList(_bookingsKey, bookings);

    List<String> requests = prefs.getStringList(_requestsKey) ?? [];
    requests.add(jsonEncode(request));
    await prefs.setStringList(_requestsKey, requests);

    await _notifyBookingParties(
      booking: request,
      tenantTitle: 'تم إرسال طلب الحجز 📋',
      tenantBody:
          'طلبك لـ ${request['title']} قيد المراجعة. سيتم إبلاغك عند موافقة المالك.',
      ownerTitle: 'طلب حجز جديد 🔔',
      ownerBody:
          'استلمت طلب حجز من ${request['tenantName']} لـ ${request['title']}.',
      notifyAdmin: true,
      adminTitle: 'حجز جديد للمراجعة',
      adminBody:
          'طلب حجز ${request['title']} — ${request['depositAmount'] ?? ''} ج.م عربون.',
    );

    return {'success': true, 'id': request['id']?.toString()};
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
  static Future<bool> updateRequestStatus(
    String requestId,
    String newStatus, {
    String? note,
  }) async {
    final booking = await _findBookingById(requestId);
    if (booking != null) {
      final current = BookingStatus.normalize(booking['status']?.toString());
      final target = BookingStatus.normalize(newStatus);
      if (!BookingStatus.canTransition(current, target)) {
        debugPrint(
            'Invalid booking transition: $current -> $target for $requestId');
        return false;
      }
    }

    final normalizedStatus = BookingStatus.normalize(newStatus);
    String backendStatus = normalizedStatus;
    if (normalizedStatus == BookingStatus.viewingScheduled) {
      backendStatus = 'موعد معاينة';
    } else if (normalizedStatus == BookingStatus.depositPaid) {
      backendStatus = 'عربون';
    } else if (normalizedStatus == BookingStatus.completed) {
      backendStatus = 'مكتمل';
    } else if (normalizedStatus == BookingStatus.depositRefunded) {
      backendStatus = 'مسترد';
    } else if (normalizedStatus == BookingStatus.paid) {
      backendStatus = 'مدفوع';
    } else if (normalizedStatus == BookingStatus.approved) {
      backendStatus = 'مؤكد';
    } else if (normalizedStatus == BookingStatus.rejected) {
      backendStatus = 'ملغي';
    } else if (normalizedStatus == BookingStatus.cancelled) {
      backendStatus = 'ملغي';
    } else if (normalizedStatus == BookingStatus.confirmed) {
      backendStatus = 'مؤكد نهائي';
    } else if (normalizedStatus == BookingStatus.active) {
      backendStatus = 'نشط';
    } else if (normalizedStatus == BookingStatus.submitted) {
      backendStatus = 'معلق';
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
          data['status'] = normalizedStatus;
          _appendStatusHistory(data, normalizedStatus, note: note);
          if (normalizedStatus == BookingStatus.rejected) {
            data['rejectedAt'] = DateTime.now().toIso8601String();
          } else if (normalizedStatus == BookingStatus.approved) {
            data['approvedAt'] = DateTime.now().toIso8601String();
          } else if (normalizedStatus == BookingStatus.viewingScheduled) {
            data['viewingScheduledAt'] = DateTime.now().toIso8601String();
          } else if (normalizedStatus == BookingStatus.depositPaid) {
            data['depositPaidAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'deposit_paid';
            data['paymentPhase'] = 'deposit';
          } else if (normalizedStatus == BookingStatus.paid) {
            data['paidAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'paid';
            data['paymentPhase'] = 'rent_paid';
          } else if (normalizedStatus == BookingStatus.active) {
            data['activeAt'] = DateTime.now().toIso8601String();
          } else if (normalizedStatus == BookingStatus.completed ||
              normalizedStatus == BookingStatus.confirmed) {
            data['completedAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'paid';
            data['paymentPhase'] = 'completed';
          } else if (normalizedStatus == BookingStatus.depositRefunded) {
            data['refundedAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'refunded';
            data['paymentPhase'] = 'refunded';
          } else if (normalizedStatus == BookingStatus.cancelled) {
            data['cancelledAt'] = DateTime.now().toIso8601String();
            data['paymentStatus'] = 'cancelled';
          }
        }
        return jsonEncode(data);
      }).toList();
    }

    List<String> requests = prefs.getStringList(_requestsKey) ?? [];
    await prefs.setStringList(_requestsKey, updateList(requests));

    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    await prefs.setStringList(_bookingsKey, updateList(bookings));

    final updatedBooking = await _findBookingById(requestId);
    if (updatedBooking != null) {
      final title = updatedBooking['title']?.toString() ?? 'الوحدة';
      if (normalizedStatus == BookingStatus.approved) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تمت الموافقة على طلبك! 🎉',
          tenantBody: 'وافق المالك على حجز $title. يمكنك الآن إتمام الدفع.',
          ownerTitle: 'تم قبول طلب الحجز ✅',
          ownerBody:
              'وافقت على طلب ${updatedBooking['tenantName']} لـ $title.',
          type: 'booking',
        );
      } else if (normalizedStatus == BookingStatus.rejected) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تم رفض الطلب ❌',
          tenantBody: 'عذراً، تم رفض طلب حجز $title من قبل المالك.',
          ownerTitle: 'تم رفض طلب الحجز',
          ownerBody:
              'رفضت طلب ${updatedBooking['tenantName']} لـ $title.',
          type: 'booking',
        );
      } else if (normalizedStatus == BookingStatus.depositPaid) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تم حجز عربون المعاينة ✅',
          tenantBody:
              'تم استلام العربون لـ $title. يمكنك متابعة تفاصيل الزيارة.',
          ownerTitle: 'عربون مستلم 💰',
          ownerBody:
              'استلمت عربون حجز $title من ${updatedBooking['tenantName']}.',
          type: 'payment',
          notifyAdmin: _isHighValueBooking(updatedBooking),
          adminTitle: 'دفعة عربون — $title',
          adminBody: 'عربون ${updatedBooking['depositAmount'] ?? ''} ج.م.',
        );
      } else if (normalizedStatus == BookingStatus.paid ||
          normalizedStatus == BookingStatus.completed ||
          normalizedStatus == BookingStatus.confirmed) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تم تأكيد الحجز! ✅',
          tenantBody: 'تم الدفع وتأكيد حجز $title. مبروك وحدتك الجديدة!',
          ownerTitle: 'حجز مؤكد 🎉',
          ownerBody: 'تم تأكيد حجز $title وإيداع المبلغ في محفظتك.',
          type: 'payment',
          notifyAdmin: _isHighValueBooking(updatedBooking),
          adminTitle: 'حجز مؤكد — $title',
          adminBody:
              'تم إتمام دفع حجز بقيمة ${updatedBooking['price'] ?? ''} ج.م.',
        );
      } else if (normalizedStatus == BookingStatus.depositRefunded) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تم استرداد العربون',
          tenantBody: 'تم تنفيذ استرداد العربون لـ $title وفق سياسة الإلغاء.',
          ownerTitle: 'استرداد عربون',
          ownerBody: 'تم استرداد عربون حجز $title للمستأجر.',
          type: 'payment',
        );
      } else if (normalizedStatus == BookingStatus.viewingScheduled) {
        await _notifyBookingParties(
          booking: updatedBooking,
          tenantTitle: 'تم تحديد موعد المعاينة',
          tenantBody: 'يمكنك متابعة تفاصيل الزيارة من حجوزاتي.',
          ownerTitle: 'موعد معاينة مجدول',
          ownerBody: 'تم جدولة معاينة لـ $title.',
          type: 'booking',
        );
      }
    }
    return true;
  }

  static bool _isHighValueBooking(Map<String, dynamic> booking) {
    final price = double.tryParse(
          (booking['price'] ?? booking['monthlyRent'] ?? '0')
              .toString()
              .replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
    return price >= 20000;
  }

  // Owner gets their bookings (filtered by ownerId / property ownership)
  static Future<List<Map<String, dynamic>>> getOwnerBookings(
      String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];
    final ownerProperties = await getOwnerProperties(ownerId);
    final ownerPropertyIds =
        ownerProperties.map((p) => p['id']?.toString() ?? '').toSet();

    List<Map<String, dynamic>> allBookings = bookings
        .map((item) =>
            _normalizeBooking(jsonDecode(item) as Map<String, dynamic>))
        .where((b) {
          final bookingOwner = b['ownerId']?.toString() ??
              b['ownerEmail']?.toString() ??
              '';
          final propertyId = b['propertyId']?.toString() ?? '';
          return bookingOwner == ownerId ||
              ownerPropertyIds.contains(propertyId);
        })
        .map((b) {
          final price = double.tryParse(
                  (b['price'] ?? b['monthlyRent'] ?? '0')
                      .toString()
                      .replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
          return {
            ...b,
            'propertyTitle': b['title'] ?? b['propertyTitle'] ?? 'عقار',
            'date': b['requestDate'] ?? b['startDate'] ?? '',
            'amount': '${price.toStringAsFixed(0)} ج.م',
            'revenue': b['revenue'] ?? price,
          };
        })
        .toList();

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

  // Get Wallet Data — from WalletService per-user store
  static Future<Map<String, dynamic>> getWalletData(String ownerId) async {
    await WalletService.init(userId: ownerId);
    final summary = await WalletService.getWalletSummary(userId: ownerId);
    final revenue = await getOwnerRevenue(ownerId);
    return {
      'totalBalance': summary['balance'] ?? revenue,
      'available': summary['balance'] ?? revenue * 0.8,
      'pending': summary['pending'] ?? revenue * 0.15,
      'escrow': summary['escrow'] ?? revenue * 0.05,
      'currency': 'ج.م',
    };
  }

  // Get Wallet Transactions
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
      String ownerId) async {
    final walletTx = await WalletService.getTransactions(userId: ownerId);
    if (walletTx.isNotEmpty) {
      return walletTx.map((tx) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        return {
          'title': tx['title'] ?? 'معاملة',
          'reason': tx['category']?.toString() ?? '',
          'amount': amount >= 0
              ? '+${amount.toStringAsFixed(0)}'
              : amount.toStringAsFixed(0),
          'date': DateParsing.parse(tx['date']) ?? DateTime.now(),
          'type': tx['type'] ?? 'deposit',
          'status': tx['status'] ?? 'completed',
        };
      }).toList();
    }

    final bookings = await getOwnerBookings(ownerId);
    List<Map<String, dynamic>> transactions = [];

    for (var b in bookings) {
      // Extract numeric revenue for formatting
      double rev = 0.0;
      if (b['revenue'] is num) {
        rev = (b['revenue'] as num).toDouble();
      } else if (b['amount'] != null) {
        String clean =
            safeStr(b['amount']).replaceAll(RegExp(r'[^0-9.]'), '');
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

  // Tenant pays for booking — with wallet debit, receipt, owner credit
  static Future<Map<String, dynamic>> payForBooking(
    String bookingId, {
    double? amount,
    String method = 'wallet',
    bool useWallet = true,
  }) async {
    final booking = await _findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    final deposit = amount ??
        double.tryParse(
          (booking['depositAmount'] ?? booking['currentAmount'] ?? '0')
              .toString()
              .replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
    final tenantId = booking['tenantEmail']?.toString() ?? '';
    final ownerId = booking['ownerEmail']?.toString() ??
        booking['ownerId']?.toString() ??
        '';
    final title = booking['title']?.toString() ?? 'حجز';

    if (useWallet && method == 'wallet') {
      final ok = await WalletService.processBookingPayment(
        tenantId: tenantId,
        ownerId: ownerId,
        amount: deposit,
        bookingId: bookingId,
        title: 'عربون $title',
        method: 'wallet',
        useWallet: true,
        isDeposit: true,
      );
      if (!ok) {
        return {'success': false, 'message': 'رصيد المحفظة غير كافٍ'};
      }
    } else {
      await WalletService.processBookingPayment(
        tenantId: tenantId,
        ownerId: ownerId,
        amount: deposit,
        bookingId: bookingId,
        title: 'عربون $title',
        method: method,
        useWallet: false,
        isDeposit: true,
      );
    }

    final receipt = await createPaymentReceipt(
      amount: deposit,
      bookingRef: bookingId,
      payer: tenantId,
      payee: ownerId,
      method: method,
      title: 'عربون $title',
    );

    await updateRequestStatus(bookingId, 'deposit_paid');
    return {'success': true, 'receipt': receipt};
  }

  static Future<Map<String, dynamic>> completeBookingPaymentWithReceipt(
    String bookingId, {
    required double amount,
    required String method,
    bool useWallet = false,
  }) async {
    final booking = await _findBookingById(bookingId);
    if (booking == null) {
      return {'success': false, 'message': 'الحجز غير موجود'};
    }

    final tenantId = booking['tenantEmail']?.toString() ?? '';
    final ownerId = booking['ownerEmail']?.toString() ??
        booking['ownerId']?.toString() ??
        '';
    final title = booking['title']?.toString() ?? 'حجز';

    if (useWallet) {
      final ok = await WalletService.payFromWallet(
        title: 'استكمال $title',
        amount: amount,
        category: 'rent',
        bookingId: bookingId,
        userId: tenantId,
      );
      if (!ok) {
        return {'success': false, 'message': 'رصيد المحفظة غير كافٍ'};
      }
    } else {
      await WalletService.recordExternalPayment(
        title: 'استكمال $title',
        amount: amount,
        method: method,
        bookingId: bookingId,
        userId: tenantId,
      );
    }

    final deposit = double.tryParse(
          (booking['depositAmount'] ?? '0')
              .toString()
              .replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;

    await WalletService.releaseBookingDeposit(
      title: 'عربون $title',
      amount: deposit,
      bookingId: bookingId,
      ownerId: ownerId,
      tenantId: tenantId,
    );

    await WalletService.creditOwnerFromPayment(
      ownerId: ownerId,
      totalAmount: amount,
      bookingId: bookingId,
      title: 'إيجار $title',
    );

    final receipt = await createPaymentReceipt(
      amount: amount,
      bookingRef: bookingId,
      payer: tenantId,
      payee: ownerId,
      method: method,
      title: 'استكمال $title',
    );

    await updateRequestStatus(bookingId, BookingStatus.paid,
        note: 'تم إتمام دفع الإيجار');
    return {'success': true, 'receipt': receipt};
  }

  static Future<void> refundBookingDeposit(
    String bookingId, {
    double? depositAmount,
  }) async {
    final booking = await _findBookingById(bookingId);
    if (booking != null && depositAmount != null && depositAmount > 0) {
      await WalletService.refundBookingDeposit(
        title: 'استرداد عربون ${booking['title'] ?? 'حجز'}',
        amount: depositAmount,
        bookingId: bookingId,
        userId: booking['tenantEmail']?.toString(),
      );
    }
    await updateRequestStatus(bookingId, 'deposit_refunded');
  }

  static Future<void> completeBookingPayment(String bookingId) async {
    await updateRequestStatus(bookingId, BookingStatus.paid);
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
  static const String _moderatedReviewsKey = 'admin_moderated_reviews_v1';

  static Future<void> addReview(
      String propertyId, Map<String, dynamic> review,
      {String? propertyTitle}) async {
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

    // Mirror to admin moderation inbox
    final modId = 'REV-${DateTime.now().millisecondsSinceEpoch}';
    final moderated = {
      'id': modId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle ?? propertyId,
      'userName': review['userName'] ?? 'مستخدم',
      'rating': review['rating'] ?? 0,
      'comment': review['comment'] ?? '',
      'date': review['date'],
      'moderationStatus': 'pending',
    };
    final modList = prefs.getStringList(_moderatedReviewsKey) ?? [];
    modList.add(jsonEncode(moderated));
    await prefs.setStringList(_moderatedReviewsKey, modList);

    await addNotificationToUser(
      _adminEmail,
      'تقييم عقار جديد ⭐',
      '${moderated['userName']}: ${moderated['rating']} نجوم — ${moderated['propertyTitle']}',
      type: 'review',
      refId: modId,
      adminFeed: true,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllModeratedReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_moderatedReviewsKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<void> moderateReview(String id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_moderatedReviewsKey) ?? [];
    final updated = list.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['id'] == id) data['moderationStatus'] = status;
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_moderatedReviewsKey, updated);
  }

  static Future<void> respondToReview(String id, String response,
      {String? adminEmail}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_moderatedReviewsKey) ?? [];
    String? userName;
    final updated = list.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['id'] == id) {
        data['adminResponse'] = response;
        data['moderationStatus'] = data['moderationStatus'] ?? 'approved';
        userName = data['userName']?.toString();
      }
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_moderatedReviewsKey, updated);

    if (userName != null) {
      await addNotificationToUser(
        _adminEmail,
        'تم الرد على تقييم',
        response,
        type: 'review',
        refId: id,
        adminFeed: true,
      );
    }
  }

  /// Unified admin lookup across bookings, contracts, receipts, maintenance, users.
  static Future<List<Map<String, dynamic>>> adminGlobalSearch(
      String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    await initDemoBookings();
    await initDemoReceipts();
    await MaintenanceService.initDemoRequests();

    final results = <Map<String, dynamic>>[];
    final prefs = await SharedPreferences.getInstance();

    void addUnique(Map<String, dynamic> item) {
      if (!results.any((r) => r['id'] == item['id'] && r['type'] == item['type'])) {
        results.add(item);
      }
    }

    bool matches(Map<String, dynamic> data, List<String> fields) {
      for (final field in fields) {
        final val = data[field]?.toString().toLowerCase() ?? '';
        if (val.contains(q)) return true;
      }
      return false;
    }

    for (final key in [_bookingsKey, _requestsKey]) {
      final list = prefs.getStringList(key) ?? [];
      for (final raw in list) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (matches(data, [
          'id',
          '_id',
          'contractNumber',
          'title',
          'tenantEmail',
          'tenantName',
          'ownerEmail',
          'ownerId',
        ])) {
          final contract = data['contractNumber']?.toString();
          addUnique({
            'type': contract != null && contract.isNotEmpty ? 'contract' : 'booking',
            'typeLabel': contract != null && contract.isNotEmpty ? 'عقد' : 'حجز',
            'id': data['id']?.toString() ?? data['_id']?.toString(),
            'title': data['title']?.toString() ?? 'حجز',
            'subtitle':
                '${data['tenantName'] ?? data['tenantEmail'] ?? ''} — ${data['status'] ?? ''}',
            'data': data,
          });
        }
      }
    }

    final receipts = prefs.getStringList(_receiptsKey) ?? [];
    for (final raw in receipts) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (matches(data, ['id', 'bookingRef', 'payer', 'payee', 'title'])) {
        addUnique({
          'type': 'receipt',
          'typeLabel': 'إيصال',
          'id': data['id']?.toString(),
          'title': data['title']?.toString() ?? 'إيصال دفع',
          'subtitle':
              '${data['amount']} ج.م — ${data['payer'] ?? ''}',
          'data': data,
        });
      }
    }

    final maintenance = await MaintenanceService.getAllRequests();
    for (final req in maintenance) {
      if (matches(req, [
        'id',
        'title',
        'tenantId',
        'tenantEmail',
        'propertyTitle',
        'description',
      ])) {
        addUnique({
          'type': 'maintenance',
          'typeLabel': 'صيانة',
          'id': req['id']?.toString(),
          'title': req['title']?.toString() ?? 'طلب صيانة',
          'subtitle':
              '${req['tenantId'] ?? req['tenantEmail'] ?? ''} — ${req['status'] ?? ''}',
          'data': req,
        });
      }
    }

    final users = prefs.getStringList('users_list') ?? [];
    for (final email in users) {
      final userRaw = prefs.getString('user_$email');
      if (userRaw == null) continue;
      final user = jsonDecode(userRaw) as Map<String, dynamic>;
      if (email.toLowerCase().contains(q) ||
          (user['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (user['phone']?.toString().toLowerCase().contains(q) ?? false) ||
          (user['accountId']?.toString().toLowerCase().contains(q) ?? false)) {
        addUnique({
          'type': 'user',
          'typeLabel': 'مستخدم',
          'id': email,
          'title': user['name']?.toString() ?? email,
          'subtitle':
              '${user['accountId'] ?? ''} — ${user['role'] ?? user['type'] ?? 'tenant'}',
          'data': user,
        });
      }
    }

    final tickets = prefs.getStringList('support_tickets_v1') ?? [];
    for (final raw in tickets) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (matches(data, ['id', 'subject', 'userEmail', 'message'])) {
        addUnique({
          'type': 'support',
          'typeLabel': 'دعم',
          'id': data['id']?.toString(),
          'title': data['subject']?.toString() ?? 'تذكرة دعم',
          'subtitle': data['userEmail']?.toString() ?? '',
          'data': data,
        });
      }
    }

    return results;
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
      'pendingVerifications': await getPendingIdentityVerificationsCount(),
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

  // --- Provider / Technician Logic (موحّد مع MaintenanceService) ---

  static Future<Map<String, dynamic>> payForMaintenanceService(
    String requestId, {
    required double amount,
    required String tenantId,
    required String technicianId,
    String? ownerId,
    required String title,
    bool useWallet = true,
    String method = 'wallet',
  }) async {
    final breakdown = FinancialService.calculateServiceBreakdown(amount);

    final ok = await WalletService.processServicePayment(
      tenantId: tenantId,
      technicianId: technicianId,
      amount: amount,
      requestId: requestId,
      title: title,
      technicianShare: breakdown.providerAmount,
      platformFee: breakdown.appCommission,
      useWallet: useWallet,
      method: method,
    );

    if (!ok) {
      return {
        'success': false,
        'message': 'رصيد المحفظة غير كافٍ — يرجى شحن الرصيد أولاً',
      };
    }

    final receipt = await createPaymentReceipt(
      amount: amount,
      bookingRef: requestId,
      payer: tenantId,
      payee: technicianId,
      method: method,
      title: 'صيانة — $title',
    );

    await addNotificationToUser(
      technicianId,
      'تم استلام أجر الصيانة 💰',
      '${breakdown.providerAmount.toStringAsFixed(0)} ج.م أُضيفت لمحفظتك',
      type: 'maintenance',
      refId: requestId,
    );
    await addNotificationToUser(
      tenantId,
      'تم دفع الصيانة بنجاح 🧾',
      'إيصال الدفع متاح في محفظتك',
      type: 'maintenance',
      refId: requestId,
    );
    if (ownerId != null && ownerId.isNotEmpty && ownerId != tenantId) {
      await addNotificationToUser(
        ownerId,
        'اكتملت صيانة العقار',
        '$title — تم الدفع والإغلاق',
        type: 'maintenance',
        refId: requestId,
      );
    }

    return {'success': true, 'receipt': receipt};
  }

  static Future<List<Map<String, dynamic>>> getProviderRequests(
      String providerId) async {
    final requests = await MaintenanceService.getTechnicianRequests(providerId);
    return requests.map(MaintenanceService.toProviderView).toList().reversed.toList();
  }

  static Future<void> updateProviderRequestStatus(
      String requestId, String newStatus) async {
    await MaintenanceService.updateProviderJobStatus(requestId, newStatus);
  }

  static Future<Map<String, dynamic>> getProviderStats(
      String providerId) async {
    return MaintenanceService.getTechnicianStats(providerId);
  }

  static Future<Map<String, dynamic>?> getActiveProviderJob(
      String providerId) async {
    final requests = await MaintenanceService.getTechnicianRequests(providerId);
    try {
      final active = requests.firstWhere((r) {
        final st = MaintenanceStatus.normalize(r['status']);
        return st == MaintenanceStatus.inProgress ||
            st == MaintenanceStatus.enRoute ||
            st == MaintenanceStatus.assigned;
      });
      return MaintenanceService.toProviderView(active);
    } catch (_) {
      try {
        final pending = requests.firstWhere((r) =>
            MaintenanceStatus.normalize(r['status']) == MaintenanceStatus.assigned);
        return MaintenanceService.toProviderView(pending);
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

  // === Identity Verification (KYC) ===

  static const String _verificationRequestsKey = 'verification_requests';

  static Future<List<Map<String, dynamic>>> getAllIdentityVerifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_verificationRequestsKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<Map<String, dynamic>?> getIdentityVerificationForUser(
      String email) async {
    final requests = await getAllIdentityVerifications();
    return requests.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['email']?.toString() == email,
          orElse: () => null,
        );
  }

  static Future<int> getPendingIdentityVerificationsCount() async {
    final requests = await getAllIdentityVerifications();
    return requests
        .where((r) => (r['status'] ?? 'pending') == 'pending')
        .length;
  }

  static Future<Map<String, String>> getIdentityVerificationStatus(
      String email) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_$email');
    if (userJson != null) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      if (user['isVerified'] == true || user['verified'] == true) {
        return {'status': 'approved', 'label': 'موافق'};
      }
    }

    final submission = await getIdentityVerificationForUser(email);
    if (submission == null) {
      return {'status': 'none', 'label': 'غير موثق'};
    }

    final status = submission['status']?.toString() ?? 'pending';
    if (status == 'approved') {
      return {'status': 'approved', 'label': 'موافق'};
    }
    if (status == 'rejected') {
      final reason = submission['rejectionReason']?.toString() ??
          submission['adminNote']?.toString() ??
          '';
      return {
        'status': 'rejected',
        'label': 'مرفوض',
        'reason': reason,
      };
    }
    return {'status': 'pending', 'label': 'قيد المراجعة'};
  }

  static Future<Map<String, dynamic>> submitIdentityVerification({
    required String userId,
    required String userName,
    required String userType,
    required String email,
    required String phone,
    required String idFront,
    required String idBack,
    required String selfie,
  }) async {
    final existing = await getIdentityVerificationForUser(email);
    if (existing != null && (existing['status'] ?? 'pending') == 'pending') {
      return {
        'success': false,
        'message': 'لديك طلب توثيق قيد المراجعة بالفعل',
      };
    }

    final request = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'email': email,
      'phone': phone,
      'status': 'pending',
      'idFront': idFront,
      'idBack': idBack,
      'selfie': selfie,
      'submittedAt': DateTime.now().toIso8601String(),
      'adminNote': null,
      'rejectionReason': null,
      'reviewedAt': null,
    };

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_verificationRequestsKey) ?? [];
    if (existing != null) {
      final updated = list.map((raw) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['email']?.toString() == email) {
          return jsonEncode(request);
        }
        return raw;
      }).toList();
      await prefs.setStringList(_verificationRequestsKey, updated);
    } else {
      list.add(jsonEncode(request));
      await prefs.setStringList(_verificationRequestsKey, list);
    }

    await addNotificationToUser(
      _adminEmail,
      'طلب توثيق هوية جديد 🪪',
      'طلب توثيق من $userName ($email) بانتظار المراجعة.',
      type: 'verification',
      refId: request['id']?.toString(),
      adminFeed: true,
    );

    return {'success': true, 'request': request};
  }

  static Future<bool> approveIdentityVerification(
    String requestId, {
    String? adminNote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_verificationRequestsKey) ?? [];
    Map<String, dynamic>? approved;

    final updated = list.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['id']?.toString() == requestId) {
        data['status'] = 'approved';
        data['adminNote'] = adminNote;
        data['rejectionReason'] = null;
        data['reviewedAt'] = DateTime.now().toIso8601String();
        approved = data;
        return jsonEncode(data);
      }
      return raw;
    }).toList();

    if (approved == null) return false;
    await prefs.setStringList(_verificationRequestsKey, updated);

    final email = approved!['email']?.toString() ?? '';
    final userName = approved!['userName']?.toString() ?? 'مستخدم';
    final userKey = 'user_$email';
    final userJson = prefs.getString(userKey);
    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      userData['isVerified'] = true;
      userData['verified'] = true;
      userData['verifiedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(userKey, jsonEncode(userData));
    }

    final currentEmail = prefs.getString(_currentUserKey);
    if (currentEmail == email) {
      final sessionRaw = prefs.getString('user_data');
      if (sessionRaw != null) {
        final session = jsonDecode(sessionRaw) as Map<String, dynamic>;
        session['isVerified'] = true;
        session['verified'] = true;
        session['verifiedAt'] = DateTime.now().toIso8601String();
        await prefs.setString('user_data', jsonEncode(session));
      }
    }

    final noteSuffix =
        adminNote != null && adminNote.isNotEmpty ? '\nملاحظة: $adminNote' : '';
    await addNotificationToUser(
      email,
      'تم توثيق حسابك! 🎉',
      'تهانينا $userName، تمت الموافقة على طلب التوثيق.$noteSuffix',
      type: 'verification',
      refId: requestId,
    );

    return true;
  }

  static Future<bool> rejectIdentityVerification(
    String requestId,
    String rejectionReason,
  ) async {
    if (rejectionReason.trim().isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_verificationRequestsKey) ?? [];
    Map<String, dynamic>? rejected;

    final updated = list.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['id']?.toString() == requestId) {
        data['status'] = 'rejected';
        data['rejectionReason'] = rejectionReason.trim();
        data['adminNote'] = rejectionReason.trim();
        data['reviewedAt'] = DateTime.now().toIso8601String();
        rejected = data;
        return jsonEncode(data);
      }
      return raw;
    }).toList();

    if (rejected == null) return false;
    await prefs.setStringList(_verificationRequestsKey, updated);

    final email = rejected!['email']?.toString() ?? '';
    final userName = rejected!['userName']?.toString() ?? 'مستخدم';

    await addNotificationToUser(
      email,
      'تم رفض طلب التوثيق ❌',
      'عذراً $userName، تم رفض طلب التوثيق.\nالسبب: ${rejectionReason.trim()}',
      type: 'verification',
      refId: requestId,
    );

    return true;
  }

  // === Property Verification ===

  static Future<bool> isPropertyVerified(String propertyId) async {
    final properties = await getAllProperties(approvedOnly: false);
    final match = properties.firstWhere(
      (p) => p['id']?.toString() == propertyId,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return false;
    return match['isVerified'] == true;
  }

  static const String _joinRequestsKey = 'provider_join_requests_v1';

  static Future<void> initDemoJoinRequests() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_joinRequestsKey)) return;
    final defaults = [
      {
        'id': 'JR-101',
        'service': 'طلب انضمام: مصور فوتوغرافي',
        'userName': 'كريم جمال',
        'customerPhone': '01288887777',
        'status': 'pending',
        'createdAt': '2024-04-22',
        'title': 'القاهرة، المعادي',
        'notes': 'خبرة 5 سنوات في تصوير العقارات الفاخرة.',
        'estimatedCost': 0,
      },
      {
        'id': 'JR-102',
        'service': 'طلب انضمام: شركة نقل أثاث',
        'userName': 'شركة السلام للنقل',
        'customerPhone': '01011223344',
        'status': 'pending',
        'createdAt': '2024-04-21',
        'title': 'الجيزة، الشيخ زايد',
        'notes': 'لدينا أسطول من 10 شاحنات مجهزة.',
        'estimatedCost': 0,
      },
    ];
    await prefs.setStringList(
      _joinRequestsKey,
      defaults.map((e) => jsonEncode(e)).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> getJoinRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_joinRequestsKey) ?? [];
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  static Future<void> updateJoinRequestStatus(
    String id,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getJoinRequests();
    final index = requests.indexWhere((r) => r['id']?.toString() == id);
    if (index == -1) return;
    requests[index]['status'] = status;
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();
    await prefs.setStringList(
      _joinRequestsKey,
      requests.map((e) => jsonEncode(e)).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> getTechnicians() async {
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users_list') ?? [];
    final technicians = <Map<String, dynamic>>[];
    for (final email in users) {
      final raw = prefs.getString('user_$email');
      if (raw == null) continue;
      final user = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final role = (user['role'] ?? user['type'] ?? 'tenant').toString();
      if (role == 'technician' ||
          role == 'provider' ||
          role == 'service_provider' ||
          role == 'tech') {
        technicians.add({
          ...user,
          'email': email,
          'name': user['name'] ?? email,
        });
      }
    }
    if (technicians.isEmpty) {
      technicians.add({
        'email': 'tech@ejari.app',
        'name': 'فني صيانة تجريبي',
      });
    }
    return technicians;
  }

  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final base = await getAdminGlobalStats();
    final prefs = await SharedPreferences.getInstance();
    final users = prefs.getStringList('users_list') ?? [];
    int tenants = 0;
    int owners = 0;
    int technicians = 0;
    for (final email in users) {
      final raw = prefs.getString('user_$email');
      if (raw == null) continue;
      final user = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final role = (user['role'] ?? user['type'] ?? 'tenant').toString();
      switch (role) {
        case 'owner':
        case 'landlord':
          owners++;
          break;
        case 'technician':
        case 'provider':
        case 'service_provider':
        case 'tech':
          technicians++;
          break;
        case 'admin':
          break;
        default:
          tenants++;
      }
    }

    final maintenance = await MaintenanceService.getAllRequests();
    final openDisputes = maintenance
        .where((r) =>
            MaintenanceStatus.normalize(r['status']?.toString()) ==
            MaintenanceStatus.disputed)
        .length;
    final activeMaintenance = maintenance.where((r) {
      final st = MaintenanceStatus.normalize(r['status']?.toString());
      return st != MaintenanceStatus.paid &&
          st != MaintenanceStatus.completed &&
          st != MaintenanceStatus.cancelled &&
          st != MaintenanceStatus.rejected;
    }).length;

    final pendingPayments = (await getBookings())
        .where((b) =>
            b['status'] == 'deposit_paid' || b['status'] == 'pending')
        .length;

    double escrowBalance = 0;
    for (final email in users) {
      final wallet = await getWalletData(email);
      escrowBalance += (wallet['escrow'] as num?)?.toDouble() ?? 0;
    }

    return {
      'totalUsers': users.length,
      'tenantsCount': tenants,
      'ownersCount': owners,
      'techniciansCount': technicians,
      'pendingVerifications': base['pendingVerifications'] ?? 0,
      'pendingProperties': (base['pendingVerifications'] as num?)?.toInt() ?? 0,
      'activeBookings': base['activeBookings'] ?? 0,
      'pendingPayments': pendingPayments,
      'escrowBalance': escrowBalance.round(),
      'openDisputes': openDisputes,
      'activeMaintenance': activeMaintenance,
      'platformRevenue': (base['totalRevenue'] as num?)?.round() ?? 0,
      'todayTransactions':
          (((base['totalRevenue'] as num?)?.toDouble() ?? 0) * 0.28).round(),
      'systemAlerts': openDisputes + pendingPayments,
    };
  }
}
