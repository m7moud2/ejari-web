import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'ejari_image.dart';

class OffersSlider extends StatefulWidget {
  const OffersSlider({super.key});

  @override
  State<OffersSlider> createState() => _OffersSliderState();
}

class _OffersSliderState extends State<OffersSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _offers = [
    {
      'title': 'انشر عقارك على إيجاري',
      'description': 'وصل لمستأجرين يدورون على وحدات قريبة وإقامات قصيرة.',
      'image': 'assets/images/home1.jpg',
      'color': '0xFF47736E',
    },
    {
      'title': 'عمولة عند الإتمام فقط',
      'description': '0 ج.م مقدماً — تدفع عند إتمام الإيجار.',
      'image': 'assets/images/home7.jpg',
      'color': '0xFF334441',
    },
    {
      'title': 'تقييم عقاري',
      'description': 'اطلب تسعيراً مقارناً بالمنطقة من داخل التطبيق.',
      'image': 'assets/images/home5.jpg',
      'color': '0xFF47736E',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _offers.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
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
      children: [
        SizedBox(
          height: 236,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(_offers[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _offers.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(Map<String, String> offer) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(offer['title']!),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EjariImage(
                  path: offer['image']!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
                Text(offer['description']!),
                const SizedBox(height: 16),
                const Text('استخدم هذا العرض الآن واستمتع بالخصم!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('استخدام العرض')),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: EjariImage.provider(offer['image']!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(int.parse(offer['color']!)).withOpacity(0.8),
              BlendMode.srcOver,
            ),
          ),
          boxShadow: const [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).cardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'عرض خاص 🔥',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                offer['title']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                offer['description']!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
