import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'notification_badge.dart';

/// Role-aware bottom navigation — max 5 destinations.
///
/// Owner IA:
/// الرئيسية → عقاراتي → إضافة → تحصيل → حسابي
///
/// Technician IA:
/// الرئيسية → المهام → الجدول → المحفظة → حسابي
///
/// Tenant IA (renting-focused):
/// الرئيسية → استكشف → حجوزاتي → المحفظة → حسابي
class EjariNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role;
  final int profileBadgeCount;

  const EjariNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'tenant',
    this.profileBadgeCount = 0,
  });

  bool get _isOwner => role == 'owner';
  bool get _isAdmin => role == 'admin';
  bool get _isTechnician => role == 'technician';

  NavigationDestination get _profileDestination => NavigationDestination(
        icon: NotificationBadge(
          count: profileBadgeCount,
          child: const Icon(Icons.person_outline_rounded),
        ),
        selectedIcon: NotificationBadge(
          count: profileBadgeCount,
          child: const Icon(Icons.person_rounded),
        ),
        label: 'حسابي',
      );

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
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
              height: 76,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppTheme.accentColor.withOpacity(0.35),
              selectedIndex: currentIndex.clamp(0, 4).toInt(),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: onTap,
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
                      : _isOwner
                          ? [
                              const NavigationDestination(
                                icon: Icon(Icons.home_outlined),
                                selectedIcon: Icon(Icons.home_rounded),
                                label: 'الرئيسية',
                              ),
                              const NavigationDestination(
                                icon: Icon(Icons.apartment_outlined),
                                selectedIcon: Icon(Icons.apartment_rounded),
                                label: 'عقاراتي',
                              ),
                              NavigationDestination(
                                icon: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_home_outlined,
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
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_home_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                label: 'إضافة',
                              ),
                              const NavigationDestination(
                                icon: Icon(Icons.payments_outlined),
                                selectedIcon: Icon(Icons.payments_rounded),
                                label: 'تحصيل',
                              ),
                              _profileDestination,
                            ]
                          : [
                              // Tenant — focused on renting, paying, staying
                              const NavigationDestination(
                                icon: Icon(Icons.home_outlined),
                                selectedIcon: Icon(Icons.home_rounded),
                                label: 'الرئيسية',
                              ),
                              const NavigationDestination(
                                icon: Icon(Icons.explore_outlined),
                                selectedIcon: Icon(Icons.explore_rounded),
                                label: 'استكشف',
                              ),
                              NavigationDestination(
                                icon: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_outlined,
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
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                label: 'حجوزاتي',
                              ),
                              const NavigationDestination(
                                icon: Icon(
                                    Icons.account_balance_wallet_outlined),
                                selectedIcon: Icon(
                                    Icons.account_balance_wallet_rounded),
                                label: 'المحفظة',
                              ),
                              _profileDestination,
                            ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
