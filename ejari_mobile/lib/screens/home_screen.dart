import 'package:flutter/material.dart';
import 'sales_properties_screen.dart';
import '../widgets/ejari_navigation_bar.dart';
import 'add_property_screen.dart';
import 'property_reels_screen.dart';
import 'properties_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import 'booking_screen.dart';
import 'property_details_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import 'notifications_screen.dart';
import 'advanced_filters_screen.dart';
import 'service_details_screen.dart';
import '../l10n/app_localizations.dart';
import 'ai_concierge_screen.dart';
import 'maintenance_requests_screen.dart';
import 'my_bookings_screen.dart';
import 'my_contracts_screen.dart';
import 'tenant_wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getUserRole();
    setState(() => _currentRole = role);
  }

  List<Widget> get _screens => [
        HomeContent(role: _currentRole),
        const PropertiesScreen(),
        const AddPropertyScreen(),
        const PropertyReelsScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: EjariNavigationBar(
        currentIndex: _currentIndex,
        role: _currentRole,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadRole();
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String role;
  const HomeContent({super.key, this.role = 'tenant'});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // PropertyProvider already loads and sorts by distance on startup
    // We just trigger a rebuild by listening to the provider
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {});
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categories = [
      {
        'label': 'الكل',
        'icon': Icons.apps_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'شقق إيجاري',
        'icon': Icons.apartment_rounded,
        'color': AppTheme.textPrimary
      },
      {
        'label': 'منطقة الفلل',
        'icon': Icons.holiday_village_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'إسكان طلاب',
        'icon': Icons.school_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'مكاتب ومحلات',
        'icon': Icons.business_center_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'إقامة فندقية',
        'icon': Icons.hotel_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'شاليهات',
        'icon': Icons.beach_access_rounded,
        'color': AppTheme.primaryColor
      },
      {
        'label': 'عقارات للبيع',
        'icon': Icons.campaign_rounded,
        'color': AppTheme.errorColor
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded,
                  size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تصفح حسب الفئة',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: categories.map((cat) {
              final label = cat['label'] as String;
              final icon = cat['icon'] as IconData;
              final color = cat['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildEjariCategory(context, label, icon, color),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    // Fetch and filter from provider
    final query = _searchController.text.toLowerCase();
    const Map<String, String> typeMap = {
      'شقق إيجاري': 'شقق',
      'منطقة الفلل': 'فلل',
      'إسكان طلاب': 'استوديو',
      'مكاتب ومحلات': 'مكاتب',
      'إقامة فندقية': 'فندقي',
      'شاليهات': 'شاليهات',
    };

    _properties = propertyProvider.rentProperties;
    _filteredProperties = _properties.where((p) {
      bool categoryMatch = true;
      if (_selectedCategory != null && _selectedCategory != 'الكل') {
        final mapped = typeMap[_selectedCategory!] ?? _selectedCategory!;
        categoryMatch = (p['type'] == mapped ||
            p['type']?.toString().toLowerCase() == mapped.toLowerCase());
      }
      bool searchMatch = true;
      if (query.isNotEmpty) {
        final title = (p['title'] ?? '').toLowerCase();
        final location = (p['location'] ?? '').toLowerCase();
        searchMatch = title.contains(query) || location.contains(query);
      }
      return categoryMatch && searchMatch;
    }).toList();

    return RefreshIndicator(
        onRefresh: () async => await propertyProvider.fetchAllProperties(),
        child: Scaffold(
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  toolbarHeight: 74,
                  titleSpacing: 12,
                  backgroundColor: AppTheme.backgroundColor.withOpacity(0.95),
                  surfaceTintColor: Colors.transparent,
                  title: _buildHeader(context),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationsScreen())),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildHeroShowcase(context, propertyProvider),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildFeatureStorySection(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildTenantOverviewCard(context, propertyProvider),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildUserNeedsSection(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _buildCategoriesGrid(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory == null
                                ? context.tr('featured_properties')
                                : 'عقارات في $_selectedCategory',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (propertyProvider.userCity != null)
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    propertyProvider.userCity!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _isLoading
                    ? const SliverToBoxAdapter(
                        child: SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator())))
                    : _filteredProperties.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color ??
                                      Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.12),
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.search_off_rounded,
                                            color: AppTheme.primaryColor),
                                        SizedBox(width: 8),
                                        Text(
                                          'لا توجد نتائج مطابقة',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'جرّب تغيير الفئة أو كلمة البحث أو افتح كل العقارات لعرض المزيد من الخيارات.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.only(bottom: 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final property = _filteredProperties[index];
                                  return PropertyCard(
                                    id: property['id'] ?? '0',
                                    title: property['title'] ?? '',
                                    price: property['price'] ?? '0',
                                    location: property['location'] ?? '',
                                    image: property['image'] ??
                                        'assets/images/home1.jpg',
                                    beds: property['beds'] ?? '0',
                                    baths: property['baths'] ?? '0',
                                    area: property['area'] ?? '0',
                                    listingMode: property['listingMode'],
                                    isDemo: property['isDemo'] ?? false,
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyDetailsScreen(
                                                    property: property))),
                                    onBook: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookingScreen(
                                                itemType: 'property',
                                                itemData: property))),
                                  );
                                },
                                childCount: _filteredProperties.length,
                              ),
                            ),
                          ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: _buildEjariServicesSection(context),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.key_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إيجاري',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    widget.role == 'owner'
                        ? 'لوحة المالك'
                        : 'تجربة الإيجار الأوضح',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroShowcase(
      BuildContext context, PropertyProvider propertyProvider) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 700;
    final locationLabel = propertyProvider.userCity ?? 'السكن، القاهرة';

    final bullets = [
      (
        icon: Icons.search_rounded,
        title: 'ابحث عن العقار المناسب',
        subtitle: 'شقق • فيلات • مكاتب • محلات',
      ),
      (
        icon: Icons.verified_user_outlined,
        title: 'عقود إلكترونية موثوقة',
        subtitle: 'توثيق واضح يحفظ الحقوق',
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        title: 'دفع إلكتروني آمن',
        subtitle: 'مدفوعات متتالية وشفافة',
      ),
      (
        icon: Icons.design_services_outlined,
        title: 'خدمات صيانة معتمدة',
        subtitle: 'اختيار سريع ومتابعة مستمرة',
      ),
      (
        icon: Icons.groups_rounded,
        title: 'تواصل مباشر',
        subtitle: 'بين المستأجر والمالك والفني',
      ),
    ];

    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.96),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(26),
                bottomLeft: Radius.circular(26),
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'قريباً',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'الإطلاق الرسمي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppTheme.borderColor.withOpacity(0.55)),
              ),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.key_rounded,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إيجاري',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ejari',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'قريباً.. ',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'تجربة إيجار أسهل وأكثر أماناً',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'منصة ذكية تربط بين المستأجرين والمالكين في مكان واحد، لتجربة إيجار متكاملة وموثوقة.',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            height: 1.75,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _heroChip(Icons.location_on_outlined, locationLabel),
            _heroChip(Icons.verified_outlined, 'عقود موثقة'),
            _heroChip(Icons.security_rounded, 'دفع آمن'),
          ],
        ),
        const SizedBox(height: 18),
        ...bullets.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(item.icon, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdvancedFiltersScreen())),
                icon: const Icon(Icons.search_rounded),
                label: const Text('ابحث الآن'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PropertiesScreen())),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('استعرض الكل'),
              ),
            ),
          ],
        ),
      ],
    );

    final phoneMockup = Container(
      width: compact ? double.infinity : width * 0.38,
      constraints: const BoxConstraints(minHeight: 420, maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: Image.asset(
                'assets/images/promo/hero_download.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surfaceColor,
                  child: const Center(
                    child: Icon(Icons.phone_iphone_rounded,
                        size: 70, color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('بحث', 'سهل وسريع'),
              const SizedBox(width: 10),
              _miniStat('عقود', 'موثقة وواضحة'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          color: AppTheme.primaryColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'امسح الكود للوصول للتجربة',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.94),
              AppTheme.backgroundColor.withOpacity(0.94),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heroText,
            const SizedBox(height: 18),
            phoneMockup,
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.94),
            AppTheme.backgroundColor.withOpacity(0.94),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: heroText),
          const SizedBox(width: 18),
          Expanded(flex: 4, child: phoneMockup),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureStorySection(BuildContext context) {
    final items = [
      (
        icon: Icons.home_rounded,
        title: 'ابحث بسهولة عن العقار المناسب',
        subtitle: 'شقق، فيلات، مكاتب، ومحلات',
      ),
      (
        icon: Icons.description_outlined,
        title: 'عقود إلكترونية موثوقة',
        subtitle: 'تحافظ على الحقوق وتوضح التفاصيل',
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        title: 'دفع إلكتروني آمن',
        subtitle: 'طرق دفع متعددة ومتابعة واضحة',
      ),
      (
        icon: Icons.handyman_rounded,
        title: 'خدمات صيانة معتمدة',
        subtitle: 'فنيون موثوقون يصلون إليك',
      ),
      (
        icon: Icons.forum_rounded,
        title: 'تواصل مباشر بين الأطراف',
        subtitle: 'المستأجر والمالك ومقدمو الخدمة',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إيجاري يسهّل عليك كل خطوة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'رحلة واضحة من أول بحث لحد الحجز والمتابعة.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon,
                            color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.45,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item != items.last)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 68, top: 14, bottom: 14),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderColor.withOpacity(0.45),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.9),
                    AppTheme.accentColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجّل بياناتك الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'وأكن من أوائل المستفيدين عند الإطلاق الرسمي.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNeedsSection(BuildContext context) {
    final actions =
        <({String title, String subtitle, IconData icon, Widget page})>[
      (
        title: 'حجوزاتي',
        subtitle: 'تابع الطلب والحالة',
        icon: Icons.calendar_month_rounded,
        page: const MyBookingsScreen(),
      ),
      (
        title: 'العقود',
        subtitle: 'حقوقك ومواعيدك',
        icon: Icons.description_outlined,
        page: const MyContractsScreen(),
      ),
      (
        title: 'طلب صيانة',
        subtitle: 'بلّغ وتابع التنفيذ',
        icon: Icons.home_repair_service_outlined,
        page: const MaintenanceRequestsScreen(),
      ),
      (
        title: 'المحفظة',
        subtitle: 'مدفوعاتك في مكان واحد',
        icon: Icons.account_balance_wallet_outlined,
        page: const TenantWalletScreen(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ماذا تريد أن تنجز؟',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'اختصارات لأكثر المهام التي يحتاجها المستأجر يومياً',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => action.page),
                ),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(action.icon,
                            color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(action.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTenantOverviewCard(
      BuildContext context, PropertyProvider propertyProvider) {
    final totalRent = propertyProvider.rentProperties.length;
    final filtered = _filteredProperties.length;
    final city = propertyProvider.userCity ?? 'لم يتم تحديد الموقع بعد';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص سريع',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'كل ما تحتاجه تبدأ منه بدون ضياع وقت.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildOverviewChip('العقارات المتاحة', '$totalRent'),
                _buildOverviewChip('النتائج الحالية', '$filtered'),
                _buildOverviewChip('المدينة', city),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildEjariCategory(
      BuildContext context, String title, IconData icon, Color color) {
    bool isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () {
        if (title == 'عقارات للبيع') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SalesPropertiesScreen()),
          );
        } else {
          _filterByCategory(isSelected ? null : title);
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : (Theme.of(context).brightness == Brightness.light
                      ? AppTheme.backgroundColor
                      : AppTheme.borderColor),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? color : AppTheme.backgroundColor,
                  width: 2),
            ),
            child:
                Icon(icon, color: isSelected ? Colors.white : color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 11,
                  color: isSelected
                      ? color
                      : (Theme.of(context).textTheme.bodyMedium?.color ??
                          AppTheme.textPrimary)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEjariServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 20, color: AppTheme.borderColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('property_management_services'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildServiceCard(
                  context,
                  context.tr('safe_transport'),
                  Icons.local_shipping_rounded,
                  AppTheme.textPrimary,
                  context.tr('safe_transport_desc'),
                  2000),
              _buildServiceCard(
                  context,
                  context.tr('hotel_cleaning'),
                  Icons.cleaning_services_rounded,
                  AppTheme.primaryColor,
                  context.tr('hotel_cleaning_desc'),
                  600),
              _buildServiceCard(
                  context,
                  context.tr('emergency_maintenance'),
                  Icons.car_repair_rounded,
                  AppTheme.borderColor,
                  context.tr('emergency_maintenance_desc'),
                  450),
              _buildServiceCard(
                  context,
                  context.tr('smart_design'),
                  Icons.format_paint_rounded,
                  AppTheme.primaryColor,
                  context.tr('smart_design_desc'),
                  5000),
              _buildServiceCard(
                  context,
                  context.tr('ai_concierge'),
                  Icons.smart_toy_rounded,
                  AppTheme.primaryColor,
                  context.tr('ai_concierge_desc'),
                  0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon,
      Color color, String desc, int price) {
    return _AnimatedGlassCard(
      title: title,
      icon: icon,
      color: color,
      desc: desc,
      price: price,
    );
  }
}

class _AnimatedGlassCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String desc;
  final int price;

  const _AnimatedGlassCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.desc,
    required this.price,
  });

  @override
  State<_AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<_AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => widget.title == context.tr('ai_concierge') ||
                    widget.title == 'AI Concierge'
                ? const AiConciergeScreen()
                : ServiceDetailsScreen(
                    serviceName: widget.title,
                    description: widget.desc,
                    icon: widget.icon,
                    color: widget.color,
                    basePrice: widget.price,
                  ),
          ),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 170,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.backgroundColor
                    : AppTheme.textPrimary,
                width: 1.5),
            boxShadow: const [],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Theme.of(context).textTheme.titleMedium?.color ??
                        AppTheme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                widget.price == 0
                    ? context.tr('free_price')
                    : '${context.tr('starts_from')} ${widget.price} ${context.tr('price_egp')}',
                style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
