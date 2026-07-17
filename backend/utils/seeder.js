// utils/seeder.js

const User = require('../models/User');
const Property = require('../models/Property');

const seedData = async () => {
    try {
        // تنظيف العقارات القديمة لإعادة التهيئة بالهوية الجديدة (إيجاري EJARI)
        await Property.deleteMany({});
        console.log('تم تنظيف قاعدة البيانات لتهيئة الهوية الجديدة إيجاري...');

        console.log('بدء عملية بذر البيانات الافتراضية...');

        // التحقق من وجود حساب المدير الافتراضي أو إنشائه
        let adminUser = await User.findOne({ email: 'admin@ejari.app' });
        if (!adminUser) {
            adminUser = await User.create({
                name: 'مدير النظام التنفيذي',
                email: 'admin@ejari.app',
                password: 'admin123',
                phone: '01234567890',
                address: 'القاهرة، مصر',
                role: 'admin',
                isVerified: true
            });
            console.log('تم إنشاء حساب المدير الافتراضي: admin@ejari.app / admin123');
        }

        const defaultProperties = [

            // ===== 🏢 شقق إيجاري (Ejari Apartments) =====
            {
                title: 'شقة فاخرة منطقة الفلل — إطلالة نيلية',
                description: 'شقة نخبويّة فاخرة ومفروشة بالكامل تطل على النيل مباشرة في أرقى مناطق الفلل. تشطيب ألترامودرن مع تكييف مركزي وأمن وحراسة على مدار الساعة. مناسبة للعائلات والمديرين التنفيذيين.',
                type: 'apartment',
                status: 'available',
                price: 9000,
                location: { address: 'منطقة الفلل، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2357, 30.0444] } },
                features: { bedrooms: 3, bathrooms: 2, area: 180, furnished: true, airCondition: true, parking: true, elevator: true },
                amenities: ['تكييف مركزى', 'أمن 24/7', 'أسانسير', 'إطلالة نيلية', 'حارس أمن'],
                images: ['assets/images/home1.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة تشطيب ألترا مودرن — فريد ندا',
                description: 'شقة سكنية ممتازة غير مفروشة بموقع حيوي في شارع فريد ندا الرئيسي. متوفر بها غاز طبيعي وتشطيب سوبر لوكس مع أسانسير. الطابق الثالث بإطلالة هادئة على الشارع.',
                type: 'apartment',
                status: 'available',
                price: 6500,
                location: { address: 'شارع فريد ندا، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2457, 30.0544] } },
                features: { bedrooms: 2, bathrooms: 1, area: 150, furnished: false, airCondition: false, parking: false, elevator: true },
                amenities: ['تشطيب سوبر لوكس', 'غاز طبيعي', 'أسانسير'],
                images: ['assets/images/home2.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة دور أرضي — المنشية',
                description: 'شقة سكنية دور أرضي للإيجار في منطقة المنشية الحيوية. غاز طبيعي وعداد كهرباء قديم بسعر مناسب جداً. مناسبة للعائلات الصغيرة والعزاب.',
                type: 'apartment',
                status: 'available',
                price: 2500,
                location: { address: 'المنشية، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2157, 30.0244] } },
                features: { bedrooms: 2, bathrooms: 1, area: 110, furnished: false, airCondition: false, parking: false, elevator: false },
                amenities: ['عداد كهرباء قديم', 'غاز طبيعي'],
                images: ['assets/images/home7.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة لقطة 200م — بطا',
                description: 'شقة للإيجار لقطة بمساحة كبيرة 200 متر في منطقة بطا الهادئة. إطلالة جانبية على مجرى النيل وهدوء تام وسعر ممتاز. فرصة نادرة في المنطقة.',
                type: 'apartment',
                status: 'available',
                price: 3000,
                location: { address: 'بطا، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2057, 30.0144] } },
                features: { bedrooms: 3, bathrooms: 2, area: 200, furnished: false, airCondition: false, parking: false, elevator: false },
                amenities: ['إطلالة نيلية هادئة', 'هدوء تام'],
                images: ['assets/images/home1.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة ريفية مريحة — الرملة',
                description: 'شقة ريفية بسيطة ومريحة في منطقة الرملة الهادئة بعيداً عن الضوضاء. إيجار منخفض جداً ومناسب للشباب والعائلات الصغيرة التي تبحث عن مسكن بجودة حياة عالية.',
                type: 'apartment',
                status: 'available',
                price: 1200,
                location: { address: 'الرملة، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.1957, 30.0044] } },
                features: { bedrooms: 2, bathrooms: 1, area: 90, furnished: false, airCondition: false, parking: false, elevator: false },
                amenities: ['هدوء تام', 'قريب من المواصلات'],
                images: ['assets/images/home5.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة بنتهاوس — مجمع النخبة',
                description: 'بنتهاوس فخم بمساحة 280 متر مطل على المدينة بالكامل. سطح خاص وحمام جاكوزي وغرفة ملابس مستقلة. تشطيب بمواد إيطالية فاخرة. المثالية للتنفيذيين.',
                type: 'apartment',
                status: 'available',
                price: 18000,
                location: { address: 'مجمع النخبة، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2600, 30.0600] } },
                features: { bedrooms: 4, bathrooms: 3, area: 280, furnished: true, airCondition: true, parking: true, elevator: true },
                amenities: ['سطح خاص', 'جاكوزي', 'تكييف مركزي', 'جراج مخصص', 'أمن 24/7'],
                images: ['assets/images/home2.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة كومباوند مسورة — إيجاري فيو',
                description: 'شقة داخل كومباوند مسور متكامل الخدمات بنظام أمن ذكي. صالة رياضية وحمام سباحة مشترك ومولد كهرباء دائم. الأفضل للعائلات التي تبحث عن الأمان والراحة.',
                type: 'apartment',
                status: 'available',
                price: 8500,
                location: { address: 'إيجاري فيو كومباوند', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2500, 30.0500] } },
                features: { bedrooms: 3, bathrooms: 2, area: 160, furnished: false, airCondition: true, parking: true, elevator: true },
                amenities: ['حمام سباحة', 'جيم', 'مولد كهرباء', 'أمن ذكي', 'حديقة'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },

            // ===== 🏡 فلل وقصور (Villas & Palaces) =====
            {
                title: 'فيلا مستقلة للبيع — منطقة الفلل',
                description: 'فيلا مستقلة فاخرة وراقية جداً للبيع مع حمام سباحة خاص وحديقة واسعة خضراء وأمن على مدار الساعة. 5 غرف نوم مع جلسة خارجية وبرجولا. استثمار نادر.',
                type: 'villa',
                status: 'available',
                price: 3900000,
                location: { address: 'الفلل، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2357, 30.0444] } },
                features: { bedrooms: 5, bathrooms: 4, area: 300, furnished: false, airCondition: true, parking: true, elevator: false },
                amenities: ['حمام سباحة', 'حديقة', 'أمن', 'جلسة خارجية'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },
            {
                title: 'فيلا تاون هاوس للإيجار — إيجاري جاردنز',
                description: 'تاون هاوس أنيق من 3 طوابق في مجمع إيجاري جاردنز الراقي. حديقة خاصة أمامية وخلفية مع جراجين. أنظمة منزل ذكي وكاميرات مراقبة. مثالية للعائلات الكبيرة.',
                type: 'villa',
                status: 'available',
                price: 22000,
                location: { address: 'إيجاري جاردنز', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2700, 30.0700] } },
                features: { bedrooms: 4, bathrooms: 3, area: 250, furnished: true, airCondition: true, parking: true, elevator: false },
                amenities: ['حديقة خاصة', 'منزل ذكي', 'جراجين', 'كاميرات'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },
            {
                title: 'قصر للبيع — ضفة النيل',
                description: 'قصر استثنائي يطل مباشرة على النيل بمساحة 600 متر على مساحة 2 فدان. 7 غرف نوم و6 حمامات وحمامان للسباحة وملعب تنس. فرصة استثمارية القرن.',
                type: 'villa',
                status: 'available',
                price: 15000000,
                location: { address: 'ضفة النيل، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2300, 30.0400] } },
                features: { bedrooms: 7, bathrooms: 6, area: 600, furnished: true, airCondition: true, parking: true, elevator: true },
                amenities: ['إطلالة نيلية', 'حمام سباحة مزدوج', 'ملعب تنس', 'مصعد', 'أمن متكامل'],
                images: ['assets/images/home1.jpg'],
                owner: adminUser._id
            },

            // ===== 🎓 إسكان طلاب (Student Housing) =====
            {
                title: 'استوديو طالبات — بجوار كلية الطب',
                description: 'استوديو أنيق ومفروش بالكامل ومخصص للطالبات يقع مباشرة بجوار كلية الطب وجامعة بنها. إنترنت فائق السرعة وأمن وحراسة نسائية متخصصة.',
                type: 'apartment',
                status: 'available',
                price: 3500,
                location: { address: 'بجوار كلية طب، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2557, 30.0644] } },
                features: { bedrooms: 1, bathrooms: 1, area: 65, furnished: true, airCondition: false, parking: false, elevator: false },
                amenities: ['إنترنت فائق', 'أمن نسائي', 'قريب من الجامعة', 'مفروش كامل'],
                images: ['assets/images/home1.jpg'],
                owner: adminUser._id
            },
            {
                title: 'غرفة مشتركة للطلاب — شارع الجامعة',
                description: 'غرفة شبه خاصة مشتركة بين طالبين في شقة نظيفة على شارع الجامعة مباشرة. إنترنت ومطبخ مشترك ومصروف الماء والكهرباء ادخل في الإيجار.',
                type: 'apartment',
                status: 'available',
                price: 1800,
                location: { address: 'شارع الجامعة، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2580, 30.0620] } },
                features: { bedrooms: 1, bathrooms: 1, area: 35, furnished: true, airCondition: false, parking: false, elevator: false },
                amenities: ['إنترنت', 'مطبخ مشترك', 'ماء وكهرباء شامل'],
                images: ['assets/images/home5.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة طلابية كاملة — المدينة الجامعية',
                description: 'شقة 3 غرف مفروشة تتسع لـ 3 طلاب بشكل مريح في المدينة الجامعية. غسالة وثلاجة وأوان مطبخ متكاملة. بعيدة عن الضوضاء وقريبة من المواصلات.',
                type: 'apartment',
                status: 'available',
                price: 4500,
                location: { address: 'المدينة الجامعية، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2560, 30.0680] } },
                features: { bedrooms: 3, bathrooms: 1, area: 120, furnished: true, airCondition: false, parking: false, elevator: true },
                amenities: ['غسالة', 'ثلاجة', 'إنترنت', 'قريبة جامعة'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },

            // ===== 🏢 مكاتب ومحلات تجارية (Commercial) =====
            {
                title: 'محل تجاري — إيجاري الجديدة',
                description: 'مكتب أو محل تجاري مميز للإيجار في إيجاري الجديدة بمساحة 80 متر وواجهة زجاجية بانورامية وتكييف مركزي. يصلح للمطاعم والمكاتب والصيدليات.',
                type: 'office',
                status: 'available',
                price: 12000,
                location: { address: 'إيجاري الجديدة، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2657, 30.0744] } },
                features: { bedrooms: 0, bathrooms: 1, area: 80, furnished: false, airCondition: true, parking: false, elevator: false },
                amenities: ['واجهة زجاجية', 'تكييف مركزي'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },
            {
                title: 'مكتب إداري راقي — برج الأعمال',
                description: 'مكتب إداري فاخر بمساحة 120 متر في برج الأعمال مطل على شارع النيل. يشمل غرفة اجتماعات خاصة وسكرتارية وصالة استقبال. جاهز للتشغيل الفوري.',
                type: 'office',
                status: 'available',
                price: 25000,
                location: { address: 'برج الأعمال، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2680, 30.0760] } },
                features: { bedrooms: 0, bathrooms: 2, area: 120, furnished: true, airCondition: true, parking: true, elevator: true },
                amenities: ['قاعة اجتماعات', 'استقبال', 'جراج', 'إنترنت', 'أمن 24/7'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },
            {
                title: 'محل تجاري أرضي — الشارع الرئيسي',
                description: 'محل تجاري دور أرضي على الشارع الرئيسي مباشرة بمساحة 45 متر وواجهة عريضة 6 متر. مرور يومي عالي جداً. مناسب للبقالات والصيدليات والبوتيكات.',
                type: 'office',
                status: 'available',
                price: 8000,
                location: { address: 'الشارع الرئيسي، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2630, 30.0720] } },
                features: { bedrooms: 0, bathrooms: 1, area: 45, furnished: false, airCondition: false, parking: false, elevator: false },
                amenities: ['واجهة عريضة', 'مرور عالي', 'شارع رئيسي'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },
            {
                title: 'وحدة إدارية — مجمع إيجاري بيزنس',
                description: 'وحدة إدارية مطورة في مجمع إيجاري بيزنس المتكامل. خدمة إنترنت مدمجة وغرفة خوادم وأنظمة تكييف ذكية. مناسب للشركات التقنية والاستشارية.',
                type: 'office',
                status: 'available',
                price: 18000,
                location: { address: 'إيجاري بيزنس بارك', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2720, 30.0800] } },
                features: { bedrooms: 0, bathrooms: 2, area: 200, furnished: false, airCondition: true, parking: true, elevator: true },
                amenities: ['إنترنت مدمج', 'تكييف ذكي', 'صالة مؤتمرات', 'كافيتيريا'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },

            // ===== 🏨 إقامة فندقية وشاليهات (Hotel & Chalet) =====
            {
                title: 'شاليه نيلي بالشاطئ الخاص — سيدي كرير',
                description: 'شاليه فاخر مطل على النيل بشاطئ رملي خاص. يتسع لـ 8 أشخاص مع مطبخ مجهز كامل وتكييف ووايفاي سريع. مثالي لإجازات نهاية الأسبوع وتجمعات الأصدقاء.',
                type: 'chalet',
                status: 'available',
                price: 15000,
                location: { address: 'سيدي كرير، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.1800, 29.9800] } },
                features: { bedrooms: 4, bathrooms: 2, area: 200, furnished: true, airCondition: true, parking: true, elevator: false },
                amenities: ['شاطئ خاص', 'إطلالة نيلية', 'مطبخ كامل', 'واي فاي'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },
            {
                title: 'جناح فندقي بالخدمات — فندق إيجاري بالاس',
                description: 'جناح فندقي متكامل بخدمة الغرف 24 ساعة ومطعم وصالة لياقة وحمام سباحة دافئ. يشمل الإفطار اليومي والتنظيف اليومي. مناسب للإقامة طويلة الأمد.',
                type: 'hotel',
                status: 'available',
                price: 6000,
                location: { address: 'فندق إيجاري بالاس', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2400, 30.0500] } },
                features: { bedrooms: 1, bathrooms: 1, area: 55, furnished: true, airCondition: true, parking: true, elevator: true },
                amenities: ['خدمة غرف', 'إفطار يومي', 'حمام سباحة', 'جيم', 'تنظيف يومي'],
                images: ['assets/images/home2.jpg'],
                owner: adminUser._id
            },

            // ===== 🏘️ منازل ومساكن كاملة (Houses) =====
            {
                title: 'منزل كامل للإيجار — كفر الجزار',
                description: 'بيت كامل مستقل للإيجار في كفر الجزار بموقع هادئ جداً ومريح مع حديقة خاصة كبيرة. ممتاز جداً للعائلات الكبيرة والذين يبحثون عن مساحة وخصوصية.',
                type: 'house',
                status: 'available',
                price: 5000,
                location: { address: 'كفر الجزار، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2257, 30.0344] } },
                features: { bedrooms: 4, bathrooms: 2, area: 220, furnished: false, airCondition: false, parking: true, elevator: false },
                amenities: ['حديقة خاصة', 'قريب من المواصلات', 'مستقل'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },
            {
                title: 'دوبلكس عائلي — حي الياسمين',
                description: 'دوبلكس فاخر على طابقين في حي الياسمين الراقي. 5 غرف نوم مع صالتين وحديقة صغيرة أمامية. تشطيب مودرن وكلاد حجري من الخارج. للإيجار السنوي.',
                type: 'house',
                status: 'available',
                price: 14000,
                location: { address: 'حي الياسمين، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2450, 30.0550] } },
                features: { bedrooms: 5, bathrooms: 3, area: 300, furnished: false, airCondition: true, parking: true, elevator: false },
                amenities: ['حديقة أمامية', 'جراج', 'تشطيب مودرن', 'طابقين'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },

            // ===== 💰 للبيع - تمليك (For Sale) =====
            {
                title: 'شقة تمليك 160م — شارع الإشارة',
                description: 'شقة تمليك ممتازة للبيع بمساحة 160 متر في شارع الإشارة الراقي. تشطيب الترا سوبر لوكس مع أسانسير وجراج خاص. الطابق الخامس بإطلالة بانورامية. سعر قابل للتفاوض.',
                type: 'apartment',
                status: 'available',
                price: 2200000,
                location: { address: 'الإشارة، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2457, 30.0544] } },
                features: { bedrooms: 3, bathrooms: 2, area: 160, furnished: false, airCondition: false, parking: true, elevator: true },
                amenities: ['أسانسير', 'جراج', 'سوبر لوكس'],
                images: ['assets/images/home2.jpg'],
                owner: adminUser._id
            },
            {
                title: 'شقة تمليك 90م — حي الهنا',
                description: 'شقة تمليك صغيرة ومتميزة في حي الهنا السكني. مناسبة للشباب المقبلين على الزواج والمستثمرين. سعر تنافسي جداً وتسليم فوري.',
                type: 'apartment',
                status: 'available',
                price: 950000,
                location: { address: 'حي الهنا، إيجاري', city: 'القليوبية', coordinates: { type: 'Point', coordinates: [31.2300, 30.0350] } },
                features: { bedrooms: 2, bathrooms: 1, area: 90, furnished: false, airCondition: false, parking: false, elevator: true },
                amenities: ['تسليم فوري', 'أسانسير'],
                images: ['assets/images/home5.jpg'],
                owner: adminUser._id
            },
            {
                title: 'أرض للبيع — المنطقة الصناعية',
                description: 'قطعة أرض 500 متر في المنطقة الصناعية بإيجاري مع توصيلات كاملة (كهرباء - غاز - مياه). رخصة بناء جاهزة. مثالية للمصانع الصغيرة والمخازن.',
                type: 'land',
                status: 'available',
                price: 1800000,
                location: { address: 'المنطقة الصناعية، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2800, 30.0900] } },
                features: { bedrooms: 0, bathrooms: 0, area: 500, furnished: false, airCondition: false, parking: true, elevator: false },
                amenities: ['توصيلات كاملة', 'رخصة جاهزة', 'واجهة عريضة'],
                images: ['assets/images/home4.jpg'],
                owner: adminUser._id
            },
            {
                title: 'فيلا تمليك مودرن — هايد بارك',
                description: 'فيلا عصرية للبيع في مشروع هايد بارك المتكامل. حمام سباحة خاص وجراجين وحديقة منسقة. نظام تدفئة وتبريد مركزي. ضمان المطور 10 سنوات.',
                type: 'villa',
                status: 'available',
                price: 8500000,
                location: { address: 'هايد بارك، إيجاري', city: 'القاهرة', coordinates: { type: 'Point', coordinates: [31.2750, 30.0650] } },
                features: { bedrooms: 5, bathrooms: 4, area: 380, furnished: false, airCondition: true, parking: true, elevator: false },
                amenities: ['حمام سباحة', 'جراجين', 'حديقة منسقة', 'ضمان 10 سنوات'],
                images: ['assets/images/home3.jpg'],
                owner: adminUser._id
            },
        ];

        await Property.insertMany(defaultProperties);
        console.log(`✅ تم بذر ${defaultProperties.length} عقار بنجاح 💎`);

    } catch (error) {
        console.error('حدث خطأ أثناء بذر البيانات الافتراضية:', error);
    }
};

module.exports = seedData;
