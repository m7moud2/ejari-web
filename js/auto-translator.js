/**
 * Auto Translation System - Ejari Platform
 * Automatically translates common UI elements without needing data-i18n attributes
 */

const AutoTranslator = {
    // Comprehensive translation dictionary
    dictionary: {
        // Navigation
        'الرئيسية': 'Home',
        'عقارات': 'Properties',
        'سيارات': 'Cars',
        'الخدمات': 'Services',
        'تواصل معنا': 'Contact Us',
        'شركاء النجاح': 'Success Partners',
        'تسجيل دخول': 'Login',
        'إنشاء حساب': 'Sign Up',
        'لوحة التحكم': 'Dashboard',
        'تسجيل الخروج': 'Logout',

        // Common buttons & actions
        'بحث': 'Search',
        'تصفية': 'Filter',
        'إرسال': 'Submit',
        'إلغاء': 'Cancel',
        'حفظ': 'Save',
        'تعديل': 'Edit',
        'حذف': 'Delete',
        'عرض': 'View',
        'تحميل': 'Download',
        'احجز الآن': 'Book Now',
        'اشترك الآن': 'Subscribe Now',
        'ابدأ مجاناً': 'Start Free',
        'المزيد': 'More',
        'عرض الكل': 'View All',
        'ابدأ التجربة': 'Start Trial',
        'تأكيد الحجز': 'Confirm Booking',
        'طلب عرض سعر': 'Request Quote',
        'حجز موعد صيانة': 'Book Maintenance',
        'احسب التكلفة': 'Calculate Cost',
        'حجز خدمة نظافة': 'Book Cleaning',
        'تواصل للمبيعات': 'Contact Sales',
        'إنشاء عقد الآن': 'Create Contract Now',

        // Services
        'الصيانة المنزلية': 'Home Maintenance',
        'الصيانة المنزلية الفورية': 'Instant Home Maintenance',
        'نقل العفش': 'Moving Services',
        'نقل العفش والأثاث': 'Furniture & Moving Services',
        'خدمات التنظيف': 'Cleaning Services',
        'خدمات التنظيف العميق': 'Deep Cleaning Services',
        'تأمين الوحدات': 'Property Insurance',
        'تأمين الوحدات السكنية': 'Residential Property Insurance',
        'ضمان دفع الإيجار': 'Rent Guarantee',
        'العقود الإلكترونية': 'E-Contracts',
        'العقود الإلكترونية الموثقة': 'Certified E-Contracts',

        // Property related
        'غرف نوم': 'Bedrooms',
        'حمامات': 'Bathrooms',
        'مساحة': 'Area',
        'السعر': 'Price',
        'الموقع': 'Location',
        'النوع': 'Type',
        'شقة': 'Apartment',
        'فيلا': 'Villa',
        'مكتب': 'Office',
        'محل تجاري': 'Shop',
        'استوديو': 'Studio',
        'متر مربع': 'sqm',
        'موقف سيارات': 'Parking',

        // Time periods
        'شهرياً': 'Monthly',
        'سنوياً': 'Yearly',
        'يومياً': 'Daily',
        'أسبوعياً': 'Weekly',
        'للعقد': 'per contract',
        'للفرع': 'per branch',

        // Status
        'متاح': 'Available',
        'مؤجر': 'Rented',
        'محجوز': 'Reserved',
        'قيد المراجعة': 'Under Review',
        'ساري': 'Active',
        'مكتمل': 'Completed',

        // Common phrases
        'مرحباً': 'Welcome',
        'اختر الدولة': 'Select Country',
        'اختر اللغة': 'Select Language',
        'الإعدادات': 'Settings',
        'جميع الحقوق محفوظة': 'All Rights Reserved',
        'روابط سريعة': 'Quick Links',
        'عن الموقع': 'About',
        'الشروط والأحكام': 'Terms & Conditions',
        'سياسة الخصوصية': 'Privacy Policy',
        'منصتك المتكاملة للبحث عن العقارات': 'Your Complete Platform for Property Search',
        'منصتك المتكاملة للبحث عن العقارات والخدمات': 'Your Complete Platform for Properties & Services',

        // Subscription plans
        'مجاني': 'Free',
        'ذهبي': 'Gold',
        'بريميوم': 'Premium',
        'الأساسية': 'Basic',
        'المتقدمة': 'Advanced',
        'المؤسسات': 'Enterprise',
        'للمستأجرين': 'For Tenants',
        'للشركات والملاك': 'For Companies & Owners',
        'للمكاتب الصغيرة': 'For Small Offices',
        'للشركات المتوسطة': 'For Medium Companies',
        'للشركات الكبرى وإدارة الأملاك': 'For Large Companies & Property Management',
        'اختر الباقة المناسبة لك': 'Choose the Right Plan for You',
        'مقارنة تفصيلية للباقات': 'Detailed Plan Comparison',
        'الأسئلة الشائعة': 'FAQ',
        'الميزة': 'Feature',
        'كل مميزات': 'All features of',
        'الباقة': 'Plan',
        'الباقة المجانية': 'Free Plan',
        'الباقة الذهبية': 'Gold Plan',
        'الباقة الشاملة': 'Comprehensive Plan',
        'مجاناً للأبد': 'Free Forever',
        'للبدء والتجربة': 'To Start & Try',
        'الأكثر شعبية': 'Most Popular',
        'للمحترفين': 'For Professionals',

        // Countries & Languages
        'السعودية': 'Saudi Arabia',
        'الإمارات': 'UAE',
        'مصر': 'Egypt',
        'العربية': 'Arabic',

        // Page titles & headers
        'أكثر من مجرد منصة تأجير': 'More Than Just a Rental Platform',
        'نظام عقاري رقمي متكامل (MLS)': 'Integrated Digital Real Estate System (MLS)',
        'باقات الاشتراك': 'Subscription Plans',
        'خدمات إيجاري - حلول متكاملة': 'Ejari Services - Complete Solutions',
        'شركاء نعتز بهم': 'Partners We\'re Proud Of',
        'نعمل مع كبرى الشركات لتقديم أفضل مستوى خدمة': 'We work with major companies to provide the best service',

        // Service descriptions
        'فنيون محترفون يصلونك أينما كنت': 'Professional technicians reach you wherever you are',
        'انتقل لمنزلك الجديد براحة بال': 'Move to your new home with peace of mind',
        'نظافة احترافية لمنزلك أو عقارك': 'Professional cleaning for your home or property',
        'احمِ ممتلكاتك من الأضرار والحوادث الطارئة': 'Protect your property from damage and emergencies',
        'استلم إيجارك في موعده حتى لو تأخر المستأجر': 'Receive your rent on time even if the tenant is late',
        'أنشئ عقد إيجار قانوني موثق يحفظ حقوق الطرفين': 'Create a certified legal rental contract that protects both parties\' rights',

        // Form labels
        'الاسم الكامل': 'Full Name',
        'رقم الهاتف': 'Phone Number',
        'البريد الإلكتروني': 'Email',
        'العنوان': 'Address',
        'نوع العقار': 'Property Type',
        'نوع الخدمة': 'Service Type',
        'وصف المشكلة': 'Problem Description',
        'الموعد المفضل': 'Preferred Date',
        'ملاحظات إضافية': 'Additional Notes',
        'مساحة العقار': 'Property Area',
        'الباقة المطلوبة': 'Required Plan',
        'اختر نوع العقار': 'Select Property Type',
        'اختر نوع الخدمة': 'Select Service Type',
        'اختر الباقة': 'Select Plan',

        // Pricing & features
        'تبدأ من': 'Starting from',
        'رسوم زيارة': 'Visit Fee',
        'خصم': 'Discount',
        'لعملاء إيجاري': 'for Ejari customers',
        'من قيمة الإيجار': 'of rent value',
        'تكلفة الخدمة': 'Service Cost',
        'التكلفة التقديرية': 'Estimated Cost',
        'الأسعار': 'Prices',
        'باقات التأمين': 'Insurance Packages',
        'احصل على عرض سعر مخصص': 'Get a Custom Quote',

        // Features & benefits
        'المميزات': 'Features',
        'المعلومات الأساسية': 'Basic Information',
        'المعلومات المالية': 'Financial Information',
        'معلومات المستأجر': 'Tenant Information',
        'سجل الصيانة': 'Maintenance History',
        'المستندات': 'Documents',
        'الخدمات القريبة': 'Nearby Services',
        'كل ما في الباقة': 'Everything in the',

        // Additional common terms
        'نماذج الشراكة المتاحة': 'Available Partnership Models',
        'الخدمات القانونية والمالية': 'Legal & Financial Services',
        'الخدمات التشغيلية': 'Operational Services',
        'شريك معتمد': 'Certified Partner',
        'جديد': 'New',
        'الأكثر طلباً': 'Most Requested',

        // Profile pages
        'الملف الشخصي': 'Profile',
        'المعلومات الشخصية': 'Personal Information',
        'المعلومات الأساسية': 'Basic Information',
        'حجوزاتي': 'My Bookings',
        'المفضلة': 'Favorites',
        'الأمان': 'Security',
        'معلومات الشركة': 'Company Information',
        'عقاراتي': 'My Properties',
        'الاشتراك': 'Subscription',
        'حفظ التغييرات': 'Save Changes',
        'تحديث كلمة المرور': 'Update Password',
        'تغيير كلمة المرور': 'Change Password',
        'كلمة المرور الحالية': 'Current Password',
        'كلمة المرور الجديدة': 'New Password',
        'تأكيد كلمة المرور الجديدة': 'Confirm New Password',
        'المصادقة الثنائية': 'Two-Factor Authentication',
        'تفعيل المصادقة الثنائية': 'Enable Two-Factor Authentication',
        'الاسم الأول': 'First Name',
        'الاسم الأخير': 'Last Name',
        'تاريخ الميلاد': 'Date of Birth',
        'الجنسية': 'Nationality',
        'سعودي': 'Saudi',
        'مصري': 'Egyptian',
        'إماراتي': 'Emirati',
        'أخرى': 'Other',
        'الحجوزات النشطة': 'Active Bookings',
        'الحجوزات المكتملة': 'Completed Bookings',
        'العقارات المفضلة': 'Favorite Properties',
        'التقييم': 'Rating',
        'نشط': 'Active',
        'قيد المراجعة': 'Under Review',
        'لا توجد عقارات في المفضلة حالياً': 'No favorite properties at the moment',
        'مستأجر': 'Tenant',
        'مالك / شركة عقارية': 'Owner / Real Estate Company',
        'عضو منذ': 'Member since',
        'باقة المؤسسات': 'Enterprise Plan',
        'نبذة عن الشركة': 'About the Company',
        'رقم السجل التجاري': 'Commercial Registration Number',
        'الرقم الضريبي': 'Tax Number',
        'عدد الفروع': 'Number of Branches',
        'اسم الشركة': 'Company Name',
        'العنوان الكامل': 'Full Address',
        'إجمالي العقارات': 'Total Properties',
        'عقارات مؤجرة': 'Rented Properties',
        'عقارات متاحة': 'Available Properties',
        'الإيرادات الشهرية': 'Monthly Revenue',
        'إضافة عقار جديد': 'Add New Property',
        'باقة الاشتراك الحالية': 'Current Subscription Plan',
        'تاريخ التجديد': 'Renewal Date',
        'عقارات غير محدودة': 'Unlimited Properties',
        'API متكامل': 'Integrated API',
        'دعم فني 24/7': '24/7 Technical Support',
        'مدير حساب خاص': 'Dedicated Account Manager',
        'تغيير الباقة': 'Change Plan',
        'قيد الصيانة': 'Under Maintenance',
        'حمام': 'Bathroom',
        'حمامات': 'Bathrooms',

        // Add Property Page
        'إضافة عقار جديد': 'Add New Property',
        'أضف عقارك وابدأ في استقبال طلبات الإيجار خلال دقائق': 'List your property and start receiving rental requests in minutes',
        'عنوان الإعلان': 'Listing Title',
        'مثال: شقة فاخرة للإيجار في حي النرجس': 'Ex: Luxury Apartment for Rent in Al-Narjis',
        'الغرض': 'Purpose',
        'لإيجار': 'For Rent',
        'للبيع': 'For Sale',
        'وصف العقار': 'Property Description',
        'اكتب وصفاً تفصيلياً للعقار ومميزاته...': 'Write a detailed description of the property and its features...',
        'العنوان التفصيلي': 'Detailed Address',
        'اسم الشارع، رقم المبنى...': 'Street Name, Building Number...',
        'الدور': 'Floor',
        'عمر العقار (سنة)': 'Property Age (Years)',
        'التشطيب': 'Finishing',
        'سوبر لوكس': 'Super Lux',
        'لوكس': 'Lux',
        'نصف تشطيب': 'Semi Finished',
        'المميزات والخدمات': 'Amenities & Services',
        'واي فاي': 'WiFi',
        'مصعد': 'Elevator',
        'مسبح': 'Swimming Pool',
        'نادي رياضي': 'Gym',
        'أمن وحراسة': 'Security',
        'تكييف مركزي': 'Central AC',
        'مفروش': 'Furnished',
        'الصور والفيديو': 'Photos & Video',
        'اضغط هنا لرفع الصور أو اسحبها وأفلتها': 'Click here to upload photos or drag and drop',
        'يمكنك رفع حتى 10 صور (JPG, PNG) بحد أقصى 5MB للصورة': 'You can upload up to 10 photos (JPG, PNG) max 5MB per image',
        'السعر وشروط الدفع': 'Price & Payment Terms',
        'السعر المطلوب': 'Asking Price',
        'دورية الدفع': 'Payment Frequency',
        'ربع سنوي': 'Quarterly',
        'نصف سنوي': 'Semi-Annually',
        'مبلغ التأمين': 'Security Deposit',
        'نشر العقار': 'Publish Property',
        'جاري النشر...': 'Publishing...',

        // Legal Pages
        'الشروط والأحكام': 'Terms & Conditions',
        'سياسة الخصوصية': 'Privacy Policy',
        'يرجى قراءة شروط الاستخدام بعناية قبل استخدام منصة إيجاري': 'Please read the terms of use carefully before using Ejari platform',
        'مقدمة': 'Introduction',
        'حقوق الملكية الفكرية': 'Intellectual Property Rights',
        'شروط الاستخدام': 'Terms of Use',
        'الحسابات والتسجيل': 'Accounts & Registration',
        'المحتوى المقدم من المستخدمين': 'User Generated Content',
        'إخلاء المسؤولية': 'Disclaimer',
        'التعديلات': 'Amendments',
        'آخر تحديث': 'Last Updated',
        'المعلومات التي نجمعها': 'Information We Collect',
        'استخدام معلوماتك الشخصية': 'Using Your Personal Information',
        'الكشف عن المعلومات الشخصية': 'Disclosing Personal Information',
        'أمن بياناتك الشخصية': 'Security of Your Personal Information',
        'حقوقك': 'Your Rights',
        'ملفات تعريف الارتباط (Cookies)': 'Cookies',

        // Success & 404 Pages
        'تمت العملية بنجاح!': 'Operation Successful!',
        'شكراً لك، تم استلام طلبك بنجاح. سنقوم بمراجعته والتواصل معك في أقرب وقت ممكن.': 'Thank you, your request has been received successfully. We will review it and contact you as soon as possible.',
        'رقم الطلب': 'Order Number',
        'التاريخ': 'Date',
        'الحالة': 'Status',
        'العودة للرئيسية': 'Back to Home',
        'عذراً، الصفحة غير موجودة': 'Sorry, Page Not Found',
        'يبدو أن الصفحة التي تبحث عنها قد تم نقلها أو حذفها أو أن الرابط غير صحيح. لا تقلق، يمكنك العودة للصفحة الرئيسية.': 'The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.',

        // About Page
        'من نحن': 'About Us',
        'نحن نعيد تعريف تجربة الإيجار وإدارة العقارات في الشرق الأوسط': 'We are redefining the rental and property management experience in the Middle East',
        'رؤيتنا': 'Our Vision',
        'نسعى لأن نكون المنصة العقارية الأولى في المنطقة': 'We aim to be the leading real estate platform in the region',
        'قيمنا': 'Our Values',
        'الأمان والموثوقية': 'Security & Reliability',
        'الابتكار': 'Innovation',
        'الشفافية': 'Transparency',
        'مستخدم نشط': 'Active User',
        'عملية ناجحة': 'Successful Transaction',

        // Forgot Password
        'استعادة كلمة المرور': 'Reset Password',
        'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور الخاصة بك.': 'Enter your email and we will send you a link to reset your password.',
        'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني. يرجى التحقق من صندوق الوارد.': 'Reset link has been sent to your email. Please check your inbox.',
        'إرسال الرابط': 'Send Link',
        'العودة لتسجيل الدخول': 'Back to Login',

        // Payment Page
        'الدفع الآمن': 'Secure Payment',
        'جميع المعاملات مشفرة ومحمية بتقنية SSL 256-bit': 'All transactions are encrypted and secured with SSL 256-bit',
        'بطاقة بنكية': 'Credit Card',
        'محفظة إلكترونية': 'E-Wallet',
        'الاسم على البطاقة': 'Name on Card',
        'رقم البطاقة': 'Card Number',
        'تاريخ الانتهاء': 'Expiry Date',
        'رمز الأمان (CVC)': 'Security Code (CVC)',
        'رقم المحفظة': 'Wallet Number',
        'سيتم إرسال طلب دفع إلى محفظتك. يرجى تأكيد الدفع من التطبيق.': 'A payment request will be sent to your wallet. Please confirm payment from the app.',
        'عنوان الدفع (IPA)': 'Payment Address (IPA)',
        'أسرع طريقة للدفع. سيصلك إشعار فوري على تطبيق InstaPay.': 'Fastest way to pay. You will receive an instant notification on InstaPay app.',
        'دفع الآن': 'Pay Now',
        'ملخص الطلب': 'Order Summary',
        'العنصر': 'Item',
        'السعر الأساسي': 'Base Price',
        'رسوم الخدمة': 'Service Fees',
        'الإجمالي': 'Total',
        'بضغطك على "دفع الآن" أنت توافق على شروط الاستخدام وسياسة الخصوصية.': 'By clicking "Pay Now" you agree to the Terms of Use and Privacy Policy.',
        'جاري المعالجة...': 'Processing...',
        'جاري التحميل...': 'Loading...',

        // Property Details Page
        'تفاصيل العقار': 'Property Details',
        'العودة للعقارات': 'Back to Properties',
        'متاح للإيجار': 'Available for Rent',
        'احجز الآن': 'Book Now',
        'تواصل مع المالك': 'Contact Owner',
        'إضافة للمفضلة': 'Add to Favorites',
        'مشاركة': 'Share',
        'الوصف': 'Description',
        'شقة فاخرة للإيجار في أرقى أحياء المعادي. تتميز الشقة بتشطيب سوبر لوكس وإطلالة رائعة على النيل. قريبة من جميع الخدمات والمواصلات. العمارة حديثة وبها مدخل فندقي وأمن وحراسة على مدار الساعة.': 'Luxury apartment for rent in the finest districts of Maadi. The apartment features super lux finishing and a wonderful Nile view. Close to all services and transportation. The building is modern with a hotel entrance and 24-hour security.',
        'تفاصيل السعر': 'Price Details',
        'رسوم المكتب': 'Agency Fees',
        'إجمالي الدفعة الأولى': 'Total First Payment',
        'خريطة الموقع (Google Maps)': 'Location Map (Google Maps)',
        'معلومات المالك': 'Owner Information',
        'مالك عقار موثوق': 'Verified Property Owner',
        'إرسال رسالة': 'Send Message',

        // Car Details Page
        'تفاصيل السيارة': 'Car Details',
        'العودة للسيارات': 'Back to Cars',
        'مواصفات السيارة': 'Car Specifications',
        'الموديل': 'Model',
        'ناقل الحركة': 'Transmission',
        'الوقود': 'Fuel',
        'كم/س': 'km/h',
        'بنزين': 'Petrol',
        'أوتوماتيك': 'Automatic',
        'المميزات الإضافية': 'Additional Features',
        'تأمين شامل': 'Comprehensive Insurance',
        'نظام ملاحة GPS': 'GPS Navigation',
        'مقاعد جلدية': 'Leather Seats',
        'كاميرا خلفية': 'Rear Camera',
        'بلوتوث و USB': 'Bluetooth & USB',
        'مثبت سرعة': 'Cruise Control',
        'استمتع بتجربة قيادة فاخرة مع مرسيدس C200 موديل 2024. السيارة تجمع بين الأناقة والأداء القوي. مثالية للمناسبات الخاصة ورحلات العمل. تأتي مع سائق محترف عند الطلب.': 'Enjoy a luxury driving experience with the 2024 Mercedes C200. The car combines elegance with powerful performance. Perfect for special occasions and business trips. Comes with a professional driver upon request.',
        'تفاصيل الإيجار': 'Rental Details',
        'السعر اليومي': 'Daily Rate',
        'السعر الأسبوعي (خصم 10%)': 'Weekly Rate (10% OFF)',
        'التأمين المسترد': 'Refundable Deposit',
        'الحد الأقصى للكيلومترات': 'Mileage Limit',
        '250 كم / يوم': '250 km / day',
        'إجمالي اليوم الواحد': 'Total Per Day',
        'موقع الاستلام': 'Pickup Location',
        'مكتب التأجير': 'Rental Agency',
        'تواصل مع المكتب': 'Contact Agency',
        'دفع آمن': 'Secure Pay',
        'الضرائب والرسوم': 'Taxes & Fees',
        'الخصم': 'Discount',
    },

    // Translate text
    translate: function (text, toLang) {
        if (toLang === 'ar') {
            // Reverse lookup for Arabic
            for (let [ar, en] of Object.entries(this.dictionary)) {
                if (en === text) return ar;
            }
            return text;
        } else if (toLang === 'en') {
            return this.dictionary[text] || text;
        }
        return text;
    },

    // Auto-translate all text nodes in the page
    translatePage: function (toLang) {
        if (toLang === 'ar') return; // Skip if already Arabic

        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function (node) {
                    // Skip script and style tags
                    if (node.parentElement.tagName === 'SCRIPT' ||
                        node.parentElement.tagName === 'STYLE') {
                        return NodeFilter.FILTER_REJECT;
                    }
                    // Only process nodes with actual text content
                    if (node.textContent.trim().length > 0) {
                        return NodeFilter.FILTER_ACCEPT;
                    }
                    return NodeFilter.FILTER_REJECT;
                }
            }
        );

        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            textNodes.push(node);
        }

        // Translate each text node
        textNodes.forEach(textNode => {
            const originalText = textNode.textContent.trim();
            if (originalText) {
                const translated = this.translate(originalText, toLang);
                if (translated !== originalText) {
                    textNode.textContent = textNode.textContent.replace(originalText, translated);
                }
            }
        });

        // Also translate placeholder attributes
        document.querySelectorAll('[placeholder]').forEach(element => {
            const placeholder = element.getAttribute('placeholder');
            const translated = this.translate(placeholder, toLang);
            if (translated !== placeholder) {
                element.setAttribute('placeholder', translated);
            }
        });

        // Translate title attributes
        document.querySelectorAll('[title]').forEach(element => {
            const title = element.getAttribute('title');
            const translated = this.translate(title, toLang);
            if (translated !== title) {
                element.setAttribute('title', translated);
            }
        });

        // Translate aria-label attributes
        document.querySelectorAll('[aria-label]').forEach(element => {
            const label = element.getAttribute('aria-label');
            const translated = this.translate(label, toLang);
            if (translated !== label) {
                element.setAttribute('aria-label', translated);
            }
        });
    }
};

// Export for use in localization.js
if (typeof window !== 'undefined') {
    window.AutoTranslator = AutoTranslator;
}
