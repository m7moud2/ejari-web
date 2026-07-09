import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'my_bookings_screen.dart';
import 'favorites_screen.dart';
import 'payment_methods_screen.dart';
import 'settings_screen.dart';
import 'subscriptions_screen.dart';
import 'wallet_screen.dart';
import 'my_contracts_screen.dart';
import 'help_center_screen.dart';
import 'edit_profile_screen.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';
import 'tenant_wallet_screen.dart';
import 'rental_statement_screen.dart';
import '../services/subscription_service.dart';
import '../services/chat_service.dart';
import 'maintenance_requests_screen.dart';
import 'coupons_screen.dart';
import 'user_analytics_screen.dart';
import 'loyalty_screen.dart';
import 'wealth_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'properties_screen.dart';
import 'add_property_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/social_links.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _subscription;
  String _currentRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getCurrentUser();
    final sub = await SubscriptionService.getCurrentSubscription();
    final role = await AuthService.getUserRole();
    setState(() {
      _userData = data;
      _subscription = sub;
      _currentRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/promo/hero_building.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.40),
                          AppTheme.primaryColor.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'إيجاري',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 55,
                    right: 20,
                    child: Row(
                      children: [
                        if (_currentRole == 'tenant') _buildBecomeOwnerBtn(),
                        if (_userData?['type'] == 'admin') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings_rounded,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminDashboardScreen()));
                            },
                            tooltip: 'لوحة التحكم الإدارية',
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 54),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.78),
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  AssetImage('assets/images/app_icon.png'),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.verified_rounded,
                                  color: AppTheme.textPrimary, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData?['name'] ?? 'زائر إيجاري',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        _userData?['email'] ?? 'Premium Member',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.88)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountSnapshot(),
                  const SizedBox(height: AppTheme.spaceMd),
                  if (_subscription != null) _buildPremiumSubCard(),
                  const SizedBox(height: AppTheme.spaceXl),

                  EjariSectionHeader(
                    title: context.tr('account_and_privacy'),
                    subtitle: 'إدارة بياناتك ومحفظتك وطرق الدفع',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem(
                        context.tr('loyalty_program'),
                        Icons.loyalty_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoyaltyScreen()))),
                    _buildEjariMenuItem(
                        'كارت الخصم والعروض',
                        Icons.local_offer_outlined,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CouponsScreen()))),
                    _buildEjariMenuItem(
                        context.tr('edit_profile'),
                        Icons.person_outline,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen()))),
                    _buildEjariMenuItem(
                        'المحفظة والرصيد',
                        Icons.account_balance_wallet_outlined,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TenantWalletScreen()))),
                    _buildEjariMenuItem(
                        'طرق الدفع المحفوظة',
                        Icons.payment_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentMethodsScreen()))),
                  ]),

                  const SizedBox(height: AppTheme.spaceXl),
                  EjariSectionHeader(
                    title: context.tr('properties_and_services'),
                    subtitle: _currentRole == 'tenant'
                        ? 'حجوزاتك وعقودك وطلبات الصيانة'
                        : 'عقاراتك وإحصائياتك ومحفظة العمولات',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    if (_currentRole == 'tenant') ...[
                      _buildEjariMenuItem(
                          'حجوزاتي',
                          Icons.calendar_month_rounded,
                          AppTheme.borderColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyBookingsScreen()))),
                      _buildEjariMenuItem(
                          'عقودي الإلكترونية',
                          Icons.description_outlined,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyContractsScreen()))),
                      _buildEjariMenuItem(
                          'طلبات الصيانة',
                          Icons.build_circle_outlined,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MaintenanceRequestsScreen()))),
                      _buildEjariMenuItem(
                          'المفضلة',
                          Icons.favorite_border_rounded,
                          AppTheme.errorColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const FavoritesScreen()))),
                    ] else ...[
                      _buildEjariMenuItem(
                          'لوحة المالك',
                          Icons.pie_chart_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const WealthDashboardScreen()))),
                      _buildEjariMenuItem(
                          'عقاراتي المعروضة',
                          Icons.holiday_village_rounded,
                          AppTheme.borderColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PropertiesScreen()))),
                      _buildEjariMenuItem(
                          'نشر عقار جديد',
                          Icons.add_business_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddPropertyScreen()))),
                      _buildEjariMenuItem(
                          'إحصائيات الإعلانات',
                          Icons.insights_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAnalyticsScreen()))),
                      _buildEjariMenuItem(
                          'محفظة العمولات',
                          Icons.account_balance_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WalletScreen()))),
                    ],
                  ]),

                  const SizedBox(height: AppTheme.spaceXl),
                  EjariSectionHeader(
                    title: context.tr('settings'),
                    subtitle: 'اللغة والدعم والإعدادات العامة',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem('اللغة',
                        Icons.language_rounded, AppTheme.borderColor, () {
                      if (localeNotifier.value.languageCode == 'ar') {
                        localeNotifier.value = const Locale('en', 'US');
                      } else {
                        localeNotifier.value = const Locale('ar', 'SA');
                      }
                    }),
                    _buildEjariMenuItem(
                        'مركز المساعدة',
                        Icons.help_outline_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HelpCenterScreen()))),
                    _buildEjariMenuItem(
                        'شات الدعم الفني',
                        Icons.support_agent_rounded,
                        AppTheme.primaryColor, () async {
                      if (_userData != null && _userData!['email'] != null) {
                        String chatId = await ChatService.startChat(
                            _userData!['email'],
                            'admin@ejari.app',
                            'دعم إيجاري',
                            'استفسار دعم فني');
                        if (!context.mounted) return;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                    chatId: chatId,
                                    otherUserName: 'دعم إيجاري',
                                    currentUserId: _userData!['email'])));
                      }
                    }),
                    _buildEjariMenuItem(
                        'الإعدادات',
                        Icons.settings_outlined,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()))),
                    _buildEjariMenuItem('تسجيل الخروج', Icons.logout_rounded,
                        AppTheme.errorColor, () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (r) => false);
                    }, isLast: true),
                  ]),

                  const SizedBox(height: AppTheme.spaceXl),
                  const EjariSectionHeader(
                    title: 'تابع إيجاري',
                    subtitle: 'تواصل معنا على منصات التواصل',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem(
                        'Facebook',
                        Icons.facebook_rounded,
                        AppTheme.primaryColor,
                        () => _launchUrl(SocialLinks.facebook)),
                    _buildEjariMenuItem(
                        'LinkedIn',
                        Icons.business_center_rounded,
                        AppTheme.primaryColor,
                        () => _launchUrl(SocialLinks.linkedin),
                        isLast: true),
                  ]),

                  if (_userData?['type'] == 'admin') ...[
                    const SizedBox(height: AppTheme.spaceXl),
                    const EjariSectionHeader(
                      title: 'إدارة المنصة',
                      subtitle: 'لوحة التحكم والمستخدمين والعقارات',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard([
                      _buildEjariMenuItem(
                          'لوحة التحكم الشاملة',
                          Icons.dashboard_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminDashboardScreen()))),
                      _buildEjariMenuItem(
                          'إدارة المستخدمين',
                          Icons.people_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminUsersScreen()))),
                      _buildEjariMenuItem(
                          'مراجعة العقارات',
                          Icons.home_work_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminPropertiesScreen()))),
                    ]),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSnapshot() {
    final roleLabel = _currentRole == 'owner'
        ? 'مالك'
        : _currentRole == 'admin'
            ? 'مدير'
            : 'مستأجر';

    final hasSubscription = _subscription != null;
    final userName = _userData?['name'] ?? 'زائر إيجاري';

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EjariSectionHeader(
            title: 'حالة الحساب',
            subtitle: 'نظرة سريعة على بياناتك واشتراكك',
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: EjariStatTile(
                  icon: Icons.person_rounded,
                  label: 'الاسم',
                  value: userName,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: EjariStatTile(
                  icon: Icons.badge_rounded,
                  label: 'الدور',
                  value: roleLabel,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              Expanded(
                child: EjariStatTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'الاشتراك',
                  value: hasSubscription ? 'نشط' : 'غير مفعل',
                  accentColor: hasSubscription
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: EjariStatTile(
                  icon: Icons.insights_rounded,
                  label: 'الوضع الحالي',
                  value: _currentRole == 'tenant'
                      ? 'قيد المتابعة'
                      : 'جاهز للاستقبال',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            height: AppTheme.ctaHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _currentRole == 'tenant'
                        ? const RentalStatementScreen()
                        : const MyBookingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded),
              label: Text(
                _currentRole == 'tenant'
                    ? 'عرض تفاصيل الحالة'
                    : 'متابعة الحجوزات',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return EjariSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildEjariMenuItem(
      String title, IconData icon, Color color, VoidCallback onTap,
      {bool isLast = false}) {
    return EjariListTile(
      title: title,
      icon: icon,
      iconColor: color,
      onTap: onTap,
      isLast: isLast,
    );
  }

  Widget _buildPremiumSubCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.textPrimary, Color(0xFF334155)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppTheme.primaryColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('العضوية الممتازة',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                    _subscription!['plan'] == 'premium'
                        ? 'الباقة الماسية'
                        : 'الباقة الذهبية',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubscriptionsScreen()));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('إدارة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBecomeOwnerBtn() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.stars, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text('التحول إلى مالك'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'لو عندك عقارات حابب تعرضها، نقدر نساعدك تبدأ بشكل أوضح وأسهل.',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'اسم المالك / الشركة',
                    hintText: 'مثال: شركة التيسير العقارية',
                    prefixIcon: const Icon(Icons.business_rounded),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'الرقم الضريبي (اختياري)',
                    prefixIcon: const Icon(Icons.description_rounded),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'تم إرسال الطلب بنجاح. هيراجع فريق إيجاري البيانات ويتواصل معك قريباً.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
                child: const Text('إرسال الطلب'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          children: [
            Icon(Icons.business_center_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('أصبح مالكاً',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

}
