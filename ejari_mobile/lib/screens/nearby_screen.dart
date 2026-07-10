import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/firestore_property_service.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';
import 'map_search_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _nearbyProperties = [];
  List<Map<String, dynamic>> _nearbyCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final allProperties = await FirestorePropertyService.getAllProperties();
    // Simulate Cars Data
    final allCars = [
      {
        'id': 'car1',
        'title': 'أودي Q8 2024',
        'price': '1500',
        'location': 'التجمع الخامس، القاهرة',
        'image': 'assets/images/audi_q8.jpg',
        'type': 'SUV',
        'seats': 7,
        'year': 2024,
      },
      {
        'id': 'car2',
        'title': 'BMW M4 2023',
        'price': '1200',
        'location': 'الشيخ زايد، القاهرة',
        'image': 'assets/images/bmw_m4.jpg',
        'type': 'كوبيه',
        'seats': 4,
        'year': 2023,
      },
      {
        'id': 'car3',
        'title': 'تويوتا كورولا 2023',
        'price': '400',
        'location': 'مدينة نصر، القاهرة',
        'image': 'assets/images/home1.jpg',
        'type': 'سيدان',
        'seats': 5,
        'year': 2023,
      },
      {
        'id': 'car4',
        'title': 'كيا سبورتاج',
        'price': '700',
        'location': 'المعادي، القاهرة',
        'image': 'assets/images/kia_seltos.jpg',
        'type': 'SUV',
        'seats': 5,
        'year': 2024,
      },
    ];

    if (mounted) {
      setState(() {
        _nearbyProperties = allProperties.map((p) {
          p['distance'] =
              (1 + (allProperties.indexOf(p) * 0.5)).toStringAsFixed(1);
          return p;
        }).toList();

        _nearbyCars = allCars.map((c) {
          c['distance'] = (2 + (allCars.indexOf(c) * 0.8)).toStringAsFixed(1);
          return c;
        }).toList();

        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps(String location) async {
    final query = Uri.encodeComponent(location);
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('جاري التوجيه للخرائط... (Simulated)')));
        }
      }
    } catch (e) {
      debugPrint("Error launching maps: $e");
    }
  }

  bool _isNetworkImage(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقرب إليك 📍'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'عقارات', icon: Icon(Icons.apartment)),
            Tab(text: 'سيارات', icon: Icon(Icons.directions_car)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_nearbyProperties, true),
                _buildList(_nearbyCars, false),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const MapSearchScreen()));
        },
        label: const Text('عرض الخريطة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.map, color: Colors.white),
        backgroundColor: AppTheme.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isProperty) {
    if (items.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNearbyItem(item, isProperty);
      },
    );
  }

  Widget _buildNearbyItem(Map<String, dynamic> item, bool isProperty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: _isNetworkImage(item['image']?.toString() ?? '')
                    ? Image.network(
                        item['image'].toString().trim(),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Image.asset(
                          'assets/images/home1.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        (item['image']?.toString() ?? '').startsWith('assets/')
                            ? item['image']
                            : 'assets/images/home1.jpg',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 180,
                          color: AppTheme.backgroundColor,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: AppTheme.textSecondary),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.near_me, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('${item['distance']} كم',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(item['title'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16))),
                    Text('${item['price']} ${isProperty ? '' : 'ج.م'}',
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(item['location'],
                          style:
                              const TextStyle(color: AppTheme.primaryColor))),
                ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchMaps(item['location']),
                        icon: const Icon(Icons.directions),
                        label: const Text('الاتجاهات'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isProperty) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PropertyDetailsScreen(property: item)));
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BookingScreen(
                                        itemType: 'car', itemData: item)));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('احجز الآن'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Text('لا توجد نتائج قريبة',
            style: TextStyle(color: AppTheme.primaryColor)));
  }
}
