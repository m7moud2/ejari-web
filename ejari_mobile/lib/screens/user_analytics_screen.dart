import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAnalyticsScreen extends StatelessWidget {
  const UserAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائياتي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [],
              ),
              child: Column(
                children: [
                  const Text(
                    'نشاطك هذا الشهر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('15', 'عقار شاهدته', Icons.visibility),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildSummaryItem('5', 'حجز', Icons.book_online),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildSummaryItem('8', 'مفضلة', Icons.favorite),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Browsing History
            const Text(
              'سجل التصفح',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHistoryChart(),

            const SizedBox(height: 24),

            // Preferences Analysis
            const Text(
              'تحليل تفضيلاتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPreferenceCard('المناطق المفضلة', [
              {'name': 'التجمع الخامس', 'percentage': 40},
              {'name': 'الشيخ زايد', 'percentage': 30},
              {'name': 'مدينة نصر', 'percentage': 20},
              {'name': 'أخرى', 'percentage': 10},
            ]),

            const SizedBox(height: 16),
            _buildPreferenceCard('نطاق الأسعار', [
              {'name': '5000-8000 ج.م', 'percentage': 50},
              {'name': '8000-12000 ج.م', 'percentage': 30},
              {'name': 'أكثر من 12000 ج.م', 'percentage': 20},
            ]),

            const SizedBox(height: 24),

            // Time Analysis
            const Text(
              'أوقات النشاط',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityTimeCard(),

            const SizedBox(height: 24),

            // Insights
            const Text(
              'رؤى ذكية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              'توفير محتمل',
              'يمكنك توفير 15% عن طريق الحجز في أيام الأسبوع',
              Icons.savings,
              AppTheme.primaryColor,
            ),
            _buildInsightCard(
              'أفضل وقت للحجز',
              'الحجوزات في الصباح الباكر تحصل على استجابة أسرع بنسبة 40%',
              Icons.access_time,
              AppTheme.primaryColor,
            ),
            _buildInsightCard(
              'توصية',
              'العقارات في منطقتك المفضلة تنخفض أسعارها بنسبة 10% في نهاية الشهر',
              Icons.lightbulb,
              AppTheme.borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر 7 أيام',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '45 عقار',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar(0.4, 'السبت'),
                _buildBar(0.6, 'الأحد'),
                _buildBar(0.3, 'الاثنين'),
                _buildBar(0.8, 'الثلاثاء'),
                _buildBar(0.5, 'الأربعاء'),
                _buildBar(0.7, 'الخميس'),
                _buildBar(0.9, 'الجمعة'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(String title, List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            data.length,
            (index) {
              final item = data[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${item['percentage']}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item['percentage'] / 100,
                        backgroundColor: AppTheme.backgroundColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeSlot(
                  'صباحاً', '20%', Icons.wb_sunny, AppTheme.borderColor),
              _buildTimeSlot('ظهراً', '30%', Icons.wb_sunny_outlined,
                  AppTheme.borderColor),
              _buildTimeSlot(
                  'مساءً', '50%', Icons.nightlight, AppTheme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(
      String time, String percentage, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
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
}
