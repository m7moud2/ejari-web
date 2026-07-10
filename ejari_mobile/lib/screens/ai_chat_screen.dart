import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_concierge_service.dart';
import '../screens/property_details_screen.dart';
import '../utils/safe_parse.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _addBotMessage(
        'أهلاً بك يا سيدي في "إيجاري كونسيرج" 🔑\nأنا مساعدك النخبوي.. كيف يمكنني ترتيب احتياجاتك اليوم؟');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true, 'time': DateTime.now()});
    });
    _scrollToBottom();
    _processAiResponse(text);
  }

  void _addBotMessage(String text, {List<Map<String, dynamic>>? suggestions}) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': false,
        'time': DateTime.now(),
        'suggestions': suggestions
      });
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _processAiResponse(String input) async {
    setState(() => _isTyping = true);

    final result = await AiConciergeService.getChatResponse(input);
    final String responseText = safeStr(result['reply'], 'عذراً، لم أتمكن من الرد الآن.');
    final List<Map<String, dynamic>> properties =
        (result['properties'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

    if (mounted) {
      setState(() => _isTyping = false);
      _addBotMessage(responseText,
          suggestions: properties.isNotEmpty ? properties : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [],
                    ),
                    child: const Icon(Icons.stars_rounded,
                        color: AppTheme.primaryColor, size: 24),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text('Ejari Concierge',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Serif')),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Premium Background with Obsidian overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/home1.jpg',
              fit: BoxFit.cover,
              color: AppTheme.primaryColor.withOpacity(0.9),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 100), // Appbar spacing
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
              // Quick Actions
              if (_messages.isEmpty || _messages.length < 3)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAction('عقارات مميزة',
                            'اعرض لي أفضل العقارات المتاحة حالياً'),
                        _buildQuickAction(
                            'سيارات فارهة 🏎️', 'أرغب في استئجار سيارة رياضية'),
                        _buildQuickAction(
                            'تنظيف فندقي 🧹', 'احتاج لخدمة تنظيف فندقية'),
                      ],
                    ),
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'];
    final suggestions = msg['suggestions'] as List<Map<String, dynamic>>?;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppTheme.textPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primaryColor : AppTheme.textPrimary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                    bottomRight: isUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          width: 0.5),
                ),
                child: Text(
                  msg['text'],
                  style: TextStyle(
                    color: isUser ? AppTheme.primaryColor : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.person,
                    color: AppTheme.primaryColor, size: 18),
              ),
            ],
          ],
        ),
        if (suggestions != null && suggestions.isNotEmpty)
          Container(
            height: 250,
            margin: const EdgeInsets.only(bottom: 20, right: 40),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PropertyDetailsScreen(property: item))),
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.15)),
                      boxShadow: const [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Stack(
                            children: [
                              _propertyImage(
                                item['image'] ?? 'assets/images/home1.jpg',
                                height: 120,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: AppTheme.textPrimary,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 12,
                                          color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text('${item['rating']}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('${item['price']} ج.م',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMiniBadge(Icons.bed, item['beds']),
                                  _buildMiniBadge(Icons.bathtub, item['baths']),
                                  _buildMiniBadge(
                                      Icons.square_foot, item['area']),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _propertyImage(String imagePath, {required double height}) {
    final isNetwork = imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/home1.jpg',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      imagePath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/home1.jpg',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: AppTheme.textPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.more_horiz,
                color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('يفكر...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 30),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(top: BorderSide(color: AppTheme.textPrimary, width: 1)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.textPrimary,
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('التعرف الصوتي غير متوفر حالياً')));
                      },
                    ),
                  ),
                );
              }),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'اطلب من الكونسيرج...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addUserMessage(value);
                    _controller.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_controller.text.trim().isNotEmpty) {
                _addUserMessage(_controller.text);
                _controller.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.borderColor]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => _addUserMessage(message),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor, width: 1.5),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
