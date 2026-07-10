import 'package:flutter/material.dart';
import '../widgets/car_card.dart';
import '../theme/app_theme.dart';
import 'booking_screen.dart';
import '../l10n/app_localizations.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  String _selectedType = 'الكل';
  final List<String> _carTypes = ['الكل', 'سيدان', 'SUV', 'هاتشباك', 'كوبيه'];

  final List<Map<String, dynamic>> _allCars = [
    {
      'id': 'car1',
      'title': 'أودي Q8 موديل 2024',
      'price': '1500',
      'location': 'التجمع الخامس، القاهرة',
      'image': 'assets/images/audi_q8.jpg',
      'type': 'SUV',
      'seats': 7,
      'transmission': 'أوتوماتيك',
      'year': 2024,
      'color': 'رمادي',
      'fuel': 'بنزين',
      'mileage': '5,000 كم',
    },
    {
      'id': 'car2',
      'title': 'BMW M4 موديل 2023',
      'price': '1200',
      'location': 'الشيخ زايد، القاهرة',
      'image': 'assets/images/bmw_m4.jpg',
      'type': 'كوبيه',
      'seats': 4,
      'transmission': 'أوتوماتيك',
      'year': 2023,
      'color': 'أزرق',
      'fuel': 'بنزين',
      'mileage': '12,000 كم',
    },
    {
      'id': 'car3',
      'title': 'شيفروليه كامارو SS',
      'price': '1000',
      'location': 'نيو كايرو، القاهرة',
      'image': 'assets/images/camaro_ss.jpg',
      'type': 'كوبيه',
      'seats': 4,
      'transmission': 'أوتوماتيك',
      'year': 2023,
      'color': 'أصفر',
      'fuel': 'بنزين',
      'mileage': '8,000 كم',
    },
    {
      'id': 'car4',
      'title': 'كيا سيلتوس 2024',
      'price': '500',
      'location': 'مدينة نصر، القاهرة',
      'image': 'assets/images/kia_seltos.jpg',
      'type': 'SUV',
      'seats': 5,
      'transmission': 'أوتوماتيك',
      'year': 2024,
      'color': 'أخضر',
      'fuel': 'بنزين',
      'mileage': '2,000 كم',
    },
    {
      'id': 'car5',
      'title': 'BMW الفئة الخامسة 2023',
      'price': '900',
      'location': 'المعادي، القاهرة',
      'image': 'assets/images/bmw_5series.jpg',
      'type': 'سيدان',
      'seats': 5,
      'transmission': 'أوتوماتيك',
      'year': 2023,
      'color': 'أسود',
      'fuel': 'بنزين',
      'mileage': '15,000 كم',
    },
    {
      'id': 'car6',
      'title': 'تويوتا كورولا 2023',
      'price': '400',
      'location': 'الدقي، القاهرة',
      'image': 'assets/images/home1.jpg',
      'type': 'سيدان',
      'seats': 5,
      'transmission': 'أوتوماتيك',
      'year': 2023,
      'color': 'فضي',
      'fuel': 'بنزين',
      'mileage': '20,000 كم',
    },
    {
      'id': 'car7',
      'title': 'هيونداي إلنترا 2022',
      'price': '350',
      'location': 'مصر الجديدة، القاهرة',
      'image': 'assets/images/home2.jpg',
      'type': 'سيدان',
      'seats': 5,
      'transmission': 'يدوي',
      'year': 2022,
      'color': 'أبيض',
      'fuel': 'بنزين',
      'mileage': '35,000 كم',
    },
    {
      'id': 'car8',
      'title': 'هيونداي i30 2023',
      'price': '380',
      'location': 'المهندسين، القاهرة',
      'image': 'assets/images/home3.jpg',
      'type': 'هاتشباك',
      'seats': 5,
      'transmission': 'أوتوماتيك',
      'year': 2023,
      'color': 'أحمر',
      'fuel': 'بنزين',
      'mileage': '10,000 كم',
    },
  ];

  List<Map<String, dynamic>> get _filteredCars {
    if (_selectedType == 'الكل') {
      return _allCars;
    }
    return _allCars.where((car) => car['type'] == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سيارات للإيجار 🚗'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Type Filter Chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _carTypes.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: AppTheme.backgroundColor,
                );
              }).toList(),
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'عدد النتائج: ${_filteredCars.length}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),

          // Cars List
          Expanded(
            child: _filteredCars.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_filled,
                            size: 80, color: AppTheme.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد سيارات متاحة',
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
                    itemCount: _filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = _filteredCars[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        child: CarCard(
                          title: car['title'],
                          price: car['price'],
                          location: car['location'],
                          image: car['image'],
                          seats: car['seats'],
                          transmission: car['transmission'],
                          year: car['year'],
                          type: car['type'],
                          onTap: () {
                            _showCarDetails(context, car);
                          },
                          onBook: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(
                                  itemType: 'car',
                                  itemData: car,
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

  void _showCarDetails(BuildContext context, Map<String, dynamic> car) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    car['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('النوع', car['type']),
            _buildDetailRow('الموديل', '${car['year']}'),
            _buildDetailRow('اللون', car['color']),
            _buildDetailRow('عدد المقاعد', '${car['seats']}'),
            _buildDetailRow('الناقل', car['transmission']),
            _buildDetailRow('الوقود', car['fuel']),
            _buildDetailRow('المسافة المقطوعة', car['mileage']),
            _buildDetailRow(
                'السعر اليومي', '${car['price']} ${context.tr('price_egp')}'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        itemType: 'car',
                        itemData: car,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('احجز الآن', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
