import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/chat_service.dart';
import '../services/data_service.dart';
import '../services/support_bot_service.dart';
import 'maintenance_requests_screen.dart';
import 'my_contracts_screen.dart';

class SupportChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String userName;
  final String userEmail;

  const SupportChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _escalated = false;
  bool _botTyping = false;
  Timer? _pollTimer;

  bool _showShortcutPanel = true;
  bool _showFeedbackPanel = false;
  bool _suggestEscalation = false;
  String? _pendingFeedbackMsgId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _escalated = await SupportBotService.isEscalated(widget.chatId);
    await SupportBotService.initializeChat(widget.chatId);
    await _loadMessages();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final messages = await ChatService.getMessages(widget.chatId);
    if (!mounted) return;

    final escalated = await SupportBotService.isEscalated(widget.chatId);
    final lastBot = messages.lastWhere(
      (m) => m['isBot'] == true,
      orElse: () => <String, dynamic>{},
    );

    final changed = messages.length != _messages.length;
    setState(() {
      _messages = messages;
      _loading = false;
      _escalated = escalated;

      if (!escalated && lastBot.isNotEmpty) {
        _showShortcutPanel = lastBot['showShortcuts'] == true;
        _showFeedbackPanel = lastBot['showFeedback'] == true;
        _suggestEscalation = lastBot['suggestEscalation'] == true;
        _pendingFeedbackMsgId = _showFeedbackPanel
            ? lastBot['id']?.toString()
            : null;
      } else {
        _showShortcutPanel = false;
        _showFeedbackPanel = false;
      }
    });

    if (changed && !silent) _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onShortcutTap(String shortcutId) async {
    if (_botTyping) return;
    setState(() {
      _botTyping = true;
      _showShortcutPanel = false;
      _showFeedbackPanel = false;
    });

    await SupportBotService.handleShortcut(
      chatId: widget.chatId,
      shortcutId: shortcutId,
      userId: widget.currentUserId,
      userName: widget.userName,
      userEmail: widget.userEmail,
    );

    setState(() => _botTyping = false);
    await _loadMessages();
    _scrollToBottom();
  }

  Future<void> _onFeedback(bool helped) async {
    setState(() {
      _showFeedbackPanel = false;
      _botTyping = true;
    });

    await SupportBotService.handleFeedback(
      chatId: widget.chatId,
      helped: helped,
      userId: widget.currentUserId,
      userName: widget.userName,
      userEmail: widget.userEmail,
    );

    setState(() => _botTyping = false);
    await _loadMessages();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _botTyping) return;
    _messageController.clear();

    if (_escalated) {
      await ChatService.sendMessage(
        widget.chatId,
        widget.currentUserId,
        text,
      );
      await DataService.addNotificationToUser(
        ChatService.adminEmail,
        'رسالة دعم جديدة',
        text,
        type: 'support',
        refId: widget.chatId,
        adminFeed: true,
      );
      await _loadMessages();
      _scrollToBottom();
      return;
    }

    setState(() => _botTyping = true);
    await SupportBotService.handleFreeText(
      chatId: widget.chatId,
      text: text,
      userId: widget.currentUserId,
      userName: widget.userName,
      userEmail: widget.userEmail,
    );
    setState(() => _botTyping = false);
    await _loadMessages();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceColor,
              child: Icon(
                _escalated ? Icons.support_agent : Icons.help_outline,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دعم إيجاري',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _escalated ? 'موظف خدمة العملاء' : 'رد آلي',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          Expanded(child: _buildMessageList()),
          if (_botTyping) _buildTypingIndicator(),
          if (_showFeedbackPanel) _buildFeedbackBar(),
          if (_showShortcutPanel && !_escalated) _buildShortcutPanel(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: _escalated
          ? AppTheme.successColor.withOpacity(0.12)
          : AppTheme.primaryColor.withOpacity(0.08),
      child: Row(
        children: [
          Icon(
            _escalated ? Icons.verified_user_outlined : Icons.support_agent_outlined,
            color: _escalated ? AppTheme.successColor : AppTheme.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _escalated
                  ? 'تم تحويلك لموظف — سيرد عليك قريباً'
                  : 'اختر موضوعاً سريعاً أو اكتب سؤالك',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _escalated
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('جاري تحميل المحادثة...'));
    }

    final reversed = _messages.reversed.toList();
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final msg = reversed[index];
        return _buildMessageItem(msg);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final senderId = msg['senderId']?.toString() ?? '';
    final isMe = senderId == widget.currentUserId;
    final isBot = msg['isBot'] == true || senderId == SupportBotService.botSenderId;
    final isAdmin = senderId == ChatService.adminEmail;
    final isSystem = msg['isSystem'] == true;

    String timeStr = '';
    final ts = msg['timestamp']?.toString();
    if (ts != null && ts.isNotEmpty) {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: EjariSurfaceCard(
            padding: const EdgeInsets.all(10),
            elevated: false,
            child: Text(
              msg['text']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (isBot)
          const Padding(
            padding: EdgeInsets.only(bottom: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 14, color: AppTheme.primaryColor),
                SizedBox(width: 4),
                Text(
                  'دعم إيجاري',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (isAdmin)
          const Padding(
            padding: EdgeInsets.only(bottom: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent,
                    size: 14, color: AppTheme.successColor),
                SizedBox(width: 4),
                Text(
                  'موظف الدعم',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        _buildBubble(
          text: msg['text']?.toString() ?? '',
          isMe: isMe,
          isBot: isBot,
          isAdmin: isAdmin,
          timeStr: timeStr,
        ),
        if (isBot && msg['showFeedback'] == true && _pendingFeedbackMsgId == msg['id']?.toString())
          const SizedBox(height: 4),
        if (isBot && msg['actionRoute'] == 'maintenance')
          _buildActionLink('فتح طلبات الصيانة', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MaintenanceRequestsScreen(),
              ),
            );
          }),
        if (isBot && msg['actionRoute'] == 'contracts')
          _buildActionLink('فتح العقود والإيصالات', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyContractsScreen()),
            );
          }),
      ],
    );
  }

  Widget _buildActionLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isMe,
    required bool isBot,
    required bool isAdmin,
    required String timeStr,
  }) {
    Color bg;
    Color fg;
    if (isMe) {
      bg = AppTheme.primaryColor;
      fg = Colors.white;
    } else if (isBot) {
      bg = AppTheme.surfaceColor;
      fg = AppTheme.textPrimary;
    } else if (isAdmin) {
      bg = AppTheme.successColor.withOpacity(0.15);
      fg = AppTheme.textPrimary;
    } else {
      bg = AppTheme.backgroundColor;
      fg = AppTheme.textPrimary;
    }

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? Radius.zero : const Radius.circular(16),
            bottomRight: isMe ? const Radius.circular(16) : Radius.zero,
          ),
          border: isBot
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.15))
              : null,
          boxShadow: isBot
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: fg, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe ? Colors.white70 : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'جاري الرد...',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBar() {
    return EjariSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'هل ساعدك هذا؟',
            subtitle: 'أخبرنا لنحسّن تجربتك',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onFeedback(true),
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  label: const Text('نعم'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onFeedback(false),
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                  label: const Text('لا'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutPanel() {
    final shortcuts = SupportBotService.shortcutsForUi();
    return EjariSurfaceCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      radius: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EjariSectionHeader(
            title: _suggestEscalation ? 'جرب خياراً آخر' : 'اختر موضوعاً',
            subtitle: _suggestEscalation
                ? 'أو تحدث مع موظف خدمة العملاء'
                : 'مواضيع شائعة',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shortcuts.map((s) {
              final isEsc = s['isEscalation'] == true;
              return ActionChip(
                label: Text(
                  s['label']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isEsc ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                backgroundColor: isEsc
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.08),
                side: BorderSide(
                  color: isEsc
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.2),
                ),
                onPressed: () => _onShortcutTap(s['id']?.toString() ?? ''),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _escalated
                    ? 'اكتب رسالتك لموظف الدعم...'
                    : 'اكتب سؤالك أو اختر اختصاراً...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
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

/// Opens or resumes a support bot chat for the current user.
Future<void> openSupportChat(
  BuildContext context, {
  required String userEmail,
  required String userName,
}) async {
  final chatId = await ChatService.getOrCreateSupportChat(
    userEmail,
    userName,
  );
  await SupportBotService.initializeChat(chatId);

  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SupportChatScreen(
        chatId: chatId,
        currentUserId: userEmail,
        userName: userName,
        userEmail: userEmail,
      ),
    ),
  );
}
