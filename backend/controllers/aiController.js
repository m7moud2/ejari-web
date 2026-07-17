// controllers/aiController.js

const { GoogleGenerativeAI } = require('@google/generative-ai');
const Property = require('../models/Property');

// @desc      المحادثة مع مساعد كونسيرج الذكي وتوصية العقارات
// @route     POST /api/ai/chat
// @access    Public
exports.getChatResponse = async (req, res, next) => {
    try {
        const { message } = req.body;
        if (!message) {
            return res.status(400).json({ success: false, error: 'الرجاء إدخال رسالة' });
        }

        // 1. جلب العقارات المتاحة من قاعدة البيانات
        const availableProperties = await Property.find({ status: 'available' });

        // 2. التحقق من وجود مفتاح Gemini ومحاولة استدعائه
        const apiKey = process.env.GEMINI_API_KEY;
        if (apiKey && apiKey !== 'your_gemini_api_key_here' && apiKey.trim() !== '') {
            try {
                const genAI = new GoogleGenerativeAI(apiKey);
                const model = genAI.getGenerativeModel({ 
                    model: 'gemini-1.5-flash',
                    generationConfig: {
                        responseMimeType: 'application/json'
                    }
                });

                // تنسيق العقارات لتمريرها للنموذج كـ Context
                const propertiesList = availableProperties.map(p => ({
                    id: p._id.toString(),
                    title: p.title,
                    description: p.description,
                    type: p.type,
                    price: p.price,
                    address: p.location?.address || '',
                    city: p.location?.city || '',
                    bedrooms: p.features?.bedrooms || 0,
                    bathrooms: p.features?.bathrooms || 0,
                    area: p.features?.area || 0,
                    furnished: p.features?.furnished || false,
                    amenities: p.amenities || []
                }));

                const systemInstruction = `
أنت المساعد الذكي النخبوّي لمنصة "إيجاري إيليت" (Ejari Elite) للخدمات العقارية الفاخرة في مصر.
مهمتك هي الإجابة عن استفسارات المستخدمين ومساعدتهم في إيجاد العقار المثالي بأرقى الأساليب.
تحدث باللغة العربية الفصحى الراقية مع لمسة ودية ولطيفة تناسب النخبة، واستخدم الرموز التعبيرية (Emojis) الفاخرة مثل 💎, ✨, 🏠, 📍, 💼.

قائمة العقارات المتاحة حالياً في النظام:
${JSON.stringify(propertiesList, null, 2)}

التعليمات:
1. قم بتحليل رسالة المستخدم وتفضيلاته (السعر، الغرف، الموقع، الفرش، النوع: apartment أو villa أو house).
2. اختر العقارات الأكثر مطابقةً لطلبه من القائمة المتاحة أعلاه وضع معرفاتها الـ (IDs) في حقل matchedIds.
3. اكتب رداً محترفاً وجذاباً باللغة العربية يوجه للمستخدم ويشرح له لماذا هذه العقارات المقترحة تناسب طلبه.
4. إذا سأل المستخدم عن أشياء عامة (مثل العقد، العمولات، الصيانة، شروط الحجز) أو لم تجد عقارات مطابقة، أجب بشكل رائع واجعل حقل matchedIds فارغاً [].
5. ردك يجب أن يكون بصيغة JSON فقط بهذا الهيكل الدقيق:
{
  "reply": "نص الرد باللغة العربية...",
  "matchedIds": ["معرف_العقار_الأول", "معرف_العقار_الثاني"]
}
`;

                const prompt = `الرسالة: "${message}"`;

                const result = await model.generateContent([
                    { text: systemInstruction },
                    { text: prompt }
                ]);

                const responseText = result.response.text().trim();
                let parsedResult;
                try {
                    parsedResult = JSON.parse(responseText);
                } catch (e) {
                    console.error('خطأ في تحليل استجابة JSON من Gemini:', responseText);
                    throw new Error('Gemini response format error');
                }

                const matchedIds = parsedResult.matchedIds || [];
                const reply = parsedResult.reply || 'أهلاً بك، كيف يمكنني مساعدتك اليوم في منصة إيجاري؟';

                // جلب العقارات المقترحة كاملة من MongoDB
                const matchedProperties = await Property.find({ _id: { $in: matchedIds } });

                return res.status(200).json({
                    success: true,
                    data: {
                        reply,
                        matchedProperties
                    }
                });

            } catch (geminiError) {
                console.error('فشل استدعاء Gemini API، جاري التحويل للمحاكي المحلي:', geminiError.message);
                // السقوط التلقائي للنظام المحلي
            }
        }

        // 3. نظام السقوط الآمن المحلي (Local Fallback System)
        // يتم تفعيله في حال غياب المفتاح أو فشل الاتصال بـ Gemini
        const queryLower = message.toLowerCase();
        let matched = [];

        // تصفية العقارات بناءً على كلمات مفتاحية بسيطة
        if (containsAny(queryLower, ['رخيص', 'اقتصادي', 'cheap', 'بسيط'])) {
            matched = availableProperties.filter(p => p.price <= 5000);
        } else if (containsAny(queryLower, ['فاخر', 'luxury', 'بريميم', 'مميز', 'راقي'])) {
            matched = availableProperties.filter(p => p.price >= 8000 || p.type === 'villa');
        } else if (containsAny(queryLower, ['شقة', 'شقق', 'apartment'])) {
            matched = availableProperties.filter(p => p.type === 'apartment');
        } else if (containsAny(queryLower, ['فيلا', 'فلل', 'villa', 'منزل'])) {
            matched = availableProperties.filter(p => p.type === 'villa' || p.type === 'house');
        } else if (containsAny(queryLower, ['مكتب', 'مكاتب', 'office', 'تجاري'])) {
            matched = availableProperties.filter(p => p.type === 'office' || p.type === 'shop');
        } else {
            // بحث نصي جزئي كبديل عام
            matched = availableProperties.filter(p => 
                p.title.includes(message) || 
                p.description.includes(message) || 
                (p.location && p.location.address.includes(message))
            );
        }

        // أخذ أول 4 عقارات كحد أقصى للترشيح
        const matchedProperties = matched.slice(0, 4);

        // إنشاء رد صياغي ودود بناءً على النتائج
        let reply = '';
        if (matchedProperties.length > 0) {
            reply = `أهلاً بك يا فندم! 💎 لقد بحثت في قاعدة بيانات "إيجاري إيليت" ووجدت لك ${matchedProperties.length} عقار يناسب طلبك تماماً. إليك الترشيحات المميزة المتاحة لدينا للطلب والمشاهدة الفورية:`;
        } else {
            // ردود مسبقة للأسئلة الشائعة
            if (containsAny(queryLower, ['عمول', 'نسبة'])) {
                reply = 'عمولتنا في منصة "إيجاري إيليت" هي الأقل والأكثر شفافية: 5% فقط على المعاملات الناجحة، مع تقديم خصومات وعضويات مجانية حصرية للملاك الجدد. 💎';
            } else if (containsAny(queryLower, ['توثيق', 'عقد', 'قانوني'])) {
                reply = 'جميع العقود المبرمة عبر منصتنا هي عقود إلكترونية موحدة وموثقة رسمياً لحفظ كامل حقوق المؤجر والمستأجر، وتخضع للقوانين المصرية المنظمة. ⚖️';
            } else if (containsAny(queryLower, ['بدأ', 'كيف', 'طريقة'])) {
                reply = 'لبدء استخدام منصة إيجاري، يمكنك ببساطة تصفح العقارات المتاحة، اختيار العقار الأنسب لك، ثم الضغط على "احجز الآن" لإرسال طلب حجز مباشر للمالك. 🏠';
            } else {
                reply = 'أهلاً بك في "إيجاري كونسيرج" 💎 المساعد النخبوي لمنصة إيجاري إيليت. كيف يمكنني خدمتك اليوم؟ يمكنك سؤالي عن العقارات المتاحة للإيجار أو البيع، وعمولات المنصة، أو طريقة توثيق العقود القانونية.';
            }
        }

        return res.status(200).json({
            success: true,
            data: {
                reply,
                matchedProperties
            }
        });

    } catch (error) {
        console.error('خطأ عام في متحكم الذكاء الاصطناعي:', error);
        res.status(500).json({ success: false, error: 'حدث خطأ داخلي في الخادم' });
    }
};

// دالة مساعدة لفحص الكلمات المفتاحية
function containsAny(text, keywords) {
    return keywords.some(k => text.includes(k));
}
