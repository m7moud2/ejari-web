import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_image.dart';

class VirtualTourScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const VirtualTourScreen({
    super.key,
    required this.property,
  });

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  int _currentRoom = 0;
  bool _isFullscreen = false;

  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'غرفة المعيشة',
      'image': 'assets/images/home1.jpg',
      'hotspots': [
        {'x': 0.3, 'y': 0.5, 'label': 'الشرفة'},
        {'x': 0.7, 'y': 0.6, 'label': 'المطبخ'},
      ],
    },
    {
      'name': 'غرفة النوم الرئيسية',
      'image': 'assets/images/home2.jpg',
      'hotspots': [
        {'x': 0.5, 'y': 0.4, 'label': 'الحمام'},
      ],
    },
    {
      'name': 'المطبخ',
      'image': 'assets/images/home3.jpg',
      'hotspots': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textPrimary,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: const Text('جولة افتراضية 360°'),
              backgroundColor: AppTheme.textPrimary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showTourInfo,
                ),
              ],
            ),
      body: Stack(
        children: [
          // 360 View (Simulated)
          GestureDetector(
            onTap: () => setState(() => _isFullscreen = !_isFullscreen),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: EjariImage.decoration(
                  path: _rooms[_currentRoom]['image'],
                ),
              ),
              child: Stack(
                children: [
                  // Hotspots
                  ...List.generate(
                    (_rooms[_currentRoom]['hotspots'] as List).length,
                    (index) {
                      final hotspot = _rooms[_currentRoom]['hotspots'][index];
                      return Positioned(
                        left: MediaQuery.of(context).size.width * hotspot['x'],
                        top: MediaQuery.of(context).size.height * hotspot['y'],
                        child: _buildHotspot(hotspot['label']),
                      );
                    },
                  ),

                  // Overlay gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.textPrimary.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls
          if (!_isFullscreen)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Room selector
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final isSelected = _currentRoom == index;
                        return GestureDetector(
                          onTap: () => setState(() => _currentRoom = index),
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    _rooms[index]['image'],
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppTheme.textPrimary.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Text(
                                    _rooms[index]['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        Icons.threesixty,
                        'وضع 360°',
                        () => setState(() {
                          _isFullscreen = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '🔄 جولة 360° — حرّك إصبعك يميناً ويساراً لاستكشاف المكان'),
                              backgroundColor: AppTheme.borderColor,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.vrpano,
                        'VR',
                        () => showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: AppTheme.textPrimary,
                            child: SizedBox(
                              width: double.infinity,
                              height: 300,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                              _rooms[_currentRoom]['image'],
                                              fit: BoxFit.cover),
                                        ),
                                        Container(
                                            width: 2,
                                            color: Theme.of(context)
                                                    .cardTheme
                                                    .color ??
                                                Theme.of(context).cardColor),
                                        Expanded(
                                          child: Image.asset(
                                              _rooms[_currentRoom]['image'],
                                              fit: BoxFit.cover),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor),
                                      child: const Text('خروج من وضع VR',
                                          style: TextStyle(
                                              color: AppTheme.textPrimary)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.share,
                        'مشاركة',
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ تم نسخ رابط الجولة الافتراضية'),
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Fullscreen toggle
          Positioned(
            top: _isFullscreen ? 40 : null,
            right: 16,
            child: IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
            ),
          ),

          // Room name overlay
          Positioned(
            top: _isFullscreen ? 40 : 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.room, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _rooms[_currentRoom]['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspot(String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الانتقال إلى: $label')),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: const [],
        ),
        child: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              Theme.of(context).cardColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTourInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('كيفية الاستخدام'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• اضغط على الشاشة للتبديل بين الوضع العادي والملء الشاشة'),
              SizedBox(height: 8),
              Text('• اختر الغرفة من الشريط السفلي'),
              SizedBox(height: 8),
              Text('• اضغط على النقاط المضيئة للانتقال بين الغرف'),
              SizedBox(height: 8),
              Text('• استخدم الأزرار للوصول لميزات إضافية'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
}
