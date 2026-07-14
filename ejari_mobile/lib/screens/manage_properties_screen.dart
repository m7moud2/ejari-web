import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../utils/auth_gate.dart';
import '../utils/safe_parse.dart';
import '../widgets/ejari_section.dart';
import 'add_property_screen.dart';
import 'owner_property_performance_screen.dart';
import '../widgets/property_image.dart';

class ManagePropertiesScreen extends StatefulWidget {
  const ManagePropertiesScreen({super.key});

  @override
  State<ManagePropertiesScreen> createState() => _ManagePropertiesScreenState();
}

class _ManagePropertiesScreenState extends State<ManagePropertiesScreen> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _performance = [];
  bool _isLoading = true;
  String _filter = 'all';
  Map<String, dynamic>? _subscriptionSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Tab shell already role-gates owner screens; only gate pushed routes.
      final embedded =
          context.findAncestorWidgetOfExactType<IndexedStack>() != null;
      if (!embedded) {
        final allowed = await AuthGate.requireRole(
          context,
          allowedRoles: const ['owner'],
          deniedMessage: 'إدارة العقارات متاحة للمالك فقط.',
        );
        if (!allowed) return;
      }
      _loadProperties();
    });
  }

  Future<void> _loadProperties() async {
    final user = await AuthService.getCurrentUser();
    final ownerId = user?['email']?.toString() ??
        user?['uid']?.toString() ??
        'owner@ejari.app';
    final properties = await DataService.getOwnerProperties(ownerId);
    final performance = await DataService.getOwnerPropertyPerformance(ownerId);
    final summary = await SubscriptionService.getSubscriptionSummary();
    setState(() {
      _properties = properties;
      _performance = performance;
      _subscriptionSummary = summary;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    return _properties.where((p) {
      final acc = p['accommodationType']?.toString() ?? 'full_unit';
      final isActive = p['isActive'] ?? true;
      switch (_filter) {
        case 'apartment':
          return acc == 'full_unit';
        case 'shared':
          return acc != 'full_unit';
        case 'active':
          return isActive == true;
        case 'inactive':
          return isActive != true;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, dynamic>? _perfFor(String id) {
    try {
      return _performance.firstWhere((e) => e['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _togglePropertyStatus(int index) async {
    final property = _filtered[index];
    final listIndex = _properties.indexOf(property);
    final id = property['id']?.toString();
    final newActive = !(property['isActive'] ?? true);
    setState(() {
      _properties[listIndex]['isActive'] = newActive;
    });
    if (id != null && id.isNotEmpty) {
      await DataService.updatePropertyActive(id, newActive);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newActive ? 'تم تفعيل العقار' : 'تم إيقاف العقار'),
      ),
    );
  }

  Future<void> _deleteProperty(int index) async {
    final property = _filtered[index];
    final listIndex = _properties.indexOf(property);
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
      final id = property['id']?.toString();
      if (id != null && id.isNotEmpty) {
        await DataService.deleteProperty(id);
      }
      setState(() => _properties.removeAt(listIndex));
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('عقاراتي'),
            if (_subscriptionSummary != null)
              Text(
                'باقة ${_subscriptionSummary!['plan_name']} — '
                '${_subscriptionSummary!['properties_used']}/'
                '${_subscriptionSummary!['properties_limit'] == -1 ? '∞' : _subscriptionSummary!['properties_limit']}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'أداء العقارات',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OwnerPropertyPerformanceScreen(),
                ),
              );
            },
          ),
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildFilters(),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        const EjariSurfaceCard(
                          elevated: false,
                          child: Text(
                            'لا توجد عقارات بهذا الفلتر.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      else
                        ...List.generate(
                          _filtered.length,
                          (i) => _buildPropertyCard(i),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      ('all', 'الكل'),
      ('apartment', 'شقة'),
      ('shared', 'سرير/غرفة'),
      ('active', 'نشط'),
      ('inactive', 'متوقف'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (id, label) = filters[i];
          final selected = _filter == id;
          return FilterChip(
            label: Text(label, style: const TextStyle(fontSize: 11)),
            selected: selected,
            onSelected: (_) => setState(() => _filter = id),
            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
            checkmarkColor: AppTheme.primaryColor,
          );
        },
      ),
    );
  }

  Widget _buildPropertyCard(int index) {
    final property = _filtered[index];
    final isActive = property['isActive'] ?? true;
    final perf = _perfFor(property['id']?.toString() ?? '');
    final occupancy = safeInt(perf?['occupancy'], 0);
    final views = safeInt(perf?['views'], safeInt(property['views'], 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.surfaceCardDecoration(radius: 16),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: PropertyImage(
                  property: property,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'متوقف',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (occupancy > 0)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$occupancy% إشغال',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title'] ?? 'عقار',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property['location'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _badge('${property['price']} ج.م', AppTheme.primaryColor),
                    _badge('$views مشاهدة', AppTheme.textSecondary),
                    if (perf != null)
                      _badge('${perf['bookings']} حجز', AppTheme.accentColor),
                    _badge(
                      property['accommodationType'] == 'full_unit'
                          ? 'شقة'
                          : 'مشترك',
                      const Color(0xFF2D6A5A),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePropertyStatus(index),
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          isActive ? 'إيقاف' : 'تفعيل',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
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
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('تعديل', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteProperty(index),
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor, size: 20),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
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
