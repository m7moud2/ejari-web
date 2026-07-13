import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import 'booking_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import '../widgets/viewing_widgets.dart';
import 'my_viewings_screen.dart';
import 'chat_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_chat_service.dart';
import '../services/chat_service.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/ejari_image.dart';
import '../widgets/ejari_section.dart';
import '../models/accommodation_type.dart';
import '../models/listing_type.dart';
import '../widgets/occupancy_calendar_widget.dart';
import '../widgets/rental_booking_widgets.dart';
import '../widgets/sale_listing_widgets.dart';
import 'map_search_screen.dart';
import 'virtual_tour_screen.dart';
import 'comparison_screen.dart';
import '../services/compare_list_service.dart';
import '../utils/first_run_tooltips.dart';
import '../utils/haptic_utils.dart';
import '../utils/short_stay_discovery.dart';
import '../utils/rental_pricing.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  double _averageRating = 4.8;
  int _reviewsCount = 24;
  bool _isFavorite = false;
  bool _inCompare = false;
  List<Map<String, dynamic>> _marketTrends = [];
  Map<String, dynamic> _occupancyCalendar = {};
  String? _selectedBedId;

  bool _isNetworkImage(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadReviewStats();
  }

  Future<void> _loadReviewStats() async {
    try {
      final id = widget.property['id']?.toString() ?? '1';
      final stats = await DataService.getReviewStats(id);
      final favoriteStatus =
          await DataService.isFavorite(widget.property['title'] ?? '');
      final compareIds = await CompareListService.getIds();
      final propId = widget.property['id']?.toString() ?? '';
      final trends =
          await DataService.getMarketTrends(widget.property['location'] ?? '');
      Map<String, dynamic> calendar = {};
      if (DataService.isSharedAccommodation(widget.property)) {
        calendar = await DataService.getOccupancyCalendar(
          id,
        );
      }

      setState(() {
        _averageRating = stats['average'] as double? ?? 0.0;
        _reviewsCount = stats['count'] as int? ?? 0;
        _isFavorite = favoriteStatus;
        _inCompare = compareIds.contains(propId);
        _marketTrends = trends;
        _occupancyCalendar = calendar;
      });
    } catch (_) {}
  }

  void _shareProperty() {
    final title = widget.property['title'];
    final price = widget.property['price'];
    final location = widget.property['location'];
    final link = "https://ejari.app/property/${widget.property['id']}";

    final text = "🔥 فرصة عقارية فاخرة من إيجاري!\n\n"
        "🏠 $title\n"
        "💰 السعر: $price ج.م\n"
        "📍 الموقع: $location\n\n"
        "شاهد التفاصيل هنا:\n$link";

    Share.share(text);
  }

  void _openWhatsApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = widget.property['phone'] ?? '+201280083336';
    final message =
        "مرحباً، أستفسر عن عقار: ${widget.property['title']} المعروض على تطبيق إيجاري.";
    final url =
        "https://wa.me/${phone.replaceAll(' ', '').replaceAll('+', '')}?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        messenger
            .showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب ❌')));
      }
    }
  }

  Future<void> _toggleCompare() async {
    final id = widget.property['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final result = await CompareListService.toggle(id);
    HapticUtils.selection();
    if (result['full'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يمكن مقارنة عقارين فقط — أزل أحدهما أولاً'),
        ),
      );
      return;
    }
    setState(() => _inCompare = result['added'] == true);
    if (result['count'] == 2 && mounted) {
      final props = await CompareListService.getProperties();
      if (!mounted || props.length < 2) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComparisonScreen(
            items: props,
            type: 'property',
          ),
        ),
      );
    }
  }

  void _openVirtualTour() {
    HapticUtils.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualTourScreen(property: widget.property),
      ),
    );
  }

  List<String> get _amenities {
    final raw = widget.property['amenities'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [
      'مسبح',
      'جيم',
      'موقف سيارات',
      'أمن 24/7',
      'إنترنت فايبر',
    ];
  }

  static const List<Map<String, String>> _nearbyAmenities = [
    {'name': 'مول سيتي ستارز', 'distance': '800 م'},
    {'name': 'مترو أنفاق', 'distance': '1.2 كم'},
    {'name': 'مستشفى', 'distance': '600 م'},
    {'name': 'مدرسة دولية', 'distance': '1.5 كم'},
  ];

  Future<void> _toggleFavorite() async {
    await DataService.toggleFavorite(widget.property);
    final status = await DataService.isFavorite(widget.property['title'] ?? '');
    setState(() => _isFavorite = status);
  }

  Future<void> _startInternalChat() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final currentUser = await AuthService.getCurrentUser();
    if (!mounted) return;
    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً للمراسلة')),
      );
      return;
    }

    final currentUserId = (currentUser['uid'] ??
            currentUser['id'] ??
            currentUser['_id'])
        ?.toString()
        .trim();
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('Cannot start chat: missing current user identifier');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر بدء المحادثة، يرجى تسجيل الدخول مرة أخرى'),
        ),
      );
      return;
    }

    final ownerId = widget.property['ownerId']?.toString() ?? 'admin';
    const ownerName = 'مالك العقار'; // Or fetch actual owner name

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    if (!mounted) return;
    final String chatId;
    if (AppConfig.demoMode) {
      chatId = await ChatService.startChat(
        currentUserId,
        ownerId,
        ownerName,
        widget.property['title'] ?? '',
        user1Name: currentUser['name']?.toString(),
      );
    } else {
      chatId = await FirestoreChatService.startChat(
        currentUserId,
        ownerId,
        ownerName,
        widget.property['title'] ?? '',
      );
    }

    // Hide loading
    if (!mounted) return;
    navigator.pop();

    if (chatId.isNotEmpty && mounted) {
      navigator.push(MaterialPageRoute(
          builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: ownerName,
              currentUserId: currentUserId)));
    } else {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء بدء المحادثة')),
        );
      }
    }
  }

  void _showPhoneCallDialog() {
    const phone = '01280083336';
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اتصال بالملاك'),
        content: const Text('هل تريد الاتصال بالرقم 01280083336؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              navigator.pop();
              final url = Uri.parse('tel:$phone');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final imageUrl = property['image']?.toString() ?? '';
    final title = property['title']?.toString() ?? 'عقار مميز';
    final location =
        property['location']?.toString() ?? 'موقع مميز داخل إيجاري';
    final price = property['price']?.toString() ?? '0';
    final isDemo = property['isDemo'] == true;
    final isSale = isSaleListing(property);
    final listingLabel =
        isSale ? ListingType.sale.saleAdBadge : listingTypeFromProperty(property).arabicLabel;
    final propertyStatus = (property['status']?.toString().trim().isNotEmpty ?? false)
        ? property['status'].toString()
        : (isDemo ? 'متاح الآن' : 'متاح الآن');
    final ownerName = property['ownerName']?.toString().trim().isNotEmpty == true
        ? property['ownerName'].toString()
        : 'أحمد محمد';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppTheme.textPrimary, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _inCompare ? Icons.compare : Icons.compare_arrows,
                      color: _inCompare
                          ? AppTheme.accentColor
                          : AppTheme.textPrimary,
                    ),
                    tooltip: 'أضف للمقارنة',
                    onPressed: _toggleCompare,
                  ),
                  IconButton(
                    icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: AppTheme.textPrimary),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: AppTheme.textPrimary),
                    onPressed: _shareProperty,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeroImage(imageUrl),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.textPrimary.withOpacity(0.08),
                              AppTheme.textPrimary.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.backgroundColor.withOpacity(0.95),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildHeroTag(
                                    propertyStatus,
                                    AppTheme.primaryColor,
                                  ),
                                  _buildHeroTag(
                                    '${property['beds'] ?? 0} غرف',
                                    AppTheme.primaryColor,
                                  ),
                                  _buildHeroTag(
                                    '${property['area'] ?? 0} م²',
                                    AppTheme.accentColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    AppTheme.spaceSm,
                    AppTheme.screenPadding,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildListingModeBanner(isSale, listingLabel, price),
                      const SizedBox(height: AppTheme.spaceSm),
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'نظرة سريعة',
                              subtitle: 'أهم الأرقام والتقييمات',
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            const PropertyTrustBadges(),
                            const SizedBox(height: AppTheme.spaceMd),
                            Wrap(
                              spacing: AppTheme.spaceXs,
                              runSpacing: AppTheme.spaceXs,
                              children: [
                                SizedBox(
                                  width: 152,
                                  child: EjariStatTile(
                                    icon: Icons.star_rounded,
                                    label: 'التقييم',
                                    value: '$_averageRating ($_reviewsCount)',
                                    accentColor: AppTheme.accentColor,
                                  ),
                                ),
                                SizedBox(
                                  width: 152,
                                  child: EjariStatTile(
                                    icon: Icons.bed_outlined,
                                    label: 'الغرف',
                                    value: '${property['beds'] ?? 0}',
                                  ),
                                ),
                                SizedBox(
                                  width: 152,
                                  child: EjariStatTile(
                                    icon: Icons.bathtub_outlined,
                                    label: 'الحمامات',
                                    value: '${property['baths'] ?? 0}',
                                  ),
                                ),
                                SizedBox(
                                  width: 152,
                                  child: EjariStatTile(
                                    icon: Icons.square_foot,
                                    label: 'المساحة',
                                    value: '${property['area'] ?? 0} م²',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      if (isSale) ...[
                        const SaleListingDisclaimerBanner(),
                        const SizedBox(height: AppTheme.spaceMd),
                      ],
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'التفاصيل والسعر',
                              subtitle: 'الوصف والموقع على الخريطة',
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isSale ? AppTheme.borderColor : AppTheme.primaryColor).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(listingLabel,
                                      style: TextStyle(
                                        color: isSale ? AppTheme.borderColor : AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            Text(
                              isSale ? '$price ج.م' : '$price ج.م / شهر',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (isSale) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'سعر العرض — التفاوض والدفع مباشرة مع المالك',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              Builder(builder: (context) {
                                final accType =
                                    accommodationTypeFromProperty(property);
                                final monthly = DataService.resolveApplicablePrice(
                                  property,
                                  durationType: 'شهر',
                                );
                                final daily = DataService.resolveApplicablePrice(
                                  property,
                                  durationType: 'يوم',
                                );
                                final weekly = DataService.resolveApplicablePrice(
                                  property,
                                  durationType: 'أسبوع',
                                );
                                final dp = property['dynamicPricing']
                                    as Map<String, dynamic>?;
                                if (monthly <= 0) {
                                  return const Text(
                                    'الأسعار اليومية/الأسبوعية تظهر عند الحجز',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (accType != AccommodationType.fullUnit)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          accType.arabicLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      'يومي: ${daily.toStringAsFixed(0)} ج.م/يوم',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'أسبوعي: ${weekly.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'شهري: ${monthly.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                    if (dp?['seasonalRate'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dp!['seasonalLabel'] ?? 'سعر موسمي'}: ${(dp['seasonalRate'] as num).toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                    if (property['depositAmount'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'عربون (إسكرو): ${property['depositAmount']} ج.م',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                            ],
                            if (DataService.isSharedAccommodation(property)) ...[
                              const SizedBox(height: AppTheme.spaceMd),
                              const EjariSectionHeader(
                                title: 'اختر السرير',
                                subtitle: 'الأسرّة الفاضية متاحة للحجز',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List<Map<String, dynamic>>.from(
                                  property['bedUnits'] as List? ?? [],
                                ).map((bed) {
                                  final vacant = bed['status'] == 'vacant';
                                  final selected =
                                      _selectedBedId == bed['id']?.toString();
                                  return ChoiceChip(
                                    label: Text(bed['label']?.toString() ?? ''),
                                    selected: selected,
                                    onSelected: vacant
                                        ? (_) => setState(() =>
                                            _selectedBedId =
                                                bed['id']?.toString())
                                        : null,
                                    avatar: Icon(
                                      vacant ? Icons.bed_outlined : Icons.bed,
                                      size: 16,
                                      color: vacant
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (_occupancyCalendar.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spaceMd),
                                const EjariSectionHeader(
                                  title: 'تقويم الإشغال',
                                  subtitle: 'تحقق من التوفر قبل الحجز',
                                ),
                                const SizedBox(height: 8),
                                OccupancyCalendarWidget(
                                  year: DateTime.now().year,
                                  month: DateTime.now().month,
                                  occupiedByDate: Map<String, List<String>>.from(
                                    (_occupancyCalendar['occupiedByDate']
                                            as Map?)
                                        ?.map(
                                      (k, v) => MapEntry(
                                        k.toString(),
                                        List<String>.from(v as List),
                                      ),
                                    ) ??
                                        {},
                                  ),
                                  vacantBedLabels: List<String>.from(
                                    _occupancyCalendar['vacantBedLabels']
                                            as List? ??
                                        [],
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: AppTheme.spaceXs),
                            const Text(
                              'شقة فاخرة بتشطيب رائع وموقع متميز في قلب إيجاري، قريبة من الخدمات والمدارس ومحاور الحركة الرئيسية.',
                              style: TextStyle(
                                height: 1.7,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            const FirstRunTooltipBanner(
                              screenKey: 'property_details',
                              message:
                                  'جرّب الجولة الافتراضية والمقارنة بين عقارين من هنا.',
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _openVirtualTour,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.cardRadius - 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceMd,
                                        vertical: AppTheme.spaceSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.cardRadius - 4),
                                        border: Border.all(
                                          color: AppTheme.accentColor
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.threed_rotation,
                                              color: AppTheme.accentColor,
                                              size: 18),
                                          SizedBox(width: AppTheme.spaceXs),
                                          Text(
                                            'جولة افتراضية 360°',
                                            style: TextStyle(
                                              color: AppTheme.accentColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MapSearchScreen(),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.cardRadius - 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceMd,
                                        vertical: AppTheme.spaceSm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.cardRadius - 4),
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.15),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.map_outlined,
                                              color: AppTheme.primaryColor,
                                              size: 18),
                                          SizedBox(width: AppTheme.spaceXs),
                                          Text(
                                            'الموقع على الخريطة',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            const EjariSectionHeader(
                              title: 'المرافق',
                              subtitle: 'ما يوفره العقار',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _amenities
                                  .map((a) => Chip(
                                        label: Text(a),
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.08),
                                      ))
                                  .toList(),
                            ),
                            if (_hasVacationHighlights(property)) ...[
                              const SizedBox(height: AppTheme.spaceMd),
                              const EjariSectionHeader(
                                title: 'مميزات الإقامة القصيرة',
                                subtitle: 'البحر · السيارة · العائلة · العروض',
                              ),
                              const SizedBox(height: 8),
                              _buildVacationHighlights(property),
                            ],
                            if (ShortStayDiscovery.specialOffers(property)
                                .isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spaceMd),
                              const EjariSectionHeader(
                                title: 'عروض المدة',
                                subtitle: 'اضغط العرض لاختيار المدة عند الحجز',
                              ),
                              const SizedBox(height: 8),
                              ...ShortStayDiscovery.specialOffers(property)
                                  .map((offer) => _buildOfferTile(offer)),
                            ],
                            if (!isSale) ...[
                              const SizedBox(height: AppTheme.spaceMd),
                              const EjariSectionHeader(
                                title: 'باقات ١ · ٣ · ٧ أيام',
                                subtitle: 'تسعير متدرج واضح قبل الحجز',
                              ),
                              const SizedBox(height: 8),
                              _buildTierPackageRow(property),
                            ],
                            const SizedBox(height: AppTheme.spaceMd),
                            const EjariSectionHeader(
                              title: 'قريب منك',
                              subtitle: 'خدمات ومرافق بالجوار',
                            ),
                            const SizedBox(height: 8),
                            ..._nearbyAmenities.map(
                              (n) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.place_outlined,
                                    color: AppTheme.primaryColor, size: 18),
                                title: Text(n['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                trailing: Text(n['distance']!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'الموقع السوقي',
                              subtitle: 'مقارنة الأسعار في المنطقة',
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _marketTrends.isEmpty
                                          ? const [
                                              FlSpot(0, 3),
                                              FlSpot(1, 4),
                                              FlSpot(2, 3.5),
                                              FlSpot(3, 5)
                                            ]
                                          : List.generate(_marketTrends.length,
                                              (index) {
                                              final double val =
                                                  double.tryParse(
                                                          _marketTrends[index]
                                                                  ['value']
                                                              .toString()) ??
                                                      0.0;
                                              return FlSpot(index.toDouble(),
                                                  val / 5000.0);
                                            }),
                                      isCurved: true,
                                      color: AppTheme.primaryColor,
                                      barWidth: 4,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            Wrap(
                              spacing: AppTheme.spaceXs,
                              runSpacing: AppTheme.spaceXs,
                              children: [
                                _buildLegend(
                                    AppTheme.primaryColor, 'متوسط السوق'),
                                _buildLegend(AppTheme.borderColor, 'فرصة قوية'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'توفر الوحدة',
                              subtitle: 'جدول المواعيد خلال 14 يوماً',
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            _buildAvailabilityCalendar(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      EjariSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EjariSectionHeader(
                              title: 'المالك والتواصل',
                              subtitle: 'تواصل مباشر مع مالك معتمد',
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Wrap(
                              spacing: AppTheme.spaceXs,
                              runSpacing: AppTheme.spaceXs,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.accentColor,
                                      child: Icon(Icons.person,
                                          color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(width: AppTheme.spaceSm),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ownerName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('مالك معتمد في إيجاري',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.phone,
                                            color: AppTheme.primaryColor),
                                        onPressed: _showPhoneCallDialog),
                                    IconButton(
                                        icon: const Icon(Icons.message,
                                            color: AppTheme.primaryColor),
                                        onPressed: _openWhatsApp),
                                    IconButton(
                                        icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            color: AppTheme.primaryColor),
                                        onPressed: _startInternalChat),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: AppTheme.screenPadding,
            left: AppTheme.screenPadding,
            right: AppTheme.screenPadding,
            child: isSale
                ? Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppTheme.ctaHeight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius - 2),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat_rounded, color: Colors.white),
                            label: const Text(
                              'تواصل مع المالك',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: AppTheme.ctaHeight,
                        width: 56,
                        child: OutlinedButton(
                          onPressed: _showPhoneCallDialog,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.cardRadius - 2),
                            ),
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppTheme.ctaHeight,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.primaryColor, width: 1.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius - 2),
                              ),
                            ),
                            onPressed: () async {
                              final allowed = await AuthGate.requireLogin(
                                context,
                                actionLabel: 'طلب معاينة',
                              );
                              if (!allowed || !context.mounted) return;
                              final ok = await RequestViewingSheet.show(
                                context,
                                property: property,
                              );
                              if (ok == true && context.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'يمكنك متابعة المعاينة من «مواعيدي»'),
                                    action: SnackBarAction(
                                      label: 'فتح',
                                      onPressed: () {
                                        navigator.push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const MyViewingsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.visibility_rounded,
                                color: AppTheme.primaryColor),
                            label: const Text(
                              'معاينة',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppTheme.ctaHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius - 2),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final allowed = await AuthGate.requireLogin(
                                context,
                                actionLabel: 'حجز الوحدة',
                              );
                              if (!allowed || !context.mounted) return;
                              if (DataService.isSharedAccommodation(property) &&
                                  _selectedBedId == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('يرجى اختيار سرير متاح أولاً'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                                return;
                              }
                              final bookingData = {
                                ...property,
                                if (_selectedBedId != null)
                                  'selectedBedId': _selectedBedId,
                                if (_selectedBedId != null)
                                  'bedLabel': (List<Map<String, dynamic>>.from(
                                    property['bedUnits'] as List? ?? [],
                                  ).firstWhere(
                                    (b) =>
                                        b['id']?.toString() == _selectedBedId,
                                    orElse: () => {'label': 'سرير'},
                                  ))['label'],
                              };
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(
                                    itemType: 'property',
                                    itemData: bookingData,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'احجز الآن',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasVacationHighlights(Map<String, dynamic> property) {
    return ShortStayDiscovery.nearbyBeachMinutes(property) != null ||
        ShortStayDiscovery.flagTrue(property, 'carAvailable') ||
        ShortStayDiscovery.flagTrue(property, 'familyFriendly') ||
        ShortStayDiscovery.flagTrue(property, 'independentHouse') ||
        ShortStayDiscovery.offerBadges(property).isNotEmpty;
  }

  Widget _buildVacationHighlights(Map<String, dynamic> property) {
    final chips = <Widget>[];
    final beach = ShortStayDiscovery.nearbyBeachMinutes(property);
    if (beach != null) {
      chips.add(_highlightChip(Icons.beach_access_rounded, 'البحر خلال $beach د'));
    }
    if (ShortStayDiscovery.flagTrue(property, 'carAvailable')) {
      chips.add(_highlightChip(Icons.directions_car_rounded, 'سيارة متاحة'));
    }
    if (ShortStayDiscovery.flagTrue(property, 'familyFriendly')) {
      chips.add(_highlightChip(Icons.family_restroom_rounded, 'مناسب للعائلات'));
    }
    if (ShortStayDiscovery.flagTrue(property, 'independentHouse')) {
      chips.add(_highlightChip(Icons.holiday_village_rounded, 'بيت مستقل'));
    }
    for (final badge in ShortStayDiscovery.offerBadges(property)) {
      chips.add(_highlightChip(Icons.local_offer_rounded, badge));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _highlightChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
    );
  }

  Widget _buildOfferTile(Map<String, dynamic> offer) {
    final title = offer['title']?.toString() ?? offer['label']?.toString() ?? 'عرض';
    final days = offer['days']?.toString() ?? '—';
    final perDay = offer['pricePerDay']?.toString() ?? '—';
    final label = offer['label']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bookWithOffer(offer),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label.isNotEmpty ? label : '$days أيام',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '$days أيام · $perDay ج.م / يوم',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierPackageRow(Map<String, dynamic> property) {
    final monthly = DataService.resolveApplicablePrice(
      property,
      durationType: 'شهر',
    );
    if (monthly <= 0) {
      final daily = ShortStayDiscovery.dailyRate(property);
      if (daily <= 0) {
        return const Text(
          'تظهر الباقات عند توفر السعر',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _packageChip('١ يوم', '${daily.round()} ج.م'),
          _packageChip('٣ أيام', '${(daily * 3).round()} ج.م'),
          _packageChip(
            '٧ أيام',
            property['packageHalfWeek'] != null
                ? '${property['packageHalfWeek']} ج.م'
                : '${(daily * 7 * 0.85).round()} ج.م',
          ),
        ],
      );
    }
    final one = RentalPricing.calculate(
      monthlyRent: monthly,
      durationType: 'يوم',
      durationCount: 1,
    );
    final three = RentalPricing.calculate(
      monthlyRent: monthly,
      durationType: 'يوم',
      durationCount: 3,
    );
    final seven = RentalPricing.calculate(
      monthlyRent: monthly,
      durationType: 'يوم',
      durationCount: 7,
    );
    final halfWeek = property['packageHalfWeek'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _packageChip('١ يوم', '${one.totalRent.round()} ج.م'),
        _packageChip('٣ أيام', '${three.totalRent.round()} ج.م'),
        _packageChip(
          '٧ أيام',
          halfWeek != null
              ? '$halfWeek ج.م'
              : '${seven.totalRent.round()} ج.م',
        ),
      ],
    );
  }

  Widget _packageChip(String label, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(price,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Future<void> _bookWithOffer(Map<String, dynamic> offer) async {
    final prefill = ShortStayDiscovery.bookingPrefillFromOffer(offer);
    final bookingData = {
      ...widget.property,
      if (prefill != null) ...prefill,
      'selectedOffer': offer,
      if (_selectedBedId != null) 'selectedBedId': _selectedBedId,
    };
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          itemType: 'property',
          itemData: bookingData,
        ),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl) {
    final path = imageUrl.trim();
    if (path.isEmpty) {
      return const EjariImage(
        path: 'assets/images/home1.jpg',
        fit: BoxFit.cover,
      );
    }

    if (_isNetworkImage(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.backgroundColor,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
        errorWidget: (context, url, error) => const EjariImage(
          path: 'assets/images/home1.jpg',
          fit: BoxFit.cover,
        ),
      );
    }

    return EjariImage(
      path: path.startsWith('assets/') ? path : 'assets/images/home1.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildListingModeBanner(
    bool isSale,
    String listingLabel,
    String price,
  ) {
    final bg = isSale ? const Color(0xFFB58D3D) : AppTheme.primaryColor;
    final priceLabel =
        isSale ? '$price ج.م — للبيع' : '$price ج.م / شهر — للإيجار';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isSale ? Icons.sell_rounded : Icons.key_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listingLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  priceLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildAvailabilityCalendar() {
    final bookedStrs = List<String>.from(widget.property['bookedDates'] ?? []);
    final bookedDates = bookedStrs
        .map((s) => DateParsing.parse(s))
        .whereType<DateTime>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('جدول المواعيد القادم (14 يوم):',
            style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isBooked = bookedDates.any((d) =>
                  d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day);

              return Container(
                width: 60,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: isBooked
                      ? AppTheme.errorColor.withOpacity(0.08)
                      : AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isBooked
                          ? AppTheme.errorColor.withOpacity(0.24)
                          : AppTheme.primaryColor.withOpacity(0.24)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(date.day.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isBooked
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor)),
                    Text(_getMonthName(date.month),
                        style: TextStyle(
                            fontSize: 10,
                            color: isBooked
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor)),
                    const SizedBox(height: 4),
                    Icon(isBooked ? Icons.close : Icons.check,
                        size: 12,
                        color: isBooked
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLegend(AppTheme.primaryColor, 'متاح'),
            const SizedBox(width: 16),
            _buildLegend(AppTheme.errorColor, 'محجوز'),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
      ],
    );
  }
}
