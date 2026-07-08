import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_theme.dart';
import '../my_contracts_screen.dart';
import '../tenant_installments_screen.dart';
import '../search_results_screen.dart';
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
          _buildGreeting(context, stats),
          const SizedBox(height: 16),
          _buildSearchCard(context),
          const SizedBox(height: 16),
          _buildQuickActions(context, stats),
          if (stats['activeBooking'] == true || (stats['nextInstallmentDays'] ?? 99) <= 7) ...[
            const SizedBox(height: 14),
            _buildBookingAlert(context, stats),
          ],
          const SizedBox(height: 18),
          _buildSectionTitle('عقارات مقترحة لك'),
          const SizedBox(height: 8),
          _buildPropertyStrip(context, recommended),
          const SizedBox(height: 16),
          _buildSectionTitle('العقارات المميزة'),
          const SizedBox(height: 8),
          _buildPropertyStrip(context, featured),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً ${stats['userName'] ?? 'بك'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stats['verificationStatus'] ?? 'ابحث عن وحدتك القادمة',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (stats['activeBooking'] == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'حجز نشط',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SearchResultsScreen(query: ''),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
        ),
        child: const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'ابحث عن شقة، فيلا، مكتب...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic> stats) {
    final quickActions = [
      (
        title: 'ابحث',
        icon: Icons.search_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: 'شقة')),
            ),
      ),
      (
        title: 'احجز',
        icon: Icons.event_available_rounded,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultsScreen(query: 'حجز')),
            ),
      ),
      (
        title: 'سدد القسط',
        icon: Icons.payments_rounded,
        onTap: () => _openRentPayment(context, stats),
      ),
      (
        title: 'عقودي',
        icon: Icons.description_outlined,
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyContractsScreen()),
            ),
      ),
    ];

    return Row(
      children: quickActions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: action.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.22)),
                  ),
                  child: Column(
                    children: [
                      Icon(action.icon,
                          color: AppTheme.primaryColor, size: 26),
                      const SizedBox(height: 8),
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
}
