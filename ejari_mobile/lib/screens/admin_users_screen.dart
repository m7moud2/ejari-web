import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/activity_log_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await AuthService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: const Text(
            'هل أنت متأكد من رغبتك في حذف هذا المستخدم؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف',
                  style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.deleteAccount(uid);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المستخدم بنجاح')));
      }
    }
  }

  Future<void> _changeRole(String uid, String currentRole) async {
    final Map<String, String> roles = {
      'tenant': 'مستأجر',
      'owner': 'مالك عقار',
      'provider': 'فني / فني هيلب',
      'admin': 'مدير نظام',
    };

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('تغيير رتبة المستخدم'),
        children: roles.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, e.key),
                  child: Text(e.value,
                      style: TextStyle(
                          color: currentRole == e.key
                              ? AppTheme.primaryColor
                              : null,
                          fontWeight:
                              currentRole == e.key ? FontWeight.bold : null)),
                ))
            .toList(),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      await AuthService.updateUserRole(uid, newRole);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تغيير الرتبة إلى ${roles[newRole]}')));
      }
    }
  }

  Future<void> _moderateUser(String uid, bool isBlocked, bool isSuspended) async {
    final reasonCtrl = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إجراء إداري'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isBlocked && !isSuspended) ...[
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.errorColor),
                title: const Text('حظر دائم'),
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle, color: Colors.orange),
                title: const Text('تعليق مؤقت (7 أيام)'),
                onTap: () => Navigator.pop(ctx, 'suspend'),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
                title: const Text('رفع الحظر / التعليق'),
                onTap: () => Navigator.pop(ctx, 'unblock'),
              ),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'السبب (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ],
      ),
    );
    if (action == null) {
      reasonCtrl.dispose();
      return;
    }
    await AuthService.moderateUser(
      uid: uid,
      action: action,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      suspendUntil: action == 'suspend'
          ? DateTime.now().add(const Duration(days: 7))
          : null,
    );
    await ActivityLogService.logSystemAction(
      userId: 'admin@ejari.app',
      action: 'moderate_user',
      detail: '$action — $uid — ${reasonCtrl.text}',
      category: 'admin',
    );
    reasonCtrl.dispose();
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تنفيذ الإجراء: $action')),
      );
    }
  }

  Future<void> _toggleBlock(String uid, bool isCurrentlyBlocked) async {
    final user = _users.firstWhere(
      (u) => (u['uid'] ?? u['email'] ?? u['id']) == uid,
      orElse: () => {},
    );
    await _moderateUser(
      uid,
      user['isBlocked'] == true,
      user['isSuspended'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمين مسجلين'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final uid =
                        user['uid'] ?? user['email'] ?? user['id'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(user['name']?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(user['name'] ?? 'مستخدم',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            if (user['isSuspended'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4)),
                                child: const Text('معلّق',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                            if (user['isBlocked'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppTheme.errorColor,
                                    borderRadius: BorderRadius.circular(4)),
                                child: const Text('محظور',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? '',
                                style: const TextStyle(fontSize: 12)),
                            if (user['accountId'] != null &&
                                user['accountId'].toString().isNotEmpty)
                              Text(
                                user['accountId'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _changeRole(
                                  uid.toString(), user['type'] ?? 'tenant'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                    _getRoleArabic(user['type'] ?? 'tenant'),
                                    style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: Icon(
                                user['isBlocked'] == true
                                    ? Icons.lock_open_rounded
                                    : Icons.block_rounded,
                                color: user['isBlocked'] == true
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                size: 20,
                              ),
                              onPressed: () => _toggleBlock(
                                  uid.toString(), user['isBlocked'] ?? false),
                              tooltip: user['isBlocked'] == true
                                  ? 'فك الحظر'
                                  : 'حظر المستخدم',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.primaryColor, size: 20),
                              onPressed: () => _deleteUser(uid.toString()),
                              tooltip: 'حذف نهائي',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _getRoleArabic(String role) {
    switch (role) {
      case 'owner':
        return 'مالك عقار';
      case 'tenant':
        return 'مستأجر';
      case 'provider':
        return 'فني هيلب';
      case 'admin':
        return 'مدير نظام';
      default:
        return role;
    }
  }
}
