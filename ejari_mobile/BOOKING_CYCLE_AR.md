# دورة الحجز والاستلام — Ejari

مرجع مختصر لحالات الحجز ومسار QR للاستلام (v1.3.8+).

## المسار السعيد (مستأجر + مالك)

```
نشر إعلان (pending) → موافقة مشرف (approved)
  → طلب معاينة اختياري (requested → confirmed → completed)
    → حجز (submitted) → دفع عربون (deposit_paid) + escrowStatus=held
  → موافقة المالك (approved) → إكمال الدفع (paid) — العربون يبقى محجوزاً
  → عقد + QR جاهز
  → المالك يمسح QR ويؤكّد الاستلام → active (check-in) — العربون ما زال held
  → إقامة → خروج (completed) + escrowStatus=released → تقييم
```

عند نزاع أضرار عند الخروج: `disputed` + `escrowStatus=disputed` (لا إفراج حتى الحسم).

## حالات `BookingStatus`

| Status | عربي | ماذا يحدث بعدها |
|--------|------|-----------------|
| `submitted` / `pending` | مُرسَل / قيد الانتظار | دفع عربون أو انتظار |
| `deposit_paid` | عربون مدفوع | انتظار موافقة المالك |
| `viewing_scheduled` | موعد معاينة | معاينة ثم موافقة |
| `approved` | موافقة المالك | ادفع المتبقي |
| `paid` / `confirmed` | مدفوع بالكامل | اعرض QR للاستلام |
| `active` | نشط | إقامة جارية (العربون محجوز) |
| `completed` | مكتمل | قيّم / إطلاق العربون |
| `cancelled` / `rejected` / `deposit_refunded` | نهائي | — |
| `disputed` | نزاع أضرار | مراجعة إدارية |

الانتقالات المسموحة مُعرَّفة في `lib/models/booking_status.dart`.

## `escrowStatus` على مستند الحجز (إنتاج)

| قيمة | متى |
|------|-----|
| `none` | عند إنشاء الحجز |
| `held` | بعد دفع العربون (وحتى الخروج) |
| `released` | عند الخروج بدون أضرار (`completed`) |
| `refunded` | استرداد العربون |
| `disputed` | مطالبة أضرار / خروج مع نزاع |

دفتر المحفظة المحلي (SharedPreferences) يبقى لوضع العرض؛ في الإنتاج تُزامَن حالة الضمان عبر `FirestoreBookingService.syncEscrowStatus`.

## QR للاستلام

1. **من يُنشئ؟** المستأجر — شاشة «رمز QR للاستلام» بعد حالة `paid` / `confirmed`.
2. **من يمسح؟** المالك — شاشة «التحقق من QR» (كاميرا أو لصق المعرّف).
3. **متى يُفعَّل؟** بعد اكتمال الدفع فقط — ليس بعد موافقة المالك وحدها.
4. **ماذا يفعل المسح؟** التحقق من التوقيع + عرض بيانات الحجز.
5. **تأكيد الاستلام:** زر «تأكيد الاستلام وتسجيل الدخول» → `CheckInOutService.confirmHandover` → `checkedInAt` + حالة `active`.
6. **اختياري:** فحص الاستلام (صور الغرف) بعد التأكيد.

صيغة الرمز: `EJARI|{bookingId}|{tenant}|{property}|{checkIn}|{hash}`

## شاشات رئيسية

- تتبع: `BookingTrackScreen` — خط زمني + الخطوة التالية
- دفع: `PaymentScreen` / Paymob (بدون نجاح وهمي)
- حجوزات المستأجر: `MyBookingsScreen`
- معاينات: `MyViewingsScreen` / `OwnerViewingsScreen` → Firestore `viewings` في الإنتاج
- QR: `BookingQrScreen` / `OwnerQrVerifyScreen`

## ملاحظات تقنية

- في وضع العرض (demo): التخزين محلي (SharedPreferences).
- في الإنتاج:
  - نشر العقار عبر `FirestorePropertyService`
  - الحجوزات عبر `FirestoreBookingService`
  - المعاينات عبر `FirestoreViewingService` (مجموعة `viewings`)
  - check-in / escrow عبر `patchBooking` / `syncEscrowStatus`
- استعلامات المالك تطابق **uid و البريد** (`AuthService.identityKeysFor`) لتفادي تعارض `ownerId`.
