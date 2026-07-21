# دورة الحجز والاستلام — Ejari

مرجع مختصر لحالات الحجز ومسار QR للاستلام (v1.3.10+).

## المسار السعيد (مستأجر + مالك)

```
نشر إعلان (pending) → موافقة مشرف (approved)
  → طلب معاينة اختياري (requested → confirmed → completed)
    → حجز + دفع عربون فقط (deposit_paid) + escrowStatus=held
  → موافقة المالك (approved) → إكمال المتبقي (paid) — العربون يبقى محجوزاً
  → عقد + QR جاهز
  → المالك يمسح QR ويؤكّد الاستلام → active (check-in) — العربون ما زال held
  → إقامة → خروج (completed) + escrowStatus=released → تقييم
```

عند نزاع أضرار عند الخروج: `disputed` + `escrowStatus=disputed` (لا إفراج حتى الحسم).

**مهم:** لا يُضاعَف العربون فوق أول فترة — العربون جزء من إجمالي أول فترة، والمتبقي = الإجمالي − العربون.

## حالات `BookingStatus`

| Status | عربي | ماذا يحدث بعدها |
|--------|------|-----------------|
| `submitted` / `pending` | مُرسَل / قيد الانتظار | ادفع العربون (CTA) |
| `deposit_paid` | عربون مدفوع | انتظار موافقة المالك |
| `viewing_scheduled` | موعد معاينة | معاينة ثم موافقة |
| `approved` | موافقة المالك | ادفع المتبقي (CTA) |
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

دفتر المحفظة في وضع العرض على SharedPreferences؛ في الإنتاج الأرصدة وسجل المعاملات على `wallets/{user}` في Firestore، بينما تُزامَن حالة الضمان عبر `FirestoreBookingService.syncEscrowStatus` على مستند الحجز.

تحويل بنكي (إيصال يدوي): `paymentStatus=pending_review` — لا يُعلَّم الحجز مدفوعاً حتى المراجعة.

## QR للاستلام

1. **من يُنشئ؟** المستأجر — شاشة «رمز QR للاستلام» بعد حالة `paid` / `confirmed`.
2. **من يمسح؟** المالك — شاشة «التحقق من QR» من الرئيسية أو «المزيد» (كاميرا أو لصق المعرّف؛ في العرض: `demo_qr_ready`).
3. **متى يُفعَّل؟** بعد اكتمال الدفع فقط — ليس بعد العربون أو موافقة المالك وحدها.
4. **ماذا يفعل المسح؟** التحقق من التوقيع + عرض بيانات الحجز.
5. **تأكيد الاستلام:** زر «تأكيد الاستلام وتسجيل الدخول» → `CheckInOutService.confirmHandover` → `checkedInAt` + حالة `active`.
6. **اختياري:** فحص الاستلام (صور الغرف) بعد التأكيد.

صيغة الرمز: `EJARI|{bookingId}|{tenant}|{property}|{checkIn}|{hash}`

## شاشات رئيسية

- تتبع: `BookingTrackScreen` — خط زمني + الخطوة التالية (`pay_deposit` / `pay` / `qr_checkin`)
- دفع: `PaymentScreen` / Paymob (بدون نجاح وهمي؛ التحويل اليدوي للمراجعة فقط)
- حجوزات المستأجر: `MyBookingsScreen`
- معاينات: `MyViewingsScreen` / `OwnerViewingsScreen` → Firestore `viewings` في الإنتاج
- QR: `BookingQrScreen` / `OwnerQrVerifyScreen`

## ملاحظات تقنية

- في وضع العرض (demo): التخزين محلي (SharedPreferences) + بذور `demo_req_1` / `demo_qr_ready` / …
- في الإنتاج:
  - نشر العقار عبر `FirestorePropertyService`
  - الحجوزات عبر `FirestoreBookingService` (إنشاء `pending` ثم ترقية لـ `deposit_paid` بعد الدفع)
  - المعاينات عبر `FirestoreViewingService` (مجموعة `viewings`)
  - check-in / escrow عبر `patchBooking` / `syncEscrowStatus`
- استعلامات المالك تطابق **uid و البريد** (`AuthService.identityKeysFor`) لتفادي تعارض `ownerId`.
