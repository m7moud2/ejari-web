import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'service_details_screen.dart';
import 'my_service_requests_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات المنزلية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'طلباتي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyServiceRequestsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              margin: const EdgeInsets.all(16),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خدمات منزلية احترافية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'نوفر لك أفضل مقدمي الخدمات',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_repair_service,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _buildQuickAction(
                          context,
                          'طلباتي',
                          Icons.list_alt,
                          AppTheme.primaryColor,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const MyServiceRequestsScreen())),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildQuickAction(
                          context,
                          'خدمة طارئة',
                          Icons.emergency,
                          AppTheme.errorColor,
                          () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('خدمة طارئة'),
                                content: const Text(
                                    'سيتم التواصل معك خلال 5 دقائق من فريق الدعم.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('حسناً'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Services Grid
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'جميع الخدمات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 230,
                ),
                children: [
                  _buildServiceCard(
                    context,
                    'خدمات التنظيف',
                    'تنظيف شامل',
                    Icons.cleaning_services,
                    AppTheme.primaryColor,
                    '150 ج.م/ساعة',
                  ),
                  _buildServiceCard(
                    context,
                    'الصيانة المنزلية',
                    'كهرباء وسباكة',
                    Icons.build,
                    AppTheme.borderColor,
                    '200 ج.م/زيارة',
                  ),
                  _buildServiceCard(
                    context,
                    'نقل الأثاث',
                    'فك وتركيب',
                    Icons.local_shipping,
                    AppTheme.primaryColor,
                    '500 ج.م',
                  ),
                  _buildServiceCard(
                    context,
                    'مكافحة الحشرات',
                    'قضاء تام',
                    Icons.bug_report,
                    AppTheme.errorColor,
                    '300 ج.م',
                  ),
                  _buildServiceCard(
                    context,
                    'تأمين العقارات',
                    'حماية شاملة',
                    Icons.security,
                    AppTheme.primaryColor,
                    'حسب التقييم',
                  ),
                  _buildServiceCard(
                    context,
                    'ضمان الإيجار',
                    'ضمان التحصيل',
                    Icons.verified_user,
                    AppTheme.primaryColor,
                    '5% من القيمة',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String price,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailsScreen(
                  serviceName: title,
                  description: subtitle,
                  icon: icon,
                  color: color,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
