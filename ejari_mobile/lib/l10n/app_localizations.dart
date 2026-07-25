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
      'home': 'Home',
      'explore': 'Explore',
      'booking': 'Booking',
      'payment': 'Payment',
      'wallet': 'Wallet',
      'profile': 'Profile',
      'settings': 'Settings',
      'general': 'General',
      'home_greeting': 'Find and book housing with clear terms.',
      'home_subtitle':
          'Short and long stays across Egypt, Saudi Arabia, and the UAE.',
      'search_hint': 'Search by city or area…',
      'ejari_portfolio': 'Ejari listings',
      'luxury_apartments': 'Apartments',
      'villas_palaces': 'Villas',
      'corporate_hq': 'Corporate',
      'hotel_stay': 'Short stay',
      'ejari_picks': 'Featured',
      'view_all': 'View all',
      'price_egp': 'EGP',
      'beds': 'Beds',
      'baths': 'Baths',
      'map_search': 'Map',
      'virtual_tour': '360° tour',
      'book_now': 'Book now',
      'language': 'Language',
      'english': 'English',
      'arabic': 'العربية',
      'country_region': 'Country / region',
      'currency': 'Currency',
      'ai_concierge': 'Help',
      'investment_dashboard': 'Portfolio',
      'loyalty_program': 'Ejari Card',
      'property_management_services': 'Property management',
      'safe_transport': 'Moving & packing',
      'safe_transport_desc': 'Relocation support for your belongings.',
      'hotel_cleaning': 'Deep cleaning',
      'hotel_cleaning_desc': 'Turnover cleaning before and after stays.',
      'emergency_maintenance': 'Maintenance',
      'emergency_maintenance_desc':
          'Request a technician and track the job to close.',
      'smart_design': 'Design & finishing',
      'smart_design_desc': 'Refresh finishes for a clearer listing.',
      'ai_concierge_desc': 'Ask about properties, bookings, and next steps.',
      'free_price': 'Free',
      'starts_from': 'From',
      'account_and_privacy': 'Account & privacy',
      'edit_profile': 'Edit profile',
      'digital_wallet': 'Wallet',
      'payment_methods': 'Payment methods',
      'properties_and_services': 'Properties & services',
      'investment_performance': 'Performance',
      'active_properties': 'Active properties',
      'total_asset_value': 'Total asset value',
      'monthly_revenue': 'Monthly revenue',
      'annual_roi': 'Annual ROI',
      'occupancy_rate': 'Occupancy',
      'maintenance_costs': 'Maintenance costs',
      'deposit': 'Deposit',
      'remaining': 'Remaining',
      'escrow': 'Escrow',
      'verified': 'Verified',
      'safety_guide': 'Safety guide',
      'pay_with_card': 'Bank card',
      'pay_with_wallet': 'Ejari wallet',
      'confirm_payment': 'Confirm payment',
      'my_bookings': 'My bookings',
      'continue_label': 'Continue',
      'cancel': 'Cancel',
      'save': 'Save',
      'region_egypt': 'Egypt',
      'region_saudi': 'Saudi Arabia',
      'region_uae': 'United Arab Emirates',
      'choose_region': 'Choose your country',
      'choose_region_hint':
          'Prices and demo listings follow the selected country.',
      'trust_escrow_note': 'Deposit held in escrow until handover rules apply.',
    },
    'ar': {
      'app_name': 'إيجاري',
      'home': 'الرئيسية',
      'explore': 'استكشاف',
      'booking': 'الحجز',
      'payment': 'الدفع',
      'wallet': 'المحفظة',
      'profile': 'الملف',
      'settings': 'الإعدادات',
      'general': 'عام',
      'home_greeting': 'ابحث واحجز بإيجار واضح وشروط محددة.',
      'home_subtitle':
          'إقامات قصيرة وطويلة في مصر والسعودية والإمارات.',
      'search_hint': 'ابحث بالمدينة أو المنطقة…',
      'ejari_portfolio': 'قوائم إيجاري',
      'luxury_apartments': 'شقق',
      'villas_palaces': 'فلل',
      'corporate_hq': 'شركات',
      'hotel_stay': 'إقامة قصيرة',
      'ejari_picks': 'مختارات',
      'view_all': 'عرض الكل',
      'price_egp': 'ج.م',
      'beds': 'غرف',
      'baths': 'حمام',
      'map_search': 'الخريطة',
      'virtual_tour': 'جولة 360°',
      'book_now': 'احجز الآن',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'country_region': 'الدولة / المنطقة',
      'currency': 'العملة',
      'ai_concierge': 'المساعدة',
      'investment_dashboard': 'المحفظة',
      'loyalty_program': 'بطاقة إيجاري',
      'property_management_services': 'إدارة الأملاك',
      'safe_transport': 'النقل والتغليف',
      'safe_transport_desc': 'دعم نقل وتركيب للممتلكات.',
      'hotel_cleaning': 'تنظيف عميق',
      'hotel_cleaning_desc': 'تجهيز الوحدة قبل وبعد الإقامة.',
      'emergency_maintenance': 'الصيانة',
      'emergency_maintenance_desc':
          'اطلب فنياً وتابع الطلب حتى الإغلاق.',
      'smart_design': 'تصميم وتشطيب',
      'smart_design_desc': 'تحديث التشطيبات لعرض أوضح للعقار.',
      'ai_concierge_desc': 'اسأل عن العقارات والحجوزات والخطوات التالية.',
      'free_price': 'مجانًا',
      'starts_from': 'يبدأ من',
      'account_and_privacy': 'الحساب والخصوصية',
      'edit_profile': 'تعديل الملف الشخصي',
      'digital_wallet': 'المحفظة الرقمية',
      'payment_methods': 'طرق الدفع',
      'properties_and_services': 'العقارات والخدمات',
      'investment_performance': 'الأداء',
      'active_properties': 'العقارات النشطة',
      'total_asset_value': 'إجمالي قيمة الأصول',
      'monthly_revenue': 'الإيراد الشهري',
      'annual_roi': 'العائد السنوي',
      'occupancy_rate': 'معدل الإشغال',
      'maintenance_costs': 'تكاليف الصيانة',
      'deposit': 'العربون',
      'remaining': 'المتبقي',
      'escrow': 'الضمان',
      'verified': 'موثّق',
      'safety_guide': 'دليل الأمان',
      'pay_with_card': 'بطاقة بنكية',
      'pay_with_wallet': 'محفظة إيجاري',
      'confirm_payment': 'تأكيد الدفع',
      'my_bookings': 'حجوزاتي',
      'continue_label': 'متابعة',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'region_egypt': 'مصر',
      'region_saudi': 'السعودية',
      'region_uae': 'الإمارات',
      'choose_region': 'اختر دولتك',
      'choose_region_hint':
          'الأسعار وقوائم العرض تتبع الدولة المحددة.',
      'trust_escrow_note':
          'يُحجز العربون في الضمان وفق قواعد التسليم.',
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
