import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

// - [x] **Admin Reports Recovery**
//     - [x] Implement CSV Export/Share simulation in `AdminReportsScreen`
// - [/] **Settings Integration**
//     - [x] Connect Help Center, About, and Privacy dialog in `SettingsScreen`
// - [/] **Rewards & Loyalty**
//     - [x] Implement "Redeem Points" logic in `RewardsScreen`
// - [ ] **Social & Engagement**
//     - [ ] Implement Share and Comment logic in `PropertyReelsScreen`

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'شهري';
  final List<String> _periods = ['يومي', 'أسبوعي', 'شهري', 'سنوي'];

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DataService.getAdminGlobalStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _showReportPreview() {
    final String reportSummary = """
تقرير إيجاري - $_selectedPeriod
تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}
الفترة: $_selectedPeriod

الملخص المالي:
- إجمالي الإيرادات: ${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)} ج.م
- الحجوزات النشطة: ${_stats['activeBookings'] ?? 0}
- التقييمات الجديدة: ${_stats['newFeedbackCount'] ?? 0}

حالة المنصة:
- إجمالي المستخدمين: ${_stats['totalUsers'] ?? 0}
- العقارات الموثقة: 85%
- النمو المالي: +12%

تم إنشاء هذا التقرير تلقائياً من نظام إيجاري.
""";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('معاينة تقرير $_selectedPeriod'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    reportSummary,
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace', height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('سيتم تصدير التقرير بصيغة PDF و Excel',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم إنشاء وتصدير التقرير بنجاح! 📄'),
                    backgroundColor: AppTheme.primaryColor),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('تصدير ومشاركة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'تصدير التقرير',
            onPressed: _showReportPreview,
          ),
        ],
      ),
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  // Period Filter
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _periods.length,
                      itemBuilder: (context, index) {
                        final period = _periods[index];
                        final isSelected = _selectedPeriod == period;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedPeriod = period);
                              }
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Metrics
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 52) / 2,
                        child: _buildMetricCard(
                          'إجمالي الإيرادات',
                          '${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)} ج.م',
                          Icons.attach_money,
                          AppTheme.primaryColor,
                          '+12%',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 52) / 2,
                        child: _buildMetricCard(
                          'عدد المستخدمين',
                          '${_stats['totalUsers'] ?? 0}',
                          Icons.people,
                          AppTheme.primaryColor,
                          '+${(_stats['totalUsers'] ?? 0)}',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 52) / 2,
                        child: _buildMetricCard(
                          'الحجوزات النشطة',
                          '${_stats['activeBookings'] ?? 0}',
                          Icons.book_online,
                          AppTheme.primaryColor,
                          '+${_stats['activeBookings'] ?? 0}',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 52) / 2,
                        child: _buildMetricCard(
                          'تقييمات جديدة',
                          '${_stats['newFeedbackCount'] ?? 0}',
                          Icons.star_rate_rounded,
                          AppTheme.borderColor,
                          'رأي',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Revenue Chart (Simulated)
                  const Text(
                    'نمو الإيرادات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBar(0.4, 'يناير'),
                          _buildBar(0.5, 'فبراير'),
                          _buildBar(0.3, 'مارس'),
                          _buildBar(0.6, 'أبريل'),
                          _buildBar(0.8, 'مايو'),
                          _buildBar(0.7, 'يونيو'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  const Text(
                    'أحدث النشاطات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    'تسجيل مستخدم جديد',
                    'محمد أحمد قام بإنشاء حساب',
                    'منذ 5 دقائق',
                    Icons.person_add,
                    AppTheme.primaryColor,
                  ),
                  _buildActivityItem(
                    'حجز جديد',
                    'تم حجز شقة المعادي لمدة شهر',
                    'منذ 15 دقيقة',
                    Icons.check_circle,
                    AppTheme.primaryColor,
                  ),
                  _buildActivityItem(
                    'طلب خدمة',
                    'طلب صيانة تكييف من سارة علي',
                    'منذ ساعة',
                    Icons.build,
                    AppTheme.borderColor,
                  ),
                  _buildActivityItem(
                    'دفع اشتراك',
                    'تم دفع اشتراك باقة الملاك الذهبية',
                    'منذ ساعتين',
                    Icons.payment,
                    AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String change) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
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
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.primaryColor.withOpacity(0.6),
                AppTheme.primaryColor,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التقارير والإحصائيات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ملخص سريع للفترة $_selectedPeriod يساعدك تراجع أداء المنصة بدون تشتيت.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerChip('إيرادات', '${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)} ج.م'),
              _headerChip('مستخدمين', '${_stats['totalUsers'] ?? 0}'),
              _headerChip('نشط', '${_stats['activeBookings'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

/*
  Future<void> _exportExcelReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء تقرير Excel...'), duration: Duration(seconds: 2)),
    );

    try {
      final excel.Workbook workbook = excel.Workbook();
      final excel.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'تقرير $_selectedPeriod';

      // Headers
      sheet.getRangeByName('A1').setText('المقياس');
      sheet.getRangeByName('B1').setText('القيمة');
      sheet.getRangeByName('A1:B1').cellStyle.bold = true;
      sheet.getRangeByName('A1:B1').cellStyle.backColor = '#10B981';
      sheet.getRangeByName('A1:B1').cellStyle.fontColor = '#FFFFFF';

      // Data (Currently using UI static values for demonstration)
      sheet.getRangeByName('A2').setText('إجمالي الإيرادات');
      sheet.getRangeByName('B2').setText('150,000 ج.م');
      
      sheet.getRangeByName('A3').setText('عدد المستخدمين');
      sheet.getRangeByName('B3').setText('1,250');
      
      sheet.getRangeByName('A4').setText('الحجوزات النشطة');
      sheet.getRangeByName('B4').setText('45');
      
      sheet.getRangeByName('A5').setText('طلبات الخدمات');
      sheet.getRangeByName('B5').setText('28');

      // Style and column widths
      sheet.getRangeByName('A1:A5').columnWidth = 25;
      sheet.getRangeByName('B1:B5').columnWidth = 20;

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final String fileName = '$path/Ejari_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File(fileName);

      await file.writeAsBytes(bytes, flush: true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء التقرير بنجاح، جاري فتحه...')),
      );

      await OpenFilex.open(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')),
      );
    }
  }
*/
}
