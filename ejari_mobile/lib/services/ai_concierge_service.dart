import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/data_service.dart';
import 'smart_pricing_service.dart';

/// خدمة الذكاء الاصطناعي لمساعد كونسيرج إيجاري
/// تستخدم Gemini API محلياً عبر حزمة google_generative_ai
class AiConciergeService {
  // ⚠️ ضع مفتاح Gemini API الخاص بك هنا من Google AI Studio
  static const String _geminiApiKey = 'your_gemini_api_key_here';

  /// إرسال رسالة للنموذج واسترجاع الرد والعقارات المقترحة
  /// يعود بـ Map يحتوي على:
  ///   - 'reply': String — نص رد المساعد الذكي
  ///   - 'properties': List<Map> — العقارات المقترحة من قاعدة البيانات
  static Future<Map<String, dynamic>> getChatResponse(
      String userMessage) async {
    try {
      // إذا لم يتم وضع المفتاح بعد، ارجع للبحث المحلي الافتراضي
      if (_geminiApiKey == 'your_gemini_api_key_here' ||
          _geminiApiKey.trim().isEmpty) {
        if (kDebugMode) {
          print('Gemini API Key is missing. Falling back to local search.');
        }
        return await _localFallback(userMessage);
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system('''
أنت المساعد الذكي النخبوّي لمنصة "إيجاري" (Ejari) للخدمات العقارية الفاخرة في مصر.
مهمتك هي الإجابة عن استفسارات المستخدمين ومساعدتهم في إيجاد العقار المثالي بأرقى الأساليب.
تحدث باللغة العربية الفصحى الراقية مع لمسة ودية ولطيفة تناسب النخبة، واستخدم الرموز التعبيرية (Emojis) الفاخرة مثل 💎, ✨, 🏠, 📍, 💼.

التعليمات:
1. قم بتحليل رسالة المستخدم وتفضيلاته (السعر، الغرف، الموقع، الفرش، النوع).
2. اختر العقارات الأكثر مطابقةً لطلبه من القائمة المتاحة أدناه وضع معرفاتها الـ (IDs) في حقل matchedIds.
3. اكتب رداً محترفاً وجذاباً باللغة العربية يوجه للمستخدم ويشرح له لماذا هذه العقارات المقترحة تناسب طلبه.
4. إذا لم تجد عقارات مطابقة، أجب بشكل رائع واجعل حقل matchedIds فارغاً [].
5. ردك يجب أن يكون بصيغة JSON فقط بهذا الهيكل الدقيق:
{
  "reply": "نص الرد باللغة العربية...",
  "matchedIds": ["معرف_العقار_الأول", "معرف_العقار_الثاني"]
}
'''),
      );

      // جلب العقارات من قاعدة البيانات المحلية / السحابية
      final availableProperties = await DataService.getAllProperties();

      // تنسيق العقارات لتناسب فهم الـ Model
      final propertiesList = availableProperties
          .map((p) => {
                'id': p['id'],
                'title': p['title'],
                'type': p['type'],
                'price': p['price'],
                'address': p['location'],
                'bedrooms': p['beds'],
                'bathrooms': p['baths'],
                'area': p['area'],
                'furnished': p['furnished'],
                'amenities': p['amenities']
              })
          .toList();

      final prompt = '''
قائمة العقارات المتاحة حالياً في النظام:
${jsonEncode(propertiesList)}

الرسالة: "$userMessage"
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final responseText = response.text?.trim() ?? '{}';
      final parsedResult = jsonDecode(responseText);

      final List<dynamic> rawMatchedIds = parsedResult['matchedIds'] ?? [];
      final String reply = parsedResult['reply'] ??
          'أهلاً بك في إيجاري كونسيرج 🔑 كيف يمكنني مساعدتك؟';

      // مطابقة ה IDs المرجعة من الذكاء الاصطناعي مع العقارات الفعلية
      final List<Map<String, dynamic>> matchedProperties = availableProperties
          .where((p) => rawMatchedIds.contains(p['id']))
          .toList();

      return {
        'reply': reply,
        'properties': matchedProperties,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API Error: $e');
      }
      // 🔄 الـ Fallback المحلي — يُفعَّل عند انقطاع الاتصال أو خطأ في النموذج
      return await _localFallback(userMessage);
    }
  }

  /// نظام السقوط الآمن المحلي — يعمل عند تعذّر الاتصال بالخادم
  static Future<Map<String, dynamic>> _localFallback(String query) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final all = await DataService.getAllProperties();
    final q = query.toLowerCase();

    List<Map<String, dynamic>> filtered;

    if (_containsAny(q, ['رخيص', 'اقتصادي', 'cheap', 'بسيط'])) {
      filtered = all.where((p) {
        final price = _parsePrice(p['price']);
        return price <= 5000;
      }).toList();
    } else if (_containsAny(q, ['فاخر', 'luxury', 'بريميم', 'نخبة'])) {
      filtered = all.where((p) {
        final price = _parsePrice(p['price']);
        return price >= 8000 || (p['type'] ?? '').contains('فلل');
      }).toList();
    } else if (_containsAny(q, ['فاضي', 'شاغر', 'vacant', 'سرير', 'غرفة'])) {
      final suggestion =
          await SmartPricingService.occupancySuggestion('owner@ejari.app');
      return {'reply': suggestion, 'properties': <Map<String, dynamic>>[]};
    } else if (_containsAny(q, ['شقة', 'شقق', 'apartment'])) {
      filtered = all
          .where((p) =>
              (p['type'] ?? '').contains('شقق') || p['type'] == 'apartment')
          .toList();
    } else if (_containsAny(q, ['فيلا', 'فلل', 'villa', 'منزل'])) {
      filtered = all
          .where(
              (p) => (p['type'] ?? '').contains('فلل') || p['type'] == 'villa')
          .toList();
    } else if (_containsAny(q, ['مكتب', 'office', 'تجاري'])) {
      filtered = all
          .where((p) =>
              (p['type'] ?? '').contains('مكاتب') || p['type'] == 'office')
          .toList();
    } else {
      filtered = all.where((p) {
        return (p['title'] ?? '').toString().contains(query) ||
            (p['location'] ?? '').toString().contains(query);
      }).toList();
    }

    final results = filtered.take(4).toList();

    String reply;
    if (results.isNotEmpty) {
      reply =
          'أهلاً يا فندم! 🔑 وجدت لك ${results.length} عقار يناسب طلبك. (ملاحظة: النظام يعمل حالياً بالبحث المحلي لعدم تفعيل Gemini)';
    } else {
      reply =
          'عذراً يا فندم، لم أجد عقارات تطابق "$query" حالياً. (ملاحظة: النظام يعمل حالياً بالبحث المحلي لعدم تفعيل Gemini) 🔑';
    }

    return {'reply': reply, 'properties': results};
  }

  static int _parsePrice(dynamic price) {
    if (price == null) return 0;
    return int.tryParse(price.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }
}
