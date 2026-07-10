import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class CarCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String image;
  final int seats;
  final String transmission;
  final int year;
  final String type;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const CarCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.image,
    required this.seats,
    required this.transmission,
    required this.year,
    required this.type,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: AppTheme.backgroundColor,
                        child: const Center(
                          child: Icon(Icons.directions_car,
                              size: 60, color: AppTheme.primaryColor),
                        ),
                      );
                    },
                  ),
                ),
                // Type Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border,
                          color: AppTheme.primaryColor),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('تمت إضافة السيارة إلى المفضلة ❤️')),
                        );
                      },
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),

            // Car Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color ??
                          AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Car Specs
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        _buildSpec(Icons.event_seat, '$seats مقاعد'),
                        const SizedBox(width: 16),
                        _buildSpec(Icons.settings, transmission),
                        const SizedBox(width: 16),
                        _buildSpec(Icons.calendar_today, '$year'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price and Book Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'السعر اليومي',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                ' ${context.tr('price_egp')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'احجز الآن',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
