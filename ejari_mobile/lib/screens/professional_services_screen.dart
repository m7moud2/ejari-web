import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/auth_gate.dart';
import '../services/auth_service.dart';
import '../services/support_service.dart';
import '../services/data_service.dart';

class ProfessionalServicesScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  const ProfessionalServicesScreen({super.key, this.property});

  @override
  State<ProfessionalServicesScreen> createState() =>
      _ProfessionalServicesScreenState();
}

class _ProfessionalServicesScreenState extends State<ProfessionalServicesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroAnimController;
  late Animation<double> _heroFadeAnim;

  int _selectedPhotoPackage = 0;
  int _selectedViewingType = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  String? _selectedTime;

  final List<Map<String, dynamic>> _photoPackages = [
    {
      'title': 'تصوير احترافي',
      'subtitle': 'بروفيشنال',
      'price': '800',
      'features': [
        '20 صورة HDR',
        'تعديل احترافي',
        'تسليم خلال 24 ساعة',
        'مصور معتمد'
      ],
      'icon': Icons.camera_alt_rounded,
      'color': AppTheme.primaryColor,
      'tag': 'شائع',
    },
    {
      'title': 'جولة 360° مع VR',
      'subtitle': 'افتراضي',
      'price': '1,800',
      'features': [
        'جولة 360° تفاعلية',
        'عرض على VR',
        'مشاركة رابط مباشر',
        '40 لقطة HDR'
      ],
      'icon': Icons.view_in_ar_rounded,
      'color': AppTheme.primaryColor,
      'tag': 'مميز',
    },
    {
      'title': 'تصوير جوي بالدرون',
      'subtitle': 'أيريال',
      'price': '2,500',
      'features': [
        'فيديو 4K جوي',
        'صور جوية بانورامية',
        'تصوير فيلاتي للمنطقة',
        'حق نشر كامل'
      ],
      'icon': Icons.flight_takeoff_rounded,
      'color': AppTheme.borderColor,
      'tag': 'إيجاري',
    },
  ];

  final List<Map<String, dynamic>> _viewingTypes = [
    {
      'title': 'معاينة حضورية',
      'desc':
          'وكيل متخصص يرافقك شخصياً لاستكشاف العقار والإجابة على كل تساؤلاتك.',
      'icon': Icons.person_pin_circle_rounded,
      'color': AppTheme.primaryColor,
      'badge': null,
    },
    {
      'title': 'بث مباشر مع الوكيل',
      'desc': 'جولة مصورة حية عبر الفيديو مع وكيلنا المعتمد من راحة بيتك.',
      'icon': Icons.video_call_rounded,
      'color': AppTheme.primaryColor,
      'badge': 'جديد',
    },
    {
      'title': 'جولة VR تفاعلية',
      'desc':
          'استكشف العقار بشكل مستقل 360° بتقنية الواقع الافتراضي في أي وقت.',
      'icon': Icons.vrpano_rounded,
      'color': AppTheme.primaryColor,
      'badge': 'ثوري',
    },
  ];

  final List<String> _availableTimes = [
    '9:00 ص',
    '10:00 ص',
    '11:30 ص',
    '1:00 م',
    '2:30 م',
    '4:00 م',
    '5:30 م',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroFadeAnim = CurvedAnimation(
        parent: _heroAnimController, curve: Curves.easeOutQuart);
    _heroAnimController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.borderColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('الخدمات الاحترافية',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _heroFadeAnim,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/pro_services_hero.png',
                        fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.borderColor.withOpacity(0.4),
                            AppTheme.borderColor.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.5)),
                            ),
                            child: const Text('تقنيات غير مسبوقة في مصر',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'اعرض عقارك للعالم\nبأحدث أساليب التسويق',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: AppTheme.borderColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('تصوير')
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_work_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('معاينة')
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('ابتكارات')
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPhotographyTab(),
            _buildViewingTab(),
            _buildInnovationsTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════ TAB 1: PHOTOGRAPHY ═══════════════════
  Widget _buildPhotographyTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('اختر باقة التصوير',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('كل صورة تساوي 1,000 مشاهدة إضافية لعقارك',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
        const SizedBox(height: 20),
        ...List.generate(
            _photoPackages.length, (i) => _buildPhotoPackageCard(i)),
        const SizedBox(height: 24),
        if (_selectedPhotoPackage >= 0)
          _buildBookingButton(
            'احجز باقة ${_photoPackages[_selectedPhotoPackage]['title']}',
            '${_photoPackages[_selectedPhotoPackage]['price']} ج.م',
            () => _showBookingConfirmation(
                context, _photoPackages[_selectedPhotoPackage]['title']),
          ),
      ],
    );
  }

  Widget _buildPhotoPackageCard(int index) {
    final pkg = _photoPackages[index];
    final isSelected = _selectedPhotoPackage == index;
    final color = pkg['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedPhotoPackage = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : AppTheme.backgroundColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]
              : [
                  BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(pkg['icon'] as IconData, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(pkg['title'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(pkg['tag'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text(pkg['subtitle'] as String,
                          style: const TextStyle(
                              color: AppTheme.primaryColor, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${pkg['price']} ج.م',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: color)),
                    const Text('جلسة واحدة',
                        style: TextStyle(
                            color: AppTheme.primaryColor, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (pkg['features'] as List<String>)
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(f,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════ TAB 2: VIEWING ═══════════════════
  Widget _buildViewingTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('نوع المعاينة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        ...List.generate(_viewingTypes.length, (i) => _buildViewingTypeCard(i)),
        const SizedBox(height: 24),
        const Text('اختر الموعد',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildDatePicker(),
        const SizedBox(height: 20),
        const Text('المواعيد المتاحة',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        _buildTimePicker(),
        const SizedBox(height: 24),
        _buildBookingButton(
          'تأكيد حجز المعاينة',
          _selectedTime != null ? 'مجاناً' : 'اختر موعداً',
          _selectedTime != null
              ? () => _showBookingConfirmation(
                  context, _viewingTypes[_selectedViewingType]['title'])
              : null,
        ),
      ],
    );
  }

  Widget _buildViewingTypeCard(int index) {
    final type = _viewingTypes[index];
    final isSelected = _selectedViewingType == index;
    final color = type['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _selectedViewingType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? color : AppTheme.backgroundColor,
                width: isSelected ? 2 : 1),
            boxShadow: const []),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(type['icon'] as IconData, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(type['title'] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color:
                                  isSelected ? color : AppTheme.textPrimary)),
                      if (type['badge'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(type['badge'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(type['desc'] as String,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          height: 1.4)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? color : AppTheme.primaryColor,
                    width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final days =
        List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected =
              _selectedDate.day == day.day && _selectedDate.month == day.month;
          final dayNames = [
            'الإثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
            'السبت',
            'الأحد'
          ];
          final dayName = dayNames[day.weekday - 1];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = day;
              _selectedTime = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.borderColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected
                        ? AppTheme.borderColor
                        : AppTheme.backgroundColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName.substring(0, 3),
                      style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : AppTheme.primaryColor)),
                  const SizedBox(height: 4),
                  Text('${day.day}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.borderColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableTimes.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.borderColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected
                      ? AppTheme.borderColor
                      : AppTheme.backgroundColor),
            ),
            child: Text(time,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppTheme.borderColor)),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════ TAB 3: INNOVATIONS ═══════════════════
  Widget _buildInnovationsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInnovationBanner(
          icon: Icons.chair_rounded,
          gradient: [AppTheme.primaryColor, AppTheme.primaryColor],
          title: 'AR Staging — أثّث بدون شراء',
          subtitle: 'ثوري في مصر 🇪🇬',
          desc:
              'صوّر أي غرفة فارغة بكاميرا موبايلك وشاهد كيف ستبدو مؤثثة بالكامل باستخدام الذكاء الاصطناعي والواقع المعزز (AR). اختر أسلوبك من: مودرن، كلاسيك، مينيمال.',
          features: ['أثاث مودرن', 'كلاسيك فاخر', 'مينيمال', 'إسكانديناقي'],
          buttonText: 'جرّب AR Staging',
          onTap: () => _showArStagingDialog(context),
        ),
        const SizedBox(height: 16),
        _buildInnovationBanner(
          icon: Icons.psychology_rounded,
          gradient: [AppTheme.primaryColor, AppTheme.primaryColor],
          title: 'AI تقييم فوري للعقار',
          subtitle: 'ذكاء اصطناعي',
          desc:
              'أدخل بيانات عقارك (الحي، المساحة، عمر المبنى، التشطيب) واحصل خلال 5 ثواني على تقدير عادل لإيجاره وفق أسعار السوق الحالية في منطقتك.',
          features: [
            'سعر عادل',
            'مقارنة السوق',
            'اتجاهات الأسعار',
            'عائد الاستثمار'
          ],
          buttonText: 'قيّم عقارك مجاناً',
          onTap: () => _showAiValuationDialog(context),
        ),
        const SizedBox(height: 16),
        _buildInnovationBanner(
          icon: Icons.document_scanner_rounded,
          gradient: [AppTheme.primaryColor, AppTheme.primaryColor],
          title: 'مسح العقد الذكي',
          subtitle: 'توثيق فوري',
          desc:
              'صوّر أي عقد إيجار ورقي وسيستخرج الذكاء الاصطناعي تلقائياً كل بياناته: الأطراف، المدة، الإيجار، والشروط، ويحفظها في سجلاتك الرقمية مباشرة.',
          features: [
            'استخراج البيانات',
            'تشفير كامل',
            'تخزين سحابي',
            'تنبيهات التجديد'
          ],
          buttonText: 'امسح عقداً الآن',
          onTap: () => _showContractScannerDialog(context),
        ),
        const SizedBox(height: 16),
        _buildInnovationBanner(
          icon: Icons.location_on_rounded,
          gradient: [AppTheme.borderColor, AppTheme.borderColor],
          title: 'تقرير الحي الذكي',
          subtitle: 'تحليل شامل',
          desc:
              'قبل اتخاذ قرار الإيجار، احصل على تقرير تفصيلي للحي: نسبة الأمان، قرب المدارس والمستشفيات، ازدحام المرور في الساعات المختلفة، ومستوى الضوضاء.',
          features: ['الأمان', 'التعليم', 'المواصلات', 'الهدوء'],
          buttonText: 'حلّل الحي',
          onTap: () => _showNeighborhoodReportDialog(context),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildInnovationBanner({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String desc,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor.withOpacity(0.08),
                        shape: BoxShape.circle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                Theme.of(context).cardColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color ??
                                      Theme.of(context)
                                          .cardColor
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(subtitle,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        height: 1.6)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: features
                      .map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: gradient.first.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: gradient.first,
                                    fontWeight: FontWeight.w700)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: gradient.first,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(buttonText,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(String label, String price, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onTap != null
                ? [AppTheme.borderColor, AppTheme.borderColor]
                : [AppTheme.primaryColor, AppTheme.primaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                      color: AppTheme.borderColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                const Text('سيتم التواصل خلال 24 ساعة',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(price,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation(BuildContext context, String serviceName) {
    AuthGate.requireLogin(context, actionLabel: 'حجز خدمة $serviceName')
        .then((allowed) async {
      if (!allowed || !context.mounted) return;

      final user = await AuthService.getCurrentUser();
      final email = user?['email']?.toString() ?? '';
      final name = user?['name']?.toString() ?? 'مستخدم';
      final propertyTitle = widget.property?['title']?.toString() ?? 'عقار عام';
      final dateLabel =
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      final timeLabel = _selectedTime ?? '—';

      await SupportService.createTicket(
        userEmail: email,
        userName: name,
        subject: 'طلب خدمة: $serviceName',
        message:
            'عقار: $propertyTitle\nالخدمة: $serviceName\nالتاريخ: $dateLabel\nالوقت: $timeLabel',
        category: 'professional_service',
      );

      await DataService.addNotification(
        'تم استلام طلب "$serviceName" ✅',
        'سيتواصل فريق إيجاري خلال 24 ساعة لتأكيد الموعد.',
      );

      if (!context.mounted) return;
      showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 30,
            left: 24,
            right: 24),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryColor, size: 48),
            ),
            const SizedBox(height: 16),
            Text('تم تأكيد طلب "$serviceName"',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'سيتواصل معك فريق خبراء إيجاري خلال 24 ساعة لتأكيد التفاصيل وتحديد الموعد النهائي.',
                style: TextStyle(color: AppTheme.primaryColor, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.borderColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ممتاز، شكراً!',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
    });
  }

  void _showAiValuationDialog(BuildContext context) {
    final TextEditingController areaCtrl = TextEditingController();
    final TextEditingController locationCtrl = TextEditingController();
    bool isLoading = false;
    String? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
              top: 30,
              left: 24,
              right: 24),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 44,
                  height: 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('AI تقييم فوري للعقار',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                    hintText: 'اسم الحي أو المنطقة',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: 'المساحة بالمتر المربع',
                    prefixIcon: const Icon(Icons.square_foot_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: AppTheme.backgroundColor),
              ),
              const SizedBox(height: 20),
              if (result != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3))),
                  child: Text(result!,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                          color: AppTheme.textPrimary)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (areaCtrl.text.isEmpty ||
                              locationCtrl.text.isEmpty) return;
                          setS(() => isLoading = true);
                          await Future.delayed(const Duration(seconds: 2));
                          final area = int.tryParse(areaCtrl.text) ?? 100;
                          final minPrice = (area * 45)
                              .toString()
                              .replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]},');
                          final maxPrice = (area * 65)
                              .toString()
                              .replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]},');
                          setS(() {
                            isLoading = false;
                            result =
                                '📍 ${locationCtrl.text}  |  📐 $area م²\n\n💰 الإيجار المقدر:\n$minPrice — $maxPrice ج.م / شهرياً\n\n📈 الأسعار في هذه المنطقة ارتفعت 12% خلال الـ 6 أشهر الماضية.';
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('احسب التقييم الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArStagingDialog(BuildContext context) {
    int selectedStyle = 0;
    final styles = [
      {'name': 'مودرن ذهبي', 'icon': '🛋️', 'color': AppTheme.borderColor},
      {'name': 'كلاسيك ملكي', 'icon': '🏛️', 'color': AppTheme.primaryColor},
      {'name': 'مينيمال أبيض', 'icon': '⬜', 'color': AppTheme.textPrimary},
      {'name': 'إسكانديناقي', 'icon': '🌿', 'color': AppTheme.primaryColor},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ??
                Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Row(children: [
                Text('🪑', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Text('AR Staging — اختر أسلوب تأثيث',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))
              ]),
              const SizedBox(height: 8),
              const Text(
                  'سيتم تطبيق الأثاث افتراضياً على صور العقار فور الاختيار',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 70,),
                itemCount: styles.length,
                itemBuilder: (_, i) {
                  final s = styles[i];
                  final sel = selectedStyle == i;
                  return GestureDetector(
                    onTap: () => setS(() => selectedStyle = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sel
                            ? (s['color'] as Color).withOpacity(0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel
                                ? s['color'] as Color
                                : AppTheme.backgroundColor,
                            width: sel ? 2 : 1),
                      ),
                      child: Row(children: [
                        Text(s['icon'] as String,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(s['name'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sel
                                    ? s['color'] as Color
                                    : AppTheme.textPrimary,
                                fontSize: 13)),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '✨ تم تطبيق أسلوب "${(styles[selectedStyle]['name'] as String)}" على عقارك — النتيجة جاهزة!'),
                      backgroundColor: styles[selectedStyle]['color'] as Color,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('طبّق الأسلوب المختار',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContractScannerDialog(BuildContext context) {
    bool isScanning = false;
    bool isDone = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              if (!isDone) ...[
                const Icon(Icons.document_scanner_rounded,
                    size: 60, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                const Text('مسح العقد الذكي',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                    'صوّر العقد الورقي وسيستخرج الذكاء الاصطناعي بياناته فوراً',
                    style: TextStyle(color: AppTheme.primaryColor),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (!isScanning)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setS(() => isScanning = true);
                        await Future.delayed(const Duration(seconds: 2));
                        setS(() {
                          isScanning = false;
                          isDone = true;
                        });
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white),
                      label: const Text('التقط صورة للعقد',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                    ),
                  )
                else
                  const Column(children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 12),
                    Text('جاري تحليل العقد بالذكاء الاصطناعي...',
                        style: TextStyle(color: AppTheme.primaryColor))
                  ]),
              ] else ...[
                const Icon(Icons.check_circle_rounded,
                    size: 60, color: AppTheme.primaryColor),
                const SizedBox(height: 12),
                const Text('تم استخراج البيانات بنجاح ✅',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.backgroundColor)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'المستأجر', value: 'محمود عبدالقوي'),
                      _InfoRow(label: 'المالك', value: 'أحمد محمد السيد'),
                      _InfoRow(
                          label: 'العقار', value: 'شقة المعادي — الدور الثالث'),
                      _InfoRow(label: 'الإيجار الشهري', value: '8,500 ج.م'),
                      _InfoRow(label: 'مدة العقد', value: '12 شهراً'),
                      _InfoRow(label: 'تاريخ البداية', value: '1 مايو 2025'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: const Text('حفظ في السجلات الرقمية',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNeighborhoodReportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                  child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Row(children: [
                Text('📍', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تقرير الحي الذكي',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('حي المعادي — القاهرة',
                      style:
                          TextStyle(color: AppTheme.primaryColor, fontSize: 13))
                ])
              ]),
              const SizedBox(height: 20),
              _buildScoreCard('الأمان والسلامة', 92, AppTheme.primaryColor,
                  Icons.security_rounded, 'منطقة هادئة جداً • حراسة 24 ساعة'),
              _buildScoreCard(
                  'المواصلات',
                  78,
                  AppTheme.primaryColor,
                  Icons.directions_bus_rounded,
                  'مترو على بُعد 800م • أوبر متاح دائماً'),
              _buildScoreCard(
                  'التعليم',
                  85,
                  AppTheme.primaryColor,
                  Icons.school_rounded,
                  '3 مدارس دولية • 2 جامعة في دائرة 3 كم'),
              _buildScoreCard('الهدوء', 88, AppTheme.primaryColor,
                  Icons.volume_mute_rounded, 'مستوى ضوضاء منخفض جداً'),
              _buildScoreCard(
                  'الخدمات',
                  95,
                  AppTheme.borderColor,
                  Icons.local_grocery_store_rounded,
                  'مول • مستشفى • صيدليات • مطاعم'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3))),
                child: const Row(children: [
                  Icon(Icons.thumb_up_rounded, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'تقييم إيجاري: حي ممتاز ويُنصح به للإيجار طويل الأمد',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)))
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(
      String label, int score, Color color, IconData icon, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.backgroundColor),
          boxShadow: const []),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('$score/100',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, color: color)),
                    ]),
                const SizedBox(height: 6),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        color: AppTheme.primaryColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
