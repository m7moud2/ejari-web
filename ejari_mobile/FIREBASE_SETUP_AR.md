# إعداد Firebase الحقيقي — إيجاري (خطة Spark المجانية)

المشروع المضبوط في التطبيق: **`ejari-elite-1`**

## هل يمكن تشغيل تطبيق حقيقي مجاناً؟

نعم. خطة Firebase Spark (المجانية) تكفي لعدد محدود من العملاء الأوائل:

| الخدمة | حد تقريبي مجاني | ملاحظات |
|--------|------------------|---------|
| Authentication | مستخدمون غير محدودين تقريباً | فعّل Email/Password فقط |
| Firestore | ~50 ألف قراءة / 20 ألف كتابة يومياً | كافٍ لعشرات المستخدمين |
| Storage | اختياري لاحقاً | الصور يمكن تأجيلها |
| Hosting / Domain | غير مطلوب للموبايل | التحميل عبر GitHub Releases |

## خطوات يجب تنفيذها في Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com/) → مشروع `ejari-elite-1`
2. **Authentication** → Sign-in method → فعّل **Email/Password**
3. **Firestore Database** → أنشئ قاعدة (production mode أو test ثم انشر القواعد)
4. من مجلد `ejari_mobile` انشر القواعد:

```bash
cd ejari_mobile
firebase login
firebase use ejari-elite-1
firebase deploy --only firestore:rules
```

5. (اختياري) أضف عقاراً تجريبياً يدوياً في Collection `properties` بالحقول:
   - `ownerId` = UID لمالك مسجّل
   - `status` = `approved`
   - `title`, `price`, `createdAt`, …

## بناء APK للإنتاج (Firebase حقيقي)

الإصدار `1.2.0+` يستخدم Firebase تلقائياً في **release** (بدون `DEMO_MODE=true`):

```bash
flutter build apk --release
# أو صراحةً:
flutter build apk --release --dart-define=DEMO_MODE=false
```

وضع العرض للتطوير/الاختبارات فقط:

```bash
flutter run --dart-define=DEMO_MODE=true
flutter test   # يعمل دائماً بوضع العرض (debug)
```

## ما يعمل على Firebase الآن

- تسجيل / دخول بالبريد وكلمة المرور
- مستند المستخدم في `users/{uid}` مع `accountId` (EJR-*)
- قراءة/إضافة العقارات (`properties`)
- إنشاء/قراءة الحجوزات (`bookings`) + حقل `escrowStatus`
- مواعيد المعاينة (`viewings`) — مشتركة بين المستأجر والمالك
- المحادثات (`chats`) عند تفعيلها خارج وضع العرض

## ما يزال محلياً (Hybrid)

- دفتر أرصدة المحفظة والمعاملات التفصيلية (SharedPreferences) — حالة الضمان على الحجز في Firestore
- الولاء، بعض تقارير الأدمن
- تذاكر الدعم المحلي (`support_tickets_v1`)
- حسابات الديمو (`user@ejari.app` …) — فقط عندما `DEMO_MODE=true`

## أمان

- لا ترفع مفاتيح service account إلى Git
- `google-services.json` و `firebase_options.dart` عامة للعميل (طبيعي)
- القواعد في `firestore.rules` تحدّ صلاحيات القراءة/الكتابة
