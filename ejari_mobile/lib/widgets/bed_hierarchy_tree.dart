import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/bed_hierarchy_service.dart';
import 'ejari_section.dart';

/// شجرة الشقة → الغرف → الأسرّة.
class BedHierarchyTree extends StatelessWidget {
  final Map<String, dynamic> tree;
  final void Function(String bedId, String bedLabel)? onBedTap;

  const BedHierarchyTree({
    super.key,
    required this.tree,
    this.onBedTap,
  });

  @override
  Widget build(BuildContext context) {
    return EjariSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tree['propertyTitle']?.toString() ?? 'عقار',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _statBadge(
                '${tree['occupiedBeds']}/${tree['totalBeds']}',
                'مشغول',
                AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${tree['totalRooms']} غرف • ${tree['vacantBeds']} سرير فاضي',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...((tree['rooms'] as List?) ?? []).map((room) => _roomNode(room)),
        ],
      ),
    );
  }

  Widget _roomNode(dynamic room) {
    final r = Map<String, dynamic>.from(room as Map);
    final status = r['status']?.toString() ?? 'vacant';
    final statusColor = status == 'full'
        ? AppTheme.errorColor
        : status == 'partial'
            ? AppTheme.accentColor
            : const Color(0xFF2D6A5A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room_rounded, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(
                r['label']?.toString() ?? 'غرفة',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${r['occupiedBeds']}/${r['totalBeds']}',
                style: TextStyle(fontSize: 11, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ((r['beds'] as List?) ?? []).map((bed) {
                final b = Map<String, dynamic>.from(bed as Map);
                return _bedChip(b);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bedChip(Map<String, dynamic> bed) {
    final vacant = bed['status'] == 'vacant';
    final color = vacant ? const Color(0xFF2D6A5A) : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onBedTap != null
          ? () => onBedTap!(bed['id']?.toString() ?? '', bed['label']?.toString() ?? '')
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vacant ? Icons.bed_outlined : Icons.bed_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              bed['label']?.toString() ?? 'سرير',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (!vacant && bed['tenantName'] != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${bed['tenantName']})',
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

/// شاشة إدارة شجرة الأسرّة للمالك.
class BedHierarchyScreen extends StatefulWidget {
  final String? propertyId;

  const BedHierarchyScreen({super.key, this.propertyId});

  @override
  State<BedHierarchyScreen> createState() => _BedHierarchyScreenState();
}

class _BedHierarchyScreenState extends State<BedHierarchyScreen> {
  List<Map<String, dynamic>> _trees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.propertyId != null) {
      final tree =
          await BedHierarchyService.getTreeForProperty(widget.propertyId!);
      setState(() {
        _trees = tree != null ? [tree] : [];
        _loading = false;
      });
      return;
    }
    final trees =
        await BedHierarchyService.getOwnerTrees('owner@ejari.app');
    setState(() {
      _trees = trees;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('شجرة الأسرّة'),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                children: [
                  const EjariSurfaceCard(
                    elevated: false,
                    child: Text(
                      'الشقة → الغرف → الأسرّة — إدارة الإشغال والحجز لكل سرير.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_trees.isEmpty)
                    const Center(child: Text('لا توجد وحدات مشتركة'))
                  else
                    ..._trees.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BedHierarchyTree(tree: t),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
