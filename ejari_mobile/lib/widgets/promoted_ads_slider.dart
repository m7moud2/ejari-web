import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class PromotedAdsSlider extends StatefulWidget {
  const PromotedAdsSlider({super.key});

  @override
  State<PromotedAdsSlider> createState() => _PromotedAdsSliderState();
}

class _PromotedAdsSliderState extends State<PromotedAdsSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _promotedAds = [
    {
      'title': 'إسكان طلاب - منطقة الجامعة',
      'description':
          'استوديوهات مفروشة بالكامل بجوار كليات الطب والعلوم. أمن وحرية تامة.',
      'image': 'assets/images/home1.jpg',
      'badge': 'الأكثر طلباً 🎓',
    },
    {
      'title': 'قصور الفلل - إطلالة النيل',
      'description':
          'عيش الرفاهية في أرقى أحياء إيجاري. فيلات وقصور بمساحات خضراء واسعة.',
      'image': 'assets/images/home2.jpg',
      'badge': 'نخبة إيجاري 🌟',
    },
    {
      'title': 'مقرات فندقية - إيجاري الجديدة',
      'description':
          'مساحات تجارية وإدارية في أرقى شارع بإيجاري الجديدة وجهات زجاجية مودرن.',
      'image': 'assets/images/home4.jpg',
      'badge': 'فرصة أعمال 💼',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _promotedAds.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Text(
                'عقارات إيجاري الممولة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('حصري',
                    style: TextStyle(
                        color: AppTheme.borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _promotedAds.length,
            itemBuilder: (context, index) {
              return _buildAdCard(_promotedAds[index], index);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promotedAds.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              width: _currentPage == index ? 24 : 12,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 220,
            width: double.infinity,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                ad['image'],
                fit: BoxFit.cover,
              ),

              // Dark Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.textPrimary.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge Container
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppTheme.borderColor, width: 1),
                        ),
                        child: Text(
                          ad['badge'],
                          style: const TextStyle(
                            color: AppTheme.borderColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Ad Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ad['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}
