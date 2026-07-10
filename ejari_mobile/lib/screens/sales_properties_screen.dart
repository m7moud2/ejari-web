import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesPropertiesScreen extends StatefulWidget {
  const SalesPropertiesScreen({super.key});

  @override
  State<SalesPropertiesScreen> createState() => _SalesPropertiesScreenState();
}

class _SalesPropertiesScreenState extends State<SalesPropertiesScreen> {
  final List<Map<String, dynamic>> _salesProperties = [
    {
      'id': 'sale1',
      'title': 'فيلا فاخرة للبيع بالشيخ زايد',
      'price': '15,000,000',
      'location': 'الشيخ زايد، الجيزة',
      'image': 'assets/images/home1.jpg',
      'beds': '5',
      'baths': '4',
      'area': '450',
      'type': 'فلل',
      'listingMode': 'for_sale',
      'advertiserPhone': '+201000000000',
    },
    {
      'id': 'sale2',
      'title': 'شقة دبل فيو بالتجمع الخامس',
      'price': '4,500,000',
      'location': 'التجمع الخامس، القاهرة',
      'image': 'assets/images/home2.jpg',
      'beds': '3',
      'baths': '2',
      'area': '180',
      'type': 'شقق',
      'listingMode': 'for_sale',
      'advertiserPhone': '+201000000000',
    },
  ];

  void _navigateToDetails(Map<String, dynamic> property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  void _contactAdvertiser(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، لا يمكن فتح تطبيق الاتصال')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عقارات للبيع 🏠'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذا القسم مخصص للإعلانات المباشرة من الملاك. تواصل معهم مباشرة بدون عمولات.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16, top: 16),
              itemCount: _salesProperties.length,
              itemBuilder: (context, index) {
                final property = _salesProperties[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    isDemo: false,
                    onTap: () => _navigateToDetails(property),
                    onBook: () =>
                        _contactAdvertiser(property['advertiserPhone']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
