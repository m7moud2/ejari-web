import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
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
import '../services/subscription_service.dart';
import '../services/chat_service.dart';
import 'maintenance_requests_screen.dart';
import 'user_analytics_screen.dart';
import 'loyalty_screen.dart';
import 'wealth_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'properties_screen.dart';
import 'add_property_screen.dart';
import 'provider_home_screen.dart';
import 'home_screen.dart';
import 'enhanced_owner_home_screen.dart';

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

  void _toggleRole(String newRole) async {
    if (_currentRole == newRole) return;

    // Smart Auth Check for Technician mode
    if (newRole == 'provider') {
      final bool loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        _showTechnicianPromoDialog();
        return;
      }
    }

    await AuthService.setUserRole(newRole);
    setState(() => _currentRole = newRole);

    if (mounted) {
      String roleName = 'المستأجر';
      Widget destination = const HomeScreen();

      if (newRole == 'owner') {
        roleName = 'المالك';
        destination = const EnhancedOwnerHomeScreen();
      } else if (newRole == 'provider') {
        roleName = 'الفني / مقدم الخدمة';
        destination = const ServiceProviderHomeScreen();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التحويل إلى وضع $roleName ✨'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ),
      );

      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => destination), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.borderColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).cardTheme.color ??
                                        Theme.of(context)
                                            .cardColor
                                            .withOpacity(0.3),
                                    width: 2),
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
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData?['name'] ?? 'زائر كيو',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          _userData?['email'] ?? 'Premium Member',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    // Role Switcher Toggle -> Replaced with Upgrade button
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Row(
                        children: [
                          if (_currentRole == 'tenant')
                            _buildUpgradeToOwnerBtn(),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.engineering_rounded,
                                color: Colors.white),
                            onPressed: () => _toggleRole('provider'),
                            tooltip: 'تحويل لوضع الفني',
                          ),
                          if (_userData?['type'] == 'admin') ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 28),
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
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountSnapshot(),
                  const SizedBox(height: 18),
                  // Subscription Badge
                  if (_subscription != null) _buildPremiumSubCard(),
                  const SizedBox(height: 24),

                  // Sections
                  _buildSectionTitle(context.tr('account_and_privacy')),
                  _buildMenuCard([
                    _buildKeyoMenuItem(
                        context.tr('loyalty_program'),
                        Icons.loyalty_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoyaltyScreen()))),
                    _buildKeyoMenuItem(
                        context.tr('edit_profile'),
                        Icons.person_outline,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen()))),
                    _buildKeyoMenuItem(
                        context.tr('digital_wallet'),
                        Icons.account_balance_wallet_outlined,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TenantWalletScreen()))),
                    _buildKeyoMenuItem(
                        context.tr('payment_methods'),
                        Icons.payment_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentMethodsScreen()))),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context.tr('properties_and_services')),
                  _buildMenuCard([
                    if (_currentRole == 'tenant') ...[
                      _buildKeyoMenuItem(
                          'حجوزاتي',
                          Icons.calendar_month_rounded,
                          AppTheme.borderColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyBookingsScreen()))),
                      _buildKeyoMenuItem(
                          'عقودي الإلكترونية',
                          Icons.description_outlined,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyContractsScreen()))),
                      _buildKeyoMenuItem(
                          'طلبات الصيانة',
                          Icons.build_circle_outlined,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MaintenanceRequestsScreen()))),
                      _buildKeyoMenuItem(
                          'المفضلة',
                          Icons.favorite_border_rounded,
                          AppTheme.errorColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const FavoritesScreen()))),
                    ] else ...[
                      _buildKeyoMenuItem(
                          context.tr('investment_dashboard'),
                          Icons.pie_chart_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const WealthDashboardScreen()))),
                      _buildKeyoMenuItem(
                          'عقاراتي المعروضة',
                          Icons.holiday_village_rounded,
                          AppTheme.borderColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PropertiesScreen()))),
                      _buildKeyoMenuItem(
                          'نشر عقار جديد',
                          Icons.add_business_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddPropertyScreen()))),
                      _buildKeyoMenuItem(
                          'إحصائيات الإعلانات',
                          Icons.insights_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UserAnalyticsScreen()))),
                      _buildKeyoMenuItem(
                          'إدارة العمولات',
                          Icons.account_balance_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const WalletScreen()))),
                    ],
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context.tr('settings')),
                  _buildMenuCard([
                    _buildKeyoMenuItem(context.tr('language'),
                        Icons.language_rounded, AppTheme.borderColor, () {
                      if (localeNotifier.value.languageCode == 'ar') {
                        localeNotifier.value = const Locale('en', 'US');
                      } else {
                        localeNotifier.value = const Locale('ar', 'SA');
                      }
                    }),
                    _buildKeyoMenuItem(
                        'مركز المساعدة',
                        Icons.help_outline_rounded,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HelpCenterScreen()))),
                    _buildKeyoMenuItem(
                        'شات الدعم الفني',
                        Icons.support_agent_rounded,
                        AppTheme.primaryColor, () async {
                      if (_userData != null && _userData!['email'] != null) {
                        String chatId = await ChatService.startChat(
                            _userData!['email'],
                            'admin@keyo.app',
                            'دعم كيو',
                            'استفسار دعم فني');
                        if (!context.mounted) return;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                    chatId: chatId,
                                    otherUserName: 'دعم كيو',
                                    currentUserId: _userData!['email'])));
                      }
                    }),
                    _buildKeyoMenuItem(
                        'الإعدادات',
                        Icons.settings_outlined,
                        AppTheme.primaryColor,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsScreen()))),
                    _buildKeyoMenuItem('تسجيل الخروج', Icons.logout_rounded,
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

                  if (_userData?['type'] == 'admin') ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('إدارة المنصة (Control Tower)'),
                    _buildMenuCard([
                      _buildKeyoMenuItem(
                          'لوحة التحكم الشاملة',
                          Icons.dashboard_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminDashboardScreen()))),
                      _buildKeyoMenuItem(
                          'إدارة المستخدمين',
                          Icons.people_rounded,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminUsersScreen()))),
                      _buildKeyoMenuItem(
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  AppTheme.textSecondary)),
    );
  }

  Widget _buildAccountSnapshot() {
    final roleLabel = _currentRole == 'owner'
        ? 'مالك'
        : _currentRole == 'provider'
            ? 'فني / مقدم خدمة'
            : _currentRole == 'admin'
                ? 'مدير'
                : 'مستأجر';

    final hasSubscription = _subscription != null;
    final userName = _userData?['name'] ?? 'زائر كيو';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'حالة الحساب',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotTile(
                  label: 'الاسم',
                  value: userName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSnapshotTile(
                  label: 'الدور',
                  value: roleLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSnapshotTile(
                  label: 'الاشتراك',
                  value: hasSubscription ? 'نشط' : 'غير مفعل',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSnapshotTile(
                  label: 'الوضع الحالي',
                  value: 'جاهز للتصفح',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotTile({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildKeyoMenuItem(
      String title, IconData icon, Color color, VoidCallback onTap,
      {bool isLast = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Theme.of(context).textTheme.bodySmall?.color ??
              AppTheme.primaryColor),
      shape: isLast
          ? null
          : Border(
              bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1))),
    );
  }

  Widget _buildPremiumSubCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.textPrimary, AppTheme.textPrimary]),
        borderRadius: BorderRadius.circular(24),
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

  Widget _buildUpgradeToOwnerBtn() {
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
                Text('طلب ترقية حساب'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'كن شريكاً في كيو وابدأ في إدارة عقاراتك بلمسة واحدة.',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'اسم الشركة / المالك',
                    hintText: 'مثال: شركة كيو للاستثمار',
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
                          'تم إرسال طلبك بنجاح! سيتم مراجعة البيانات وتحديث حسابك خلال 24 ساعة.'),
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
            Text('ترقية لمالك عقار',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showTechnicianPromoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor:
            Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering_rounded,
                    color: AppTheme.primaryColor, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'انضم لشبكة الفنيين',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'ابدأ في استقبال طلبات الصيانة من ملاك العقارات في كيو. كن جزءاً من مجتمعنا الموثوق وابدأ عملك الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, height: 1.6, fontSize: 13),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const LoginScreen(redirectToRole: 'provider')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('تسجيل الدخول',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupScreen(
                                redirectToRole: 'provider')));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('إنشاء حساب جديد',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ربما لاحقاً',
                    style: TextStyle(color: AppTheme.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
