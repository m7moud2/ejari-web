import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import 'booking_screen.dart';
import '../utils/auth_gate.dart';
import '../utils/date_utils.dart';
import 'chat_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_chat_service.dart';
import '../services/auth_service.dart';
import 'map_search_screen.dart';

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
  List<Map<String, dynamic>> _marketTrends = [];

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
      final trends =
          await DataService.getMarketTrends(widget.property['location'] ?? '');

      setState(() {
        _averageRating = stats['average'] as double? ?? 0.0;
        _reviewsCount = stats['count'] as int? ?? 0;
        _isFavorite = favoriteStatus;
        _marketTrends = trends;
      });
    } catch (_) {}
  }

  void _shareProperty() {
    final title = widget.property['title'];
    final price = widget.property['price'];
    final location = widget.property['location'];
    final link = "https://keyo.app/property/${widget.property['id']}";

    final text = "🔥 فرصة عقارية فاخرة من كيو!\n\n"
        "🏠 $title\n"
        "💰 السعر: $price ج.م\n"
        "📍 الموقع: $location\n\n"
        "شاهد التفاصيل هنا:\n$link";

    Share.share(text);
  }

  void _openWhatsApp() async {
    final phone = widget.property['phone'] ?? '+201280083336';
    final message =
        "مرحباً، أستفسر عن عقار: ${widget.property['title']} المعروض على تطبيق كيو.";
    final url =
        "https://wa.me/${phone.replaceAll(' ', '').replaceAll('+', '')}?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب ❌')));
      }
    }
  }

  Future<void> _toggleFavorite() async {
    await DataService.toggleFavorite(widget.property);
    final status = await DataService.isFavorite(widget.property['title'] ?? '');
    setState(() => _isFavorite = status);
  }

  Future<void> _startInternalChat() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً للمراسلة')),
      );
      return;
    }

    final ownerId = widget.property['ownerId']?.toString() ?? 'admin';
    final ownerName = 'مالك العقار'; // Or fetch actual owner name

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    final chatId = await FirestoreChatService.startChat(
      currentUser['uid'],
      ownerId,
      ownerName,
      widget.property['title'] ?? '',
    );

    // Hide loading
    Navigator.pop(context);

    if (chatId.isNotEmpty && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatScreen(
                  chatId: chatId,
                  otherUserName: ownerName,
                  currentUserId: currentUser['uid'])));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء بدء المحادثة')),
        );
      }
    }
  }

  void _showPhoneCallDialog() {
    const phone = '01280083336';
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
              Navigator.pop(context);
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

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareProperty,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: property['image'].startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: property['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.backgroundColor,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor)),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/home1.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(property['image'], fit: BoxFit.cover),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(property['title'],
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          if (property['isDemo'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: AppTheme.borderColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppTheme.borderColor)),
                              child: const Text('متاح للتجربة والتقييم',
                                  style: TextStyle(
                                      color: AppTheme.borderColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppTheme.primaryColor)),
                              child: const Text('متاح فعلياً',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.borderColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '$_averageRating ($_reviewsCount تقييم)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(property['location'],
                          style: const TextStyle(color: AppTheme.primaryColor)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MapSearchScreen())),
                        child: const Row(
                          children: [
                            Icon(Icons.map_outlined,
                                color: AppTheme.primaryColor, size: 16),
                            SizedBox(width: 4),
                            Text('عرض الموقع على الخريطة',
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSpecItem(Icons.bed, '${property['beds']} غرف'),
                          _buildSpecItem(
                              Icons.bathtub, '${property['baths']} حمام'),
                          _buildSpecItem(
                              Icons.square_foot, '${property['area']} م²'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('الوصف',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'شقة فاخرة بتشطيب رائع وموقع متميز في قلب كيو، قريبة من كافة الخدمات والجامعة.',
                          style: TextStyle(
                              color: AppTheme.primaryColor, height: 1.5)),
                      const SizedBox(height: 32),
                      const Text('الموقع السوقي',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
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
                                        final double val = double.tryParse(
                                                _marketTrends[index]['value']
                                                    .toString()) ??
                                            0.0;
                                        return FlSpot(
                                            index.toDouble(), val / 5000.0);
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
                      const SizedBox(height: 32),
                      const Text('توفر الوحدة',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildAvailabilityCalendar(),
                      const SizedBox(height: 32),
                      // Owner Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('أحمد محمد',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('مالك معتمد في كيو',
                                      style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.phone,
                                    color: AppTheme.primaryColor),
                                onPressed: _showPhoneCallDialog),
                            IconButton(
                                icon: const Icon(Icons.message,
                                    color: AppTheme.primaryColor),
                                onPressed: _openWhatsApp),
                            IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: _startInternalChat),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                AuthGate.requireLogin(context, actionLabel: 'حجز الوحدة')
                    .then((allowed) {
                  if (!allowed || !mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BookingScreen(
                            itemType: 'property', itemData: property)),
                  );
                });
              },
              child: const Text('احجز الآن',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
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
          height: 80,
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
                      ? AppTheme.errorColor.withOpacity(0.05)
                      : AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isBooked
                          ? AppTheme.errorColor.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.3)),
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

  Widget _buildSpecItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
