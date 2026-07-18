# تفعيل Paymob (بطاقة بنكية) — إيجاري

بوابة الدفع اختيارية. بدون المفاتيح يبقى مسار البطاقة **تجريبياً/محلياً** مع إفصاح واضح في شاشة الدفع.

## المتطلبات من لوحة Paymob Accept

1. حساب تاجر مفعّل في مصر.
2. **API Key** من Settings → Account Info.
3. **Integration ID** لتكامل البطاقة (Card / Online).
4. **Iframe ID** لصفحة الدفع المضمّنة.

لا تضع هذه القيم في Git. مرّرها وقت البناء فقط.

## بناء APK / AAB مع Paymob

```bash
cd ejari_mobile

flutter build appbundle --release \
  --dart-define=DEMO_MODE=false \
  --dart-define=PAYMOB_API_KEY='YOUR_LIVE_API_KEY' \
  --dart-define=PAYMOB_INTEGRATION_ID='YOUR_INTEGRATION_ID' \
  --dart-define=PAYMOB_IFRAME_ID='YOUR_IFRAME_ID'
```

للتأكد أن المفاتيح ليست placeholders: لا تستخدم `...` أو القيم التجريبية `456789` / `123456` — الكود يرفضها عبر `PaymobService.isConfigured`.

## كيف يعمل في التطبيق

| الحالة | السلوك |
|--------|--------|
| مفاتيح صحيحة + `DEMO_MODE=false` | بطاقة → Paymob iframe |
| غير مكوّن أو وضع عرض | بطاقة → مسار محلي/تجريبي مع ملاحظة للمستخدم |
| فشل الشبكة مع Paymob | رجوع تلقائي للمسار المحلي مع رسالة عربية |

الكود: `lib/services/paymob_service.dart` و `lib/screens/paymob_iframe_screen.dart`.

## Google Play Billing مقابل Paymob

- **إيجار / حجز / صيانة عقارية** عبر Paymob عادةً مقبولة كخدمات واقعية (ليست سلعاً رقمية داخل Play).
- **اشتراكات رقمية داخل التطبيق فقط** (ميزات/محتوى رقمي) قد تتطلب **Google Play Billing** — راجع نموذج المدفوعات في Play Console قبل الإطلاق.

## اختبار قبل الإنتاج

1. ابنِ نسخة release بمفاتيح **اختبار** Paymob أولاً إن وُجدت.
2. ادفع مبلغاً صغيراً وتحقق من عودة النجاح إلى شاشة الدفع.
3. تأكد أن نصوص الإفصاح العقاري ظاهرة تحت طرق الدفع.
4. لا ترفع `key.properties` أو مفاتيح Paymob إلى المستودع.

راجع أيضاً: `LAUNCH_CHECKLIST_AR.md`.
