import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import 'my_bookings_screen.dart';
import 'admin_users_screen.dart';
import 'admin_service_requests_screen.dart';
import 'admin_support_screen.dart';
import 'tenant_wallet_screen.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastQuery = trimmed;
    });

    final results = await DataService.adminGlobalSearch(trimmed);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('بحث شامل'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'رقم عقد، حجز، إيصال، صيانة، بريد...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
              onSubmitted: _search,
              onChanged: (v) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'ابحث في العقود والحجوزات والإيصالات وطلبات الصيانة والمستخدمين',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => _buildResultCard(_results[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _search(_controller.text),
        icon: const Icon(Icons.manage_search_rounded),
        label: const Text('بحث'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _lastQuery.isEmpty ? Icons.travel_explore_rounded : Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _lastQuery.isEmpty
                  ? 'أدخل رقم عقد أو حجز أو إيصال للبحث'
                  : 'لا توجد نتائج لـ "$_lastQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final type = result['type']?.toString() ?? 'unknown';
    final icon = _iconForType(type);
    final color = _colorForType(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openResult(result),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            result['typeLabel']?.toString() ?? type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result['subtitle']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if (result['id'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'المعرّف: ${result['id']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'contract':
        return Icons.description_outlined;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'user':
        return Icons.person_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
        return AppTheme.primaryColor;
      case 'contract':
        return AppTheme.accentColor;
      case 'receipt':
        return Colors.teal;
      case 'maintenance':
        return Colors.orange;
      case 'user':
        return AppTheme.borderColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _openResult(Map<String, dynamic> result) {
    final type = result['type']?.toString() ?? '';
    Widget? page;
    switch (type) {
      case 'booking':
      case 'contract':
        page = const MyBookingsScreen();
        break;
      case 'receipt':
        page = const TenantWalletScreen();
        break;
      case 'maintenance':
        page = const AdminServiceRequestsScreen();
        break;
      case 'support':
        page = const AdminSupportScreen();
        break;
      case 'user':
        page = const AdminUsersScreen();
        break;
    }

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تفاصيل: ${result['title']}')),
      );
    }
  }
}
