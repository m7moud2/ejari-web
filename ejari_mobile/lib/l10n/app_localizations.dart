import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Ejari',
      'home_greeting': 'Elevate Your Lifestyle!',
      'home_subtitle': 'Discover the finest residences designed for the keyo.',
      'search_hint': 'Search for your next community...',
      'ejari_portfolio': 'Ejari Investment Portfolio',
      'luxury_apartments': 'Luxury\nApartments',
      'villas_palaces': 'Villas &\nPalaces',
      'corporate_hq': 'Corporate\nHQ',
      'hotel_stay': 'Hotel\nStay',
      'ejari_picks': 'Ejari Picks',
      'view_all': 'View All',
      'price_egp': 'EGP',
      'beds': 'Beds',
      'baths': 'Baths',
      'map_search': 'Explore Map',
      'virtual_tour': '360° Tour',
      'book_now': 'Book Now',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'arabic': 'العربية',
      'ai_concierge': 'Help',
      'investment_dashboard': 'Wealth Portfolio',
      'loyalty_program': 'Ejari Card',
      'property_management_services': 'Ejari Property Management',
      'safe_transport': 'Safe Transport & Packing',
      'safe_transport_desc': 'Expert relocation to protect your belongings.',
      'hotel_cleaning': 'Premium Hotel Cleaning',
      'hotel_cleaning_desc': 'Deep cleaning for faster investment turnaround.',
      'emergency_maintenance': 'Emergency & Routine Maintenance',
      'emergency_maintenance_desc':
          'Fast response with comprehensive parts warranty.',
      'smart_design': 'Design & Finishing',
      'smart_design_desc': 'Refresh finishes and layout for a stronger listing.',
      'ai_concierge_desc': 'Ask about properties, bookings, and next steps.',
      'free_price': 'Free',
      'starts_from': 'Starts from',
      'account_and_privacy': 'Account & Privacy',
      'edit_profile': 'Edit Profile',
      'digital_wallet': 'Digital Wallet',
      'payment_methods': 'Payment Methods',
      'properties_and_services': 'Properties & Services',
      'investment_performance': 'Investment Performance',
      'active_properties': 'Active Properties',
      'total_asset_value': 'Total Asset Value',
      'monthly_revenue': 'Monthly Revenue',
      'annual_roi': 'Annual ROI',
      'occupancy_rate': 'Occupancy Rate',
      'maintenance_costs': 'Maintenance Costs',
    },
    'ar': {
      'app_name': 'إيجاري',
      'home_greeting': 'ارتقِ بمستوى حياتك!',
      'home_subtitle': 'اكتشف أرقى المساكن المصممة لصفوة المجتمع.',
      'search_hint': 'ابحث عن مجتمعك القادم...',
      'ejari_portfolio': 'محفظة استثمارات إيجاري',
      'luxury_apartments': 'شقق\nفاخرة',
      'villas_palaces': 'قصور\nوفلل',
      'corporate_hq': 'مقرات\nشركات',
      'hotel_stay': 'إقامة\nفندقية',
      'ejari_picks': 'مختارات إيجاري المميزة',
      'view_all': 'عرض الكل',
      'price_egp': 'ج.م',
      'beds': 'غرف',
      'baths': 'حمام',
      'map_search': 'استكشف الخريطة',
      'virtual_tour': 'جولة 360°',
      'book_now': 'احجز الآن',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'ai_concierge': 'المساعدة',
      'investment_dashboard': 'محفظة الثروة',
      'loyalty_program': 'بطاقة إيجاري السوداء',
      'property_management_services': 'خدمات إدارة الأملاك لكبار العملاء',
      'safe_transport': 'النقل والتغليف المأمون',
      'safe_transport_desc': 'نقل وتركيب بأيدي خبراء للحفاظ على ممتلكاتك.',
      'hotel_cleaning': 'التعقيم الفندقي المتكامل',
      'hotel_cleaning_desc':
          'تجهيز وتنظيف عميق للوحدة قبل وبعد السكن لدوران استثماري أسرع.',
      'emergency_maintenance': 'الصيانة الطارئة والدورية',
      'emergency_maintenance_desc':
          'استجابة سريعة للأعطال مع ضمان شامل على قطع الغيار.',
      'smart_design': 'تصميم وتشطيب',
      'smart_design_desc': 'تحديث التشطيبات والترتيب لعرض أوضح للعقار.',
      'ai_concierge_desc': 'اسأل عن العقارات والحجوزات والخطوات التالية.',
      'free_price': 'مجانًا',
      'starts_from': 'يبدأ من',
      'account_and_privacy': 'الحساب والخصوصية',
      'edit_profile': 'تعديل الملف الشخصي',
      'digital_wallet': 'المحفظة الرقمية',
      'payment_methods': 'طرق الدفع',
      'properties_and_services': 'العقارات والخدمات',
      'investment_performance': 'أداء الاستثمارات',
      'active_properties': 'العقارات النشطة',
      'total_asset_value': 'إجمالي قيمة الأصول',
      'monthly_revenue': 'العائد الشهري',
      'annual_roi': 'العائد السنوي (ROI)',
      'occupancy_rate': 'معدل الإشغال',
      'maintenance_costs': 'تكاليف الصيانة',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for easier usage: context.tr('key')
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.get(key) ?? key;
  }
}
