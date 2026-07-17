# دليل الاستخدام - نظام التقييمات

## للمطورين - كيفية استخدام DataService

### 1. تحميل التقييمات

```dart
import 'package:ejari_mobile/services/data_service.dart';

// في أي screen
final reviews = await DataService.getReviewsForProperty('p1');

// النتيجة: List<Map<String, dynamic>>
// على أول حمل: تُرجع 3 تقييمات demo وتحفظها
// على الحمل التالي: ترجع التقييمات المحفوظة
```

### 2. إضافة تقييم جديد

```dart
final newReview = {
  'userName': 'أحمد محمد',
  'rating': 4.5,
  'comment': 'عقار رائع وموقع ممتاز!',
  // date يُضاف تلقائياً إن لم يكن موجوداً
};

await DataService.addReview('p1', newReview);
// → يُضاف التقييم الجديد في البداية (الأحدث أولاً)
// → يُحفظ تلقائياً في SharedPreferences
```

### 3. الحصول على إحصائيات التقييمات

```dart
final stats = await DataService.getReviewStats('p1');

// النتيجة:
// {
//   'average': 4.5,    // double
//   'count': 3         // int
// }
```

### 4. حذف التقييمات (للاختبار)

```dart
await DataService.clearReviewsForProperty('p1');
// → يحذف كل التقييمات للعقار p1
```

---

## مثال كامل - ReviewsScreen

```dart
@override
void initState() {
  super.initState();
  _loadReviews();
}

Future<void> _loadReviews() async {
  try {
    final reviews = await DataService.getReviewsForProperty(widget.propertyId);
    
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _calculateAverage();
        _isLoading = false;
      });
    }
  } catch (_) {
    if (mounted) setState(() => _isLoading = false);
  }
}

void _showAddReviewDialog() {
  double rating = 5.0;
  final commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      // UI للتقييم والتعليق
      actions: [
        ElevatedButton(
          onPressed: () async {
            final newReview = {
              'userName': 'أنت',
              'rating': rating,
              'comment': commentController.text,
            };
            
            // استخدم DataService
            await DataService.addReview(widget.propertyId, newReview);
            
            // حدّث الـ UI
            if (mounted) {
              setState(() {
                _reviews.insert(0, newReview);
                _calculateAverage();
              });
              Navigator.pop(context);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    ),
  );
}
```

---

## مثال كامل - PropertyDetailsScreen

```dart
@override
void initState() {
  super.initState();
  _loadReviewStats();
}

Future<void> _loadReviewStats() async {
  try {
    final id = widget.property['id']?.toString() ?? '1';
    final stats = await DataService.getReviewStats(id);
    
    setState(() {
      _averageRating = stats['average'] as double? ?? 0.0;
      _reviewsCount = stats['count'] as int? ?? 0;
    });
  } catch (_) {
    // Keep defaults on error
  }
}

Future<void> _openReviewsAndRefresh() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReviewsScreen(
        propertyId: widget.property['id']?.toString() ?? '1',
        propertyTitle: widget.property['title'] ?? '',
      ),
    ),
  );
  
  // أعد تحميل الإحصائيات بعد العودة
  await _loadReviewStats();
}

// في build():
Text('$_averageRating'),  // يعرض التقييم الحالي
Text('($_reviewsCount تقييم)'),  // يعرض العدد
```

---

## النموذج البيانات (Data Model)

### Review Object
```dart
{
  'userName': String,              // "أحمد محمد"
  'rating': double,                // 4.5
  'comment': String,               // "تعليق التقييم"
  'date': String,                  // ISO 8601: "2024-12-02T15:30:00..."
}
```

### Storage Key
```dart
// كل عقار له مفتاح منفصل:
'reviews_p1'
'reviews_p2'
'reviews_p3'
// إلخ...
```

---

## الخصائص المهمة

### ✅ Demo Fallback
```dart
// على أول حمل (لا توجد مراجعات محفوظة):
getReviewsForProperty('p1')
  → توليد 3 تقييمات demo
  → حفظها في SharedPreferences
  → إرجاعها
```

### ✅ Newest First
```dart
// الترتيب:
addReview('p1', newReview)
  → insert(0, newReview)  // في البداية
  → save()
// النتيجة: أحدث تقييم أولاً
```

### ✅ Auto Timestamp
```dart
// إذا لم يوجد date:
addReview('p1', {
  'userName': 'أحمد',
  'rating': 5,
  'comment': 'رائع',
  // date غير موجود
})
// → review['date'] = DateTime.now().toIso8601String()
```

---

## الأخطاء الشائعة والحلول

### ❌ خطأ: Context استخدام بدون mounted check
```dart
// ❌ خطأ:
await DataService.addReview(id, review);
ScaffoldMessenger.of(context).showSnackBar(...);  // قد يتسبب crash

// ✅ الصحيح:
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### ❌ خطأ: عدم تحديث الـ UI بعد التعديل
```dart
// ❌ خطأ:
await DataService.addReview(id, review);
// لا تحديث للـ UI - التغييرات لن تظهر

// ✅ الصحيح:
await DataService.addReview(id, review);
setState(() {
  _reviews = await DataService.getReviewsForProperty(id);
});
```

### ❌ خطأ: استخدام property ID خاطئ
```dart
// ❌ خطأ:
await DataService.getReviewsForProperty('1');  // string
// قد تختلط مع 'p1'

// ✅ الصحيح:
await DataService.getReviewsForProperty('p1');  // استخدم نفس ID
```

---

## الخطوات التالية

### للتطوير المتقدم:
1. **Mocking في الاختبارات**:
   ```dart
   // استخدم mocktail لـ mock DataService
   when(mockDataService.getReviewsForProperty('p1'))
       .thenAnswer((_) async => testReviews);
   ```

2. **Backend Integration**:
   ```dart
   // استبدل SharedPreferences بـ API call
   static Future<List<Map<String, dynamic>>> 
       getReviewsForProperty(String propertyId) async {
     final response = await http.get(
       Uri.parse('$apiUrl/properties/$propertyId/reviews')
     );
     // ...
   }
   ```

3. **State Management (Provider)**:
   ```dart
   class ReviewProvider extends ChangeNotifier {
     List<Map<String, dynamic>> _reviews = [];
     
     Future<void> loadReviews(String propertyId) async {
       _reviews = await DataService.getReviewsForProperty(propertyId);
       notifyListeners();
     }
   }
   ```

---

**آخر تحديث**: 2 ديسمبر 2024
**الإصدار**: 1.1.0
**الحالة**: ✅ مستقر وجاهز للإنتاج
