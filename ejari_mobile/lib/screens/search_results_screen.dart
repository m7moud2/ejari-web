import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import '../widgets/empty_state_view.dart';
import '../utils/property_image_resolver.dart';
import '../models/accommodation_type.dart';
import '../services/firestore_property_service.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.filters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _accommodationFilter;

  @override
  void initState() {
    super.initState();
    _accommodationFilter = widget.filters?['accommodationType']?.toString();
    _performSearch();
  }

  Future<void> _performSearch() async {
    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 500));

    final allProperties = await FirestorePropertyService.getAllProperties();

    final query = widget.query.trim().toLowerCase();
    final isFeaturedQuery = query == 'مميز' || query.contains('featured');

    final results = allProperties.where((property) {
      if (isFeaturedQuery) {
        return property['isFeatured'] == true;
      }

      // Empty query → show all rent/sale listings
      final title = property['title']?.toString().toLowerCase() ?? '';
      final location = property['location']?.toString().toLowerCase() ?? '';
      final governorate = property['governorate']?.toString().toLowerCase() ?? '';

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          location.contains(query) ||
          governorate.contains(query);

      if (!matchesQuery) return false;

      // Apply filters
      final filters = widget.filters ?? {};
      if (filters.isNotEmpty || _accommodationFilter != null) {

        // Price Range
        final priceStr =
            property['price']?.toString().replaceAll(',', '') ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;

        if (filters['minPrice'] != null) {
          if (price < filters['minPrice']) return false;
        }
        if (filters['maxPrice'] != null) {
          if (price > filters['maxPrice']) return false;
        }

        // Bedrooms
        if (filters['beds'] != null) {
          final beds = int.tryParse(
                  property['beds']?.toString().split(' ').first ?? '0') ??
              0;
          if (beds < filters['beds']) return false;
        }

        // Bathrooms
        if (filters['baths'] != null) {
          final baths = int.tryParse(
                  property['baths']?.toString().split(' ').first ?? '0') ??
              0;
          if (baths < filters['baths']) return false;
        }

        // Property Type
        if (filters['type'] != null) {
          final type = property['type']?.toString().toLowerCase() ?? '';
          if (!type.contains(filters['type'].toString().toLowerCase())) {
            return false;
          }
        }

        // Accommodation type filter
        if (filters['accommodationType'] != null ||
            _accommodationFilter != null) {
          final acc = filters['accommodationType']?.toString() ??
              _accommodationFilter ??
              'full_unit';
          if ((property['accommodationType']?.toString() ?? 'full_unit') !=
              acc) {
            return false;
          }
        }

        // Listing mode (rent / sale)
        if (filters['listingMode'] != null) {
          final mode = filters['listingMode'].toString();
          if (mode == 'rent' && property['listingMode'] == 'for_sale') {
            return false;
          }
          if (mode == 'sale' && property['listingMode'] != 'for_sale') {
            return false;
          }
        }

        // Governorate
        if (filters['governorate'] != null) {
          final gov = filters['governorate'].toString();
          final loc =
              '${property['governorate'] ?? ''} ${property['location'] ?? ''}';
          if (!loc.contains(gov)) return false;
        }

        // Furnished
        if (filters['furnished'] != null) {
          final furnished = property['furnished'] == true ||
              property['isFurnished'] == true;
          if (filters['furnished'] == true && !furnished) return false;
          if (filters['furnished'] == false && furnished) return false;
        }

        // Amenities
        if (filters['amenities'] != null) {
          final List<String> requiredAmenities =
              List<String>.from(filters['amenities']);
          final propertyAmenities =
              List<String>.from(property['amenities'] ?? []);

          for (var amenity in requiredAmenities) {
            if (!propertyAmenities.contains(amenity)) return false;
          }
        }
      }

      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.query.isEmpty
            ? 'نتائج البحث'
            : 'نتائج البحث: ${widget.query}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: _performSearch,
                    child: _results.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyStateView(
                                icon: Icons.search_off_rounded,
                                title: 'لا توجد نتائج مطابقة لبحثك',
                                subtitle:
                                    'حاول استخدام كلمات مفتاحية مختلفة أو افتح الفلتر المتقدم.',
                                actionLabel: 'تعديل البحث',
                                onAction: () => Navigator.pop(context),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final property = _results[index];
                              final image =
                                  PropertyImageResolver.resolve(property);
                              return PropertyCard(
                                id: property['id'] ?? '0',
                                title: property['title'] ?? '',
                                price: property['price'] ?? '0',
                                location: property['location'] ?? '',
                                image: image,
                                beds: property['beds'] ?? '0',
                                baths: property['baths'] ?? '0',
                                area: property['area'] ?? '0',
                                isVerified: property['isVerified'] == true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PropertyDetailsScreen(
                                              property: property),
                                    ),
                                  );
                                },
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
                              );
                            },
                          ),
                  ),
          ),
        ],
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
        onSelected: (_) {
          setState(() {
            _accommodationFilter = value;
            _isLoading = true;
          });
          _performSearch();
        },
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
}
