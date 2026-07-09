import 'package:flutter/material.dart';

import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../services/financial_service.dart';
import 'create_maintenance_request_screen.dart';
import 'payment_screen.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/auth_gate.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() =>
      _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _requests = [];

  bool _isLoading = true;
  String _filter = 'all';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadRequests();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    var requests = await MaintenanceService.getUserRequests(user['email']);

    if (requests.isEmpty) {
      requests = [
        {
          'id': 'DEMO-001',
          'userId': user['email'],
          'propertyId': 'PROP-001',
          'category': 'plumbing',
          'priority': 'high',
          'title': 'تسريب مياه في الحمام الرئيسي',
          'description': 'يوجد تسريب مياه قوي تحت الحوض يحتاج صيانة عاجلة.',
          'status': 'quote_received',
          'quotePrice': 450.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'DEMO-002',
          'userId': user['email'],
          'propertyId': 'PROP-001',
          'category': 'ac',
          'priority': 'medium',
          'title': 'صيانة التكييف السنوية',
          'description':
              'تنظيف الفلاتر وفحص الفريون والتأكد من سلامة التوصيلات.',
          'status': 'in_progress',
          'quotePrice': 200.0,
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'updatedAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        },
        {
          'id': 'DEMO-003',
          'userId': user['email'],
          'propertyId': 'PROP-001',
          'category': 'electrical',
          'priority': 'urgent',
          'title': 'عطل في لوحة الكهرباء',
          'description': 'انقطاع متكرر في التيار الكهربائي في غرفة المعيشة.',
          'status': 'completed',
          'quotePrice': 750.0,
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String(),
          'updatedAt': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
        },
        {
          'id': 'DEMO-004',
          'userId': user['email'],
          'propertyId': 'PROP-001',
          'category': 'painting',
          'priority': 'low',
          'title': 'دهان الصالة الرئيسية',
          'description': 'تجديد طلاء جدران الصالة وإصلاح التشققات.',
          'status': 'pending',
          'quotePrice': null,
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'updatedAt': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
        },
      ];
    } else {
      requests = requests.map((req) {
        if (req['status'] == 'pending' && req['quotePrice'] == null) {
          return {
            ...req,
            'status': 'quote_received',
            'quotePrice': FinancialService.generateTechnicianQuote(
              MaintenanceService.categories.firstWhere(
                (c) => c['id'] == req['category'],
                orElse: () => {'name': 'عام'},
              )['name'],
            ),
          };
        }
        return req;
      }).toList();
    }

    setState(() {
      _requests = requests;
      _isLoading = false;
    });
    _fadeController.forward(from: 0);
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.borderColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'طلبات الصيانة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
            tooltip: 'تحديث',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.borderColor),
                  SizedBox(height: 16),
                  Text('جاري تحميل الطلبات...',
                      style: TextStyle(color: AppTheme.borderColor)),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildOverviewBanner(),
                  _buildHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              return _buildRequestCard(
                                  _filteredRequests[index], index);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateMaintenanceRequestScreen()),
          );
          _loadRequests();
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('طلب جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.borderColor,
        elevation: 0,
      ),
    );
  }

  Widget _buildHeader() {
    final total = _requests.length;
    final quoteCount =
        _requests.where((r) => r['status'] == 'quote_received').length;
    final inProgressCount =
        _requests.where((r) => r['status'] == 'in_progress').length;
    final completedCount =
        _requests.where((r) => r['status'] == 'completed').length;

  return Container(
      color: AppTheme.borderColor,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 430;
          final chips = [
            _buildStatChip('الكل', total, 'all', isNarrow: narrow),
            _buildStatChip(
                'عروض', quoteCount, 'quote_received',
                isNarrow: narrow),
            _buildStatChip('جاري', inProgressCount, 'in_progress',
                isNarrow: narrow),
            _buildStatChip('مكتمل', completedCount, 'completed',
                isNarrow: narrow),
          ];

          if (narrow) {
            final chipWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((chip) => SizedBox(width: chipWidth, child: chip))
                  .toList(),
            );
          }

          return Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                Expanded(child: chips[i]),
                if (i != chips.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, int count, String filter,
      {bool isNarrow = false}) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: isNarrow ? 12 : 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: isNarrow ? 18 : 20,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.borderColor : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isNarrow ? 11 : 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.borderColor : Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewBanner() {
    final waitingCount =
        _requests.where((r) => r['status'] == 'pending').length;
    final urgentCount = _requests
        .where((r) => r['priority'] == 'urgent' && r['status'] != 'completed')
        .length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خدمة صيانة أوضح وأسرع',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل طلب بيتراجع بعرض سعر واضح، ومعاينة، ثم موافقتك قبل أي دفع. عندك $waitingCount قيد المراجعة و$urgentCount حالات عاجلة.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 18, color: AppTheme.textPrimary),
          const SizedBox(width: 6),
          Text(
            'عرض: ${_filter == 'all' ? 'الكل (${_requests.length})' : '${_getStatusText(_filter)} (${_filteredRequests.length})'}',
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final category = MaintenanceService.categories.firstWhere(
      (c) => c['id'] == request['category'],
      orElse: () => MaintenanceService.categories.last,
    );
    final priority = MaintenanceService.priorities[request['priority']] ??
        MaintenanceService.priorities['medium']!;
    final statusColor = _getStatusColor(request['status']);
    final statusBg = statusColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(priority['color']).withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ??
                        Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [],
                  ),
                  child: Center(
                    child: Text(category['icon'],
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(priority['color']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['description'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ── Status + Date Row ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(request['status']),
                              size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(request['status']),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (request['quotePrice'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${request['quotePrice']?.toStringAsFixed(0) ?? '-'} ج.م',
                          style: const TextStyle(
                            color: AppTheme.borderColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Date ────────────────────────────────────────────
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request['createdAt']),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.primaryColor),
                    ),
                  ],
                ),

                // ── Action Buttons ───────────────────────────────────
                if (request['status'] == 'quote_received') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectQuote(request),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child:
                              const Text('رفض', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _showQuoteDetails(context, request),
                          icon: const Icon(Icons.payments_rounded,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'قبول وسداد',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.borderColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (request['status'] == 'in_progress') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmCompletion(request),
                      icon: const Icon(Icons.check_circle_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'تأكيد استلام العمل',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else if (request['status'] == 'completed') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: AppTheme.primaryColor, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'تم إنجاز العمل بنجاح',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuoteDetails(BuildContext context, Map<String, dynamic> request) {
    final price = double.tryParse(request['quotePrice'].toString()) ?? 0.0;
    final breakdown = FinancialService.calculateServiceBreakdown(price);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppTheme.borderColor, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تفاصيل عرض السعر',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPriceRow(
                'تكلفة الخدمة', breakdown.totalAmount, AppTheme.textPrimary),
            _buildPriceRow('ضمان الجودة إيجاري', 0.0, AppTheme.primaryColor),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  '${breakdown.totalAmount.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_rounded,
                      color: AppTheme.primaryColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'المبلغ يظل محفوظاً لدى إيجاري ولا يُحوَّل للفني إلا بعد تأكيدك على جودة العمل.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final allowed = await AuthGate.requireLogin(
                    context,
                    actionLabel: 'دفع الصيانة',
                  );
                  if (!allowed || !context.mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        itemType: 'service',
                        itemData: {
                          'id': request['id'],
                          'name': request['title'],
                          'description': breakdown.details,
                        },
                        amount: breakdown.totalAmount,
                      ),
                    ),
                  ).then((success) {
                    if (success == true) {
                      _updateRequestStatus(request['id'], 'in_progress');
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.borderColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'موافقة والمتابعة للدفع',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          Text(
            amount == 0.0 ? 'مجاني ✓' : '${amount.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  amount == 0.0 ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _rejectQuote(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('رفض العرض'),
          ],
        ),
        content:
            const Text('هل تريد رفض هذا العرض؟ سيتم إلغاء الطلب وإشعار الفني.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateRequestStatus(request['id'], 'cancelled');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم رفض العرض وإلغاء الطلب'),
                    backgroundColor: AppTheme.errorColor),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCompletion(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('تأكيد الاستلام'),
          ],
        ),
        content: const Text(
            'هل أنت متأكد من إتمام العمل بشكل جيد؟ سيتم تحويل المبلغ للفني الآن.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateRequestStatus(request['id'], 'completed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم تأكيد الاستلام وتحويل المبلغ للفني'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateRequestStatus(String id, String newStatus) {
    setState(() {
      final index = _requests.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _requests[index] = {..._requests[index], 'status': newStatus};
      }
    });
    MaintenanceService.updateStatus(id, newStatus);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.borderColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_circle_outlined,
                  size: 72, color: AppTheme.borderColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد طلبات',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                _filter == 'all'
                    ? 'ابدأ بطلب جديد، وحدد نوع المشكلة والأولوية، وسيتم توجيه الطلب للمتابعة فورًا.'
                    : 'لا توجد طلبات بهذه الحالة حالياً. جرّب تغيير الفلتر أو إنشاء طلب جديد.',
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const CreateMaintenanceRequestScreen()),
                );
                _loadRequests();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'طلب جديد',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.borderColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateParsing.parse(isoDate);
    if (dt == null) return isoDate;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'quote_received':
        return Icons.price_check_rounded;
      case 'in_progress':
        return Icons.construction_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.primaryColor;
      case 'quote_received':
        return AppTheme.borderColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'جاري المعاينة';
      case 'quote_received':
        return 'عرض سعر جديد';
      case 'in_progress':
        return 'جاري العمل';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
