import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../utils/account_id_service.dart';
import '../widgets/ejari_section.dart';

class AccountIdSearchScreen extends StatefulWidget {
  const AccountIdSearchScreen({super.key});

  @override
  State<AccountIdSearchScreen> createState() => _AccountIdSearchScreenState();
}

class _AccountIdSearchScreenState extends State<AccountIdSearchScreen> {
  final _controller = TextEditingController();
  bool _isSearching = false;
  bool _isAdmin = false;
  Map<String, dynamic>? _publicResult;
  Map<String, dynamic>? _adminResult;
  List<Map<String, dynamic>> _adminGlobalResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getUserRole();
    if (!mounted) return;
    setState(() => _isAdmin = role == 'admin');
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _publicResult = null;
      _adminResult = null;
      _adminGlobalResults = [];
    });

    if (_isAdmin) {
      final global = await DataService.adminGlobalSearch(query);
      final user = await AccountIdService.findUserByAccountId(query);
      if (!mounted) return;
      setState(() {
        _adminGlobalResults = global;
        _adminResult = user;
        _isSearching = false;
        if (user == null && global.isEmpty) {
          _errorMessage = 'لم يتم العثور على حساب بهذا الرقم';
        }
      });
      return;
    }

    final user = await AccountIdService.findUserByAccountId(query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (user == null) {
        _errorMessage = 'لم يتم العثور على حساب بهذا الرقم';
      } else {
        _publicResult = AccountIdService.toPublicProfile(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('بحث برقم الحساب'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'مثال: EJR-100002',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _publicResult = null;
                          _adminResult = null;
                          _adminGlobalResults = [];
                          _errorMessage = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
            ),
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_isSearching ? 'جاري البحث...' : 'بحث'),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          if (_errorMessage != null)
            EjariSurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          if (_publicResult != null) _buildPublicResult(_publicResult!),
          if (_adminResult != null) _buildAdminResult(_adminResult!),
          if (_adminGlobalResults.isNotEmpty && _adminResult == null)
            ..._adminGlobalResults.map(_buildGlobalResultTile),
        ],
      ),
    );
  }

  Widget _buildPublicResult(Map<String, dynamic> profile) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile['name']?.toString() ?? 'مستخدم',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('رقم الحساب', profile['accountId']?.toString() ?? ''),
          _detailRow('الدور', profile['roleLabel']?.toString() ?? ''),
          _detailRow(
            'التوثيق',
            profile['verificationLabel']?.toString() ?? 'غير موثق',
          ),
          const SizedBox(height: 8),
          Text(
            'عرض محدود — لا تظهر بيانات مالية أو خاصة',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminResult(Map<String, dynamic> user) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user['name']?.toString() ?? 'مستخدم',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('رقم الحساب', user['accountId']?.toString() ?? ''),
          _detailRow('البريد', user['email']?.toString() ?? ''),
          _detailRow('الهاتف', user['phone']?.toString() ?? '—'),
          _detailRow('الدور', AccountIdService.toPublicProfile(user)['roleLabel']),
          _detailRow(
            'التوثيق',
            user['verificationStatus']?.toString() ??
                (user['isVerified'] == true ? 'approved' : 'none'),
          ),
          _detailRow('الحالة', user['isBlocked'] == true ? 'محظور' : 'نشط'),
          if (user['status'] != null)
            _detailRow('status', user['status']?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget _buildGlobalResultTile(Map<String, dynamic> result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EjariSurfaceCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_iconForType(result['type']?.toString())),
          title: Text(result['title']?.toString() ?? ''),
          subtitle: Text(result['subtitle']?.toString() ?? ''),
          trailing: Text(
            result['typeLabel']?.toString() ?? '',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'user':
        return Icons.person_rounded;
      case 'booking':
      case 'contract':
        return Icons.description_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'support':
        return Icons.support_agent_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
