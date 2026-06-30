import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../utils/date_utils.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      _currentUserId = user['email']; // Using email as ID for demo
      final chats = await ChatService.getChats(_currentUserId!);

      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل 💬')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) =>
                      _buildChatCard(_chats[index]),
                ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.backgroundColor,
          child: Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        title: Text(
          chat['participants'] != null && chat['participants'].length == 2
              ? chat['participants'].firstWhere((p) => p != _currentUserId,
                  orElse: () => chat['otherUserName'] ?? 'مستخدم')
              : (chat['otherUserName'] ?? 'مستخدم'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat['subtitle'] != null)
              Text(chat['subtitle'],
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.primaryColor)),
            Text(
              chat['lastMessage'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          _formatTime(chat['lastMessageTime']),
          style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chat['id'],
                otherUserName: chat['otherUserName'],
                currentUserId: _currentUserId!,
              ),
            ),
          ).then((_) => _loadChats()); // Refresh on return
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('لا توجد محادثات',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    final time = DateParsing.parse(timeStr);
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
