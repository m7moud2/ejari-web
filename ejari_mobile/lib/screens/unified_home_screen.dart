import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../services/auth_service.dart';
import '../services/deep_link_service.dart';
import '../theme/app_theme.dart';

import 'views/tenant_home_view.dart';
import 'views/owner_home_view.dart';
import 'views/technician_home_view.dart';
import 'views/admin_home_view.dart';
import '../widgets/home/skeleton_home_loader.dart';
import '../widgets/home/error_state_widget.dart';

class UnifiedHomeScreen extends StatefulWidget {
  const UnifiedHomeScreen({super.key});

  @override
  State<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends State<UnifiedHomeScreen> {
  String userRole = 'tenant';
  bool _isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    try {
      final role = await AuthService.getUserRole().timeout(
        const Duration(seconds: 2),
        onTimeout: () => 'tenant',
      );
      if (!mounted) return;
      setState(() {
        userRole = role;
        _isRoleLoaded = true;
      });
      await context.read<HomeProvider>().loadHomeData(userRole);
      await DeepLinkService.processPending();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userRole = 'tenant';
        _isRoleLoaded = true;
      });
      await context.read<HomeProvider>().loadHomeData(userRole);
      await DeepLinkService.processPending();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<HomeProvider>().loadHomeData(userRole);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoleLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SkeletonHomeLoader(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          if (homeProvider.isLoading) {
            return const SkeletonHomeLoader();
          }

          if (homeProvider.hasError) {
            return ErrorStateWidget(
              onRetry: _onRefresh,
              errorMessage: homeProvider.errorMessage,
            );
          }

          Widget currentView;
          switch (userRole) {
            case 'owner':
              currentView = const OwnerHomeView();
              break;
            case 'technician':
              currentView = const TechnicianHomeView();
              break;
            case 'admin':
              currentView = const AdminHomeView();
              break;
            case 'tenant':
            default:
              currentView = const TenantHomeView();
          }

          return DecoratedBox(
            decoration: const BoxDecoration(color: AppTheme.backgroundColor),
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryColor,
              child: currentView,
            ),
          );
        },
      ),
    );
  }
}
