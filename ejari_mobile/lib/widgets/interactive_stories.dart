import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/property_reels_screen.dart';
import '../screens/add_property_screen.dart';
import 'ejari_image.dart';

class InteractiveStories extends StatelessWidget {
  const InteractiveStories({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stories = [
      {
        'title': 'شارك ريلز ➕',
        'image': 'assets/images/home1.jpg',
        'isAdd': true
      },
      {
        'title': 'إطلالة النيل',
        'image': 'assets/images/home2.jpg',
        'isAdd': false
      },
      {
        'title': 'منطقة الفلل',
        'image': 'assets/images/home3.jpg',
        'isAdd': false
      },
      {
        'title': 'إسكان طلاب',
        'image': 'assets/images/home1.jpg',
        'isAdd': false
      },
      {'title': 'عروض إيجاري', 'image': 'assets/images/home2.jpg', 'isAdd': false},
    ];

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final bool isAdd = story['isAdd'] as bool;

          return GestureDetector(
            onTap: () {
              if (isAdd) {
                // تفعيل الميزة: إضافة ريل / عقار
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddPropertyScreen()));
              } else {
                // تفعيل الميزة: مشاهدة الريلز
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PropertyReelsScreen()));
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isAdd
                          ? null
                          : const LinearGradient(
                              colors: [
                                AppTheme.borderColor,
                                AppTheme.primaryColor
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: isAdd
                          ? Border.all(color: AppTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.backgroundColor,
                        image: DecorationImage(
                          image: EjariImage.provider(story['image']),
                          fit: BoxFit.cover,
                          colorFilter: isAdd
                              ? ColorFilter.mode(
                                  AppTheme.textPrimary.withOpacity(0.3),
                                  BlendMode.darken)
                              : null,
                        ),
                      ),
                      child: isAdd
                          ? const Center(
                              child: Icon(Icons.add_rounded,
                                  color: Colors.white, size: 30),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story['title'],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: isAdd ? FontWeight.w900 : FontWeight.bold,
                        color: isAdd
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
