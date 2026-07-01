import 'package:flutter/material.dart';

import '../screens/advanced_filters_screen.dart';
import '../theme/app_theme.dart';

/// A predictable, accessible bottom navigation bar.
///
/// The middle action solves the user's main job: finding the right property.
/// Owners get "add property" in the same familiar location.
class EjariNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role;

  const EjariNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'tenant',
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppTheme.surfaceColor.withOpacity(0.96),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.42)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              height: 76,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppTheme.accentColor.withOpacity(0.35),
              selectedIndex: currentIndex.clamp(0, 4),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                if (index != 2) {
                  onTap(index);
                  return;
                }

                if (isOwner) {
                  onTap(2);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdvancedFiltersScreen(),
                    ),
                  );
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.apartment_outlined),
                  selectedIcon: Icon(Icons.apartment_rounded),
                  label: 'العقارات',
                ),
                NavigationDestination(
                  icon: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOwner ? Icons.add_home_outlined : Icons.search_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  selectedIcon: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isOwner ? Icons.add_home_rounded : Icons.search_rounded,
                      color: Colors.white,
                    ),
                  ),
                  label: isOwner ? 'إضافة' : 'بحث',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.star_border_rounded),
                  selectedIcon: Icon(Icons.star_rounded),
                  label: 'مميز',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
