import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tenant_list_service.dart';
import '../services/auth_service.dart';

class OwnerTenantListsScreen extends StatefulWidget {
  const OwnerTenantListsScreen({super.key});

  @override
  State<OwnerTenantListsScreen> createState() => _OwnerTenantListsScreenState();
}

class _OwnerTenantListsScreenState extends State<OwnerTenantListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _blacklist = [];
  List<Map<String, dynamic>> _preferred = [];
  bool _loading = true;
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await AuthService.getCurrentUser();
    _ownerId = user?['email']?.toString() ?? 'owner@ejari.app';
    final bl = await TenantListService.getList(_ownerId!, 'blacklist');
    final pr = await TenantListService.getList(_ownerId!, 'preferred');
    if (mounted) {
      setState(() {
        _blacklist = bl;
        _preferred = pr;
        _loading = false;
      });
    }
  }

  Future<void> _addTenant(String type) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'blacklist' ? 'إضافة للقائمة السوداء' : 'إضافة مستأجر مفضل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد')),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'ملاحظة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (ok == true && _ownerId != null) {
      await TenantListService.addTenant(
        ownerId: _ownerId!,
        type: type,
        tenantEmail: emailCtrl.text.trim(),
        tenantName: nameCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      );
      _load();
    }
    nameCtrl.dispose();
    emailCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قوائم المستأجرين'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'القائمة السوداء'),
            Tab(text: 'المفضلون'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTenant(_tab.index == 0 ? 'blacklist' : 'preferred'),
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_blacklist, 'blacklist'),
                _buildList(_preferred, 'preferred'),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return const Center(child: Text('القائمة فارغة', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final t = items[i];
        return Card(
          child: ListTile(
            leading: Icon(
              type == 'blacklist' ? Icons.block : Icons.star,
              color: type == 'blacklist' ? AppTheme.errorColor : AppTheme.accentColor,
            ),
            title: Text(t['name']?.toString() ?? ''),
            subtitle: Text('${t['email']}\n${t['note'] ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await TenantListService.removeTenant(
                  ownerId: _ownerId!,
                  type: type,
                  tenantEmail: t['email']?.toString() ?? '',
                );
                _load();
              },
            ),
          ),
        );
      },
    );
  }
}
