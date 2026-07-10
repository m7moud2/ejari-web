import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_chat_service.dart';
import '../services/chat_service.dart';
import '../services/data_service.dart';
import '../config/app_config.dart';
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
  List<Map<String, dynamic>> _localMessages = [];
  bool _loadingLocal = true;

  @override
  void initState() {
    super.initState();
    if (AppConfig.demoMode) {
      _loadLocalMessages();
    }
  }

  Future<void> _loadLocalMessages() async {
    final messages = await ChatService.getMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _localMessages = messages;
      _loadingLocal = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    if (AppConfig.demoMode) {
      await ChatService.sendMessage(widget.chatId, widget.currentUserId, text);

      final isAdminSender = widget.currentUserId == 'admin@ejari.app';
      if (isAdminSender) {
        final otherId = widget.otherUserName == 'دعم إيجاري'
            ? null
            : _peerEmail();
        if (otherId != null && otherId != 'admin@ejari.app') {
          await DataService.addNotificationToUser(
            otherId,
            'رد من دعم إيجاري 💬',
            text,
            type: 'support',
            refId: widget.chatId,
          );
        }
      } else {
        await DataService.addNotificationToUser(
          'admin@ejari.app',
          'رسالة دعم جديدة',
          text,
          type: 'support',
          refId: widget.chatId,
          adminFeed: true,
        );
      }

      await _loadLocalMessages();
      _scrollToBottom();
      return;
    }

    await FirestoreChatService.sendMessage(
        widget.chatId, widget.currentUserId, text);
    _scrollToBottom();
  }

  String? _peerEmail() {
    // Best-effort for demo notifications
    if (widget.currentUserId == 'admin@ejari.app') {
      return widget.otherUserName.contains('@')
          ? widget.otherUserName
          : null;
    }
    return widget.currentUserId;
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
            Expanded(
              child: Text(
                widget.otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
            child: AppConfig.demoMode
                ? _buildLocalMessages()
                : _buildFirestoreMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLocalMessages() {
    if (_loadingLocal) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_localMessages.isEmpty) {
      return const Center(child: Text('لا توجد رسائل حتى الآن.'));
    }

    final reversed = _localMessages.reversed.toList();
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final msg = reversed[index];
        final isMe = msg['senderId'] == widget.currentUserId;
        String timeStr = '';
        final ts = msg['timestamp']?.toString();
        if (ts != null && ts.isNotEmpty) {
          final dt = DateTime.tryParse(ts);
          if (dt != null) {
            timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          }
        }
        return _buildMessageBubble(msg['text'] ?? '', isMe, timeStr);
      },
    );
  }

  Widget _buildFirestoreMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreChatService.getMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد رسائل حتى الآن.'));
        }

        final messages = snapshot.data!.docs;
        final reversedMessages = messages.reversed.toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: reversedMessages.length,
          itemBuilder: (context, index) {
            final msg =
                reversedMessages[index].data() as Map<String, dynamic>;
            final isMe = msg['senderId'] == widget.currentUserId;

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
