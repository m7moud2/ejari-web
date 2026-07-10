import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../widgets/car_card.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import 'comparison_screen.dart';

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
  String _selectedFolder = 'عام'; // Default folder

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final favorites = await DataService.getFavorites();
    final folders = await DataService.getFavoriteFolders();
    setState(() {
      _favorites = favorites;
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

  void _compareItems() {
    if (_selectedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر عنصرين على الأقل للمقارنة')),
      );
      return;
    }

    // Check if all items are of the same type
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة ❤️'),
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('مسح الكل'),
                  content: const Text('هل تريد مسح جميع العناصر من المفضلة؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _favorites.clear();
                          _selectedItems.clear();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFavorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final item = _filteredFavorites[index];
                          final isSelected = _selectedItems.contains(item);
                          final isCar = item['type'] != null &&
                              (item['type'] == 'SUV' ||
                                  item['type'] == 'سيدان' ||
                                  item['type'] == 'كوبيه' ||
                                  item['type'] == 'هاتشباك');

                          return GestureDetector(
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
                                            onTap: () {},
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
                              ],
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
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'لا توجد عناصر في المفضلة',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'اضغط على ❤️ لإضافة عقارات أو سيارات للمفضلة',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
