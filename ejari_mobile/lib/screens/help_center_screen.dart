import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المساعدة'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'بحث عن حل لمشكلة...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            const Text('تواصل معنا مباشرة',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionCard(
                  Icons.chat_bubble_outline,
                  'دعم واتساب',
                  AppTheme.primaryColor,
                  () => _launchWhatsApp(),
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  Icons.support_agent_rounded,
                  'شات الدعم',
                  AppTheme.primaryColor,
                  () async {
                    final user = await AuthService.getCurrentUser();
                    if (user != null && user['email'] != null) {
                      String chatId = await ChatService.startChat(user['email'],
                          'admin@ejari.app', 'دعم إيجاري', 'استفسار دعم فني');
                      if (!context.mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                  chatId: chatId,
                                  otherUserName: 'دعم إيجاري',
                                  currentUserId: user['email'])));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLongActionCard(
              Icons.report_gmailerrorred_rounded,
              'تبليغ عن مشكلة فنية',
              AppTheme.borderColor,
              () => _showReportDialog(context),
            ),
            const SizedBox(height: 32),
            const Text('الأسئلة الشائعة',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            _buildFaqItem('كيف أقوم بحجز عقار؟',
                'يمكنك الحجز من خلال الضغط على زر احجز الآن في صفحة العقار ورفع إيصال الدفع.'),
            _buildFaqItem('كيف أوثق حسابي؟',
                'التوثيق متاح للملاك من خلال إعدادات الملف الشخصي.'),
            _buildFaqItem('ما هي الخدمات المتاحة؟',
                'خدمات تشمل النقل الذكي، التصميم المعماري، والكونسيرج المدعوم بالذكاء الاصطناعي.'),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp() async {
    const url = "https://wa.me/201280083336";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildActionCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLongActionCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تبليغ عن مشكلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اشرح المشكلة التي واجهتك...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم إرسال بلاغك بنجاح وسيتم التواصل معك')),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title:
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(answer))
      ],
    );
  }
}
