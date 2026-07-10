import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom periodically if needed, or rely on reverse list
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Because we will use reverse: true in ListView
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    _messageController.clear();

    await FirestoreChatService.sendMessage(
        widget.chatId, widget.currentUserId, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceColor,
              child: Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Security Warning
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.borderColor.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppTheme.borderColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه: لا تقم بأي تحويلات مالية خارج التطبيق. إيجاري غير مسؤول عن أي تعاملات خارجية.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.borderColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreChatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل حتى الآن.'));
                }

                final messages = snapshot.data!.docs;
                // Reverse the messages to show the latest at the bottom
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Auto scrolls to bottom natively
                  padding: const EdgeInsets.all(16),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        reversedMessages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.currentUserId;

                    // Handle Firestore Timestamp
                    String timeStr = '';
                    if (msg['timestamp'] != null) {
                      final dt = (msg['timestamp'] as Timestamp).toDate();
                      timeStr =
                          '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    }

                    return _buildMessageBubble(
                        msg['text'] ?? '', isMe, timeStr);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String timeStr) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? Radius.zero : const Radius.circular(16),
            bottomRight: isMe ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                  color: isMe ? Colors.white70 : AppTheme.textPrimary,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
