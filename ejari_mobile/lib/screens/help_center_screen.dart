import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'support_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/support_service.dart';
import '../config/app_config.dart';
import '../config/social_links.dart';
import 'dart:async';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  final _reportController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _reportController.dispose();
    super.dispose();
  }

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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
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
                  _launchWhatsApp,
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  Icons.support_agent_rounded,
                  'شات الدعم',
                  AppTheme.primaryColor,
                  _openSupportChat,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionCard(
                  Icons.email_outlined,
                  'بريد الدعم',
                  AppTheme.accentColor,
                  _launchEmail,
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  Icons.privacy_tip_outlined,
                  'الخصوصية',
                  AppTheme.accentColor,
                  _openPrivacy,
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
            const SizedBox(height: 12),
            Text(
              'واتساب: ${SocialLinks.supportWhatsAppE164} · ${SocialLinks.supportEmail}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const Text('الأسئلة الشائعة',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            _buildFaqItem('كيف أقوم بحجز عقار؟',
                'افتح العقار ← احجز الآن ← أكمل البيانات ← ادفع العربون عبر البطاقة أو المحفظة أو التحويل. يمكنك متابعة الحالة من «حجوزاتي».'),
            _buildFaqItem('كيف أوثق حسابي (KYC)؟',
                'من الملف الشخصي ← طلب التوثيق. التقط صورة وجهي البطاقة والسيلفي، ثم انتظر مراجعة الإدارة.'),
            _buildFaqItem('هل المدفوعات آمنة؟',
                'مدفوعات الإيجار والحجز والصيانة لخدمات عقارية حقيقية. عند تفعيل Paymob تُعالَج البطاقة عبر بوابة آمنة، وإلا يظهر مسار تجريبي واضح.'),
            _buildFaqItem('ما دور الضمان (Escrow)؟',
                'جزء من العربون/التأمين يُحجز في المحفظة حتى انتهاء الإقامة أو إتمام الصيانة، ثم يُحرَّر أو يُخصم حسب الحالة.'),
            _buildFaqItem('ما هي الخدمات المتاحة؟',
                'حجز وإيجار قصير/طويل، معاينات، عقود، محفظة وضمان، صيانة بفنيين، ودعم داخل التطبيق.'),
          ],
        ),
      ),
    );
  }

  Future<void> _openSupportChat() async {
    try {
      final user = await AuthService.getCurrentUser()
          .timeout(AppConfig.authTimeout);
      final email = user?['email']?.toString();
      if (email == null || email.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('سجّل الدخول أولاً لفتح شات الدعم'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final name = user?['name']?.toString() ?? 'مستخدم';
      if (!mounted) return;
      await openSupportChat(
        context,
        userEmail: email,
        userName: name,
      ).timeout(AppConfig.authTimeout);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is TimeoutException
                ? 'انتهت مهلة فتح الشات. حاول مرة أخرى'
                : 'تعذر فتح شات الدعم. حاول مرة أخرى',
          ),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'إعادة',
            textColor: Colors.white,
            onPressed: _openSupportChat,
          ),
        ),
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse(SocialLinks.whatsappUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse(SocialLinks.mailtoSupport);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('راسلنا على ${SocialLinks.supportEmail}')),
      );
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح سياسة الخصوصية')),
      );
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
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    _reportController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تبليغ عن مشكلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reportController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'اشرح المشكلة التي واجهتك...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final text = _reportController.text.trim();
                if (text.isEmpty) return;

                final user = await AuthService.getCurrentUser();
                await SupportService.createTicket(
                  userEmail: user?['email']?.toString() ?? 'guest@ejari.app',
                  userName: user?['name']?.toString() ?? 'زائر',
                  subject: 'بلاغ فني',
                  message: text,
                  category: 'technical',
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال بلاغك بنجاح وسيتم التواصل معك'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
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
}
