/**
 * Localization Manager - Ejari Platform
 * Handles country selection, currency conversion, and language switching
 */

const LocalizationManager = {
    // Supported countries with their currencies and exchange rates
    countries: {
        'sa': {
            name: 'السعودية',
            nameEn: 'Saudi Arabia',
            currency: 'ر.س',
            currencyEn: 'SAR',
            exchangeRate: 1, // Base currency
            flag: '🇸🇦',
            locale: 'ar-SA'
        },
        'ae': {
            name: 'الإمارات',
            nameEn: 'UAE',
            currency: 'د.إ',
            currencyEn: 'AED',
            exchangeRate: 1.02, // 1 SAR = 1.02 AED
            flag: '🇦🇪',
            locale: 'ar-AE'
        },
        'eg': {
            name: 'مصر',
            nameEn: 'Egypt',
            currency: 'ج.م',
            currencyEn: 'EGP',
            exchangeRate: 12.5, // 1 SAR = 12.5 EGP
            flag: '🇪🇬',
            locale: 'ar-EG'
        }
    },

    // Translations
    translations: {
        ar: {
            // Navigation
            'home': 'الرئيسية',
            'properties': 'عقارات',
            'services': 'الخدمات',
            'partners': 'شركاء النجاح',
            'login': 'تسجيل دخول',
            'signup': 'إنشاء حساب',
            'dashboard': 'لوحة التحكم',
            'logout': 'تسجيل الخروج',

            // Common
            'welcome': 'مرحباً',
            'search': 'بحث',
            'filter': 'تصفية',
            'price': 'السعر',
            'location': 'الموقع',
            'submit': 'إرسال',
            'cancel': 'إلغاء',
            'save': 'حفظ',
            'edit': 'تعديل',
            'delete': 'حذف',
            'view': 'عرض',
            'download': 'تحميل',

            // Services
            'maintenance': 'الصيانة المنزلية',
            'moving': 'نقل العفش',
            'cleaning': 'خدمات التنظيف',
            'insurance': 'تأمين الوحدات',
            'rent_guarantee': 'ضمان دفع الإيجار',
            'contracts': 'العقود الإلكترونية',

            // Settings
            'select_country': 'اختر الدولة',
            'select_language': 'اختر اللغة',
            'settings': 'الإعدادات'
        },
        en: {
            // Navigation
            'home': 'Home',
            'properties': 'Properties',
            'services': 'Services',
            'partners': 'Partners',
            'login': 'Login',
            'signup': 'Sign Up',
            'dashboard': 'Dashboard',
            'logout': 'Logout',

            // Common
            'welcome': 'Welcome',
            'search': 'Search',
            'filter': 'Filter',
            'price': 'Price',
            'location': 'Location',
            'submit': 'Submit',
            'cancel': 'Cancel',
            'save': 'Save',
            'edit': 'Edit',
            'delete': 'Delete',
            'view': 'View',
            'download': 'Download',

            // Services
            'maintenance': 'Home Maintenance',
            'moving': 'Moving Services',
            'cleaning': 'Cleaning Services',
            'insurance': 'Property Insurance',
            'rent_guarantee': 'Rent Guarantee',
            'contracts': 'E-Contracts',

            // Settings
            'select_country': 'Select Country',
            'select_language': 'Select Language',
            'settings': 'Settings'
        }
    },

    // Initialize localization
    init: function () {
        // Load saved preferences or set defaults
        const savedCountry = localStorage.getItem('ejari_country') || 'sa';
        const savedLanguage = localStorage.getItem('ejari_language') || 'ar';

        // Apply language and direction immediately
        this.currentLanguage = savedLanguage;
        this.currentCountry = savedCountry;

        // Update HTML attributes
        document.documentElement.lang = savedLanguage;
        document.documentElement.dir = savedLanguage === 'ar' ? 'rtl' : 'ltr';

        // Update UI
        this.updateUI();

        // Apply auto-translation if needed and AutoTranslator is available
        if (savedLanguage === 'en' && typeof AutoTranslator !== 'undefined') {
            AutoTranslator.translatePage('en');
        }
    },

    // Set country and currency
    setCountry: function (countryCode) {
        if (this.countries[countryCode]) {
            localStorage.setItem('ejari_country', countryCode);
            this.currentCountry = countryCode;
            this.updatePrices();
        }
    },

    // Set language
    setLanguage: function (lang) {
        if (this.translations[lang]) {
            const currentLang = localStorage.getItem('ejari_language');

            // Always update storage and attributes
            localStorage.setItem('ejari_language', lang);
            this.currentLanguage = lang;

            // Update HTML lang and dir attributes immediately
            document.documentElement.lang = lang;
            document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';

            // Reload page if language actually changed
            if (currentLang && currentLang !== lang) {
                // Small delay to ensure storage is saved
                setTimeout(() => {
                    window.location.reload();
                }, 100);
            } else {
                this.updateTexts();
                // Apply auto-translation if AutoTranslator is available
                if (typeof AutoTranslator !== 'undefined') {
                    AutoTranslator.translatePage(lang);
                }
            }
        }
    },

    // Get current country
    getCurrentCountry: function () {
        return this.countries[this.currentCountry || 'sa'];
    },

    // Get current language
    getCurrentLanguage: function () {
        return this.currentLanguage || 'ar';
    },

    // Convert price to current currency
    convertPrice: function (priceInSAR) {
        const country = this.getCurrentCountry();
        return Math.round(priceInSAR * country.exchangeRate);
    },

    // Format price with currency
    formatPrice: function (priceInSAR) {
        const country = this.getCurrentCountry();
        const convertedPrice = this.convertPrice(priceInSAR);
        return convertedPrice.toLocaleString() + ' ' + country.currency;
    },

    // Get translation
    t: function (key) {
        const lang = this.getCurrentLanguage();
        return this.translations[lang][key] || key;
    },

    // Update all prices on the page
    updatePrices: function () {
        const priceElements = document.querySelectorAll('[data-price]');
        priceElements.forEach(element => {
            const basePrice = parseFloat(element.getAttribute('data-price'));
            element.textContent = this.formatPrice(basePrice);
        });
    },

    // Update all translatable texts
    updateTexts: function () {
        const textElements = document.querySelectorAll('[data-i18n]');
        textElements.forEach(element => {
            const key = element.getAttribute('data-i18n');
            element.textContent = this.t(key);
        });
    },

    // Update UI (country selector, language selector)
    updateUI: function () {
        this.updateCountrySelector();
        this.updateLanguageSelector();
        this.updatePrices();
        this.updateTexts();
    },

    // Update country selector dropdown
    updateCountrySelector: function () {
        const selector = document.getElementById('countrySelector');
        if (selector) {
            const country = this.getCurrentCountry();
            selector.innerHTML = `${country.flag} ${country.name}`;
        }
    },

    // Update language selector
    updateLanguageSelector: function () {
        const selector = document.getElementById('languageSelector');
        if (selector) {
            const lang = this.getCurrentLanguage();
            selector.innerHTML = lang === 'ar' ? '🇸🇦 العربية' : '🇬🇧 English';
        }
    },

    // Create settings dropdown HTML
    createSettingsDropdown: function () {
        const country = this.getCurrentCountry();
        const lang = this.getCurrentLanguage();

        return `
            <div class="settings-dropdown" id="settingsDropdown">
                <div class="dropdown-section">
                    <h4>${this.t('select_country')}</h4>
                    <div class="country-options">
                        ${Object.keys(this.countries).map(code => {
            const c = this.countries[code];
            const isActive = code === this.currentCountry ? 'active' : '';
            return `
                                <div class="country-option ${isActive}" onclick="LocalizationManager.setCountry('${code}'); LocalizationManager.updateUI();">
                                    <span class="flag">${c.flag}</span>
                                    <span class="name">${lang === 'ar' ? c.name : c.nameEn}</span>
                                    <span class="currency">${c.currency}</span>
                                </div>
                            `;
        }).join('')}
                    </div>
                </div>
                <div class="dropdown-section">
                    <h4>${this.t('select_language')}</h4>
                    <div class="language-options">
                        <div class="language-option ${lang === 'ar' ? 'active' : ''}" onclick="LocalizationManager.setLanguage('ar'); LocalizationManager.updateUI();">
                            🇸🇦 العربية
                        </div>
                        <div class="language-option ${lang === 'en' ? 'active' : ''}" onclick="LocalizationManager.setLanguage('en'); LocalizationManager.updateUI();">
                            🇬🇧 English
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    LocalizationManager.init();
});

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LocalizationManager;
}
