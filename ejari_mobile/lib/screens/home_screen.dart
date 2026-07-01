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
import 'search_results_screen.dart';
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

  void _performLiveSearch(String query) {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {});
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _performLiveSearch,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SearchResultsScreen(query: value)),
                  );
                }
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.tr('search_hint'),
                hintStyle:
                    const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performLiveSearch('');
                        })
                    : null,
              ),
            ),
          ),
          Container(
              height: 50,
              width: 1,
              color: AppTheme.primaryColor.withOpacity(0.2)),
          IconButton(
            icon: Icon(Icons.tune_rounded,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdvancedFiltersScreen())),
          ),
        ],
      ),
    );
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
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 224,
                        floating: true,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: AppTheme.backgroundColor,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset('assets/images/promo/hero_building.jpg',
                                  fit: BoxFit.cover,
                                  color: AppTheme.textPrimary.withOpacity(0.18),
                                  colorBlendMode: BlendMode.darken),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.primaryColor.withOpacity(0.46),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 98,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.74),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppTheme.borderColor.withOpacity(0.28),
                                    ),
                                  ),
                                  child: const Text(
                                    'منصة إيجاري الذكية للإيجار • بأسلوب هادئ وراقي',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(108),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildSearchBar(context),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.role == 'owner'
                                              ? 'مرحباً، مستثمر إيجاري'
                                              : 'مرحباً بك في إيجاري',
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.76),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppTheme.borderColor.withOpacity(0.5),
                                              width: 0.5),
                                        ),
                                        child: const Text('عضو مؤسس',
                                            style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      widget.role == 'owner'
                                          ? 'إدارة استثماراتك'
                                          : 'استأجر أفضل الشقق في إيجاري والمنطقة',
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_active_rounded,
                                color: AppTheme.textPrimary),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen())),
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildTrustStrip(context),
                            const SizedBox(height: 20),
                            _buildHowItWorksSection(context),
                            const SizedBox(height: 20),
                            _buildTenantOverviewCard(context, propertyProvider),
                            const SizedBox(height: 20),
                            _buildUserNeedsSection(context),
                            const SizedBox(height: 24),
                            _buildCategoriesGrid(context),
                            const SizedBox(height: 28),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16,
                                              color: AppTheme.primaryColor),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 110),
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _isLoading
                          ? const SliverToBoxAdapter(
                              child: SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator())))
                          : _filteredProperties.isEmpty
                              ? SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                                .cardTheme
                                                .color ??
                                            Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.12),
                                        ),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.search_off_rounded,
                                                  color:
                                                      AppTheme.primaryColor),
                                              SizedBox(width: 8),
                                              Text(
                                                'لا توجد نتائج مطابقة',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppTheme.textPrimary,
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
                                              builder: (context) =>
                                                  BookingScreen(
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
              ],
            ),
          ),
        ));
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

  Widget _buildTrustStrip(BuildContext context) {
    final items = [
      {
        'icon': Icons.verified_outlined,
        'title': 'عقارات موثقة',
        'subtitle': 'تفاصيل وصور أوضح قبل القرار',
      },
      {
        'icon': Icons.description_outlined,
        'title': 'عقد واضح',
        'subtitle': 'حماية حقوق الطرفين',
      },
      {
        'icon': Icons.support_agent_outlined,
        'title': 'متابعة مستمرة',
        'subtitle': 'طلبك لا يضيع',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: AppTheme.primaryColor, size: 18),
                      const SizedBox(height: 10),
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final steps = [
      (
        title: 'ابحث',
        subtitle: 'فلتر على السعر، الموقع، ونوع الوحدة بسرعة',
        icon: Icons.search_rounded,
      ),
      (
        title: 'عاين',
        subtitle: 'افتح التفاصيل واحجز المعاينة لو مناسب',
        icon: Icons.event_available_rounded,
      ),
      (
        title: 'كمّل بثقة',
        subtitle: 'استكمل بخطوات واضحة بدل اللفة الطويلة',
        icon: Icons.verified_user_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.08),
              Colors.white,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إزاي إيجاري بيمشي؟',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'رحلة مختصرة وواضحة من أول بحث لحد حجز المعاينة.',
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final step = steps[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(step.icon,
                            color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          step.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdvancedFiltersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('ابدأ البحث'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PropertiesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.apartment_rounded),
                    label: const Text('كل العقارات'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
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
