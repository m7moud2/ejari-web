import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import 'property_details_screen.dart';
import 'booking_screen.dart';

class AIRecommendationsScreen extends StatefulWidget {
  const AIRecommendationsScreen({super.key});

  @override
  State<AIRecommendationsScreen> createState() =>
      _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen> {
  bool _isAnalyzing = true;

  // Demo data based on user preferences
  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'شقة فاخرة في التجمع الخامس',
      'price': '8000',
      'location': 'التجمع الخامس، القاهرة',
      'image': 'assets/images/home1.jpg',
      'beds': '3 غرف',
      'baths': '2 حمام',
      'area': '180 م²',
      'matchScore': 95,
      'reasons': ['يطابق ميزانيتك', 'في منطقتك المفضلة', 'مساحة مناسبة'],
    },
    {
      'title': 'فيلا مودرن في الشيخ زايد',
      'price': '12000',
      'location': 'الشيخ زايد، القاهرة',
      'image': 'assets/images/home2.jpg',
      'beds': '4 غرف',
      'baths': '3 حمام',
      'area': '250 م²',
      'matchScore': 88,
      'reasons': ['تصميم عصري', 'حديقة خاصة', 'قريب من الخدمات'],
    },
    {
      'title': 'شقة عائلية في مدينة نصر',
      'price': '6500',
      'location': 'مدينة نصر، القاهرة',
      'image': 'assets/images/home3.jpg',
      'beds': '3 غرف',
      'baths': '2 حمام',
      'area': '160 م²',
      'matchScore': 82,
      'reasons': ['سعر مناسب', 'منطقة هادئة', 'قريب من المدارس'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _simulateAnalysis();
  }

  Future<void> _simulateAnalysis() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقترحات لك'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showPreferencesDialog();
            },
          ),
        ],
      ),
      body: _isAnalyzing
          ? _buildAnalyzingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommendations header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ??
                                Theme.of(context).cardColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مقترحات حسب اهتماماتك',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'بناءً على تفضيلاتك وسلوك التصفح',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      _buildStatCard('تم التحليل', '${_recommendations.length}',
                          Icons.analytics),
                      const SizedBox(width: 12),
                      _buildStatCard(
                          'دقة التطابق',
                          '${_recommendations[0]['matchScore']}%',
                          Icons.verified),
                      const SizedBox(width: 12),
                      _buildStatCard('توفير الوقت', '80%', Icons.timer),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'أفضل التوصيات لك',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations List
                  ...List.generate(
                    _recommendations.length,
                    (index) => _buildRecommendationCard(
                        _recommendations[index], index),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'جاري تجهيز المقترحات...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'نراجع تفضيلاتك لإيجاد خيارات مناسبة',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.backgroundColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> property,
      [int index = 0]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Score Badge
          Stack(
            children: [
              PropertyCard(
                id: property['id'] ?? 'recommended_$index',
                title: property['title'],
                price: property['price'],
                location: property['location'],
                image: property['image'],
                beds: property['beds'],
                baths: property['baths'],
                area: property['area'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PropertyDetailsScreen(property: property),
                    ),
                  );
                },
                onBook: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        itemType: 'property',
                        itemData: property,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${property['matchScore']}% تطابق',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Reasons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb,
                        color: AppTheme.borderColor, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'لماذا نوصي بهذا العقار؟',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  (property['reasons'] as List).length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          property['reasons'][index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث التفضيلات'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('قريباً: ستتمكن من تحديث تفضيلاتك لتحسين التوصيات'),
              SizedBox(height: 16),
              Text('• الميزانية المفضلة'),
              Text('• المناطق المفضلة'),
              Text('• نوع العقار'),
              Text('• المساحة المطلوبة'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
