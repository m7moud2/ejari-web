import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';
import '../services/data_service.dart';

class MaintenanceService {
  static const String _requestsKey = 'maintenance_requests';

  // Maintenance Categories
  static const List<Map<String, dynamic>> categories = [
    {'id': 'plumbing', 'name': 'سباكة', 'icon': '🚰'},
    {'id': 'electrical', 'name': 'كهرباء', 'icon': '⚡'},
    {'id': 'ac', 'name': 'تكييف', 'icon': '❄️'},
    {'id': 'cleaning', 'name': 'نظافة', 'icon': '🧹'},
    {'id': 'painting', 'name': 'دهانات', 'icon': '🎨'},
    {'id': 'carpentry', 'name': 'نجارة', 'icon': '🔨'},
    {'id': 'other', 'name': 'أخرى', 'icon': '🔧'},
  ];

  // Priority Levels
  static const Map<String, Map<String, dynamic>> priorities = {
    'urgent': {'name': 'عاجل', 'color': 0xFFA65F57, 'responseTime': '2 ساعة'},
    'high': {'name': 'مرتفع', 'color': 0xFFD8C3A5, 'responseTime': '24 ساعة'},
    'medium': {'name': 'متوسط', 'color': 0xFFD8C3A5, 'responseTime': '3 أيام'},
    'low': {'name': 'منخفض', 'color': 0xFF47736E, 'responseTime': '7 أيام'},
  };

  // Helper to normalize maintenance request maps
  static Map<String, dynamic> _normalizeRequest(Map<String, dynamic> r) {
    String status = r['status']?.toString() ?? 'pending';
    if (status == 'معلق') {
      status = 'pending';
    } else if (status == 'قيد_المعالجة' || status == 'in_progress') {
      status = 'in_progress';
    } else if (status == 'مكتمل' || status == 'completed') {
      status = 'completed';
    }

    String priority = r['priority']?.toString() ?? 'medium';
    if (priority == 'عاجل') {
      priority = 'urgent';
    } else if (priority == 'مرتفع') {
      priority = 'high';
    } else if (priority == 'متوسط') {
      priority = 'medium';
    } else if (priority == 'منخفض') {
      priority = 'low';
    }

    return {
      'id': r['_id']?.toString() ?? r['id']?.toString() ?? '',
      'userId': r['user']?.toString() ?? r['userId']?.toString() ?? '',
      'propertyId':
          r['property']?.toString() ?? r['propertyId']?.toString() ?? '',
      'category': r['type'] ?? r['category'] ?? 'other',
      'priority': priority,
      'title': r['title'] ??
          r['description']?.toString().split('\n').first ??
          'طلب صيانة',
      'description': r['description'] ?? '',
      'status': status,
      'createdAt': r['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': r['updatedAt'] ?? DateTime.now().toIso8601String(),
      'assignedTo': r['assignedTo'],
      'estimatedCost':
          double.tryParse(r['estimatedCost']?.toString() ?? '0') ?? 0.0,
      'actualCost': double.tryParse(r['actualCost']?.toString() ?? '0') ?? 0.0,
    };
  }

  // Create maintenance request
  static Future<String> createRequest({
    required String userId,
    required String propertyId,
    required String category,
    required String priority,
    required String title,
    required String description,
    double? lat,
    double? lng,
    List<String>? images,
  }) async {
    final requestId = 'MNT${DateTime.now().millisecondsSinceEpoch}';

    // 1. Try to post to backend API
    try {
      // Find a real seeded property if propertyId is not found
      String realPropertyId = propertyId;
      if (propertyId == 'none' || propertyId.isEmpty) {
        final props = await DataService.getAllProperties();
        if (props.isNotEmpty) {
          realPropertyId = props.first['id'] ?? 'none';
        }
      }

      // Map priority to Arabic for backend
      String backendPriority = 'متوسط';
      if (priority == 'urgent') backendPriority = 'عاجل';
      if (priority == 'high') backendPriority = 'مرتفع';
      if (priority == 'low') backendPriority = 'منخفض';

      final body = {
        'property': realPropertyId,
        'type': category,
        'priority': backendPriority,
        'description': '$title\n$description',
      };

      final response = await ApiClient.post('/maintenance', body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final serverData = decoded['data'] as Map<String, dynamic>;
          final normalized = _normalizeRequest(serverData);

          // Save locally
          final prefs = await SharedPreferences.getInstance();
          final localRequests = await getAllRequests();
          localRequests.add(normalized);
          await prefs.setString(_requestsKey, jsonEncode(localRequests));

          return normalized['id'];
        }
      }
    } catch (e) {
      debugPrint('CreateRequest API Error: $e. Falling back to local storage.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();

    final request = {
      'id': requestId,
      'userId': userId,
      'propertyId': propertyId,
      'category': category,
      'priority': priority,
      'title': title,
      'description': description,
      'images': images ?? [],
      'lat': lat ?? 30.0444, // Default to Cairo if not provided
      'lng': lng ?? 31.2357,
      'status': 'pending', // pending, in_progress, completed, cancelled
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'assignedTo': null,
      'estimatedCost': 0.0,
      'actualCost': 0.0,
      'completedAt': null,
      'rating': null,
      'feedback': null,
    };

    requests.add(request);
    await prefs.setString(_requestsKey, jsonEncode(requests));

    return requestId;
  }

  // Wrapper for registration
  static Future<void> submitRequest(Map<String, dynamic> application) async {
    await createRequest(
      userId: application['email'] ?? 'unknown',
      propertyId: 'none',
      category: application['service'] ?? 'other',
      priority: 'medium',
      title: application['service'] ?? 'Registration',
      description:
          'Experience: ${application['experience']}\nNotes: ${application['notes']}',
    );
  }

  // Get all requests
  static Future<List<Map<String, dynamic>>> getAllRequests() async {
    // 1. Try to fetch from API
    try {
      final response = await ApiClient.get('/maintenance');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['success'] == true) {
          final List<dynamic> rawList = decoded['data'] ?? [];
          final List<Map<String, dynamic>> requests = rawList
              .map((r) => _normalizeRequest(r as Map<String, dynamic>))
              .toList();

          // Cache locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_requestsKey, jsonEncode(requests));
          return requests;
        }
      }
    } catch (e) {
      debugPrint('GetAllRequests API Error: $e. Using local cache.');
    }

    // 2. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final String? requestsJson = prefs.getString(_requestsKey);

    if (requestsJson != null) {
      final List<dynamic> decoded = jsonDecode(requestsJson);
      return decoded
          .map((r) => _normalizeRequest(r as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Get user requests
  static Future<List<Map<String, dynamic>>> getUserRequests(
      String userId) async {
    final allRequests = await getAllRequests();
    return allRequests
        .where((req) =>
            req['userId'] == userId || req['userId'].toString().isEmpty)
        .toList();
  }

  // Update request status
  static Future<bool> updateStatus(String requestId, String status,
      {String? assignedTo, double? estimatedCost}) async {
    // 1. Try backend API
    String backendStatus = status;
    if (status == 'pending') backendStatus = 'معلق';
    if (status == 'in_progress') backendStatus = 'قيد_المعالجة';
    if (status == 'completed') backendStatus = 'مكتمل';

    try {
      final response = await ApiClient.put('/maintenance/$requestId', {
        'status': backendStatus,
      });
      if (response.statusCode == 200) {
        debugPrint('Maintenance status updated on backend.');
      }
    } catch (e) {
      debugPrint('UpdateStatus API Error: $e. Syncing locally.');
    }

    // 2. Local sync
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();

    final index = requests.indexWhere((req) => req['id'] == requestId);
    if (index == -1) return false;

    requests[index]['status'] = status;
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();

    if (assignedTo != null) {
      requests[index]['assignedTo'] = assignedTo;
    }

    if (estimatedCost != null) {
      requests[index]['estimatedCost'] = estimatedCost;
    }

    if (status == 'completed') {
      requests[index]['completedAt'] = DateTime.now().toIso8601String();
    }

    await prefs.setString(_requestsKey, jsonEncode(requests));
    return true;
  }

  // Add rating and feedback
  static Future<bool> addFeedback(
      String requestId, int rating, String feedback) async {
    // 1. Try backend API
    try {
      final response = await ApiClient.post('/maintenance/$requestId/rating', {
        'rating': rating,
        'comment': feedback,
      });
      if (response.statusCode == 200) {
        debugPrint('Maintenance rating sent to backend.');
      }
    } catch (e) {
      debugPrint('AddFeedback API Error: $e. Syncing locally.');
    }

    // 2. Local sync
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();

    final index = requests.indexWhere((req) => req['id'] == requestId);
    if (index == -1) return false;

    requests[index]['rating'] = rating;
    requests[index]['feedback'] = feedback;
    requests[index]['updatedAt'] = DateTime.now().toIso8601String();

    await prefs.setString(_requestsKey, jsonEncode(requests));
    return true;
  }

  // Get request by ID
  static Future<Map<String, dynamic>?> getRequest(String requestId) async {
    final requests = await getAllRequests();
    try {
      return requests.firstWhere((req) => req['id'] == requestId);
    } catch (e) {
      return null;
    }
  }

  // Get statistics
  static Future<Map<String, int>> getStatistics(String userId) async {
    final userRequests = await getUserRequests(userId);

    return {
      'total': userRequests.length,
      'pending': userRequests.where((r) => r['status'] == 'pending').length,
      'in_progress':
          userRequests.where((r) => r['status'] == 'in_progress').length,
      'completed': userRequests.where((r) => r['status'] == 'completed').length,
    };
  }
}
