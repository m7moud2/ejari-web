# إصدارات إيجاري — Ejari Releases

## رابط التحميل للمستخدمين

بعد نشر الإصدار على GitHub Releases، أرسل أحد الروابط التالية:

| الرابط | الاستخدام |
|--------|-----------|
| صفحة التحميل (GitHub Pages) | `https://m7moud2.github.io/ejari-web/docs/download/` |
| أحدث إصدار مباشرة | `https://github.com/m7moud2/ejari-web/releases/latest` |
| تحميل APK مباشرة | `https://github.com/m7moud2/ejari-web/releases/download/v1.1.8/ejari-1.1.8.apk` |

> GitHub Pages مفعّل من فرع `main` (جذر المستودع). صفحة التحميل بعد الدفع: `/docs/download/`.

## تثبيت APK (اختبار داخلي)

1. فعّل **مصادر غير معروفة** على جهاز Android (الإعدادات ← الأمان / تثبيت تطبيقات غير معروفة).
2. افتح رابط التحميل من الهاتف واضغط **تحميل**.
3. افتح ملف الـ APK واضغط **تثبيت**.
4. بعد التثبيت، افتح التطبيق وسجّل الدخول بحساب تجريبي:
   - مستأجر: `user@ejari.app` / `123456`
   - مالك: `owner@ejari.app` / `123456`
   - أدمن: `admin@ejari.app` / `123456`

## نشر إصدار جديد (مهم للتحديثات)

عندما تبني APK جديد (مثلاً `1.1.9`):

```bash
cd ejari_mobile

# 1) ابنِ الـ APK وضعْه هنا باسم واضح
# flutter build apk --release ...
# cp build/app/outputs/flutter-apk/app-release.apk releases/ejari-1.1.9.apk

# 2) سجّل الدخول إلى GitHub إن لزم
gh auth login -h github.com

# 3) أنشئ Release وارفق الـ APK
gh release create v1.1.9 releases/ejari-1.1.9.apk \
  --repo m7moud2/ejari-web \
  --title "Ejari 1.1.9" \
  --notes "$(cat <<'EOF'
## ما الجديد
- وصف التحديثات بالعربية هنا

EOF
)"
```

بعدها مباشرة:

- رابط التحميل العام يتحدّث عبر `releases/latest`
- التطبيق يتحقق من أحدث إصدار عبر GitHub Releases API ويفتح صفحة التحميل إن وُجد إصدار أحدث

حدّث أيضاً في الكود قبل البناء:

- `pubspec.yaml` → `version: X.Y.Z+N`
- `lib/config/app_config.dart` → `appVersion` و `buildNumber`

## إصدار حالي

| الملف | الوصف |
|-------|--------|
| `ejari-1.1.8.apk` | إصلاح تسجيل الدخول / إنشاء الحساب / المحادثات على أندرويد |
| `index.html` | صفحة تحميل عربية للمشاركة |

> ملفات `.apk` محلية ولا تُرفع إلى git (حجم كبير). تُرفع كـ **Release assets** عبر `gh release create`.

## رفع Google Play (AAB)

### 1. إعداد التوقيع

```bash
cp android/key.properties.example android/key.properties
# عدّل المسارات وكلمات المرور في key.properties
```

### 2. بناء حزمة Play

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.ejari.app/api \
  --dart-define=DEMO_MODE=false
```

الملف الناتج: `build/app/outputs/bundle/release/app-release.aab`

### 3. رفع Play Console

1. ادخل [Google Play Console](https://play.google.com/console).
2. **إنشاء تطبيق** ← اسم «إيجاري» ← فئة «عقارات».
3. **الإصدار** ← **الإنتاج** (أو اختبار داخلي أولاً).
4. **إنشاء إصدار جديد** ← ارفع `app-release.aab`.
5. أكمل: لقطات شاشة، أيقونة، سياسة خصوصية، تصنيف المحتوى.
6. **مراجعة ونشر**.

### 4. ملاحظات مهمة

- النسخة التجريبية (demo) تعرض شارة **«وضع العرض»** — لا تُرفع للإنتاج.
- للإنتاج: `--dart-define=DEMO_MODE=false` و `API_BASE_URL` صحيح.
- رقم الإصدار: `1.1.8+9` (versionName + versionCode).

## الدعم

- البريد: support@ejari.app
- المستودع: https://github.com/m7moud2/ejari-web
