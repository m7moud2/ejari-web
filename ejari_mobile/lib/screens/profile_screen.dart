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
import 'tenant_wallet_screen.dart';
import 'wallet_screen.dart';
import 'my_contracts_screen.dart';
import 'help_center_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_center_screen.dart';
import '../main.dart';
import 'rental_statement_screen.dart';
import '../services/chat_service.dart';
import '../services/support_service.dart';
import 'my_service_requests_screen.dart';
import 'provider_jobs_screen.dart';
import 'provider_timeline_screen.dart';
import 'provider_wallet_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_financials_screen.dart';
import 'admin_search_screen.dart';
import 'admin_support_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_service_requests_screen.dart';
import 'admin_reports_screen.dart';
import 'manage_properties_screen.dart';
import 'add_property_screen.dart';
import 'owner_collection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  String _currentRole = 'tenant';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getCurrentUser();
    final role = await AuthService.getUserRole();
    setState(() {
      _userData = data;
      _currentRole = role;
    });
  }

  bool get _isAdmin =>
      _currentRole == 'admin' || _userData?['type'] == 'admin';
  bool get _isOwner => _currentRole == 'owner';
  bool get _isTechnician => _currentRole == 'technician';
  bool get _isTenant => !_isAdmin && !_isOwner && !_isTechnician;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home1.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppTheme.primaryColor),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 54),
                      const CircleAvatar(
                        radius: 46,
                        backgroundImage:
                            AssetImage('assets/images/app_icon.png'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _userData?['name'] ?? 'زائر إيجاري',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        _userData?['email'] ?? '',
                        style: TextStyle(
                            fontSize: 13,
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
                  const SizedBox(height: AppTheme.spaceXl),

                  // الحساب
                  const EjariSectionHeader(
                    title: 'الحساب',
                    subtitle: 'بياناتك الشخصية والإشعارات',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem('تعديل الملف الشخصي',
                        Icons.person_outline, AppTheme.primaryColor, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()));
                    }),
                    _buildEjariMenuItem('مركز الإشعارات',
                        Icons.notifications_outlined, AppTheme.primaryColor,
                        () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationCenterScreen()));
                    }),
                    if (_isTenant)
                      _buildEjariMenuItem('أصبح مالكاً',
                          Icons.business_center_outlined, AppTheme.accentColor,
                          _showBecomeOwnerDialog, isLast: true)
                    else if (!_isAdmin)
                      _buildEjariMenuItem('طرق الدفع المحفوظة',
                          Icons.payment_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PaymentMethodsScreen()));
                      }, isLast: true)
                    else
                      _buildEjariMenuItem('لوحة التحكم',
                          Icons.dashboard_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminDashboardScreen()));
                      }, isLast: true),
                  ]),

                  const SizedBox(height: AppTheme.spaceXl),

                  // العقارات والحجوزات / مهام الفني / إدارة
                  if (!_isAdmin) ...[
                    EjariSectionHeader(
                      title: _isTechnician ? 'المهام' : 'العقارات والحجوزات',
                      subtitle: _isTechnician
                          ? 'مهامك وجدولك'
                          : _isTenant
                              ? 'حجوزاتك وعقودك'
                              : 'عقاراتك وطلبات الحجز',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard(_propertyMenuItems()),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],

                  // المالية
                  if (!_isAdmin) ...[
                    EjariSectionHeader(
                      title: 'المالية',
                      subtitle: _isTechnician
                          ? 'محفظة الأرباح'
                          : 'المحفظة والكشوف والتحصيل',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard(_financeMenuItems()),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],

                  // الدعم
                  if (!_isAdmin) ...[
                    const EjariSectionHeader(
                      title: 'الدعم',
                      subtitle: 'المساعدة والتواصل',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard([
                      _buildEjariMenuItem('مركز المساعدة',
                          Icons.help_outline_rounded, AppTheme.primaryColor,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpCenterScreen()));
                      }),
                      _buildEjariMenuItem('شات الدعم الفني',
                          Icons.support_agent_rounded, AppTheme.primaryColor,
                          _openSupportChat, isLast: true),
                    ]),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],

                  // الإعدادات
                  const EjariSectionHeader(
                    title: 'الإعدادات',
                    subtitle: 'اللغة والحساب',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem('اللغة', Icons.language_rounded,
                        AppTheme.borderColor, _toggleLanguage),
                    _buildEjariMenuItem('الإعدادات', Icons.settings_outlined,
                        AppTheme.primaryColor, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    }),
                    _buildEjariMenuItem('تسجيل الخروج', Icons.logout_rounded,
                        AppTheme.errorColor, _logout, isLast: true),
                  ]),

                  if (_isAdmin) ...[
                    const SizedBox(height: AppTheme.spaceXl),
                    const EjariSectionHeader(
                      title: 'إدارة المنصة',
                      subtitle: 'لوحة المدير — أدوات التشغيل والإشراف',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard([
                      _buildEjariMenuItem('لوحة التحكم',
                          Icons.dashboard_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminDashboardScreen()));
                      }),
                      _buildEjariMenuItem('بحث شامل', Icons.manage_search_rounded,
                          AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminSearchScreen()));
                      }),
                      _buildEjariMenuItem('إدارة المستخدمين',
                          Icons.people_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminUsersScreen()));
                      }),
                      _buildEjariMenuItem('مراجعة العقارات',
                          Icons.home_work_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminPropertiesScreen()));
                      }),
                      _buildEjariMenuItem('المالية والمعاملات',
                          Icons.account_balance_rounded, AppTheme.primaryColor,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminFinancialsScreen()));
                      }),
                      _buildEjariMenuItem('صندوق الدعم',
                          Icons.support_agent_rounded, AppTheme.accentColor,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminSupportScreen()));
                      }),
                      _buildEjariMenuItem('مراجعة التقييمات',
                          Icons.star_rate_rounded, AppTheme.borderColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminReviewsScreen()));
                      }),
                      _buildEjariMenuItem('طلبات الخدمة',
                          Icons.handyman_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminServiceRequestsScreen()));
                      }),
                      _buildEjariMenuItem('التقارير',
                          Icons.analytics_rounded, AppTheme.primaryColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminReportsScreen()));
                      }, isLast: true),
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

  List<Widget> _propertyMenuItems() {
    if (_isTechnician) {
      return [
        _buildEjariMenuItem('مهام الصيانة', Icons.handyman_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProviderJobsScreen()));
        }),
        _buildEjariMenuItem('جدول المهام', Icons.calendar_month_rounded,
            AppTheme.accentColor, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProviderTimelineScreen()));
        }, isLast: true),
      ];
    }
    if (_isAdmin) {
      return [
        _buildEjariMenuItem('مراجعة العقارات', Icons.home_work_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminPropertiesScreen()));
        }, isLast: true),
      ];
    }
    if (_isOwner) {
      return [
        _buildEjariMenuItem('عقاراتي', Icons.holiday_village_rounded,
            AppTheme.borderColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManagePropertiesScreen()));
        }),
        _buildEjariMenuItem('نشر عقار', Icons.add_business_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
        }),
        _buildEjariMenuItem('طلبات الحجز', Icons.inbox_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
        }, isLast: true),
      ];
    }
    return [
      _buildEjariMenuItem('حجوزاتي', Icons.calendar_month_rounded,
          AppTheme.borderColor, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
      }),
      _buildEjariMenuItem('عقودي', Icons.description_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyContractsScreen()));
      }),
      _buildEjariMenuItem('المفضلة', Icons.favorite_border_rounded,
          AppTheme.errorColor, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()));
      }),
      _buildEjariMenuItem('طلبات الصيانة', Icons.build_circle_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MyServiceRequestsScreen()));
      }, isLast: true),
    ];
  }

  List<Widget> _financeMenuItems() {
    if (_isTechnician) {
      return [
        _buildEjariMenuItem('محفظة الأرباح', Icons.account_balance_wallet_rounded,
            AppTheme.accentColor, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProviderWalletScreen()));
        }, isLast: true),
      ];
    }
    if (_isOwner) {
      return [
        _buildEjariMenuItem('محفظة الأرباح', Icons.account_balance_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        }),
        _buildEjariMenuItem('تحصيل الإيجارات', Icons.payments_outlined,
            AppTheme.primaryColor, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const OwnerCollectionScreen()));
        }, isLast: true),
      ];
    }
    return [
      _buildEjariMenuItem('محفظتي', Icons.account_balance_wallet_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantWalletScreen()));
      }),
      _buildEjariMenuItem('كشف الإيجار', Icons.receipt_long_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RentalStatementScreen()));
      }, isLast: true),
    ];
  }

  Widget _buildAccountSnapshot() {
    final roleLabel = _isAdmin
        ? 'مدير'
        : _isOwner
            ? 'مالك'
            : _isTechnician
                ? 'فني'
                : 'مستأجر';
    final verification =
        _userData?['verified'] == true || _userData?['isVerified'] == true
            ? 'موثق'
            : 'قيد المراجعة';

    return EjariSurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: EjariStatTile(
              icon: Icons.badge_rounded,
              label: 'الدور',
              value: roleLabel,
              compact: true,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Expanded(
            child: EjariStatTile(
              icon: Icons.verified_user_rounded,
              label: 'الحالة',
              value: verification,
              accentColor: AppTheme.accentColor,
              compact: true,
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

  void _toggleLanguage() {
    if (localeNotifier.value.languageCode == 'ar') {
      localeNotifier.value = const Locale('en', 'US');
    } else {
      localeNotifier.value = const Locale('ar', 'SA');
    }
  }

  Future<void> _openSupportChat() async {
    if (_userData == null || _userData!['email'] == null) return;
    final email = _userData!['email'].toString();
    final name = _userData!['name']?.toString() ?? 'مستخدم';
    final chatId = await ChatService.startChat(
      email,
      SupportService.adminEmail,
      'دعم إيجاري',
      'استفسار دعم فني',
      user1Name: name,
    );
    await SupportService.createTicket(
      userEmail: email,
      userName: name,
      subject: 'استفسار من الملف الشخصي',
      message: 'بدء محادثة دعم',
      chatId: chatId,
    );
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserName: 'دعم إيجاري',
                currentUserId: email)));
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false);
  }

  void _showBecomeOwnerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التحول إلى مالك'),
        content: const Text(
            'أرسل بياناتك وسيتواصل فريق إيجاري معك لتفعيل حساب المالك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_userData == null) return;
              final email = _userData!['email']?.toString() ?? '';
              final name = _userData!['name']?.toString() ?? 'مستأجر';
              await SupportService.createTicket(
                userEmail: email,
                userName: name,
                subject: 'طلب التحول إلى مالك',
                message: 'يرغب المستأجر في تفعيل حساب مالك',
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم إرسال الطلب. سنتواصل معك قريباً.')),
              );
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
