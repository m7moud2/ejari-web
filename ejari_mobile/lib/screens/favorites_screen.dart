import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../widgets/car_card.dart';
import '../services/data_service.dart';
import '../services/offline_cache_service.dart';
import '../widgets/offline_banner.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import 'comparison_screen.dart';
import 'search_results_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  List<String> _folders = ['عام'];
  bool _isLoading = true;
  bool _showOfflineBanner = false;
  String _selectedFolder = 'عام';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await OfflineCacheService.loadFavorites();
    final folders = await DataService.getFavoriteFolders();
    if (!mounted) return;
    setState(() {
      _favorites = result.items;
      _showOfflineBanner = result.fromCache;
      _folders = folders;
      if (!folders.contains(_selectedFolder) && folders.isNotEmpty) {
        _selectedFolder = folders.first;
      }
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredFavorites {
    return _favorites
        .where((item) => item['folder'] == _selectedFolder)
        .toList();
  }

  Future<void> _createNewFolder() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء مجلد جديد'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم المجلد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await DataService.addFavoriteFolder(controller.text.trim());
                await _loadData();
                setState(() => _selectedFolder = controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(Map<String, dynamic> item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    await DataService.removeFavorite(item);
    _selectedItems.remove(item);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الإزالة من المفضلة')),
    );
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الكل'),
        content: const Text('هل تريد مسح جميع العناصر من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DataService.clearFavoritesForCurrentUser();
    _selectedItems.clear();
    await _loadData();
  }

  void _compareItems() {
    if (_selectedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر عنصرين على الأقل للمقارنة')),
      );
      return;
    }

    final firstItemIsCar = _selectedItems[0]['type'] != null &&
        (_selectedItems[0]['type'] == 'SUV' ||
            _selectedItems[0]['type'] == 'سيدان');

    final allSameType = _selectedItems.every((item) {
      final isCar = item['type'] != null &&
          (item['type'] == 'SUV' ||
              item['type'] == 'سيدان' ||
              item['type'] == 'كوبيه' ||
              item['type'] == 'هاتشباك');
      return isCar == firstItemIsCar;
    });

    if (!allSameType) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار عناصر من نفس النوع للمقارنة')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonScreen(
          items: _selectedItems,
          type: firstItemIsCar ? 'car' : 'property',
        ),
      ),
    );
  }

  bool _isCar(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? '';
    return type == 'SUV' ||
        type == 'سيدان' ||
        type == 'كوبيه' ||
        type == 'هاتشباك';
  }

  @override
  Widget build(BuildContext context) {
    final count = _filteredFavorites.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة${count > 0 ? ' ($count)' : ''}'),
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: _compareItems,
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              label: Text(
                'مقارنة (${_selectedItems.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'مسح الكل',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showOfflineBanner) const OfflineBanner(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _folders
                          .map((folder) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _buildFilterChip(folder),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder,
                      color: AppTheme.primaryColor),
                  tooltip: 'مجلد جديد',
                  onPressed: _createNewFolder,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final item = _filteredFavorites[index];
                          final isSelected = _selectedItems.contains(item);
                          final isCar = _isCar(item);

                          return Dismissible(
                            key: ValueKey(
                              '${item['id']}_${item['title']}_$index',
                            ),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              await _removeItem(item);
                              return false;
                            },
                            child: GestureDetector(
                              onLongPress: () => _toggleSelection(item),
                              child: Stack(
                                children: [
                                  Opacity(
                                    opacity: isSelected ? 0.7 : 1.0,
                                    child: isCar
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: CarCard(
                                              title: item['title'],
                                              price: item['price'],
                                              location: item['location'],
                                              image: item['image'],
                                              seats: item['seats'] ?? 4,
                                              transmission:
                                                  item['transmission'] ??
                                                      'أوتوماتيك',
                                              year: item['year'] ?? 2023,
                                              type: item['type'] ?? 'سيارة',
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookingScreen(
                                                      itemType: 'car',
                                                      itemData: item,
                                                    ),
                                                  ),
                                                );
                                              },
                                              onBook: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookingScreen(
                                                      itemType: 'car',
                                                      itemData: item,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : PropertyCard(
                                            id: item['id'] ?? 'fav_$index',
                                            title: item['title'],
                                            price: item['price'],
                                            location: item['location'],
                                            image: item['image'],
                                            beds: item['beds'] ?? '2 غرفة',
                                            baths: item['baths'] ?? '1 حمام',
                                            area: item['area'] ?? '100 م²',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PropertyDetailsScreen(
                                                          property: item),
                                                ),
                                              );
                                            },
                                            onBook: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BookingScreen(
                                                    itemType: 'property',
                                                    itemData: item,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      left: 24,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 8,
                                    right: 28,
                                    child: Material(
                                      color: Colors.white.withOpacity(0.92),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        tooltip: 'إزالة',
                                        iconSize: 18,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _removeItem(item),
                                        icon: const Icon(
                                          Icons.favorite,
                                          color: Colors.redAccent,
                                        ),
                                      ),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFolder == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFolder = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'لا توجد عناصر في المفضلة',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'احفظ عقارات الساحل أو الإقامة القصيرة للمقارنة لاحقاً',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchResultsScreen(
                      query: '',
                      filters: {'shortStayOnly': true, 'coastalOnly': true},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.beach_access_rounded),
              label: const Text('استكشف الساحل'),
            ),
          ],
        ),
      ),
    );
  }
}
