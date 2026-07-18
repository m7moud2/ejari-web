# قائمة إطلاق إيجاري - النسخة الأولى

## المتاح الآن للتجربة والإعلان المحدود

- أحدث إصدار منشور: **1.3.5+21**
  - GitHub Releases: https://github.com/m7moud2/ejari-web/releases/tag/v1.3.5
  - صفحة الترويج: https://m7moud2.github.io/ejari-web/promo/
  - AAB للرفع على Play: `ejari_mobile/releases/ejari-1.3.5.aab`
- دليل رفع Play (يدوي): [`PLAY_CONSOLE_UPLOAD_AR.md`](PLAY_CONSOLE_UPLOAD_AR.md)
- التطبيق يعمل بـ Firebase في APK/AAB الإنتاج، ووضع Demo محلياً/ويب بدون Console.
- حسابات تجربة محلية (وضع العرض / عند فشل الشبكة):
  - مستأجر: `user@ejari.app` / `user123`
  - مالك: `owner@ejari.app` / `owner123`
  - فني صيانة: `tech@ejari.app` / `tech123`
  - مدير: `admin@ejari.app` / `admin123`
- صفحات قانونية على GitHub Pages (تم التحقق 200):
  - خصوصية: https://m7moud2.github.io/ejari-web/docs/privacy.html
  - شروط: https://m7moud2.github.io/ejari-web/docs/terms.html
- دعم: واتساب `201280083336` · `support@ejari.app`

## حالة خطوات الإطلاق (بعد 1.3.5)

| الخطوة | الحالة |
|--------|--------|
| بناء ونشر APK 1.3.5 على GitHub | تم |
| تجهيز AAB 1.3.5+21 موقّع | تم — `releases/ejari-1.3.5.aab` |
| رفع تلقائي عبر Play API | غير متاح (لا credentials في المستودع) |
| رفع يدوي Internal testing | **عليك** — راجع `PLAY_CONSOLE_UPLOAD_AR.md` |
| مفاتيح Paymob الحية | منتظر أسرار منك |
| Firebase QA على جهاز حقيقي | بعد رابط Internal testing |

## قبل الرفع الرسمي على Google Play

1. تجهيز API حقيقي آمن `https://.../api` (اختياري إذا كان Firebase كافياً).
2. إنشاء Android keystore رسمي وعدم مشاركته.
   - المسار المتوقع: `android/app/ejari-release-key.jks` (**موجود محلياً**)
   - ملف التوقيع المحلي (لا يُرفع للمستودع): `android/key.properties`
3. إنشاء ملف `android/key.properties` من المثال:
   `android/key.properties.example`
   مع `storeFile=app/ejari-release-key.jks` (يُحلّ نسبةً إلى مجلد `android/`)
4. بناء Android App Bundle (إنتاج):

```bash
cd ejari_mobile
flutter build appbundle --release --dart-define=DEMO_MODE=false
```

المخرجات: `build/app/outputs/bundle/release/app-release.aab`  
نسخة جاهزة للرفع: `releases/ejari-1.3.5.aab`

اختياري — تفعيل بطاقة Paymob في نفس البناء (التفاصيل: `PAYMOB_SETUP_AR.md`):

```bash
flutter build appbundle --release \
  --dart-define=DEMO_MODE=false \
  --dart-define=PAYMOB_API_KEY=YOUR_KEY \
  --dart-define=PAYMOB_INTEGRATION_ID=YOUR_ID \
  --dart-define=PAYMOB_IFRAME_ID=YOUR_IFRAME
```

بدون تعريفات Paymob أعلاه يبقى مسار البطاقة تجريبياً/محلياً.

5. اختبار التسجيل/الدخول/نسيت كلمة المرور/الحجز/الصيانة على السيرفر الحقيقي قبل الإعلان الواسع.
6. تأكد من وجود مساحة قرص كافية قبل البناء (يفضّل >15 GB حرة).

### حقول Play Console للصق

| الحقل | القيمة |
|--------|--------|
| Package name | `com.ejari.app` |
| Version name / code | `1.3.5` / `21` |
| Privacy policy URL | `https://m7moud2.github.io/ejari-web/docs/privacy.html` |
| Terms URL | `https://m7moud2.github.io/ejari-web/docs/terms.html` |
| AAB path | `ejari_mobile/releases/ejari-1.3.5.aab` |

### Firebase (إصدار الإنتاج)

- `android/app/google-services.json` موجود — package `com.ejari.app` — project `ejari-mobile-d9f8e`
- أضف SHA-1 / SHA-256 لمفتاح الرفع (موجودان في `PLAY_CONSOLE_UPLOAD_AR.md`) وفي Console بعد Play App Signing أضف شهادة App signing أيضاً

### أذونات للتصريح في Data safety / App content

| إذن | سبب تقريبي |
|-----|------------|
| INTERNET / NETWORK | Firebase، الخرائط، الدفع |
| LOCATION | البحث عن عقارات قريبة |
| CAMERA / MEDIA | صور العقارات والمستندات |
| BIOMETRIC | قفل التطبيق اختياري |
| POST_NOTIFICATIONS | تذكيرات ودفعات FCM |

### المدفوعات وGoogle Play

- **مدفوعات الإيجار / الحجز / الصيانة العقارية عبر Paymob** عادةً مقبولة كخدمات واقعية (ليست سلعاً رقمية داخل Play).
- **اشتراكات رقمية داخل التطبيق** (محتوى رقمي / ميزات داخل التطبيق فقط) قد تتطلب **Google Play Billing** — راجع نموذج المدفوعات في Play Console قبل الإطلاق.
- تأكد من إفصاح واضح في شاشة الدفع بأن المدفوعات لخدمات عقارية حقيقية.

### ما يبقى في Play Console بعد رفع الـ AAB

- حساب مطوّر / رسوم التسجيل إن لم تُدفع
- لقطات شاشة + أيقونة 512 + feature graphic
- Content rating
- قائمة مختبري Internal
- إكمال Store listing والوصف (نصوص جاهزة في `PLAY_CONSOLE_UPLOAD_AR.md`)

## ملاحظة مهمة

ملف APK التجريبي مناسب لتجربة العملاء الأوائل وجمع الملاحظات، لكنه ليس مناسبًا للرفع على Google Play إذا كان Debug-signed. استخدم AAB الموقّع بمفتاح الإصدار أعلاه (`releases/ejari-1.3.5.aab`).
