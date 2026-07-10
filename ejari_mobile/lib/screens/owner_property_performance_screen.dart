import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../utils/safe_parse.dart';
import '../widgets/ejari_section.dart';

/// أداء العقارات — مشاهدات، حجوزات، إيراد، إشغال لكل عقار.
class OwnerPropertyPerformanceScreen extends StatefulWidget {
  const OwnerPropertyPerformanceScreen({super.key});

  @override
  State<OwnerPropertyPerformanceScreen> createState() =>
      _OwnerPropertyPerformanceScreenState();
}

class _OwnerPropertyPerformanceScreenState
    extends State<OwnerPropertyPerformanceScreen> {
  List<Map<String, dynamic>> _items = [];
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
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
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
