import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PropertyCard extends StatefulWidget {
  final String id;
  final String title;
  final String price;
  final String location;
  final String image;
  final String beds;
  final String baths;
  final String area;
  final String? listingMode; // Added listingMode
  final bool isDemo;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const PropertyCard({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.image,
    required this.beds,
    required this.baths,
    required this.area,
    this.listingMode, // Optional
    this.isDemo = false,
    required this.onTap,
    required this.onBook,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final status = await DataService.isFavorite(widget.title);
    if (mounted) {
      setState(() => _isFavorite = status);
    }
  }

  Future<void> _toggleFavorite() async {
    final property = {
      'id': widget.id,
      'title': widget.title,
      'price': widget.price,
      'location': widget.location,
      'image': widget.image,
      'beds': widget.beds,
      'baths': widget.baths,
      'area': widget.area,
      'listingMode': widget.listingMode,
    };
    await DataService.toggleFavorite(property);
    _checkFavorite();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.42)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                Hero(
                  tag: widget.id,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: widget.image.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.image,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 220,
                              color: AppTheme.backgroundColor,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primaryColor)),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/home1.jpg',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            widget.image,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                  ),
                  ),
                ),

                // Superior/Ejari Badge
                if (widget.listingMode != null &&
                    widget.listingMode != 'commission')
                  Positioned(
                    top: 15,
                    right: 15,
                    child: _buildBadge(
                        'إيجاري ${widget.listingMode!.toUpperCase()}',
                        AppTheme.primaryColor,
                        Icons.workspace_premium_rounded),
                  )
                else
                  Positioned(
                    top: 15,
                    right: 15,
                    child: _buildBadge(
                        'سوبريور', AppTheme.primaryColor, Icons.star_rounded),
                  ),

                // Commission Indicator (If applicable)
                if (widget.listingMode == 'commission')
                  Positioned(
                    top: 15,
                    left: 60, // Next to favorite
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('عمولة مرنة',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary)),
                    ),
                  ),

                // Favorite Button
                Positioned(
                  top: 15,
                  left: 15,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ??
                              Theme.of(context).cardColor.withOpacity(0.9),
                          shape: BoxShape.circle),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: AppTheme.errorColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Verified Badge
                if (DataService.isPropertyVerified(widget.id))
                  Positioned(
                    top: 15,
                    left: 65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        boxShadow: const [],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('موثق إيجاري',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                // Real Data Badge
                if (!widget.isDemo)
                  Positioned(
                    bottom: 60,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('متاحة فعلياً',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // Demo Badge
                if (widget.isDemo)
                  Positioned(
                    bottom: 60,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.science_rounded,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('متاحة للتجربة والتقييم',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // Commission Badge
                if (widget.listingMode == 'commission' || widget.id == '1')
                  Positioned(
                    bottom: 60,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('بدون عمولة %0',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Price Tag
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(widget.price,
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(' ${context.tr('price_egp')}',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ... (rest of the card content remains the same)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color ??
                            AppTheme.textPrimary,
                        height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                            child: _buildEjariFeature(
                                Icons.king_bed_rounded, widget.beds, 'غرف')),
                        Expanded(
                            child: _buildEjariFeature(
                                Icons.bathtub_rounded, widget.baths, 'حمامات')),
                        Expanded(
                            child: _buildEjariFeature(
                                Icons.straighten_rounded, widget.area, 'م²')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: widget.onBook,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                              widget.listingMode == 'for_sale'
                                  ? 'تواصل مع المعلن'
                                  : 'حجز الشقة',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: AppTheme.primaryColor),
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

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEjariFeature(IconData icon, String value, String unit) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const TextSpan(text: ' '),
                TextSpan(
                    text: unit,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
