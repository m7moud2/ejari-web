import 'package:flutter/material.dart';
import '../services/firestore_property_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sale_listing_widgets.dart';
import 'property_details_screen.dart';

class ForSaleScreen extends StatefulWidget {
  const ForSaleScreen({super.key});

  @override
  State<ForSaleScreen> createState() => _ForSaleScreenState();
}

class _ForSaleScreenState extends State<ForSaleScreen> {
  List<Map<String, dynamic>> _saleProperties = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'شقق', 'فلل', 'شاليهات'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await FirestorePropertyService.getAllProperties();
    setState(() {
      _saleProperties =
          all.where((p) => p['listingMode'] == 'for_sale').toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'الكل') return _saleProperties;
    return _saleProperties.where((p) => p['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Header ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.borderColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('إعلانات البيع',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/home3.jpg', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.borderColor.withOpacity(0.5),
                          AppTheme.borderColor.withOpacity(0.95)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: AppTheme.borderColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderColor)),
                          child: const Text(
                              'منصة عرض إعلانات — بدون عمولة بيع',
                              style: TextStyle(
                                  color: AppTheme.borderColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        const Text('اعرض عقارك للبيع\nبرسوم نشر فقط',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.borderColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _filters.map((f) {
                      final isSel = _selectedFilter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.borderColor
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isSel
                                    ? AppTheme.borderColor
                                    : Colors.white24),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  color: isSel
                                      ? AppTheme.borderColor
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ─── Ad platform banner ─────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SaleListingDisclaimerBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.borderColor, AppTheme.borderColor]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.campaign_rounded,
                        color: AppTheme.borderColor, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رسوم نشر فقط — لا عمولة على الصفقة',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text(
                              'المالك يدفع باقة عرض الإعلان. المشتري يتواصل مباشرة مع المالك.',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Properties List ──────────────────────────────
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64, color: AppTheme.primaryColor),
                            SizedBox(height: 16),
                            Text('لا توجد عقارات في هذه الفئة حالياً',
                                style: TextStyle(color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.only(bottom: 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSaleCard(_filtered[index]),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> p) {
    final salePrice = p['price'];

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(property: p))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.asset(
                    p['image'] as String? ?? 'assets/images/home1.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: AppTheme.backgroundColor,
                        child: const Icon(Icons.home,
                            size: 50, color: AppTheme.primaryColor)),
                  ),
                ),
                // FOR SALE badge
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.campaign_rounded,
                            color: AppTheme.borderColor, size: 14),
                        SizedBox(width: 4),
                        Text(kSaleAdBadgeLabel,
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : AppTheme.textPrimary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        '${p['area'] ?? '—'} م²',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.textPrimary
                                    : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color:
                              Theme.of(context).textTheme.titleMedium?.color ??
                                  AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(p['location'] as String? ?? '',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price comparison
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppTheme.backgroundColor
                            : AppTheme.textPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.backgroundColor
                                    : AppTheme.textPrimary)),
                    child: Row(
                      children: [
                        const Icon(Icons.sell_outlined,
                            color: AppTheme.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سعر العرض',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10)),
                              const SizedBox(height: 2),
                              FittedBox(
                                  child: Text('$salePrice ج.م',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.color ??
                                              AppTheme.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Features
                  Row(
                    children: [
                      _feat(Icons.king_bed_rounded, '${p['beds']} غرف'),
                      const SizedBox(width: 12),
                      _feat(Icons.bathtub_rounded, '${p['baths']} حمام'),
                      const SizedBox(width: 12),
                      _feat(Icons.straighten_rounded, '${p['area']} م²'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailsScreen(property: p))),
                      icon: const Icon(Icons.contact_phone_rounded, size: 18),
                      label: const Text('تواصل مع المالك',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.borderColor,
                        foregroundColor: AppTheme.borderColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
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

  Widget _feat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
