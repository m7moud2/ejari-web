# إصدارات إيجاري — Ejari Releases

## رابط التحميل للمستخدمين

بعد نشر الإصدار على GitHub Releases، أرسل أحد الروابط التالية:

| الرابط | الاستخدام |
|--------|-----------|
| صفحة التحميل (GitHub Pages) | `https://m7moud2.github.io/ejari-web/docs/download/` |
| صفحة الترويج | `https://m7moud2.github.io/ejari-web/promo/` |
| أحدث إصدار مباشرة | `https://github.com/m7moud2/ejari-web/releases/latest` |
| تحميل APK مباشرة | `https://github.com/m7moud2/ejari-web/releases/download/v1.2.1/ejari-1.2.1.apk` |

> GitHub Pages مفعّل من فرع `main` (جذر المستودع). صفحة التحميل بعد الدفع: `/docs/download/`.

## العملية القياسية بعد كل تحديث

**أي تحديث للتطبيق يجب أن يصل إلى GitHub وإلى روابط التحميل العامة.**

```bash
# من مجلد ejari_mobile (أو المستودع الجذر):
./scripts/publish_release.sh
```

السكربت يقوم تلقائياً بـ:

1. قراءة الإصدار من `pubspec.yaml`
2. بناء APK: `flutter build apk --release --dart-define=DEMO_MODE=false`
3. نسخ الملف إلى `releases/ejari-X.Y.Z.apk`
4. إنشاء/تحديث GitHub Release عبر `gh release create`
5. تحديث روابط التحميل في `promo/` و `docs/download/`

ثم ادفع التغييرات:

```bash
cd ..   # جذر المستودع
git add promo/ docs/download/ ejari_mobile/releases/ ejari_mobile/scripts/
git commit -m "Publish Ejari X.Y.Z and update download links"
git push origin main
```

### يدوياً (بدون السكربت)

```bash
cd ejari_mobile

flutter build apk --release --dart-define=DEMO_MODE=false
cp build/app/outputs/flutter-apk/app-release.apk releases/ejari-1.2.1.apk

gh release create v1.2.1 releases/ejari-1.2.1.apk \
  --repo m7moud2/ejari-web \
  --title "Ejari 1.2.1" \
  --notes "$(cat <<'EOF'
## ما الجديد
- محفظة المستأجر وتذكيرات الدفع
- اكتشاف إقامة قصيرة وعروض
- إصلاحات الحجوزات والمعاينة
- Firebase Auth + Firestore

EOF
)"
```

حدّث أيضاً قبل البناء:

- `pubspec.yaml` → `version: X.Y.Z+N`
- `lib/config/app_config.dart` → `appVersion` و `buildNumber`

### مصادقة GitHub CLI

إذا فشل `gh`:

```bash
gh auth login -h github.com
# HTTPS → Login with a web browser
# أو: GH_TOKEN=ghp_xxx gh release create ...
```

## تثبيت APK (عملاء حقيقيون — v1.2.0+)

1. فعّل **مصادر غير معروفة** على جهاز Android.
2. افتح رابط التحميل من الهاتف واضغط **تحميل**.
3. ثبّت الـ APK وافتح التطبيق.
4. من شاشة التسجيل: أنشئ حساباً ببريدك الحقيقي — البيانات تُحفظ على **Firebase** (مجاني).
5. لا تعتمد على حسابات العرض (`user@ejari.app`) في نسخة الإنتاج.

> وضع العرض يظهر فقط في نسخ التطوير أو عند البناء بـ `DEMO_MODE=true`.

## إصدار حالي

| الملف | الوصف |
|-------|--------|
| `ejari-1.2.1.apk` | أحدث إنتاج — محفظة + إقامة قصيرة + Firebase |
| `index.html` | صفحة تحميل عربية للمشاركة |

## Firebase

راجع [`../FIREBASE_SETUP_AR.md`](../FIREBASE_SETUP_AR.md).

## رفع Google Play (AAB)

```bash
flutter build appbundle --release --dart-define=DEMO_MODE=false
```

## الدعم

- البريد: support@ejari.app
- المستودع: https://github.com/m7moud2/ejari-web
