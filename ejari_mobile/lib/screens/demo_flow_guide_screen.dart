import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ejari_section.dart';
import '../services/demo_flow_service.dart';
import 'search_results_screen.dart';
import 'my_bookings_screen.dart';
import 'booking_qr_screen.dart';
import 'owner_rating_screen.dart';
import 'property_details_screen.dart';
import '../services/data_service.dart';

/// دليل التدفق التجريبي الكامل — خطوة بخطوة بالعربية.
class DemoFlowGuideScreen extends StatefulWidget {
  const DemoFlowGuideScreen({super.key});

  @override
  State<DemoFlowGuideScreen> createState() => _DemoFlowGuideScreenState();
}

class _DemoFlowGuideScreenState extends State<DemoFlowGuideScreen> {
  List<Map<String, dynamic>> _steps = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DemoFlowService.ensureFlowBooking();
    final steps = await DemoFlowService.getSteps();
    if (mounted) {
      setState(() {
        _steps = steps;
        _loading = false;
      });
    }
  }

  Future<void> _runStep(Map<String, dynamic> step) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await DemoFlowService.advanceStep(step['id']?.toString() ?? '');
    await _load();
    if (mounted) {
      setState(() {
        _loading = false;
        _message = result['message']?.toString();
      });
      if (result['success'] == true && result['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'].toString())),
        );
      }
    }
  }

  void _navigateToStep(Map<String, dynamic> step) {
    final id = step['id']?.toString() ?? '';
    switch (id) {
      case 'search':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchResultsScreen(
              query: 'مشتركة',
              filters: {'accommodationType': 'bed'},
            ),
          ),
        );
        break;
      case 'book':
        _openPropertyDetails();
        break;
      case 'pay':
      case 'approve':
      case 'checkin':
      case 'checkout':
      case 'deposit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
        break;
      case 'qr':
        _openQrScreen();
        break;
      case 'rate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OwnerRatingScreen(
              ownerEmail: DemoFlowService.ownerEmail,
              tenantEmail: DemoFlowService.tenantEmail,
              bookingId: DemoFlowService.bookingId,
            ),
          ),
        );
        break;
    }
  }

  Future<void> _openPropertyDetails() async {
    final props = await DataService.getAllProperties();
    final property = props.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['id']?.toString() == DemoFlowService.propertyId,
          orElse: () => null,
        );
    if (property == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  Future<void> _openQrScreen() async {
    final booking = await DataService.findBookingById(DemoFlowService.bookingId);
    if (booking == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingQrScreen(booking: booking),
      ),
    );
  }

  IconData _iconFor(String? icon) => switch (icon) {
        'search' => Icons.search_rounded,
        'bed' => Icons.single_bed_rounded,
        'payment' => Icons.payments_rounded,
        'check' => Icons.check_circle_outline_rounded,
        'qr' => Icons.qr_code_rounded,
        'login' => Icons.login_rounded,
        'logout' => Icons.logout_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        'star' => Icons.star_rounded,
        _ => Icons.circle_outlined,
      };

  Color _stateColor(String state) => switch (state) {
        'done' => AppTheme.successColor,
        'current' => AppTheme.accentColor,
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('جرب التدفق الكامل'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط',
            onPressed: () async {
              await DemoFlowService.resetFlow();
              await _load();
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _loading && _steps.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2E26), Color(0xFF1B594B)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_rounded,
                                color: AppTheme.accentColor),
                            SizedBox(width: 8),
                            Text(
                              'تدفق حجز متصل — shared_egy1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'من البحث → حجز سرير → دفع → موافقة → QR → دخول → خروج → عربون → تقييم',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _message!,
                            style: const TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  const EjariSectionHeader(
                    title: 'الخطوات',
                    subtitle: 'اضغط «تنفيذ» للمحاكاة أو «انتقل» للشاشة',
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  ..._steps.map(_stepCard),
                ],
              ),
            ),
    );
  }

  Widget _stepCard(Map<String, dynamic> step) {
    final state = step['state']?.toString() ?? 'pending';
    final color = _stateColor(state);
    final isCurrent = state == 'current';
    final isDone = state == 'done';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: EjariSurfaceCard(
        elevated: isCurrent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : _iconFor(step['icon']?.toString()),
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${step['index']}. ${step['title']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      step['statusAr']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  if (isCurrent || isDone) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isCurrent)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _runStep(step),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('تنفيذ',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        if (isCurrent) const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _navigateToStep(step),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('انتقل',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
