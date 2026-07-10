import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import '../services/firestore_property_service.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  String _selectedType = 'الكل';
  String _selectedGovernorate = 'الكل';
  String _listingFilter = 'rent';
  List<Map<String, dynamic>> _allProperties = [];
  bool _isLoading = true;

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
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final properties = await FirestorePropertyService.getAllProperties();
    if (mounted) {
      setState(() {
        // Filter out for_sale properties since they have their own screen
        _allProperties =
            properties.where((p) => p['listingMode'] != 'for_sale').toList();
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
    if (_selectedType == 'الكل') {
      return list;
    }
    const typeMapping = {
      'شقة': 'شقق',
      'فيلا': 'فلل',
      'استوديو': 'استوديو',
      'دوبلكس': 'دوبلكس',
    };
    final targetType = typeMapping[_selectedType] ?? _selectedType;
    return list.where((prop) => prop['type'] == targetType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('العقارات المتاحة'),
        centerTitle: true,
        elevation: 0,
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

          // Listing mode filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _listingChip('rent', 'للإيجار'),
                const SizedBox(width: 8),
                _listingChip('sale', 'للبيع'),
                const SizedBox(width: 8),
                _listingChip('all', 'الكل'),
              ],
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
                    onChanged: (v) => setState(() => _selectedGovernorate = v!),
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
            child: _isLoading
                ? const ColoredBox(
                    color: AppTheme.backgroundColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : _filteredProperties.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apartment,
                                size: 80, color: AppTheme.primaryColor),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد عقارات متاحة',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = _filteredProperties[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: PropertyCard(
                              id: property['id'] ?? '0',
                              title: property['title'],
                              price: property['price'],
                              location: property['location'],
                              image: property['image'],
                              beds: property['beds'],
                              baths: property['baths'],
                              area: property['area'],
                              listingMode: property['listingMode'],
                              isDemo: property['isDemo'] ?? false,
                              supportedDurations: (property['supportedDurations'] as List?)
                                  ?.map((e) => e.toString())
                                  .toList(),
                              onTap: () => _navigateToDetails(property),
                              onBook: () {
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

  Widget _listingChip(String mode, String label) {
    final selected = _listingFilter == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _listingFilter = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.borderColor.withOpacity(0.3),
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
      ),
    );
  }
}
