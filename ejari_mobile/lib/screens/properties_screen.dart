import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../widgets/empty_state_view.dart';
import '../utils/property_image_resolver.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_list_loader.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import 'map_search_screen.dart';
import '../models/listing_type.dart';
import '../widgets/sale_listing_widgets.dart';
import '../models/accommodation_type.dart';
import '../services/firestore_property_service.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  String _selectedType = 'الكل';
  String? _accommodationFilter;
  String _selectedGovernorate = 'الكل';
  String _listingFilter = 'rent';
  List<Map<String, dynamic>> _allProperties = [];
  bool _isLoading = true;
  static const int _pageSize = 20;
  int _visibleCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _governorates = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الشرقية',
    'مطروح',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProperties();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final properties = await FirestorePropertyService.getAllProperties();
    if (mounted) {
      setState(() {
        _allProperties = properties;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProperties {
    var list = _allProperties;
    if (_listingFilter == 'rent') {
      list = list.where((p) => p['listingMode'] != 'for_sale').toList();
    } else if (_listingFilter == 'sale') {
      list = list.where((p) => p['listingMode'] == 'for_sale').toList();
    }
    if (_selectedGovernorate != 'الكل') {
      list = list
          .where((p) =>
              (p['governorate'] ?? p['location'] ?? '')
                  .toString()
                  .contains(_selectedGovernorate))
          .toList();
    }
    if (_selectedType != 'الكل') {
      const typeMapping = {
        'شقة': 'شقق',
        'فيلا': 'فلل',
        'استوديو': 'استوديو',
        'دوبلكس': 'دوبلكس',
      };
      final targetType = typeMapping[_selectedType] ?? _selectedType;
      list = list.where((prop) => prop['type'] == targetType).toList();
    }
    if (_accommodationFilter != null) {
      list = list
          .where((p) =>
              (p['accommodationType']?.toString() ?? 'full_unit') ==
              _accommodationFilter)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('العقارات المتاحة'),
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
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', _selectedType == 'الكل', () {
                    setState(() => _selectedType = 'الكل');
                  }),
                  _buildFilterChip('شقة', _selectedType == 'شقة', () {
                    setState(() => _selectedType = 'شقة');
                  }),
                  _buildFilterChip('فيلا', _selectedType == 'فيلا', () {
                    setState(() => _selectedType = 'فيلا');
                  }),
                  _buildFilterChip('استوديو', _selectedType == 'استوديو', () {
                    setState(() => _selectedType = 'استوديو');
                  }),
                  _buildFilterChip('دوبلكس', _selectedType == 'دوبلكس', () {
                    setState(() => _selectedType = 'دوبلكس');
                  }),
                ],
              ),
            ),
          ),

          // Accommodation type: شقق / غرف / أسرّة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _accChip(null, 'الكل'),
                  _accChip(AccommodationType.fullUnit.value,
                      AccommodationType.fullUnit.filterLabel),
                  _accChip(AccommodationType.sharedRoom.value,
                      AccommodationType.sharedRoom.filterLabel),
                  _accChip(AccommodationType.bed.value,
                      AccommodationType.bed.filterLabel),
                ],
              ),
            ),
          ),

          // Listing mode filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _listingChip('rent', 'للإيجار'),
                  const SizedBox(width: 8),
                  _listingChip('sale', 'إعلانات البيع'),
                  const SizedBox(width: 8),
                  _listingChip('all', 'الكل'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Governorate Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text('المحافظة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedGovernorate,
                    isExpanded: true,
                    isDense: true,
                    items: _governorates
                        .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedGovernorate = v!;
                      _visibleCount = _pageSize;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'عدد النتائج: ${_filteredProperties.length}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadProperties,
              child: _isLoading
                  ? const SkeletonListLoader(itemCount: 6, itemHeight: 140)
                  : _filteredProperties.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            EmptyStateView(
                              icon: Icons.apartment_outlined,
                              title: 'لا توجد عقارات متاحة',
                              subtitle:
                                  'جرّب تغيير الفلاتر أو اسحب للأسفل للتحديث.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _visibleProperties.length +
                              (_visibleCount < _filteredProperties.length
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
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
                            final property = _visibleProperties[index];
                            final image = PropertyImageResolver.resolve(property);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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
                                      builder: (_) =>
                                          SaleContactScreen(property: property),
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
                        },
                      ),
            ),
          ),
        ],
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) => onTap(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _accChip(String? value, String label) {
    final selected = _accommodationFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          _accommodationFilter = value;
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
  }

  Widget _listingChip(String mode, String label) {
    final selected = _listingFilter == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _listingFilter = mode;
        _visibleCount = _pageSize;
      }),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.borderColor.withOpacity(0.3),
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            )),
      ),
    );
  }
}
