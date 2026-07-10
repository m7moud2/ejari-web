import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';

class FirestoreReviewsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// إرسال تقييم جديد إلى قاعدة البيانات
  static Future<bool> submitFeedback({
    required int appRating,
    required int serviceRating,
    String? opinion,
    String? suggestion,
    String? userId,
  }) async {
    if (AppConfig.demoMode) return true;
    try {
      await _db.collection('feedbacks').add({
        'appRating': appRating,
        'serviceRating': serviceRating,
        'opinion': opinion ?? '',
        'suggestion': suggestion ?? '',
        'userId': userId ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// لجلب التقييمات في لوحة تحكم الإدارة (كمثال مستقبلي)
  static Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    if (AppConfig.demoMode) return [];
    try {
      final snapshot = await _db
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
