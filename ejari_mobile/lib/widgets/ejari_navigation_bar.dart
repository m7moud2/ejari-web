import 'package:flutter/material.dart';

import '../screens/advanced_filters_screen.dart';
import '../theme/app_theme.dart';

/// A predictable, accessible bottom navigation bar.
///
/// The middle action solves the user's main job: finding the right property.
/// Owners get "add property" in the same familiar location.
/// Admins get search/users/support shortcuts.
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

  bool get _isOwner => role == 'owner';
  bool get _isAdmin => role == 'admin';
  bool get _isTechnician => role == 'technician';

  @override
  Widget build(BuildContext context) {
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
                if (_isAdmin) {
                  onTap(index);
                  return;
                }
                if (_isTechnician) {
                  onTap(index);
                  return;
                }
                if (index != 2) {
                  onTap(index);
                  return;
                }

                if (_isOwner) {
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
              destinations: _isAdmin
                  ? const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'لوحة',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline_rounded),
                        selectedIcon: Icon(Icons.people_rounded),
                        label: 'المستخدمين',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.manage_search_outlined),
                        selectedIcon: Icon(Icons.manage_search_rounded),
                        label: 'بحث',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.support_agent_outlined),
                        selectedIcon: Icon(Icons.support_agent_rounded),
                        label: 'الدعم',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'حسابي',
                      ),
                    ]
                  : _isTechnician
                      ? const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: 'الرئيسية',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.handyman_outlined),
                            selectedIcon: Icon(Icons.handyman_rounded),
                            label: 'المهام',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.schedule_outlined),
                            selectedIcon: Icon(Icons.schedule_rounded),
                            label: 'الجدول',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.account_balance_wallet_outlined),
                            selectedIcon:
                                Icon(Icons.account_balance_wallet_rounded),
                            label: 'المحفظة',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.person_outline_rounded),
                            selectedIcon: Icon(Icons.person_rounded),
                            label: 'حسابي',
                          ),
                        ]
                      : [
                      const NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'الرئيسية',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.apartment_outlined),
                        selectedIcon: const Icon(Icons.apartment_rounded),
                        label: _isOwner ? 'عقاراتي' : 'العقارات',
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
                            _isOwner
                                ? Icons.add_home_outlined
                                : Icons.search_rounded,
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
                            _isOwner
                                ? Icons.add_home_rounded
                                : Icons.search_rounded,
                            color: Colors.white,
                          ),
                        ),
                        label: _isOwner ? 'إضافة' : 'بحث',
                      ),
                      NavigationDestination(
                        icon: Icon(
                          _isOwner
                              ? Icons.payments_outlined
                              : Icons.star_border_rounded,
                        ),
                        selectedIcon: Icon(
                          _isOwner
                              ? Icons.payments_rounded
                              : Icons.star_rounded,
                        ),
                        label: _isOwner ? 'تحصيل' : 'مميز',
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
