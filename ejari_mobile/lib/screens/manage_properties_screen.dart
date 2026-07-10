import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'add_property_screen.dart';

class ManagePropertiesScreen extends StatefulWidget {
  const ManagePropertiesScreen({super.key});

  @override
  State<ManagePropertiesScreen> createState() => _ManagePropertiesScreenState();
}

class _ManagePropertiesScreenState extends State<ManagePropertiesScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final user = await AuthService.getCurrentUser();
    final properties =
        await DataService.getOwnerProperties(user?['email'] ?? 'admin');
    setState(() {
      _properties = properties;
      _isLoading = false;
    });
  }

  Future<void> _togglePropertyStatus(int index) async {
    setState(() {
      _properties[index]['isActive'] =
          !(_properties[index]['isActive'] ?? true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_properties[index]['isActive']
            ? 'تم تفعيل العقار'
            : 'تم إيقاف العقار'),
      ),
    );
  }

  Future<void> _deleteProperty(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العقار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _properties.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العقار بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة عقاراتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen()),
              );
              _loadProperties();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) => _buildPropertyCard(index),
                  ),
                ),
    );
  }

  Widget _buildPropertyCard(int index) {
    final property = _properties[index];
    final isActive = property['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: const [],
      ),
      child: Column(
        children: [
          // Image and Status
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  property['image'] ?? 'assets/images/home1.jpg',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 150,
                    color: AppTheme.backgroundColor,
                    child: const Icon(Icons.home, size: 50),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'متوقف',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title'] ?? 'عقار',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(property['location'] ?? '',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${property['price']} ج.م/شهر',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${property['views'] ?? 0}',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePropertyStatus(index),
                        icon: Icon(isActive ? Icons.pause : Icons.play_arrow,
                            size: 18),
                        label: Text(isActive ? 'إيقاف' : 'تفعيل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive
                              ? AppTheme.borderColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddPropertyScreen(initialData: property),
                            ),
                          );
                          _loadProperties();
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteProperty(index),
                      icon:
                          const Icon(Icons.delete, color: AppTheme.errorColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_outlined,
              size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text(
            'لم تقم بإضافة عقارات بعد',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen()),
              );
              _loadProperties();
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة عقار جديد'),
          ),
        ],
      ),
    );
  }
}
