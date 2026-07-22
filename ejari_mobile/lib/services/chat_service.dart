import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

class ChatService {
  static const String _chatsKey = 'chats';
  static const String adminEmail = 'admin@ejari.app';

  static Future<List<Map<String, dynamic>>> getChats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    final allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    return allChats
        .where((chat) => (chat['participants'] as List?)?.contains(userId) == true)
        .toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a['lastMessageTime']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['lastMessageTime']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  static Future<Map<String, dynamic>?> getChatById(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    for (final raw in chatsJson) {
      final chat = jsonDecode(raw) as Map<String, dynamic>;
      if (chat['id']?.toString() == chatId) return chat;
    }
    return null;
  }

  static String? peerIdFor(Map<String, dynamic> chat, String currentUserId) {
    final participants =
        (chat['participants'] as List?)?.map((p) => p.toString()).toList() ??
            [];
    for (final participant in participants) {
      if (participant != currentUserId) return participant;
    }
    return null;
  }

  static String displayNameFor(Map<String, dynamic> chat, String currentUserId) {
    final peer = peerIdFor(chat, currentUserId);
    if (peer == null) return chat['otherUserName']?.toString() ?? 'مستخدم';
    if (peer == adminEmail || peer == 'support' || peer == 'admin') {
      return chat['otherUserName']?.toString() ?? 'دعم إيجاري';
    }
    if (currentUserId == adminEmail) {
      return chat['initiatorName']?.toString() ?? peer;
    }
    return chat['otherUserName']?.toString() ?? peer;
  }

  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('messages_$chatId') ?? [];
    return messagesJson
        .map((m) => jsonDecode(m) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    bool isShortcut = false,
    String? shortcutId,
    bool isSystem = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      if (isShortcut) 'isShortcut': true,
      if (shortcutId != null) 'shortcutId': shortcutId,
      if (isSystem) 'isSystem': true,
    };

    final messages = prefs.getStringList('messages_$chatId') ?? [];
    messages.add(jsonEncode(message));
    await prefs.setStringList('messages_$chatId', messages);

    await _updateChatLastMessage(chatId, text);
  }

  static Future<void> sendBotMessage(
    String chatId,
    String text, {
    bool showShortcuts = false,
    bool showFeedback = false,
    bool suggestEscalation = false,
    String? actionRoute,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'support_bot',
      'text': text,
      'isBot': true,
      'timestamp': DateTime.now().toIso8601String(),
      if (showShortcuts) 'showShortcuts': true,
      if (showFeedback) 'showFeedback': true,
      if (suggestEscalation) 'suggestEscalation': true,
      if (actionRoute != null) 'actionRoute': actionRoute,
    };

    final messages = prefs.getStringList('messages_$chatId') ?? [];
    messages.add(jsonEncode(message));
    await prefs.setStringList('messages_$chatId', messages);

    await _updateChatLastMessage(chatId, text);
  }

  static Future<void> _updateChatLastMessage(String chatId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    final allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    final index = allChats.indexWhere((c) => c['id'] == chatId);
    if (index != -1) {
      allChats[index]['lastMessage'] = text;
      allChats[index]['lastMessageTime'] = DateTime.now().toIso8601String();
      await prefs.setStringList(
          _chatsKey, allChats.map((c) => jsonEncode(c)).toList());
    }
  }

  static Future<void> setSupportMode(String chatId, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    final allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    final index = allChats.indexWhere((c) => c['id']?.toString() == chatId);
    if (index == -1) return;

    allChats[index]['supportMode'] = mode;
    allChats[index]['chatType'] = 'support';
    await prefs.setStringList(
        _chatsKey, allChats.map((c) => jsonEncode(c)).toList());
  }

  static Future<String?> getSupportMode(String chatId) async {
    final chat = await getChatById(chatId);
    return chat?['supportMode']?.toString();
  }

  static bool isSupportChat(Map<String, dynamic> chat) {
    return chat['chatType']?.toString() == 'support' ||
        (chat['participants'] as List?)?.contains(adminEmail) == true;
  }

  static Future<String> startChat(
    String user1Id,
    String user2Id,
    String user2Name,
    String propertyTitle, {
    String? user1Name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    final allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    final existingChat = allChats.cast<Map<String, dynamic>?>().firstWhere(
      (c) =>
          c!['participants']?.contains(user1Id) == true &&
          c['participants']?.contains(user2Id) == true,
      orElse: () => null,
    );

    if (existingChat != null) {
      return existingChat['id']?.toString() ?? '';
    }

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    final newChat = {
      'id': chatId,
      'participants': [user1Id, user2Id],
      'otherUserName': user2Name,
      'initiatorId': user1Id,
      if (user1Name != null) 'initiatorName': user1Name,
      'subtitle': propertyTitle,
      'lastMessage': 'بدء المحادثة',
      'lastMessageTime': DateTime.now().toIso8601String(),
    };

    allChats.add(newChat);
    await prefs.setStringList(
        _chatsKey, allChats.map((c) => jsonEncode(c)).toList());

    if (user2Id == adminEmail || user2Id == 'support' || user2Id == 'admin') {
      allChats[allChats.length - 1]['chatType'] = 'support';
      allChats[allChats.length - 1]['supportMode'] = 'bot';
      await prefs.setStringList(
          _chatsKey, allChats.map((c) => jsonEncode(c)).toList());

      await DataService.addNotificationToUser(
        adminEmail,
        'محادثة دعم جديدة 💬',
        '${user1Name ?? user1Id}: $propertyTitle',
        type: 'support',
        refId: chatId,
        adminFeed: true,
      );
    }

    return chatId;
  }

  /// Reuse existing support chat or create a new bot-mode support session.
  static Future<String> getOrCreateSupportChat(
    String userId,
    String userName, {
    String subtitle = 'دعم إيجاري',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getStringList(_chatsKey) ?? [];
    final allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    final existing = allChats.cast<Map<String, dynamic>?>().firstWhere(
      (c) =>
          c!['participants']?.contains(userId) == true &&
          c['participants']?.contains(adminEmail) == true &&
          (c['chatType']?.toString() == 'support' ||
              c['subtitle']?.toString().contains('دعم') == true),
      orElse: () => null,
    );

    if (existing != null) {
      return existing['id']?.toString() ?? '';
    }

    return startChat(
      userId,
      adminEmail,
      'دعم إيجاري',
      subtitle,
      user1Name: userName,
    );
  }

  static Future<void> sendSmartResponse(
      String chatId, String userMessage) async {
    await Future.delayed(const Duration(seconds: 1));

    final reply = generateAIResponse(userMessage);
    final prefs = await SharedPreferences.getInstance();

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'ai_assistant',
      'text': reply,
      'isAi': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final messages = prefs.getStringList('messages_$chatId') ?? [];
    messages.add(jsonEncode(message));
    await prefs.setStringList('messages_$chatId', messages);
  }

  static String generateAIResponse(String input) {
    input = input.toLowerCase();

    if (input.contains('سعر') ||
        input.contains('تكلفة') ||
        input.contains('بكام')) {
      return 'تختلف الأسعار حسب العقار والمدة. \n\n• الإيجار اليومي يبدأ من: **400 ج.م**\n• الإيجار الشهري يبدأ من: **5,000 ج.م**\n\nهل تود رؤية العروض المتاحة الآن؟ 🏠';
    }

    if (input.contains('حجز') || input.contains('احجز')) {
      return 'الحجز سهل جداً! 📝\n1. اختر العقار أو السيارة.\n2. اضغط "احجز الآن".\n3. أكمل التحقق للهوية وادفع بأمان.\n\nهل واجهت مشكلة في حجز معين؟';
    }

    if (input.contains('عقد') || input.contains('قانوني')) {
      return 'لا تقلق، جميع عقودنا موثقة إلكترونياً وتضمن حقك وحق المالك (عقد إيجار موحد). ⚖️\nيصلك نسخة PDF موقعة فور الدفع.';
    }

    if (input.contains('مكان') ||
        input.contains('موقع') ||
        input.contains('فين')) {
      return 'نغطي معظم مناطق القاهرة الكبرى (التجمع، زايد، المعادي، مدينة نصر). 📍\nيمكنك استخدام خريطة البحث لرؤية العقارات القريبة منك.';
    }

    if (input.contains('سيار') || input.contains('car')) {
      return 'لدينا أسطول سيارات متنوع (سيدان، SUV، فارهة). 🚗\nتذكر: نحتاج فقط لرخصة قيادة سارية لتسليم السيارة.';
    }

    if (input.contains('شكرا') || input.contains('تمام')) {
      return 'العفو! أنا هنا دائماً لمساعدتك. 😊';
    }

    return 'أهلاً بك في إيجاري.\nكيف نقدر نساعدك؟\n\n- الأسعار والحجز\n- العقود\n- الدفع والمحفظة\n- الدعم الفني';
  }
}
