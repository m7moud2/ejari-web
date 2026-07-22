import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/data_service.dart';
import 'smart_pricing_service.dart';

/// Property / booking help chat — Gemini when configured, local search otherwise.
class AiConciergeService {
  static const String _geminiApiKey = 'your_gemini_api_key_here';

  /// Returns:
  ///   - 'reply': String
  ///   - 'properties': List<Map>
  static Future<Map<String, dynamic>> getChatResponse(
      String userMessage) async {
    try {
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
أنت موظف دعم في منصة "إيجاري" للعقارات في مصر.
أجب باختصار ووضوح بالعربية، بدون مبالغة تسويقية وبدون رموز تعبيرية.
ساعد المستخدم في البحث عن عقار أو فهم الحجز والخطوات التالية.

التعليمات:
1. حلّل رسالة المستخدم (السعر، الغرف، الموقع، الفرش، النوع).
2. اختر العقارات الأكثر مطابقة من القائمة وضع معرفاتها في matchedIds.
3. اكتب رداً مهنياً يشرح لماذا تناسب المقترحات الطلب.
4. إن لم تجد تطابقاً، أوضح ذلك واترك matchedIds فارغاً [].
5. الرد JSON فقط:
{
  "reply": "نص الرد...",
  "matchedIds": ["id1", "id2"]
}
'''),
      );

      final availableProperties = await DataService.getAllProperties();

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
          'أهلاً بك في مساعدة إيجاري. كيف يمكننا مساعدتك؟';

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
      return await _localFallback(userMessage);
    }
  }

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
          'وجدت ${results.length} عقاراً يناسب طلبك. يمكنك فتح أي بطاقة للتفاصيل أو الحجز.';
    } else {
      reply =
          'لم أجد عقارات تطابق "$query" حالياً. جرّب تغيير المنطقة أو نوع العقار، أو تواصل مع الدعم.';
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
