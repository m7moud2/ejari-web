import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../my_contracts_screen.dart';
import '../tenant_installments_screen.dart';
import '../maintenance_requests_screen.dart';
import '../help_center_screen.dart';
import '../rental_statement_screen.dart';
import '../search_results_screen.dart';
import '../coupons_screen.dart';
import '../property_reels_screen.dart';
import '../payment_screen.dart';

class TenantHomeView extends StatelessWidget {
  const TenantHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeProvider>().stats.tenantStats;
    final recommended = List<Map<String, dynamic>>.from(
      stats['recommendedProperties'] ?? const [],
    );
    final featured = List<Map<String, dynamic>>.from(
      stats['featuredProperties'] ?? const [],
    );

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => context.read<HomeProvider>().loadHomeData('tenant'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHero(context, stats),
          const SizedBox(height: 14),
          _buildSearchCard(),
          const SizedBox(height: 14),
          _buildQuickFilters(),
          const SizedBox(height: 14),
          _buildQuickActions(context, stats),
          const SizedBox(height: 14),
          _buildBookingAlert(context, stats),
          const SizedBox(height: 14),
          _buildOfferBanner(context, stats),
          const SizedBox(height: 14),
          _buildSectionTitle('عقارات مقترحة لك'),
          const SizedBox(height: 4),
          const Text(
            'اختيارات أقرب لتفضيلاتك وتساعدك تختصر وقت البحث.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildPropertyStrip(context, recommended),
          const SizedBox(height: 12),
          _buildSectionTitle('العقارات المميزة'),
          const SizedBox(height: 4),
          const Text(
            'عقارات موثقة أو ذات ظهور أعلى لتسهيل المقارنة قبل القرار.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildPropertyStrip(context, featured),
          const SizedBox(height: 14),
          _buildTourHintCard(context),
          const SizedBox(height: 12),
          _buildSectionTitle('آخر الأنشطة'),
          ..._buildRecentActivities(context, stats),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentColor,
                child: Icon(Icons.person, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً ${stats['userName'] ?? 'بك'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حساب ${stats['verificationStatus'] ?? 'قيد التوثيق'} • استعد لاكتشاف أفضل الفرص',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroMetric(
                  'الحجز النشط', '${stats['activeBooking'] == true ? 1 : 0}'),
              _buildHeroMetric(
                  'أيام للقسط', '${stats['nextInstallmentDays'] ?? 0}'),
              _buildHeroMetric('المحفوظ', '${stats['savedCount'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 124),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن شقة، فيلا، مكتب...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SearchHintChip(label: 'المدينة'),
              _SearchHintChip(label: 'المنطقة'),
              _SearchHintChip(label: 'السعر'),
              _SearchHintChip(label: 'الغرف'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = ['شقة', 'فيلا', 'مكتب', 'محل', 'شاليه'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: index == 0 ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: index == 0
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor.withOpacity(0.22),
            ),
          ),
          child: Text(
            filters[index],
            style: TextStyle(
              color: index == 0 ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> stats) {
    final quickActions = [
      (
        title: 'ابحث عن شقة',
        subtitle: 'ابدأ من البحث الذكي',
        icon: Icons.search_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: 'شقة')),
            ),
      ),
      (
        title: 'احجز الآن',
        subtitle: 'احجز الوحدة المناسبة',
        icon: Icons.event_available_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: 'حجز')),
            ),
      ),
      (
        title: 'سدد القسط الآن',
        subtitle: 'ادفع المستحق الحالي',
        icon: Icons.payments_rounded,
        onTap: () => _openRentPayment(context, stats),
      ),
      (
        title: 'كشف حساب الإيجار',
        subtitle: 'كل الأقساط والإيصالات',
        icon: Icons.account_balance_wallet_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RentalStatementScreen()),
            ),
      ),
      (
        title: 'اطلب صيانة',
        subtitle: 'أنشئ طلباً وتابع حالته',
        icon: Icons.build_circle_outlined,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MaintenanceRequestsScreen()),
            ),
      ),
      (
        title: 'كارت الخصم',
        subtitle: 'عروض وكوبونات مفيدة',
        icon: Icons.local_offer_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CouponsScreen()),
            ),
      ),
      (
        title: 'تواصل مع الدعم',
        subtitle: 'حلول واستفساراتك',
        icon: Icons.support_agent_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
      ),
      (
        title: 'عقودي',
        subtitle: 'ملخص العقد والمتابعة',
        icon: Icons.description_outlined,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyContractsScreen()),
            ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('خدمات سريعة',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quickActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 118,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return _ActionCard(
                title: action.title,
                subtitle: action.subtitle,
                icon: action.icon,
                onTap: action.onTap,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingAlert(BuildContext context, Map<String, dynamic> stats) {
    final nextAmount = stats['nextInstallmentAmount'] ?? 0;
    final nextDays = stats['nextInstallmentDays'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.25)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.payments_rounded, color: Colors.white),
          ),
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('أقرب قسط مستحق',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'متبقي $nextDays أيام على سداد $nextAmount ج.م',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, height: 1.4, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openRentPayment(context, stats),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('ادفع الآن'),
          ),
        ],
      ),
    );
  }

  void _openRentPayment(BuildContext context, Map<String, dynamic> stats) {
    final bookingId = stats['bookingId']?.toString() ?? '';
    final bookingTitle = stats['bookingTitle']?.toString() ?? 'حجز الإيجار';
    final monthlyRent = (stats['monthlyRent'] as num?)?.toDouble() ?? 0.0;
    final depositAmount =
        (stats['depositAmount'] as num?)?.toDouble() ?? monthlyRent * 0.1;
    final remainingAmount = (stats['remainingAmount'] as num?)?.toDouble() ??
        (monthlyRent - depositAmount);
    final bookingStatus = stats['bookingStatus']?.toString() ?? 'deposit_paid';
    final paymentStage =
        bookingStatus == 'deposit_paid' ? 'remaining' : 'deposit';

    if (bookingId.isEmpty || monthlyRent <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TenantInstallmentsScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: {
            'id': bookingId,
            'title': bookingTitle,
            'monthlyRent': monthlyRent,
            'price': monthlyRent,
            'status': bookingStatus,
            'ownerId': stats['ownerId']?.toString() ?? 'owner',
          },
          amount: paymentStage == 'remaining' ? remainingAmount : depositAmount,
          paymentStage: paymentStage,
          totalAmount: monthlyRent,
          depositAmount: depositAmount,
          remainingAmount: remainingAmount,
        ),
      ),
    );
  }

  Widget _buildTourHintCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PropertyReelsScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الجولات السريعة',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تعرف على الشكل والموقع قبل الزيارة.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
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

  List<Widget> _buildRecentActivities(
      BuildContext context, Map<String, dynamic> stats) {
    final rawActivities = List<Map<String, dynamic>>.from(
      stats['recentActivities'] ?? const [],
    );

    if (rawActivities.isEmpty) {
      return [
        _buildActivityCard(
          icon: Icons.search_rounded,
          title: 'ابحث عن عقار',
          subtitle: 'ابدأ رحلة البحث من الصفحة الرئيسية.',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: 'شقة'))),
        ),
      ];
    }

    return rawActivities.take(3).map((activity) {
      final iconName = activity['icon']?.toString() ?? 'notifications';
      final icon = switch (iconName) {
        'payments' => Icons.payments_rounded,
        'contract' => Icons.description_outlined,
        'favorite' => Icons.favorite_outline_rounded,
        'search' => Icons.search_rounded,
        _ => Icons.notifications_none_rounded,
      };

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildActivityCard(
          icon: icon,
          title: activity['title']?.toString() ?? '',
          subtitle: activity['subtitle']?.toString() ?? '',
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TenantInstallmentsScreen())),
        ),
      );
    }).toList();
  }

  Widget _buildOfferBanner(BuildContext context, Map<String, dynamic> stats) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CouponsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.local_offer_rounded,
                color: AppTheme.accentColor, size: 30),
            SizedBox(
              width: 220,
              child: Text(
                stats['offers'] ??
                    'اكتشف عروضًا حصرية وخصومات مميزة هذا الأسبوع',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildPropertyStrip(
      BuildContext context, List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 186,
      child: items.isEmpty
          ? const Center(child: Text('لا توجد بيانات حالياً'))
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SearchResultsScreen(
                              query: item['title'] ?? 'عقار مميز'))),
                  child: Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppTheme.borderColor.withOpacity(0.18)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          child: _propertyImage(
                            item['image'] ?? 'assets/images/home1.jpg',
                            height: 84,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary)),
                              const SizedBox(height: 3),
                              Text(item['location'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${item['price'] ?? ''} ج.م',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _propertyImage(String imagePath, {required double height}) {
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
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

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon ?? Icons.arrow_outward_rounded,
                  size: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHintChip extends StatelessWidget {
  final String label;
  const _SearchHintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
