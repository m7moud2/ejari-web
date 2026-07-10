import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import 'search_results_screen.dart';
import '../services/firestore_property_service.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  RangeValues _priceRange = const RangeValues(1000, 100000);
  int _selectedBeds = 0;
  int _selectedBaths = 0;
  String _selectedType = 'الكل';
  bool? _isFurnished;
  String _listingFilter = 'all';
  String _selectedGovernorate = 'الكل';

  static const List<String> _governorates = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الشرقية',
    'مطروح',
  ];

  final List<String> _propertyTypes = ['الكل', 'شقق', 'فلل', 'مكاتب', 'فندقي'];
  final List<String> _selectedAmenities = [];
  final List<Map<String, dynamic>> _amenitiesList = [
    {'name': 'مسبح خاص', 'icon': Icons.pool_rounded},
    {'name': 'جيم حديث', 'icon': Icons.fitness_center_rounded},
    {'name': 'موقف سيارات', 'icon': Icons.directions_car_rounded},
    {'name': 'أمن 24/7', 'icon': Icons.security_rounded},
    {'name': 'سمارت هوم', 'icon': Icons.home_max_rounded},
  ];

  int _matchingCount = 0;
  List<Map<String, dynamic>> _allProperties = [];
  List<double> _histogramHeights = [];

  @override
  void initState() {
    super.initState();
    _generateHistogram();
    _loadProperties();
  }

  void _generateHistogram() {
    final rand = Random(42);
    _histogramHeights = List.generate(30, (index) {
      if (index < 5) return rand.nextDouble() * 20;
      if (index < 15) return 20 + rand.nextDouble() * 80;
      if (index < 25) return 10 + rand.nextDouble() * 40;
      return rand.nextDouble() * 20;
    });
  }

  Future<void> _loadProperties() async {
    final props = await FirestorePropertyService.getAllProperties();
    if (mounted) {
      setState(() {
        _allProperties = props;
        _updateFiltersCount();
      });
    }
  }

  void _updateFiltersCount() {
    final minPrice = _priceRange.start;
    final maxPrice = _priceRange.end;

    int count = _allProperties.where((p) {
      final priceStr = p['price']?.toString().replaceAll(',', '') ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;
      if (price < minPrice || price > maxPrice) return false;

      if (_listingFilter == 'rent' && p['listingMode'] == 'for_sale') {
        return false;
      }
      if (_listingFilter == 'sale' && p['listingMode'] != 'for_sale') {
        return false;
      }

      if (_selectedGovernorate != 'الكل') {
        final loc =
            '${p['governorate'] ?? ''} ${p['location'] ?? ''}'.toString();
        if (!loc.contains(_selectedGovernorate)) return false;
      }

      if (_selectedType != 'الكل' && p['type'] != _selectedType) return false;

      if (_selectedBeds > 0) {
        final b = int.tryParse(p['beds']?.toString() ?? '0') ?? 0;
        if (b < _selectedBeds) return false;
      }

      if (_selectedBaths > 0) {
        final b = int.tryParse(p['baths']?.toString() ?? '0') ?? 0;
        if (b < _selectedBaths) return false;
      }

      return true;
    }).length;

    setState(() => _matchingCount = count);
  }

  void _applyFilters() {
    final filters = {
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'beds': _selectedBeds > 0 ? _selectedBeds : null,
      'baths': _selectedBaths > 0 ? _selectedBaths : null,
      'type': _selectedType != 'الكل' ? _selectedType : null,
      'furnished': _isFurnished,
      'amenities': _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
      'listingMode': _listingFilter == 'all' ? null : _listingFilter,
      'governorate':
          _selectedGovernorate != 'الكل' ? _selectedGovernorate : null,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: '',
          filters: filters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('محرك البحث الذكي',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _priceRange = const RangeValues(1000, 100000);
                _selectedBeds = 0;
                _selectedBaths = 0;
                _selectedType = 'الكل';
                _isFurnished = null;
                _listingFilter = 'all';
                _selectedGovernorate = 'الكل';
                _selectedAmenities.clear();
                _updateFiltersCount();
              });
            },
            child: const Text('إعادة ضبط',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 168),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text('فلترة أذكى',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'حدد الميزانية والمواصفات التي تهمك، ثم اعرض النتائج الأقرب لاحتياجك.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('ما الذي تبحث عنه؟'),
                const SizedBox(height: 16),
                _buildPropertyTypes(),
                const SizedBox(height: 24),
                _buildSectionTitle('نوع العرض'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassyChip(
                          'للإيجار', _listingFilter == 'rent', () {
                        setState(() => _listingFilter = 'rent');
                        _updateFiltersCount();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassyChip(
                          'للبيع', _listingFilter == 'sale', () {
                        setState(() => _listingFilter = 'sale');
                        _updateFiltersCount();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassyChip('الكل', _listingFilter == 'all',
                          () {
                        setState(() => _listingFilter = 'all');
                        _updateFiltersCount();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('المحافظة'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _governorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedGovernorate = val);
                    _updateFiltersCount();
                  },
                ),
                const SizedBox(height: 36),
                _buildSectionTitle('نطاق الاستثمار المخطط'),
                const SizedBox(height: 12),
                _buildPriceHistogram(),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildSelectorColumn('الغرف', _selectedBeds, (v) {
                      setState(() => _selectedBeds = v);
                      _updateFiltersCount();
                    })),
                    const SizedBox(width: 20),
                    Expanded(
                        child: _buildSelectorColumn('الحمامات', _selectedBaths,
                            (v) {
                      setState(() => _selectedBaths = v);
                      _updateFiltersCount();
                    })),
                  ],
                ),
                const SizedBox(height: 36),
                _buildSectionTitle('تجهيزات الرفاهية'),
                const SizedBox(height: 16),
                _buildAmenities(),
                const SizedBox(height: 36),
                _buildSectionTitle('نمط الأثاث'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildGlassyChip('الكل', _isFurnished == null, () {
                      setState(() => _isFurnished = null);
                      _updateFiltersCount();
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                            _buildGlassyChip('مفروش', _isFurnished == true, () {
                      setState(() => _isFurnished = true);
                      _updateFiltersCount();
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildGlassyChip(
                            'غير مفروش', _isFurnished == false, () {
                      setState(() => _isFurnished = false);
                      _updateFiltersCount();
                    })),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Refined Bottom Button with Gradient and Shadow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  boxShadow: const [],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.borderColor, AppTheme.borderColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _matchingCount > 0
                                ? 'استعراض العقارات'
                                : 'لا توجد نتائج مطابقة',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        if (_matchingCount > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_matchingCount',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3),
    );
  }

  Widget _buildPropertyTypes() {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _propertyTypes.length,
        itemBuilder: (context, index) {
          final type = _propertyTypes[index];
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = type);
              _updateFiltersCount();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.borderColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppTheme.borderColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
                border: Border.all(
                    color: isSelected
                        ? AppTheme.borderColor
                        : AppTheme.backgroundColor,
                    width: 1.5),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceHistogram() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceLabel('الحد الأدنى', _priceRange.start),
              _buildPriceLabel('الحد الأعلى', _priceRange.end),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(30, (index) {
                double ratio = index / 29;
                double currentMinRatio = _priceRange.start / 100000;
                double currentMaxRatio = _priceRange.end / 100000;
                bool isActive =
                    ratio >= currentMinRatio && ratio <= currentMaxRatio;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7,
                  height: max(5.0, _histogramHeights[index]),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.7)
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : null,
                    color: isActive ? null : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.backgroundColor,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10, elevation: 0),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10, elevation: 0),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 100000,
              onChanged: (values) {
                setState(() => _priceRange = values);
                _updateFiltersCount();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLabel(String label, double price) {
    return Column(
      crossAxisAlignment: label == 'الحد الأدنى'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.backgroundColor,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
            '${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ج.م',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildSelectorColumn(
      String title, int currentValue, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 52, // Height for the selector items
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final isSelected = currentValue == index;
              return GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppTheme.textPrimary.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                    border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index == 0 ? 'أي' : '$index',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.borderColor
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _amenitiesList.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity['name']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAmenities.remove(amenity['name']);
              } else {
                _selectedAmenities.add(amenity['name']);
              }
              _updateFiltersCount();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.borderColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSelected
                      ? AppTheme.borderColor
                      : AppTheme.backgroundColor,
                  width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppTheme.borderColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(amenity['icon'],
                    size: 16,
                    color: isSelected
                        ? AppTheme.borderColor
                        : AppTheme.backgroundColor),
                const SizedBox(width: 8),
                Text(
                  amenity['name']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlassyChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.borderColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  isSelected ? AppTheme.borderColor : AppTheme.backgroundColor,
              width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.borderColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
