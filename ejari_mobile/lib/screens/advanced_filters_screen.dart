import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import 'search_results_screen.dart';
import '../services/firestore_property_service.dart';
import '../services/search_filters_service.dart';
import '../utils/short_stay_discovery.dart';
import '../data/egypt_locations.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  RangeValues _priceRange = const RangeValues(1000, 100000);
  RangeValues _dailyPriceRange = const RangeValues(200, 2000);
  bool _useDailyPrice = true;
  int _selectedBeds = 0;
  int _selectedBaths = 0;
  int _selectedBedsCount = 0;
  String _selectedType = 'الكل';
  bool? _isFurnished;
  String _listingFilter = 'all';
  String? _offerType;
  String? _finishStatus;
  String? _suitableFor;
  String? _selectedGovernorate;
  String? _selectedCity;
  String _sortMode = 'nearest';
  bool _specialOffersOnly = false;
  final Set<String> _selectedGovernorates = {};
  String? _durationIntentId;
  final List<String> _selectedOfferFilters = [];

  final List<String> _propertyTypes = [
    'الكل',
    'شقق',
    'فلل',
    'شاليهات',
    'مكاتب',
    'فندقي',
    'سكن مشترك',
  ];

  final List<String> _offerTypes = [
    'إيجار يومي',
    'أسبوعي',
    'شهري',
    'طويل',
    'إعلان بيع',
  ];

  final List<String> _finishOptions = ['مفروش', 'على التشطيب', 'جديد'];
  final List<String> _audienceOptions = [
    'أفراد',
    'عائلات',
    'طلاب',
    'عمال',
    'شركات',
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'id': 'nearest', 'label': 'الأقرب'},
    {'id': 'cheapest', 'label': 'الأرخص'},
    {'id': 'newest', 'label': 'الأحدث'},
    {'id': 'rating', 'label': 'الأعلى تقييماً'},
  ];

  final List<String> _selectedAmenities = [];
  final List<Map<String, dynamic>> _amenitiesList = [
    {'name': 'قريب من البحر', 'icon': Icons.beach_access_rounded},
    {'name': 'واي فاي', 'icon': Icons.wifi_rounded},
    {'name': 'مكيف', 'icon': Icons.ac_unit_rounded},
    {'name': 'مصعد', 'icon': Icons.elevator_rounded},
    {'name': 'موقف', 'icon': Icons.local_parking_rounded},
    {'name': 'مطبخ', 'icon': Icons.kitchen_rounded},
    {'name': 'غاز', 'icon': Icons.local_fire_department_rounded},
    {'name': 'سيارة متاحة', 'icon': Icons.directions_car_rounded},
    {'name': 'مناسب للعائلات', 'icon': Icons.family_restroom_rounded},
    {'name': 'بيت مستقل', 'icon': Icons.holiday_village_rounded},
    {'name': 'تشطيب لوكس', 'icon': Icons.diamond_rounded},
    {'name': 'سراير متعددة', 'icon': Icons.bed_rounded},
  ];

  int _matchingCount = 0;
  List<Map<String, dynamic>> _allProperties = [];
  List<double> _histogramHeights = [];

  @override
  void initState() {
    super.initState();
    _generateHistogram();
    _loadProperties();
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    final last = await SearchFiltersService.loadLast();
    if (last == null || !mounted) return;
    setState(() {
      _priceRange = RangeValues(
        (last['minPrice'] as num?)?.toDouble() ?? _priceRange.start,
        (last['maxPrice'] as num?)?.toDouble() ?? _priceRange.end,
      );
      _dailyPriceRange = RangeValues(
        (last['minDailyPrice'] as num?)?.toDouble() ?? _dailyPriceRange.start,
        (last['maxDailyPrice'] as num?)?.toDouble() ?? _dailyPriceRange.end,
      );
      _useDailyPrice = last['useDailyPrice'] as bool? ?? true;
      _selectedBeds = last['beds'] as int? ?? 0;
      _selectedBaths = last['baths'] as int? ?? 0;
      _selectedBedsCount = last['bedsCount'] as int? ?? 0;
      _selectedType = last['type']?.toString() ?? 'الكل';
      _isFurnished = last['furnished'] as bool?;
      _listingFilter = last['listingMode']?.toString() ?? 'all';
      _durationIntentId = last['durationIntent']?.toString();
      _offerType = last['offerType']?.toString();
      _finishStatus = last['finishStatus']?.toString();
      _suitableFor = last['suitableFor']?.toString();
      _selectedCity = last['city']?.toString();
      _sortMode = last['sortMode']?.toString() ?? 'nearest';
      _specialOffersOnly = last['specialOffersOnly'] == true;
      _selectedGovernorates
        ..clear()
        ..addAll(_governoratesFromFilters(last));
      if (_selectedGovernorates.length == 1) {
        _selectedGovernorate = _selectedGovernorates.first;
      } else {
        _selectedGovernorate = last['governorate']?.toString();
      }
      final amenities = last['amenities'];
      if (amenities is List) {
        _selectedAmenities
          ..clear()
          ..addAll(amenities.map((e) => e.toString()));
      }
      final offers = last['offerFilters'];
      if (offers is List) {
        _selectedOfferFilters
          ..clear()
          ..addAll(offers.map((e) => e.toString()));
      }
      _updateFiltersCount();
    });
  }

  List<String> _governoratesFromFilters(Map<String, dynamic> f) {
    final list = f['governorates'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    final single = f['governorate']?.toString();
    if (single != null && single.isNotEmpty && single != 'الكل') {
      return [single];
    }
    return const [];
  }

  Map<String, dynamic> _buildFiltersMap() {
    final gov = _selectedGovernorate;
    return {
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'minDailyPrice': _useDailyPrice ? _dailyPriceRange.start : null,
      'maxDailyPrice': _useDailyPrice ? _dailyPriceRange.end : null,
      'useDailyPrice': _useDailyPrice,
      'beds': _selectedBeds > 0 ? _selectedBeds : null,
      'baths': _selectedBaths > 0 ? _selectedBaths : null,
      'bedsCount': _selectedBedsCount > 0 ? _selectedBedsCount : null,
      'type': _selectedType != 'الكل' ? _selectedType : null,
      'furnished': _isFurnished,
      'amenities': _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
      'listingMode': _listingFilter == 'all' ? null : _listingFilter,
      'governorates': gov != null && gov.isNotEmpty ? [gov] : null,
      'governorate': gov,
      'city': _selectedCity,
      'durationIntent': _durationIntentId,
      'offerType': _offerType,
      'finishStatus': _finishStatus,
      'suitableFor': _suitableFor,
      'sortMode': _sortMode,
      'specialOffersOnly': _specialOffersOnly ? true : null,
      'offerFilters':
          _selectedOfferFilters.isNotEmpty ? _selectedOfferFilters : null,
      'shortStayOnly': _durationIntentId != null ||
          _selectedOfferFilters.isNotEmpty ||
          _offerType == 'إيجار يومي' ||
          _offerType == 'أسبوعي' ||
          _selectedAmenities.any((a) => ShortStayDiscovery.vacationAmenityFilters
              .any((v) => v['name'] == a)),
    };
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
    final filters = _buildFiltersMap();
    final count = _allProperties.where((p) {
      if (_listingFilter == 'rent' && p['listingMode'] == 'for_sale') {
        return false;
      }
      if (_listingFilter == 'sale' && p['listingMode'] != 'for_sale') {
        return false;
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
      if (_isFurnished != null) {
        final furnished = p['furnished'] == true || p['isFurnished'] == true;
        if (_isFurnished == true && !furnished) return false;
        if (_isFurnished == false && furnished) return false;
      }
      final effective = Map<String, dynamic>.from(filters);
      if (_useDailyPrice) {
        effective.remove('minPrice');
        effective.remove('maxPrice');
      } else {
        effective.remove('minDailyPrice');
        effective.remove('maxDailyPrice');
      }
      return ShortStayDiscovery.matchesFilters(p, effective);
    }).length;
    setState(() => _matchingCount = count);
  }

  void _applyFilters() {
    final filters = _buildFiltersMap();
    if (_useDailyPrice) {
      filters.remove('minPrice');
      filters.remove('maxPrice');
    } else {
      filters.remove('minDailyPrice');
      filters.remove('maxDailyPrice');
    }
    SearchFiltersService.saveLast(filters);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: '', filters: filters),
      ),
    );
  }

  Future<void> _savePreset() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ البحث'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'اسم البحث المحفوظ'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await SearchFiltersService.savePreset(
          nameCtrl.text.trim(), _buildFiltersMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ البحث ✅')),
        );
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _loadPreset() async {
    final presets = await SearchFiltersService.getPresets();
    if (!mounted) return;
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عمليات بحث محفوظة')),
      );
      return;
    }
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ListView(
        children: presets
            .map((p) => ListTile(
                  title: Text(p['name']?.toString() ?? ''),
                  subtitle:
                      Text(p['savedAt']?.toString().split('T').first ?? ''),
                  onTap: () => Navigator.pop(ctx, p),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    final f = Map<String, dynamic>.from(picked['filters'] as Map? ?? {});
    setState(() {
      _priceRange = RangeValues(
        (f['minPrice'] as num?)?.toDouble() ?? _priceRange.start,
        (f['maxPrice'] as num?)?.toDouble() ?? _priceRange.end,
      );
      _dailyPriceRange = RangeValues(
        (f['minDailyPrice'] as num?)?.toDouble() ?? _dailyPriceRange.start,
        (f['maxDailyPrice'] as num?)?.toDouble() ?? _dailyPriceRange.end,
      );
      _useDailyPrice = f['useDailyPrice'] as bool? ?? _useDailyPrice;
      _selectedBeds = f['beds'] as int? ?? 0;
      _selectedBaths = f['baths'] as int? ?? 0;
      _selectedBedsCount = f['bedsCount'] as int? ?? 0;
      _selectedType = f['type']?.toString() ?? 'الكل';
      _durationIntentId = f['durationIntent']?.toString();
      _offerType = f['offerType']?.toString();
      _finishStatus = f['finishStatus']?.toString();
      _suitableFor = f['suitableFor']?.toString();
      _selectedCity = f['city']?.toString();
      _sortMode = f['sortMode']?.toString() ?? 'nearest';
      _specialOffersOnly = f['specialOffersOnly'] == true;
      _selectedGovernorate = f['governorate']?.toString();
      _selectedGovernorates
        ..clear()
        ..addAll(_governoratesFromFilters(f));
      final amenities = f['amenities'];
      if (amenities is List) {
        _selectedAmenities
          ..clear()
          ..addAll(amenities.map((e) => e.toString()));
      }
      final offers = f['offerFilters'];
      if (offers is List) {
        _selectedOfferFilters
          ..clear()
          ..addAll(offers.map((e) => e.toString()));
      }
      _updateFiltersCount();
    });
  }

  void _resetAll() {
    setState(() {
      _priceRange = const RangeValues(1000, 100000);
      _dailyPriceRange = const RangeValues(200, 2000);
      _useDailyPrice = true;
      _selectedBeds = 0;
      _selectedBaths = 0;
      _selectedBedsCount = 0;
      _selectedType = 'الكل';
      _isFurnished = null;
      _listingFilter = 'all';
      _selectedGovernorates.clear();
      _selectedGovernorate = null;
      _selectedCity = null;
      _durationIntentId = null;
      _offerType = null;
      _finishStatus = null;
      _suitableFor = null;
      _sortMode = 'nearest';
      _specialOffersOnly = false;
      _selectedAmenities.clear();
      _selectedOfferFilters.clear();
      _updateFiltersCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('فلاتر احترافية',
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
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'تحميل بحث محفوظ',
            onPressed: _loadPreset,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'حفظ البحث',
            onPressed: _savePreset,
          ),
          TextButton(
            onPressed: _resetAll,
            child: const Text('إعادة ضبط',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 168),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 20),
                _buildSectionTitle('نوع العرض'),
                const SizedBox(height: 12),
                _buildChipWrap(_offerTypes, _offerType, (v) {
                  setState(() {
                    _offerType = _offerType == v ? null : v;
                    if (_offerType == 'إعلان بيع') {
                      _listingFilter = 'sale';
                    } else if (_offerType != null) {
                      _listingFilter = 'rent';
                    }
                  });
                  _updateFiltersCount();
                }),
                const SizedBox(height: 24),
                _buildSectionTitle('مدة الإقامة المرنة'),
                const SizedBox(height: 12),
                _buildDurationIntents(),
                const SizedBox(height: 24),
                _buildSectionTitle('نوع الوحدة'),
                const SizedBox(height: 12),
                _buildPropertyTypes(),
                const SizedBox(height: 24),
                _buildSectionTitle('المحافظة والمدينة'),
                const SizedBox(height: 12),
                _buildGovernorateCityCascading(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSectionTitle(_useDailyPrice
                          ? 'السعر اليومي من–إلى'
                          : 'السعر الشهري من–إلى'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _useDailyPrice = !_useDailyPrice);
                        _updateFiltersCount();
                      },
                      child: Text(
                        _useDailyPrice ? 'شهري' : 'يومي',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceHistogram(),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorColumn('الغرف', _selectedBeds, (v) {
                        setState(() => _selectedBeds = v);
                        _updateFiltersCount();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectorColumn('السراير', _selectedBedsCount,
                          (v) {
                        setState(() => _selectedBedsCount = v);
                        _updateFiltersCount();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          _buildSelectorColumn('الحمامات', _selectedBaths, (v) {
                        setState(() => _selectedBaths = v);
                        _updateFiltersCount();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('حالة الوحدة'),
                const SizedBox(height: 12),
                _buildChipWrap(_finishOptions, _finishStatus, (v) {
                  setState(() {
                    _finishStatus = _finishStatus == v ? null : v;
                    if (_finishStatus == 'مفروش') _isFurnished = true;
                  });
                  _updateFiltersCount();
                }),
                const SizedBox(height: 24),
                _buildSectionTitle('مناسب لـ'),
                const SizedBox(height: 12),
                _buildChipWrap(_audienceOptions, _suitableFor, (v) {
                  setState(() {
                    _suitableFor = _suitableFor == v ? null : v;
                  });
                  _updateFiltersCount();
                }),
                const SizedBox(height: 24),
                _buildSectionTitle('المرافق'),
                const SizedBox(height: 12),
                _buildAmenities(),
                const SizedBox(height: 24),
                _buildSectionTitle('عروض خاصة'),
                const SizedBox(height: 12),
                FilterChip(
                  label: const Text('عروض خاصة فقط',
                      style: TextStyle(fontSize: 12)),
                  selected: _specialOffersOnly,
                  onSelected: (v) {
                    setState(() => _specialOffersOnly = v);
                    _updateFiltersCount();
                  },
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _specialOffersOnly
                        ? Colors.white
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOfferFilters(),
                const SizedBox(height: 24),
                _buildSectionTitle('ترتيب النتائج'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sortOptions.map((o) {
                    final id = o['id'] as String;
                    final selected = _sortMode == id;
                    return FilterChip(
                      label: Text(o['label'] as String,
                          style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _sortMode = id);
                        _updateFiltersCount();
                      },
                      selectedColor: AppTheme.accentColor.withOpacity(0.45),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                child: ElevatedButton(
                  onPressed: _matchingCount > 0 ? _applyFilters : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.borderColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_matchingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('بحث بمستوى جروبات الإيجار',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'كل المحافظات والمدن، مدة الإقامة، السعر، المرافق، والترتيب حسب القرب.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          letterSpacing: -0.3),
    );
  }

  Widget _buildChipWrap(
    List<String> options,
    String? selected,
    ValueChanged<String> onTap,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected == o;
        return FilterChip(
          label: Text(o, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (_) => onTap(o),
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGovernorateCityCascading() {
    final cities = EgyptLocations.citiesFor(_selectedGovernorate);
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedGovernorate,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'المحافظة',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل المحافظات')),
            ...EgyptLocations.allGovernorates.map(
              (g) => DropdownMenuItem(value: g, child: Text(g)),
            ),
          ],
          onChanged: (v) {
            setState(() {
              _selectedGovernorate = v;
              _selectedCity = null;
              _selectedGovernorates
                ..clear()
                ..addAll(v == null ? const [] : [v]);
            });
            _updateFiltersCount();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'المدينة / الحي',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل المدن')),
            ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: _selectedGovernorate == null
              ? null
              : (v) {
                  setState(() => _selectedCity = v);
                  _updateFiltersCount();
                },
        ),
      ],
    );
  }

  Widget _buildPropertyTypes() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _propertyTypes.length,
        itemBuilder: (context, index) {
          final type = _propertyTypes[index];
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(type, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedType = type);
                _updateFiltersCount();
              },
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceHistogram() {
    final range = _useDailyPrice ? _dailyPriceRange : _priceRange;
    final maxVal = _useDailyPrice ? 3000.0 : 100000.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceLabel('من', range.start),
              _buildPriceLabel('إلى', range.end),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(30, (index) {
                final ratio = index / 29;
                final currentMinRatio = range.start / maxVal;
                final currentMaxRatio = range.end / maxVal;
                final isActive =
                    ratio >= currentMinRatio && ratio <= currentMaxRatio;
                return Container(
                  width: 6,
                  height: max(4.0, _histogramHeights[index] * 0.7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor.withOpacity(0.35),
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
              inactiveTrackColor: AppTheme.borderColor.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10, elevation: 0),
            ),
            child: RangeSlider(
              values: range,
              min: 0,
              max: maxVal,
              onChanged: (values) {
                setState(() {
                  if (_useDailyPrice) {
                    _dailyPriceRange = values;
                  } else {
                    _priceRange = values;
                  }
                });
                _updateFiltersCount();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationIntents() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShortStayDiscovery.durationIntents.map((intent) {
        final selected = _durationIntentId == intent.id;
        return FilterChip(
          label: Text(intent.label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _durationIntentId = selected ? null : intent.id;
              if (_durationIntentId != null) _useDailyPrice = true;
            });
            _updateFiltersCount();
          },
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOfferFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShortStayDiscovery.offerFilterLabels.map((label) {
        final selected = _selectedOfferFilters.contains(label);
        return FilterChip(
          avatar: Icon(
            Icons.local_offer_rounded,
            size: 16,
            color: selected ? Colors.white : AppTheme.primaryColor,
          ),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedOfferFilters.add(label);
              } else {
                _selectedOfferFilters.remove(label);
              }
            });
            _updateFiltersCount();
          },
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceLabel(String label, double price) {
    return Column(
      crossAxisAlignment:
          label == 'من' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        Text(
            '${price.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ج.م',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildSelectorColumn(
      String title, int currentValue, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              final isSelected = currentValue == index;
              return GestureDetector(
                onTap: () => onChanged(index),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index == 0 ? 'أي' : '$index${index == 4 ? '+' : ''}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
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
      spacing: 8,
      runSpacing: 8,
      children: _amenitiesList.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity['name']);
        return FilterChip(
          avatar: Icon(
            amenity['icon'] as IconData,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.primaryColor,
          ),
          label: Text(amenity['name'] as String,
              style: const TextStyle(fontSize: 11)),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedAmenities.add(amenity['name'] as String);
              } else {
                _selectedAmenities.remove(amenity['name']);
              }
            });
            _updateFiltersCount();
          },
          selectedColor: AppTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        );
      }).toList(),
    );
  }
}
