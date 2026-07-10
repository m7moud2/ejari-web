import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import 'booking_screen.dart';
import 'property_details_screen.dart';

class CommercialScreen extends StatelessWidget {
  const CommercialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عقارات تجارية 🏢')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          PropertyCard(
            id: 'commercial_1',
            title: 'مكتب إداري بالتجمع الخامس',
            price: '45,000',
            location: 'التجمع الخامس، شارع التسعين',
            image: 'assets/images/home1.jpg',
            beds: '5',
            baths: '2',
            area: '200',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertyDetailsScreen(property: {
                    'id': 'commercial_1',
                    'title': 'مكتب إداري بالتجمع الخامس',
                    'price': '45,000',
                    'location': 'التجمع الخامس، شارع التسعين',
                    'image': 'assets/images/home1.jpg',
                    'beds': '5',
                    'baths': '2',
                    'area': '200',
                  }),
                ),
              );
            },
            onBook: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingScreen(
                    itemType: 'property',
                    itemData: {
                      'id': 'commercial_1',
                      'title': 'مكتب إداري بالتجمع الخامس',
                      'price': '45,000',
                      'image': 'assets/images/home1.jpg',
                    },
                  ),
                ),
              );
            },
          ),
          PropertyCard(
            id: 'commercial_2',
            title: 'محال تجاري في مول',
            price: '80,000',
            location: 'الشيخ زايد',
            image: 'assets/images/home2.jpg',
            beds: '1',
            baths: '1',
            area: '120',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertyDetailsScreen(property: {
                    'id': 'commercial_2',
                    'title': 'محال تجاري في مول',
                    'price': '80,000',
                    'location': 'الشيخ زايد',
                    'image': 'assets/images/home2.jpg',
                    'beds': '1',
                    'baths': '1',
                    'area': '120',
                  }),
                ),
              );
            },
            onBook: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingScreen(
                    itemType: 'property',
                    itemData: {
                      'id': 'commercial_2',
                      'title': 'محال تجاري في مول',
                      'price': '80,000',
                      'image': 'assets/images/home2.jpg',
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
