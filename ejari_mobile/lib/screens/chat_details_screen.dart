import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String userName;
  final String? initialMessage;

  const ChatDetailsScreen({
    super.key,
    required this.userName,
    this.initialMessage,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text':
          'أهلاً بك في خدمات إيجاري، كيف يمكنني مساعدتك في استثمارك القادم؟',
      'time': DateTime.now().subtract(const Duration(minutes: 5)).toString(),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      if (widget.initialMessage!.startsWith('PROPERTY_ID:')) {
        _sendPropertyMessage({
          'title': 'عقار مقترح حصري',
          'price': '15,000',
          'location': 'الشيخ زايد',
          'image': 'assets/images/home1.jpg'
        });
      } else {
        _messages.add({
          'isMe': true,
          'text': widget.initialMessage,
          'time': DateTime.now().toString(),
        });
      }
    }
  }

  void _sendPropertyMessage(Map<String, dynamic> property) {
    setState(() {
      _messages.add({
        'isMe': true,
        'type': 'property',
        'property': property,
        'time': DateTime.now().toString(),
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': DateTime.now().toString(),
      });
      _messageController.clear();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isMe': false,
            'text':
                'شكراً لتواصلك مع إدارتنا. سأقوم بإرسال التفاصيل الرسمية لك حالاً.',
            'time': DateTime.now().toString(),
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).textTheme.titleLarge?.color ??
                    AppTheme.textPrimary,
                size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.borderColor,
                    child: Icon(Icons.person, color: AppTheme.borderColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).cardTheme.color ??
                                Colors.white,
                            width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.userName,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color ??
                                  AppTheme.textPrimary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          color: AppTheme.primaryColor, size: 14),
                    ],
                  ),
                  const Text('استشاري إيجاري',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.call_rounded,
                    color: Theme.of(context).textTheme.titleLarge?.color ??
                        AppTheme.textPrimary),
                onPressed: () => _showComingSoon('مكالمة صوتية')),
            IconButton(
                icon: Icon(Icons.videocam_rounded,
                    color: Theme.of(context).textTheme.titleLarge?.color ??
                        AppTheme.textPrimary),
                onPressed: () => _showComingSoon('مكالمة فيديو')),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['type'] == 'property') {
                  return _buildPropertyBubble(msg['property'], msg['isMe']);
                }
                return _buildMessageBubble(
                    msg['text'] ?? '', msg['isMe'], msg['time']);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildPropertyBubble(Map<String, dynamic> property, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: _propertyImage(
                property['image'] ?? 'assets/images/home1.jpg',
                height: 140,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${property['price']} ج.م / شهر',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.borderColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('التفاصيل',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [],
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor, shape: BoxShape.circle),
              child: IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.textPrimary),
                  onPressed: _showPropertyPicker),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: const TextStyle(color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppTheme.borderColor, AppTheme.borderColor]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPropertyPicker() async {
    final properties = await DataService.getFavorites();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إرفاق استثمار محفوظ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              if (properties.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('المفضلة النخبوية فارغة',
                            style: TextStyle(color: AppTheme.primaryColor))))
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final p = properties[index];
                      return GestureDetector(
                        onTap: () {
                          _sendPropertyMessage(p);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: _propertyImage(
                                  p['image'] ?? 'assets/images/home1.jpg',
                                  height: 100,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(p['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
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

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.borderColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: isMe ? const Radius.circular(24) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(24),
          ),
          boxShadow: const [],
        ),
        child: Text(
          text,
          style: TextStyle(
              color: isMe ? Colors.white : AppTheme.textPrimary,
              fontSize: 15,
              height: 1.5),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$feature ⏳',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هذه الخدمة ستتوفر قريباً لنخبة إيجاري.',
            style: TextStyle(color: AppTheme.primaryColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً',
                  style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );
  }
}
