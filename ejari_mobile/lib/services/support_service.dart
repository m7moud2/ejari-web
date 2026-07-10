import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

/// Local support ticket store (SharedPreferences) for demo + offline admin inbox.
class SupportService {
  static const String _ticketsKey = 'support_tickets_v1';
  static const String adminEmail = 'admin@ejari.app';

  static Future<String> createTicket({
    required String userEmail,
    required String userName,
    required String subject,
    required String message,
    String category = 'support',
    String? chatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ticketsKey) ?? [];

    final id = 'TKT-${DateTime.now().millisecondsSinceEpoch}';
    final ticket = {
      'id': id,
      'userEmail': userEmail,
      'userName': userName,
      'subject': subject,
      'message': message,
      'category': category,
      'status': 'open',
      'chatId': chatId,
      'replies': <Map<String, dynamic>>[],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    list.add(jsonEncode(ticket));
    await prefs.setStringList(_ticketsKey, list);

    await DataService.addNotificationToUser(
      adminEmail,
      'تذكرة دعم جديدة 🎫',
      '$userName: $subject',
      type: 'support',
      refId: id,
      adminFeed: true,
    );

    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ticketsKey) ?? [];
    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getTicketsForUser(
      String email) async {
    final all = await getAllTickets();
    return all.where((t) => t['userEmail'] == email).toList();
  }

  static Future<Map<String, dynamic>?> getTicketById(String id) async {
    final all = await getAllTickets();
    try {
      return all.firstWhere((t) => t['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateStatus(String id, String status) async {
    await _mutate(id, (ticket) {
      ticket['status'] = status;
      ticket['updatedAt'] = DateTime.now().toIso8601String();
    });
  }

  static Future<void> addReply({
    required String ticketId,
    required String senderEmail,
    required String senderName,
    required String text,
    bool isAdmin = false,
  }) async {
    await _mutate(ticketId, (ticket) {
      final rawReplies = ticket['replies'] as List<dynamic>? ?? [];
      final replies = rawReplies
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      replies.add({
        'senderEmail': senderEmail,
        'senderName': senderName,
        'text': text,
        'isAdmin': isAdmin,
        'timestamp': DateTime.now().toIso8601String(),
      });
      ticket['replies'] = replies;
      if (isAdmin) {
        ticket['status'] = ticket['status'] == 'open' ? 'in_progress' : ticket['status'];
      }
      ticket['updatedAt'] = DateTime.now().toIso8601String();
    });

    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;

    if (isAdmin) {
      await DataService.addNotificationToUser(
        ticket['userEmail']?.toString() ?? '',
        'رد من دعم إيجاري 💬',
        text,
        type: 'support',
        refId: ticketId,
      );
    } else {
      await DataService.addNotificationToUser(
        adminEmail,
        'رد جديد على تذكرة $ticketId',
        text,
        type: 'support',
        refId: ticketId,
        adminFeed: true,
      );
    }
  }

  static Future<void> _mutate(
      String id, void Function(Map<String, dynamic>) mutate) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_ticketsKey) ?? [];
    final updated = list.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['id'] == id) mutate(data);
      return jsonEncode(data);
    }).toList();
    await prefs.setStringList(_ticketsKey, updated);
  }

  static String statusLabelAr(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      default:
        return status;
    }
  }
}
