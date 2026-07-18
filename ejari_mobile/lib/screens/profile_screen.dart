import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import 'support_chat_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'my_bookings_screen.dart';
import 'payment_methods_screen.dart';
import 'settings_screen.dart';
import 'tenant_wallet_screen.dart';
import 'wallet_screen.dart';
import 'my_contracts_screen.dart';
import 'help_center_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_center_screen.dart';
import 'rental_statement_screen.dart';
import '../services/support_service.dart';
import '../services/data_service.dart';
import 'request_verification_screen.dart';
import 'verification_screen.dart';
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
import 'owner_booking_requests_screen.dart';
import 'corporate_command_center_screen.dart';
import 'listing_plans_screen.dart';
import 'subscriptions_screen.dart';
import 'changelog_screen.dart';
import 'about_app_screen.dart';
import 'account_id_screen.dart';
import 'payment_reminders_screen.dart';
import '../services/subscription_service.dart';
import '../services/share_app_service.dart';
import '../services/pdf_export_service.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  String _currentRole = 'tenant';
  Map<String, String> _verificationStatus = {'status': 'none', 'label': 'غير موثق'};
  Map<String, dynamic>? _subscriptionSummary;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getCurrentUser();
    final role = await AuthService.getUserRole();
    Map<String, String> verification = {'status': 'none', 'label': 'غير موثق'};
    final email = data?['email']?.toString() ?? '';
    if (email.isNotEmpty) {
      verification = await DataService.getIdentityVerificationStatus(email);
    }
    Map<String, dynamic>? subSummary;
    if (role == 'owner') {
      subSummary = await SubscriptionService.getSubscriptionSummary();
    }
    setState(() {
      _userData = data;
      _currentRole = role;
      _verificationStatus = verification;
      _subscriptionSummary = subSummary;
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
                  _buildAccountIdCard(),
                  const SizedBox(height: AppTheme.spaceMd),
                  _buildAccountSnapshot(),
                  if (_isOwner && _subscriptionSummary != null) ...[
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildSubscriptionCard(),
                  ],
                  const SizedBox(height: AppTheme.spaceXl),

                  // —— حسابي ——
                  const EjariSectionHeader(
                    title: 'حسابي',
                    subtitle: 'الملف والتوثيق ورقم الحساب',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard(_accountMenuItems()),

                  const SizedBox(height: AppTheme.spaceXl),

                  // —— حجوزاتي / عقارات / مهام ——
                  if (!_isAdmin) ...[
                    EjariSectionHeader(
                      title: _isTechnician
                          ? 'المهام'
                          : _isTenant
                              ? 'حجوزاتي'
                              : 'العقارات والحجوزات',
                      subtitle: _isTechnician
                          ? 'مهامك وجدولك'
                          : _isTenant
                              ? 'حجوزات وعقود وإيصالات'
                              : 'عقاراتك وطلبات الحجز',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard(_propertyMenuItems()),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],

                  // —— مالية ——
                  if (!_isAdmin) ...[
                    EjariSectionHeader(
                      title: 'مالية',
                      subtitle: _isTechnician
                          ? 'محفظة الأرباح'
                          : _isTenant
                              ? 'محفظة وطرق دفع وتذكيرات'
                              : 'المحفظة والكشوف والتحصيل',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard(_financeMenuItems()),
                    const SizedBox(height: AppTheme.spaceXl),
                  ],

                  // —— خدمات (tenant: maintenance + companies + support once) ——
                  if (_isTenant) ...[
                    const EjariSectionHeader(
                      title: 'خدمات',
                      subtitle: 'صيانة وشركات ودعم',
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildMenuCard([
                      _buildEjariMenuItem('طلبات الصيانة',
                          Icons.build_circle_outlined, AppTheme.primaryColor,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MyServiceRequestsScreen()));
                      }),
                      _buildEjariMenuItem(
                          'حساب الشركات',
                          Icons.corporate_fare_rounded,
                          AppTheme.accentColor, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CorporateCommandCenterScreen()));
                      }),
                      _buildEjariMenuItem('شات الدعم الفني',
                          Icons.support_agent_rounded, AppTheme.primaryColor,
                          _openSupportChat),
                      _buildEjariMenuItem(
                          'أصبح مالكاً',
                          Icons.business_center_outlined,
                          AppTheme.accentColor,
                          _showBecomeOwnerDialog,
                          isLast: true),
                    ]),
                    const SizedBox(height: AppTheme.spaceXl),
                  ] else if (!_isAdmin) ...[
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

                  // —— عام ——
                  const EjariSectionHeader(
                    title: 'عام',
                    subtitle: 'إعدادات ومعلومات التطبيق',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  _buildMenuCard([
                    _buildEjariMenuItem('الإعدادات', Icons.settings_outlined,
                        AppTheme.primaryColor, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    }),
                    _buildEjariMenuItem(
                      'ما الجديد',
                      Icons.new_releases_outlined,
                      AppTheme.primaryColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangelogScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEjariMenuItem(
                      'شارك التطبيق',
                      Icons.share_rounded,
                      AppTheme.accentColor,
                      () => ShareAppService.shareInvite(),
                    ),
                    _buildEjariMenuItem(
                      'عن التطبيق',
                      Icons.info_outline_rounded,
                      AppTheme.borderColor,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        );
                      },
                    ),
                    _buildEjariMenuItem('تسجيل الخروج', Icons.logout_rounded,
                        AppTheme.errorColor, _logout, isLast: true),
                  ]),
                  const SizedBox(height: AppTheme.spaceSm),
                  Center(
                    child: Text(
                      'إيجاري ${AppConfig.versionLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),

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
                      _buildEjariMenuItem('مراجعة التوثيق',
                          Icons.verified_user_rounded, AppTheme.primaryColor,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VerificationScreen()));
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

  List<Widget> _accountMenuItems() {
    if (_isAdmin) {
      return [
        _buildEjariMenuItem('تعديل الملف الشخصي', Icons.person_outline,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        }),
        _buildEjariMenuItem('مركز الإشعارات', Icons.notifications_outlined,
            AppTheme.primaryColor, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen()));
        }),
        _buildEjariMenuItem('رقم الحساب', Icons.fingerprint_rounded,
            AppTheme.accentColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccountIdScreen()));
        }),
        _buildEjariMenuItem('لوحة التحكم', Icons.dashboard_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        }, isLast: true),
      ];
    }

    final items = <Widget>[
      _buildEjariMenuItem('تعديل الملف الشخصي', Icons.person_outline,
          AppTheme.primaryColor, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()));
      }),
      _buildEjariMenuItem(
        'توثيق الحساب',
        Icons.verified_user_outlined,
        AppTheme.accentColor,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RequestVerificationScreen(),
            ),
          );
        },
      ),
      _buildEjariMenuItem('مركز الإشعارات', Icons.notifications_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen()));
      }),
      _buildEjariMenuItem('رقم الحساب', Icons.fingerprint_rounded,
          AppTheme.accentColor, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AccountIdScreen()));
      }, isLast: _isTenant),
    ];

    if (_isOwner || _isTechnician) {
      items.add(
        _buildEjariMenuItem('طرق الدفع المحفوظة', Icons.payment_rounded,
            AppTheme.primaryColor, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
        }, isLast: true),
      );
    }

    return items;
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
        _buildEjariMenuItem('خطط النشر', Icons.workspace_premium_rounded,
            AppTheme.accentColor, () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ListingPlansScreen()));
          _loadUserData();
        }),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerBookingRequestsScreen(),
            ),
          );
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
      _buildEjariMenuItem('إيصالاتي', Icons.receipt_long_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RentalStatementScreen()));
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
        _buildEjariMenuItem('باقتي', Icons.card_membership_rounded,
            AppTheme.accentColor, () async {
          await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
          _loadUserData();
        }),
        _buildEjariMenuItem('تحصيل الإيجارات', Icons.payments_outlined,
            AppTheme.primaryColor, () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const OwnerCollectionScreen()));
        }),
        _buildEjariMenuItem('تقرير شهري PDF', Icons.picture_as_pdf_rounded,
            AppTheme.accentColor, _exportOwnerMonthlyReport, isLast: true),
      ];
    }
    // Tenant finance: wallet, payment methods, dedicated reminders screen
    return [
      _buildEjariMenuItem('محفظتي', Icons.account_balance_wallet_outlined,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TenantWalletScreen()));
      }),
      _buildEjariMenuItem('طرق الدفع', Icons.payment_rounded,
          AppTheme.primaryColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
      }),
      _buildEjariMenuItem('تذكيرات الدفع', Icons.notifications_active_outlined,
          AppTheme.accentColor, () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PaymentRemindersScreen()));
      }, isLast: true),
    ];
  }

  Future<void> _exportOwnerMonthlyReport() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء التقرير الشهري...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final ownerId = _userData?['email']?.toString() ?? 'owner@ejari.app';
      final report = await DataService.exportOwnerMonthlyReport(ownerId);
      await PdfExportService.shareOwnerMonthlyReportPdf(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تصدير التقرير الشهري كـ PDF'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تصدير التقرير: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildAccountIdCard() {
    final accountId = _userData?['accountId']?.toString() ?? '—';

    return EjariSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رقم الحساب',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accountId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ رقم الحساب',
            onPressed: accountId == '—'
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: accountId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ رقم الحساب')),
                    );
                  },
            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final summary = _subscriptionSummary!;
    final planName = summary['plan_name']?.toString() ?? 'مجاني';
    final used = summary['properties_used'] ?? 0;
    final limit = summary['properties_limit'] ?? 2;
    final endDate = summary['end_date']?.toString();
    final features = List<String>.from(summary['features'] as List? ?? []);

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('باقة النشر',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    Text(
                      planName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ListingPlansScreen()),
                  );
                  _loadUserData();
                },
                child: const Text('ترقية'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الإعلانات: $used / ${limit == -1 ? '∞' : limit}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          if (endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'تنتهي: ${endDate.split('T').first}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
          if (features.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...features.take(4).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(f, style: const TextStyle(fontSize: 11))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountSnapshot() {
    final roleLabel = _isAdmin
        ? 'مدير'
        : _isOwner
            ? 'مالك'
            : _isTechnician
                ? 'فني'
                : 'مستأجر';
    final verification = _verificationStatus['label'] ?? 'غير موثق';

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

  Future<void> _openSupportChat() async {
    if (_userData == null || _userData!['email'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّل الدخول أولاً لفتح شات الدعم'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    final email = _userData!['email'].toString();
    final name = _userData!['name']?.toString() ?? 'مستخدم';
    if (!mounted) return;
    try {
      await openSupportChat(
        context,
        userEmail: email,
        userName: name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح شات الدعم. حاول مرة أخرى'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
