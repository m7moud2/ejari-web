import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String _chatsKey = 'chats';

  // Get all chats for a user
  static Future<List<Map<String, dynamic>>> getChats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatsJson = prefs.getStringList(_chatsKey) ?? [];
    List<Map<String, dynamic>> allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    // Filter chats where user is participant
    return allChats
        .where((chat) => chat['participants'].contains(userId))
        .toList();
  }

  // Get messages for a specific chat
  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> messagesJson = prefs.getStringList('messages_$chatId') ?? [];
    return messagesJson
        .map((m) => jsonDecode(m) as Map<String, dynamic>)
        .toList();
  }

  // Send a message
  static Future<void> sendMessage(
      String chatId, String senderId, String text) async {
    final prefs = await SharedPreferences.getInstance();

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save message
    List<String> messages = prefs.getStringList('messages_$chatId') ?? [];
    messages.add(jsonEncode(message));
    await prefs.setStringList('messages_$chatId', messages);

    // Update chat last message
    List<String> chatsJson = prefs.getStringList(_chatsKey) ?? [];
    List<Map<String, dynamic>> allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    int index = allChats.indexWhere((c) => c['id'] == chatId);
    if (index != -1) {
      allChats[index]['lastMessage'] = text;
      allChats[index]['lastMessageTime'] = DateTime.now().toIso8601String();
      await prefs.setStringList(
          _chatsKey, allChats.map((c) => jsonEncode(c)).toList());
    }
  }

  // Start a new chat
  static Future<String> startChat(String user1Id, String user2Id,
      String user2Name, String propertyTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatsJson = prefs.getStringList(_chatsKey) ?? [];
    List<Map<String, dynamic>> allChats =
        chatsJson.map((c) => jsonDecode(c) as Map<String, dynamic>).toList();

    // Check if chat already exists
    // For simplicity, we just check participants. In real app, might be per property.
    var existingChat = allChats.firstWhere(
      (c) =>
          c['participants'].contains(user1Id) &&
          c['participants'].contains(user2Id),
      orElse: () => {},
    );

    if (existingChat.isNotEmpty) {
      return existingChat['id'];
    }

    // Create new chat
    String chatId = DateTime.now().millisecondsSinceEpoch.toString();
    final newChat = {
      'id': chatId,
      'participants': [user1Id, user2Id],
      'otherUserName': user2Name, // Simplified for demo
      'subtitle': propertyTitle,
      'lastMessage': 'بدء المحادثة',
      'lastMessageTime': DateTime.now().toIso8601String(),
    };

    allChats.add(newChat);
    await prefs.setStringList(
        _chatsKey, allChats.map((c) => jsonEncode(c)).toList());

    // Auto-send welcome message for support chats
    if (user2Id == 'support' || user2Id == 'admin') {
      await sendMessage(chatId, user2Id,
          'أهلاً بك في دعم إيجاري. سيتم الرد عليك من خلال ممثل خدمة العملاء في أقرب وقت. يمكنك كتابة استفسارك هنا وسنوافيك بالرد.');
    }

    return chatId;
  }

  static Future<void> sendSmartResponse(
      String chatId, String userMessage) async {
    // Simulate thinking time
    await Future.delayed(const Duration(seconds: 1));

    String reply = generateAIResponse(userMessage);

    final prefs = await SharedPreferences.getInstance();

    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'ai_assistant',
      'text': reply,
      'isAi': true, // Flag for UI styling
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save message
    List<String> messages = prefs.getStringList('messages_$chatId') ?? [];
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

    // Default
    return 'أهلاً بك في "إيجاري"! 👋\nأنا مساعدك الذكي. كيف يمكنني خدمتك اليوم؟\n\n- استفسار عن الأسعار\n- كيفية الحجز\n- عقود الإيجار\n- الدعم الفني';
  }
}
