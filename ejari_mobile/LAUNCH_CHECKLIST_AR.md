# قائمة إطلاق إيجاري - النسخة الأولى

## المتاح الآن للتجربة والإعلان المحدود

- ملف APK تجريبي جاهز للتثبيت اليدوي:
  `dist/keyo-initial-demo.apk`
- التطبيق يعمل في وضع Demo بدون انتظار السيرفر.
- حسابات تجربة محلية:
  - مستأجر: `user@ejari.app` / `user123`
  - مالك: `owner@ejari.app` / `owner123`
  - فني صيانة: `tech@ejari.app` / `tech123`
  - مدير: `admin@ejari.app` / `admin123`

## قبل الرفع الرسمي على Google Play

1. تجهيز API حقيقي آمن `https://.../api`.
2. إنشاء Android keystore رسمي وعدم مشاركته.
3. إنشاء ملف `android/key.properties` من المثال:
   `android/key.properties.example`
4. بناء Android App Bundle:

```bash
flutter build appbundle --release \
  --dart-define=DEMO_MODE=false \
  --dart-define=API_BASE_URL=https://your-domain.com/api
```

5. اختبار التسجيل/الدخول/الحجز/الصيانة على السيرفر الحقيقي قبل الإعلان الواسع.

## ملاحظة مهمة

ملف APK التجريبي الحالي مناسب لتجربة العملاء الأوائل وجمع الملاحظات، لكنه ليس مناسبًا للرفع على Google Play لأنه Debug-signed.
