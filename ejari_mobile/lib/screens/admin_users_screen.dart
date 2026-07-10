import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

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

  Future<void> _toggleBlock(String uid, bool isCurrentlyBlocked) async {
    await AuthService.toggleUserBlock(uid);
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyBlocked
              ? 'تم فك حظر المستخدم'
              : 'تم حظر المستخدم بنجاح'),
          backgroundColor:
              isCurrentlyBlocked ? AppTheme.primaryColor : AppTheme.errorColor,
        ),
      );
    }
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
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _changeRole(
                                  user['uid'], user['type'] ?? 'tenant'),
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
                                  user['uid'], user['isBlocked'] ?? false),
                              tooltip: user['isBlocked'] == true
                                  ? 'فك الحظر'
                                  : 'حظر المستخدم',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.primaryColor, size: 20),
                              onPressed: () => _deleteUser(user['uid']),
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
