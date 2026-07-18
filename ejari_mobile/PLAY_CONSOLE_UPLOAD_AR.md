# رفع إيجاري على Google Play — دليل يدوي (1.3.5)

> **حالة الأتمتة:** لا يوجد في المستودع `fastlane` ولا service account لـ Play Developer API، ومتغيرات البيئة (`GOOGLE_APPLICATION_CREDENTIALS` / `PLAY_*`) غير مضبوطة. الرفع يتم **يدوياً** من Play Console.

## الملف الجاهز للرفع

| البند | القيمة |
|--------|--------|
| المسار | `/Users/mahmoudabdelkawy/ejari-web1/ejari_mobile/releases/ejari-1.3.5.aab` |
| Package | `com.ejari.app` |
| Version name | `1.3.5` |
| Version code | `21` |
| التوقيع | `android/app/ejari-release-key.jks` (محلي، gitignored) عبر `android/key.properties` |

نسخة البناء أيضاً: `build/app/outputs/bundle/release/app-release.aab` (نفس الإصدار إن لم تُعد البناء).

## 5 خطوات سريعة (Internal testing)

1. افتح [Google Play Console](https://play.google.com/console) → أنشئ تطبيقاً جديداً إن لم يكن موجوداً (`com.ejari.app`، لغة عربية، تطبيق).
2. أكمل **App content** الأساسية: سياسة الخصوصية  
   `https://m7moud2.github.io/ejari-web/docs/privacy.html`  
   ثم **Data safety** (انظر الجدول أدناه) و**Content rating** وبيان الأذونات عند الطلب.
3. من **Testing → Internal testing** → **Create new release** → ارفع الملف  
   `ejari_mobile/releases/ejari-1.3.5.aab`.
4. راجع ملاحظات الإصدار (اختياري) → **Save** → **Review release** → **Start rollout to Internal testing**.
5. أضف مختبرين (إيميلات Google) في قائمة Internal testers وانسخ رابط الدعوة.

## عند أول رفع — Play App Signing

- Google تدير مفتاح التوقيع النهائي؛ مفتاحك المحلي هو **upload key**.
- احفظ الـ keystore وكلمات المرور محلياً فقط (لا ترفعها لـ Git).
- بصمات مفتاح الرفع الحالي (للمرجع / Firebase):

```
Alias: ejari
SHA-1:   7D:E1:DE:D6:D9:79:BC:86:9A:F0:AA:6D:8E:28:F8:A3:33:A7:58:E2
SHA-256: 00:BF:09:98:60:C6:65:8F:9C:A0:43:1B:2A:DA:8A:AA:A6:99:EC:ED:4F:F8:A6:AF:55:21:4C:C8:4F:B5:E1:08
```

بعد تفعيل Play App Signing، انسخ **App signing key certificate** من Console → App integrity وأضفه أيضاً في Firebase إن لزم.

## نصوص المتجر (للصق)

**عنوان التطبيق:** إيجاري

**وصف قصير (≤80 حرفاً تقريباً):**
```
منصة إيجار وعقارات: بحث، حجز، صيانة، ومحفظة للمستأجر والمالك.
```

**وصف كامل:**
```
إيجاري يربط المستأجرين وملاك العقارات في منصة واحدة.

• استكشف العقارات واحجز معاينة أو إقامة قصيرة
• تابع الحجوزات والصيانة من داخل التطبيق
• محفظة المستأجر وتذكيرات الدفع
• تسجيل آمن عبر البريد (Firebase)

سياسة الخصوصية: https://m7moud2.github.io/ejari-web/docs/privacy.html
الشروط: https://m7moud2.github.io/ejari-web/docs/terms.html
الدعم: support@ejari.app · واتساب 201280083336
```

## Data safety — أساس سريع

أفصح حسب السلوك الفعلي للتطبيق (حدّث إن تغيّر):

| بيانات | تُجمع؟ | الغرض التقريبي |
|--------|---------|----------------|
| البريد / معرف الحساب | نعم | تسجيل الدخول والحساب |
| الموقع (تقريبي/دقيق) | نعم (بإذن) | البحث عن عقارات قريبة / الخرائط |
| صور (كاميرا/معرض) | نعم (بإذن) | رفع صور عقار / مستندات عند الطلب |
| معرفات الجهاز / إشعارات | نعم | Firebase / الإشعارات |
| بيانات مالية داخل التطبيق | مدفوعات إيجار/حجز عبر بوابة خارجية (Paymob) — ليست Google Play Billing للسلع الرقمية |

التشفير أثناء النقل: نعم (HTTPS). حذف الحساب: وضح عبر الدعم إن لم توجد شاشة حذف بعد.

## أذونات التطبيق (للمراجعة في Console)

`INTERNET` · `CAMERA` · `ACCESS_FINE/COARSE_LOCATION` · `USE_BIOMETRIC` · `POST_NOTIFICATIONS` · قراءة وسائط/تخزين (حسب SDK) · أذونات Firebase/FCM المعتادة.

## ما يبقى عليك يدوياً في Console

- نموذج التاجر / حساب المطوّر المدفوع إن لم يُفعّل
- لقطات شاشة الهاتف (ومن ثم الجهاز اللوحي إن طُلب)
- Content rating questionnaire
- أكمل أقسام Store listing (أيقونة 512، feature graphic)
- قوائم المختبرين Internal
- (لاحقاً) Production بعد نجاح Internal

## إعادة بناء AAB (بدون / مع Paymob)

بدون مفاتيح دفع (البطاقة تبقى تجريبية محلياً):

```bash
cd ejari_mobile
flutter build appbundle --release --dart-define=DEMO_MODE=false
cp build/app/outputs/bundle/release/app-release.aab releases/ejari-1.3.5.aab
```

مع مفاتيح Paymob الحية (عندما تتوفر):

```bash
flutter build appbundle --release \
  --dart-define=DEMO_MODE=false \
  --dart-define=PAYMOB_API_KEY=YOUR_KEY \
  --dart-define=PAYMOB_INTEGRATION_ID=YOUR_ID \
  --dart-define=PAYMOB_IFRAME_ID=YOUR_IFRAME
```

## بعد نجاح الرفع على Internal

1. **Paymob live keys** — ابنِ AAB جديداً بالتعريفات أعلاه ثم ارفع إصداراً أعلى إن لزم.
2. **Firebase QA على جهاز حقيقي** — ثبّت من رابط Internal testing؛ اختبر تسجيل/دخول/عقار/حجز؛ تأكد من SHA في Firebase Console.

## أتمتة لاحقاً (اختياري)

عند توفر JSON لـ service account بصلاحية Play Console:

```bash
# مثال fastlane supply — بعد إضافة fastlane/ وملف المفتاح محلياً (gitignored)
bundle exec fastlane supply \
  --aab releases/ejari-1.3.5.aab \
  --track internal \
  --json_key path/to/play-service-account.json \
  --package_name com.ejari.app
```

لا ترفع ملف service account إلى Git.
