import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class WealthDashboardScreen extends StatelessWidget {
  const WealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('investment_dashboard'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalAssetCard(context),
            const SizedBox(height: 24),
            Text(context.tr('investment_performance'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildMetricsGrid(context),
            const SizedBox(height: 32),
            Text(context.tr('active_properties'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildPropertyList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAssetCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.borderColor, AppTheme.borderColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('total_asset_value'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward,
                          color: AppTheme.primaryColor, size: 14),
                      SizedBox(width: 4),
                      Text('12.5%',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '14,500,000 ${context.tr('price_egp')}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif'),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildAssetDetail(context.tr('monthly_revenue'),
                  '120,000 ${context.tr('price_egp')}'),
              _buildAssetDetail(context.tr('annual_roi'), '8.4%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDetail(String title, String value) {
    return SizedBox(
      width: 150,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            title: context.tr('occupancy_rate'),
            value: '92%',
            icon: Icons.pie_chart_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            context,
            title: context.tr('maintenance_costs'),
            value: '15,000',
            icon: Icons.build_rounded,
            color: AppTheme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPropertyList(BuildContext context) {
    return Column(
      children: [
        _buildPropertyItem(
          context,
          name: 'فيلا إيجاري زايد',
          location: 'الشيخ زايد',
          roi: '9.2%',
          value: '8,500,000',
        ),
        const SizedBox(height: 12),
        _buildPropertyItem(
          context,
          name: 'شقة فاخرة النرجس',
          location: 'التجمع الخامس',
          roi: '7.5%',
          value: '6,000,000',
        ),
      ],
    );
  }

  Widget _buildPropertyItem(BuildContext context,
      {required String name,
      required String location,
      required String roi,
      required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/home1.jpg'),
                  fit: BoxFit.cover,
                )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.primaryColor, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$value ج.م',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('ROI $roi',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
