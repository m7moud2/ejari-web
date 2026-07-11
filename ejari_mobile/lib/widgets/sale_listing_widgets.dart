import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';

/// إيجاري منصة إعلانات — لا تتدخل في عملية البيع ولا تحصل على عمولة.
const String kSaleListingDisclaimer =
    'إيجاري منصة إعلانات — لا تتدخل في عملية البيع ولا تحصل على عمولة';

const String kSaleAdBadgeLabel = 'إعلان — للعرض فقط';

String resolveOwnerPhone(Map<String, dynamic> property) {
  return property['phone']?.toString() ??
      property['advertiserPhone']?.toString() ??
      property['ownerPhone']?.toString() ??
      '+201280083336';
}

class SaleListingDisclaimerBanner extends StatelessWidget {
  const SaleListingDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.28)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.accentColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              kSaleListingDisclaimer,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaleContactScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const SaleContactScreen({super.key, required this.property});

  Future<void> _call(BuildContext context) async {
    final phone = resolveOwnerPhone(property);
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
      );
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    final phone = resolveOwnerPhone(property);
    final title = property['title']?.toString() ?? 'العقار';
    final message =
        'مرحباً، أستفسر عن إعلان البيع: $title المعروض على تطبيق إيجاري.';
    final url = Uri.parse(
      'https://wa.me/${phone.replaceAll(' ', '').replaceAll('+', '')}?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = property['title']?.toString() ?? 'إعلان بيع';
    final price = property['price']?.toString() ?? '0';
    final location = property['location']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('تواصل مع المالك'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SaleListingDisclaimerBanner(),
            const SizedBox(height: 20),
            EjariSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      kSaleAdBadgeLabel,
                      style: TextStyle(
                        color: AppTheme.borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    location,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$price ج.م',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'السعر للعرض فقط — التفاوض والدفع مباشرة مع المالك.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const EjariSectionHeader(
              title: 'اتصل للاستفسار',
              subtitle: 'تواصل مباشرة مع المالك — إيجاري لا يتوسط البيع',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: AppTheme.ctaHeight,
              child: ElevatedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(Icons.phone_rounded),
                label: const Text(
                  'اتصال',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: AppTheme.ctaHeight,
              child: OutlinedButton.icon(
                onPressed: () => _whatsapp(context),
                icon: const Icon(Icons.chat_rounded, color: Colors.green),
                label: const Text(
                  'واتساب',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
