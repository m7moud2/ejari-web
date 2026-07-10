import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/mock_data_seeder.dart';
import '../utils/property_image_resolver.dart';

class FirestorePropertyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب العقارات من Firestore
  static Future<List<Map<String, dynamic>>> getAllProperties(
      {bool approvedOnly = true}) async {
    if (AppConfig.demoMode) {
      final local = await DataService.getAllProperties(approvedOnly: approvedOnly);
      final demo = MockDataSeeder.getEgyptianProperties();
      final merged = _mergePropertyCatalog(local, demo);
      if (approvedOnly) {
        return merged
            .where((p) =>
                p['status'] == 'approved' ||
                p['status'] == 'متاح' ||
                p['isDemo'] == true)
            .toList();
      }
      return merged;
    }
    try {
      QuerySnapshot query;
      if (approvedOnly) {
        query = await _firestore
            .collection('properties')
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .get();
      } else {
        query = await _firestore
            .collection('properties')
            .orderBy('createdAt', descending: true)
            .get();
      }

      final properties = query.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _normalizeProperty(data);
      }).toList();

      // If Firestore is completely empty (no properties added yet),
      // fallback to mock data so the app doesn't look empty for the demo.
      if (properties.isEmpty) {
        return MockDataSeeder.getEgyptianProperties();
      }

      return properties;
    } catch (e) {
      debugPrint('Firestore Error fetching properties: $e');
      // السقوط التلقائي للبيانات المحلية في حالة فشل الاتصال بالسحابة
      return MockDataSeeder.getEgyptianProperties();
    }
  }

  /// جلب الطلبات المعلقة (للمشرفين)
  static Future<List<Map<String, dynamic>>> getPendingProperties() async {
    if (AppConfig.demoMode) {
      return DataService.getPendingProperties();
    }
    try {
      final query = await _firestore
          .collection('properties')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return _normalizeProperty(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore Error fetching pending properties: $e');
      return await DataService.getPendingProperties();
    }
  }

  /// إضافة عقار جديد
  static Future<void> addProperty(Map<String, dynamic> property) async {
    final currentUser = await AuthService.getCurrentUser();
    final ownerId = (currentUser?['uid'] ??
            currentUser?['id'] ??
            currentUser?['_id'])
        ?.toString()
        .trim();
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError('Cannot create property without an authenticated owner.');
    }
    property['ownerId'] = ownerId;

    if (AppConfig.demoMode) {
      await DataService.addProperty(property);
      return;
    }
    try {
      property['status'] = 'pending';
      property['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('properties').add(property);
    } catch (e) {
      debugPrint('Firestore Error adding property: $e');
      // Fallback
      await DataService.addProperty(property);
    }
  }

  /// تحديث حالة العقار (موافقة / رفض)
  static Future<void> updatePropertyStatus(String id, String status) async {
    if (AppConfig.demoMode) {
      await DataService.updatePropertyStatus(id, status);
      return;
    }
    try {
      await _firestore.collection('properties').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore Error updating property status: $e');
      await DataService.updatePropertyStatus(id, status);
    }
  }

  /// حذف العقار نهائياً
  static Future<void> deleteProperty(String id) async {
    if (AppConfig.demoMode) {
      await DataService.deleteProperty(id);
      return;
    }
    try {
      await _firestore.collection('properties').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore Error deleting property: $e');
      await DataService.deleteProperty(id);
    }
  }

  /// تبديل حالة التوثيق
  static Future<void> toggleVerifyProperty(String id) async {
    if (AppConfig.demoMode) {
      await DataService.toggleVerifyProperty(id);
      return;
    }
    try {
      final docRef = _firestore.collection('properties').doc(id);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final current = snapshot.data()?['isVerified'] ?? false;
        await docRef.update({'isVerified': !current});
      }
    } catch (e) {
      debugPrint('Firestore Error verifying property: $e');
      await DataService.toggleVerifyProperty(id);
    }
  }

  /// تبديل حالة التمييز
  static Future<void> toggleFeatureProperty(String id) async {
    if (AppConfig.demoMode) {
      await DataService.toggleFeatureProperty(id);
      return;
    }
    try {
      final docRef = _firestore.collection('properties').doc(id);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final current = snapshot.data()?['isFeatured'] ?? false;
        await docRef.update({'isFeatured': !current});
      }
    } catch (e) {
      debugPrint('Firestore Error featuring property: $e');
      await DataService.toggleFeatureProperty(id);
    }
  }

  /// دالة مساعدة لتنظيف البيانات (مثل DataService)
  static List<Map<String, dynamic>> _mergePropertyCatalog(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> supplemental,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final property in [...primary, ...supplemental]) {
      final id = property['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = {...byId[id] ?? {}, ...property};
    }
    return byId.values.toList();
  }

  static Map<String, dynamic> _normalizeProperty(Map<String, dynamic> p) {
    final features = p['features'] as Map<String, dynamic>? ?? {};
    final locationData = p['location'];
    String locationStr = '';
    if (locationData is Map) {
      locationStr = locationData['address']?.toString() ?? '';
    } else {
      locationStr = locationData?.toString() ?? '';
    }

    final imagesList = p['images'] as List<dynamic>?;
    String imageStr = PropertyImageResolver.defaultImage;
    if (imagesList != null && imagesList.isNotEmpty) {
      imageStr = imagesList[0].toString();
    } else if (p['image'] != null) {
      imageStr = p['image'].toString();
    }

    final normalized = {
      ...p,
      'id': p['id'] ?? '',
      'title': p['title'] ?? '',
      'price': (p['price'] ?? '0').toString(),
      'location': locationStr,
      'image': imageStr,
      'beds': (features['bedrooms'] ?? p['beds'] ?? 0).toString(),
      'baths': (features['bathrooms'] ?? p['baths'] ?? 0).toString(),
      'area': (features['area'] ?? p['area'] ?? 0).toString(),
      'type': p['type'] ?? 'apartment',
      'status': p['status'] ?? 'available',
      'amenities': p['amenities'] ?? [],
      'furnished': features['furnished'] ?? p['furnished'] ?? false,
      'listingMode': p['listingMode'] ?? 'rent',
      'isDemo': p['isDemo'] ?? false,
      'isVerified': p['isVerified'] ?? false,
      'isFeatured': p['isFeatured'] ?? false,
      'phone': p['phone']?.toString() ?? '',
      'ownerId': p['ownerId']?.toString() ?? 'admin',
      'governorate': p['governorate'] ?? '',
      'supportedDurations': p['supportedDurations'] ?? [],
      'corporateEligible': p['corporateEligible'] ?? false,
      'lat': p['lat'],
      'lng': p['lng'],
    };
    return {
      ...normalized,
      'image': PropertyImageResolver.resolve(normalized),
    };
  }
}
