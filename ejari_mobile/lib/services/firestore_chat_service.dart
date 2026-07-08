import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class FirestoreChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start or get existing chat
  static Future<String> startChat(
      String user1Id, String user2Id, String user2Name, String subtitle) async {
    if (AppConfig.demoMode) {
      return 'demo-chat-$user1Id-$user2Id';
    }
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user1Id)
          .get();

      // Find if chat between these two already exists
      for (var doc in querySnapshot.docs) {
        List<dynamic> participants = doc.data()['participants'] ?? [];
        if (participants.contains(user2Id)) {
          return doc.id; // Return existing chat ID
        }
      }

      // If not, create new chat
      final newChatRef = await _firestore.collection('chats').add({
        'participants': [user1Id, user2Id],
        'otherUserName':
            user2Name, // For simple UI, but usually you'd fetch from users collection
        'subtitle': subtitle,
        'lastMessage': 'بدء المحادثة',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newChatRef.id;
    } catch (e) {
      debugPrint('Error starting chat: $e');
      return '';
    }
  }

  // Stream messages for a specific chat
  static Stream<QuerySnapshot> getMessagesStream(String chatId) {
    if (AppConfig.demoMode) {
      return const Stream<QuerySnapshot>.empty();
    }
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  static Future<void> sendMessage(
      String chatId, String senderId, String text) async {
    if (AppConfig.demoMode) return;
    try {
      // 1. Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update last message in the parent chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // Get all chats for a specific user (Stream for real-time updates)
  static Stream<QuerySnapshot> getUserChatsStream(String userId) {
    if (AppConfig.demoMode) {
      return const Stream<QuerySnapshot>.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
