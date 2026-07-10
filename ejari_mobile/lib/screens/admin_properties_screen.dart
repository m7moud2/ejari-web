import 'package:flutter/material.dart';
import '../services/firestore_property_service.dart';
import '../widgets/ejari_image.dart';
import '../theme/app_theme.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _approvedProperties = [];
  List<Map<String, dynamic>> _pendingProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final all =
        await FirestorePropertyService.getAllProperties(approvedOnly: false);
    if (mounted) {
      setState(() {
        _approvedProperties =
            all.where((p) => p['status'] == 'approved').toList();
        _pendingProperties =
            all.where((p) => p['status'] == 'pending').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? 'تأكيد الموافقة' : 'تأكيد الرفض'),
        content: Text(status == 'approved'
            ? 'هل تريد الموافقة على هذا العقار ونشره للمستخدمين؟'
            : 'هل تريد رفض هذا العقار وإيقافه من الظهور؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved'
                  ? AppTheme.primaryColor
                  : AppTheme.errorColor,
            ),
            child: Text(
              status == 'approved' ? 'موافقة ونشر' : 'رفض الطلب',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirestorePropertyService.updatePropertyStatus(id, status);
    _loadProperties();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'تمت الموافقة على النشر 🎉'
              : 'تم رفض الطلب ❌'),
          backgroundColor: status == 'approved'
              ? AppTheme.primaryColor
              : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteProperty(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العقار'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العقار نهائياً؟'),
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
      await FirestorePropertyService.deleteProperty(id);
      _loadProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العقارات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'المنشورة (${_approvedProperties.length})'),
            Tab(text: 'قيد المراجعة (${_pendingProperties.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPropertyList(_approvedProperties, isPending: false),
                _buildPropertyList(_pendingProperties, isPending: true),
              ],
            ),
    );
  }

  Widget _buildPropertyList(List<Map<String, dynamic>> properties,
      {required bool isPending}) {
    if (properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isPending
                    ? Icons.fact_check_outlined
                    : Icons.holiday_village_rounded,
                size: 80,
                color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(isPending
                ? 'لا توجد طلبات معلقة حالياً'
                : 'لا توجد عقارات منشورة'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        final bool isLocal = property['image'] != null &&
            !property['image'].startsWith('assets/');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: EjariImage(
                      path: property['image'],
                      isLocalFile: isLocal,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppTheme.textPrimary,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('${property['price']} ج.م',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (isPending)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppTheme.borderColor,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('طلب جديد',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property['title'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(property['location'],
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المالك: ${property['ownerId']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 32),
                    if (isPending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(
                                  property['id'].toString(), 'rejected'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor),
                              child: const Text('رفض الطلب'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(
                                  property['id'].toString(), 'approved'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor),
                              child: const Text('موافقة ونشر'),
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionPill(
                            icon: property['isVerified'] == true
                                ? Icons.verified
                                : Icons.verified_user_outlined,
                            label: property['isVerified'] == true
                                ? 'موثق'
                                : 'توثيق',
                            color: AppTheme.primaryColor,
                            onTap: () async {
                              await FirestorePropertyService
                                  .toggleVerifyProperty(
                                      property['id'].toString());
                              _loadProperties();
                            },
                          ),
                          _buildActionPill(
                            icon: property['isFeatured'] == true
                                ? Icons.star
                                : Icons.star_border,
                            label: property['isFeatured'] == true
                                ? 'مميز'
                                : 'تمييز',
                            color: AppTheme.borderColor,
                            onTap: () async {
                              await FirestorePropertyService
                                  .toggleFeatureProperty(
                                      property['id'].toString());
                              _loadProperties();
                            },
                          ),
                          _buildActionPill(
                            icon: Icons.delete_outline,
                            label: 'حذف',
                            color: AppTheme.errorColor,
                            onTap: () =>
                                _deleteProperty(property['id'].toString()),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
