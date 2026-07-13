import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../widgets/empty_state_view.dart';
import '../utils/property_image_resolver.dart';
import '../utils/short_stay_discovery.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_list_loader.dart';
import '../widgets/ejari_section.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import 'map_search_screen.dart';
import 'advanced_filters_screen.dart';
import '../models/listing_type.dart';
import '../widgets/sale_listing_widgets.dart';
import '../models/accommodation_type.dart';
import '../services/offline_cache_service.dart';
import '../widgets/offline_banner.dart';

enum _ExploreSort { newest, priceAsc, priceDesc, rating }

/// تبويب استكشف — مركز اكتشاف العقارات للمستأجر.
class PropertiesScreen extends StatefulWidget {
  final String? initialGovernorate;
  final bool coastalOnly;
  final String? durationIntentId;

  const PropertiesScreen({
    super.key,
    this.initialGovernorate,
    this.coastalOnly = false,
    this.durationIntentId,
  });

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  /// الكل | شقق | غرف مشتركة | أسرّة | إعلانات البيع
  String _hubFilter = 'الكل';
  String _selectedGovernorate = 'الكل';
  bool _coastalOnly = false;
  String? _durationIntentId;
  _ExploreSort _sort = _ExploreSort.newest;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProperties = [];
  bool _isLoading = true;
  bool _showOfflineBanner = false;
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _hubFilters = [
    'الكل',
    'شقق',
    'غرف مشتركة',
    'أسرّة',
    'إعلانات البيع',
  ];

  @override
  void initState() {
    super.initState();
    _selectedGovernorate = widget.initialGovernorate ?? 'الكل';
    _coastalOnly = widget.coastalOnly;
    _durationIntentId = widget.durationIntentId;
    _scrollController.addListener(_onScroll);
    _loadProperties();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = _filteredProperties.length;
    if (_visibleCount >= total) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
    });
  }

  List<Map<String, dynamic>> get _visibleProperties =>
      _filteredProperties.take(_visibleCount).toList();

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final result = await OfflineCacheService.loadProperties();
    if (mounted) {
      setState(() {
        _allProperties = result.items;
        _showOfflineBanner = result.fromCache;
        _isLoading = false;
        _visibleCount = _pageSize;
      });
    }
  }

  List<Map<String, dynamic>> get _featuredProperties {
    final featured = _allProperties
        .where((p) => p['isFeatured'] == true && p['listingMode'] != 'for_sale')
        .toList();
    if (featured.isNotEmpty) return featured.take(8).toList();
    return _allProperties
        .where((p) => p['listingMode'] != 'for_sale')
        .take(6)
        .toList();
  }

  List<Map<String, dynamic>> get _shortStayProperties {
    return _allProperties
        .where(ShortStayDiscovery.isShortStayListing)
        .take(12)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredProperties {
    var list = List<Map<String, dynamic>>.from(_allProperties);

    switch (_hubFilter) {
      case 'شقق':
        list = list
            .where((p) =>
                p['listingMode'] != 'for_sale' &&
                accommodationTypeFromProperty(p) == AccommodationType.fullUnit)
            .toList();
      case 'غرف مشتركة':
        list = list
            .where((p) =>
                p['listingMode'] != 'for_sale' &&
                accommodationTypeFromProperty(p) ==
                    AccommodationType.sharedRoom)
            .toList();
      case 'أسرّة':
        list = list
            .where((p) =>
                p['listingMode'] != 'for_sale' &&
                accommodationTypeFromProperty(p) == AccommodationType.bed)
            .toList();
      case 'إعلانات البيع':
        list = list.where((p) => p['listingMode'] == 'for_sale').toList();
      default:
        break;
    }

    final discoveryFilters = <String, dynamic>{
      if (_selectedGovernorate != 'الكل') 'governorate': _selectedGovernorate,
      if (_coastalOnly) 'coastalOnly': true,
      if (_durationIntentId != null) 'durationIntent': _durationIntentId,
    };
    if (discoveryFilters.isNotEmpty) {
      list = list
          .where((p) => ShortStayDiscovery.matchesFilters(p, discoveryFilters))
          .toList();
    }

    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final hay = [
          p['title'],
          p['location'],
          p['governorate'],
          p['type'],
          p['address'],
          ...(p['amenities'] is List
              ? (p['amenities'] as List).map((e) => e.toString())
              : const <String>[]),
        ].map((e) => e?.toString() ?? '').join(' ');
        return hay.contains(q);
      }).toList();
    }

    list = _applySort(list);
    return list;
  }

  List<Map<String, dynamic>> _applySort(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    switch (_sort) {
      case _ExploreSort.newest:
        sorted.sort((a, b) {
          final da = DateTime.tryParse(
                  a['createdAt']?.toString() ?? a['updatedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse(
                  b['createdAt']?.toString() ?? b['updatedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      case _ExploreSort.priceAsc:
        sorted.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
      case _ExploreSort.priceDesc:
        sorted.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
      case _ExploreSort.rating:
        sorted.sort((a, b) {
          final ra = (a['rating'] as num?)?.toDouble() ??
              (a['avgRating'] as num?)?.toDouble() ??
              0;
          final rb = (b['rating'] as num?)?.toDouble() ??
              (b['avgRating'] as num?)?.toDouble() ??
              0;
          final cmp = rb.compareTo(ra);
          if (cmp != 0) return cmp;
          final va = a['isVerified'] == true ? 1 : 0;
          final vb = b['isVerified'] == true ? 1 : 0;
          return vb.compareTo(va);
        });
    }
    return sorted;
  }

  double _priceOf(Map<String, dynamic> p) {
    final raw = p['price']?.toString() ?? p['monthlyRent']?.toString() ?? '0';
    return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('استكشف'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'الخريطة',
            icon: const Icon(Icons.map_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapSearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showOfflineBanner) const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadProperties,
              child: _isLoading
                  ? const SkeletonListLoader(itemCount: 6, itemHeight: 140)
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildSearchAndFilters()),
                        if (_hubFilter == 'الكل' &&
                            _searchQuery.isEmpty &&
                            !_coastalOnly &&
                            _durationIntentId == null &&
                            _selectedGovernorate == 'الكل' &&
                            _shortStayProperties.isNotEmpty)
                          SliverToBoxAdapter(child: _buildShortStaySection()),
                        if (_hubFilter == 'الكل' &&
                            _searchQuery.isEmpty &&
                            _featuredProperties.isNotEmpty)
                          SliverToBoxAdapter(child: _buildFeaturedSection()),
                        SliverToBoxAdapter(child: _buildResultsHeader()),
                        if (_filteredProperties.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyStateView(
                              icon: Icons.apartment_outlined,
                              title: 'لا توجد عقارات مطابقة',
                              subtitle:
                                  'جرّب مسح الفلاتر أو تغيير البحث أو المنطقة.',
                              actionLabel: 'مسح الفلاتر',
                              actionIcon: Icons.filter_alt_off_rounded,
                              onAction: () {
                                setState(() {
                                  _hubFilter = 'الكل';
                                  _selectedGovernorate = 'الكل';
                                  _coastalOnly = false;
                                  _durationIntentId = null;
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _sort = _ExploreSort.newest;
                                  _visibleCount = _pageSize;
                                });
                              },
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= _visibleProperties.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildPropertyTile(
                                      _visibleProperties[index]);
                                },
                                childCount: _visibleProperties.length +
                                    (_visibleCount <
                                            _filteredProperties.length
                                        ? 1
                                        : 0),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spaceSm,
        AppTheme.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _visibleCount = _pageSize;
            }),
            decoration: InputDecoration(
              hintText: 'ابحث عن عقار، منطقة، محافظة…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _visibleCount = _pageSize;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._hubFilters.map((f) {
                  final selected = _hubFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _hubFilter = f;
                        _visibleCount = _pageSize;
                      }),
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.beach_access_rounded,
                      size: 16,
                      color: _coastalOnly ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: const Text('الساحل والبحر'),
                    selected: _coastalOnly,
                    onSelected: (v) => setState(() {
                      _coastalOnly = v;
                      _visibleCount = _pageSize;
                    }),
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          _coastalOnly ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'مدة الإقامة',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ShortStayDiscovery.durationIntents.map((intent) {
                final selected = _durationIntentId == intent.id;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(intent.label,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _durationIntentId = selected ? null : intent.id;
                      _visibleCount = _pageSize;
                    }),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'المحافظة',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ShortStayDiscovery.exploreGovernorates.map((g) {
                final selected = _selectedGovernorate == g;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(g, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedGovernorate = g;
                      _visibleCount = _pageSize;
                    }),
                    selectedColor: AppTheme.accentColor.withOpacity(0.25),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.sort_rounded,
                  size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              const Text(
                'ترتيب:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sortChip(_ExploreSort.newest, 'الأحدث'),
                      _sortChip(_ExploreSort.priceAsc, 'السعر ↑'),
                      _sortChip(_ExploreSort.priceDesc, 'السعر ↓'),
                      _sortChip(_ExploreSort.rating, 'الأعلى تقييماً'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapSearchScreen()),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('الخريطة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdvancedFiltersScreen()),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('فلاتر متقدمة'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sortChip(_ExploreSort value, String label) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => setState(() {
          _sort = value;
          _visibleCount = _pageSize;
        }),
        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildShortStaySection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
            child: Row(
              children: [
                const Expanded(
                  child: EjariSectionHeader(
                    title: 'إقامات قصيرة وعروض',
                    subtitle: 'ليلة · أيام · نصف أسبوع · ساحل',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _coastalOnly = true;
                    _visibleCount = _pageSize;
                  }),
                  child: const Text(
                    'الكل',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenPadding),
              itemCount: _shortStayProperties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = _shortStayProperties[index];
                final image = PropertyImageResolver.resolve(p);
                final daily =
                    ShortStayDiscovery.dailyRate(p).round().toString();
                final badges = ShortStayDiscovery.offerBadges(p);
                final beach = ShortStayDiscovery.nearbyBeachMinutes(p);
                return InkWell(
                  onTap: () => _navigateToDetails(p),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 230,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.35),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.08),
                                  child: const Icon(Icons.beach_access_rounded,
                                      color: AppTheme.primaryColor),
                                ),
                              ),
                              if (badges.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      badges.first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['title']?.toString() ?? 'عقار',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'من $daily ج.م / يوم',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              if (beach != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'البحر خلال $beach دقائق',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
  }

  Widget _buildFeaturedSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.screenPadding),
            child: EjariSectionHeader(
              title: 'مميز ومُوصى به',
              subtitle: 'اختيارات سريعة للبدء',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenPadding),
              itemCount: _featuredProperties.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = _featuredProperties[index];
                final image = PropertyImageResolver.resolve(p);
                final price = p['price']?.toString() ?? '—';
                final isSale = p['listingMode'] == 'for_sale';
                return InkWell(
                  onTap: () => _navigateToDetails(p),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.35),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  child: const Icon(Icons.home_rounded,
                                      color: AppTheme.primaryColor),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSale
                                        ? AppTheme.accentColor
                                        : AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isSale ? 'بيع' : 'إيجار',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['title']?.toString() ?? 'عقار',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$price ج.م',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
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
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        4,
        AppTheme.screenPadding,
        8,
      ),
      child: Row(
        children: [
          Text(
            'النتائج: ${_filteredProperties.length}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_hubFilter != 'الكل' ||
              _selectedGovernorate != 'الكل' ||
              _searchQuery.isNotEmpty ||
              _coastalOnly ||
              _durationIntentId != null)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _hubFilter = 'الكل';
                  _selectedGovernorate = 'الكل';
                  _searchQuery = '';
                  _coastalOnly = false;
                  _durationIntentId = null;
                  _sort = _ExploreSort.newest;
                  _visibleCount = _pageSize;
                });
              },
              child: const Text('مسح الفلاتر', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyTile(Map<String, dynamic> property) {
    final image = PropertyImageResolver.resolve(property);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: PropertyCard(
        id: property['id'] ?? '0',
        title: property['title'],
        price: property['price'],
        location: property['location'],
        image: image,
        beds: property['beds'],
        baths: property['baths'],
        area: property['area'],
        listingMode: property['listingMode'],
        isDemo: property['isDemo'] ?? false,
        isVerified: property['isVerified'] == true,
        supportedDurations: (property['supportedDurations'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        onTap: () => _navigateToDetails(property),
        onBook: () {
          if (isSaleListing(property)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleContactScreen(property: property),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(
                itemType: 'property',
                itemData: property,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(property: property),
      ),
    );
  }
}
