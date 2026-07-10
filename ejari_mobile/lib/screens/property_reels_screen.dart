import 'package:flutter/material.dart';
import '../services/firestore_property_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_image.dart';
import 'property_details_screen.dart';

class PropertyReelsScreen extends StatefulWidget {
  const PropertyReelsScreen({super.key});

  @override
  State<PropertyReelsScreen> createState() => _PropertyReelsScreenState();
}

class _PropertyReelsScreenState extends State<PropertyReelsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _featured = [];

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    final properties = await FirestorePropertyService.getAllProperties();
    if (!mounted) return;

    final curated = properties.where((p) {
      final price = (p['price'] ?? '').toString();
      return price.isNotEmpty;
    }).take(8).toList();

    setState(() {
      _featured = curated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('العروض المميزة'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeatured,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: AppTheme.primaryColor, size: 30),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اختيارات مميزة بدل شكل الفيديوهات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'عرض هادئ وواضح للوحدات الأقرب للثقة والجاهزية.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionHeader('وحدات مقترحة'),
                  const SizedBox(height: 12),
                  ..._featured.map(_buildFeaturedCard),
                  if (_featured.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.borderColor.withOpacity(0.45),
                        ),
                      ),
                      child: const Text(
                        'لا توجد عروض جاهزة الآن، لكن الصفحة ستعرض أول ما تتوفر وحدات جديدة.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _buildSectionHeader('بدل الجولات: ماذا يفيد المستخدم؟'),
                  const SizedBox(height: 12),
                  _buildValueCard(
                    icon: Icons.visibility_outlined,
                    title: 'تركيز على العقار نفسه',
                    subtitle: 'بدل فيديوهات ووضع ريلز مشتت، المستخدم يرى تفاصيل قابلة للحسم.',
                  ),
                  _buildValueCard(
                    icon: Icons.verified_outlined,
                    title: 'قرار أسرع',
                    subtitle: 'الصورة والسعر والموقع أهم من الشكل الاستعراضي إذا كان الهدف الحجز.',
                  ),
                  _buildValueCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'مباشرة إلى المعاينة',
                    subtitle: 'كل عرض ينتهي بخطوة عملية: فتح التفاصيل ثم الحجز أو التواصل.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: AspectRatio(
                aspectRatio: 1.55,
                child: _buildPropertyImage(item['image']?.toString()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? 'وحدة سكنية',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item['price'] ?? '0'} ج.م',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'] ?? 'الموقع غير محدد',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('${item['beds'] ?? '0'} غرف', Icons.bed_outlined),
                      _chip('${item['baths'] ?? '0'} حمامات', Icons.bathtub_outlined),
                      _chip('${item['area'] ?? '0'} م²', Icons.square_foot_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyDetailsScreen(property: item),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'عرض التفاصيل وحجز المعاينة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyImage(String? imagePath) {
    final path = (imagePath == null || imagePath.isEmpty)
        ? 'assets/images/home1.jpg'
        : imagePath;
    final isUrl = path.startsWith('http://') || path.startsWith('https://');

    return isUrl
        ? Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.backgroundColor,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: AppTheme.textSecondary, size: 36),
            ),
          )
        : EjariImage(
            path: path,
            fit: BoxFit.cover,
          );
  }
}
