import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/safe_parse.dart';
import '../widgets/ejari_section.dart';

/// أداء العقارات — مشاهدات، حجوزات، إيراد، إشغال، تصدير، ومقارنة سوقية.
class OwnerPropertyPerformanceScreen extends StatefulWidget {
  const OwnerPropertyPerformanceScreen({super.key});

  @override
  State<OwnerPropertyPerformanceScreen> createState() =>
      _OwnerPropertyPerformanceScreenState();
}

class _OwnerPropertyPerformanceScreenState
    extends State<OwnerPropertyPerformanceScreen> {
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _areaAvg = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final items = await DataService.getOwnerPropertyPerformance(ownerId);
    final area = items.isNotEmpty
        ? (items.first['title']?.toString() ?? 'المعادي').split('—').last.trim()
        : 'المعادي';
    final avg = await DataService.getAreaAveragePrice(area);
    if (mounted) {
      setState(() {
        _items = items;
        _areaAvg = avg;
        _loading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final summary = await DataService.exportCollectionSummary(ownerId);
    final now = DateTime.now();
    final rows = _items.map((p) {
      return '<tr><td>${safeStr(p['title'])}</td><td>${p['views']}</td>'
          '<td>${p['bookings']}</td><td>${p['revenue']} ج.م</td>'
          '<td>${p['occupancy']}%</td></tr>';
    }).join();

    final html = '''
<!DOCTYPE html><html dir="rtl" lang="ar"><head><meta charset="utf-8">
<title>تقرير أداء العقارات — إيجاري</title>
<style>body{font-family:Tajawal,sans-serif;padding:24px;background:#f5f5f0}
h1{color:#0F3A30}table{width:100%;border-collapse:collapse;margin-top:16px}
th,td{border:1px solid #ddd;padding:8px;text-align:right}
th{background:#0F3A30;color:#fff}</style></head><body>
<h1>تقرير أداء العقارات</h1>
<p>التاريخ: ${now.day}/${now.month}/${now.year}</p>
<p>إيراد شهري: ${summary['monthlyRevenue']} ج.م | مستأجرون: ${summary['tenantCount']}</p>
<table><thead><tr><th>العقار</th><th>مشاهدات</th><th>حجوزات</th><th>إيراد</th><th>إشغال</th></tr></thead>
<tbody>$rows</tbody></table></body></html>''';

    await Clipboard.setData(ClipboardData(text: html));
    await Share.share(html, subject: 'تقرير أداء العقارات — إيجاري');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ التقرير — يمكنك لصقه أو طباعته')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('أداء العقارات'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            tooltip: 'تصدير التقرير',
            onPressed: _items.isEmpty ? null : _exportReport,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'لا توجد عقارات بعد',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        if (_areaAvg.isNotEmpty) _marketComparison(),
                        const SizedBox(height: AppTheme.spaceSm),
                        _revenueChart(),
                        const SizedBox(height: AppTheme.spaceMd),
                        const EjariSectionHeader(
                          title: 'مقارنة الأداء',
                          subtitle: 'مشاهدات، حجوزات، إيراد، ونسبة الإشغال',
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        ..._items.map(_propertyCard),
                      ],
                    ),
            ),
    );
  }

  Widget _marketComparison() {
    final avg = safeInt(_areaAvg['average'], 8500);
    final myAvg = _items.isEmpty
        ? 0
        : (_items.fold<int>(0, (s, p) => s + safeInt(p['revenue'], 0)) /
                _items.length)
            .round();
    final diff = myAvg - avg;
    final better = diff >= 0;

    return EjariSurfaceCard(
      child: Row(
        children: [
          Icon(
            better ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: better ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متوسط المنطقة ${_areaAvg['area'] ?? ''}: $avg ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  better
                      ? 'أداؤك أعلى بـ ${diff.abs()} ج.م من المتوسط'
                      : 'أقل بـ ${diff.abs()} ج.م — فرصة لرفع السعر',
                  style: TextStyle(
                    fontSize: 11,
                    color: better ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueChart() {
    final top = _items.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإيراد حسب العقار',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: top
                        .map((p) => safeDouble(p['revenue'], 0))
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= top.length) {
                          return const SizedBox.shrink();
                        }
                        final title = safeStr(top[i]['title'], '');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            title.length > 8
                                ? '${title.substring(0, 8)}…'
                                : title,
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: top.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: safeDouble(e.value['revenue'], 0),
                        color: AppTheme.primaryColor,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyCard(Map<String, dynamic> p) {
    final occupancy = safeInt(p['occupancy'], 0);
    final occColor = occupancy >= 75
        ? const Color(0xFF2D6A5A)
        : occupancy >= 40
            ? AppTheme.primaryColor
            : AppTheme.errorColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    safeStr(p['title'], 'عقار'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: occColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$occupancy% إشغال',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: occColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                mainAxisExtent: 72,
              ),
              children: [
                EjariStatTile(
                  icon: Icons.visibility_rounded,
                  label: 'مشاهدات',
                  value: '${p['views'] ?? 0}',
                  compact: true,
                ),
                EjariStatTile(
                  icon: Icons.event_available_rounded,
                  label: 'حجوزات',
                  value: '${p['bookings'] ?? 0}',
                  compact: true,
                ),
                EjariStatTile(
                  icon: Icons.payments_rounded,
                  label: 'إيراد',
                  value: '${p['revenue'] ?? 0} ج.م',
                  accentColor: AppTheme.accentColor,
                  compact: true,
                ),
                EjariStatTile(
                  icon: Icons.category_rounded,
                  label: 'النوع',
                  value: safeStr(p['type'], 'شقق'),
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
