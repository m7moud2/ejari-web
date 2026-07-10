import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ComparisonScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String type; // 'property' or 'car'

  const ComparisonScreen({
    super.key,
    required this.items,
    required this.type,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.items.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('المقارنة')),
        body: const Center(
          child: Text('يجب اختيار عنصرين على الأقل للمقارنة'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة العقارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رابط المقارنة')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            headingRowColor:
                WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
            columns: [
              const DataColumn(
                label: Text(
                  'المواصفات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...widget.items.map((item) => DataColumn(
                    label: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item['image'] ?? 'assets/images/home1.jpg',
                              width: 150,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 150,
                                height: 100,
                                color: AppTheme.backgroundColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
            rows: _buildRows(),
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildRows() {
    if (widget.type == 'property') {
      return [
        _buildDataRow(
            'السعر', widget.items.map((e) => '${e['price']} ج.م').toList()),
        _buildDataRow(
            'الموقع',
            widget.items
                .map((e) => (e['location'] ?? '-').toString())
                .toList()),
        _buildDataRow('المساحة',
            widget.items.map((e) => (e['area'] ?? '-').toString()).toList()),
        _buildDataRow('الغرف',
            widget.items.map((e) => (e['beds'] ?? '-').toString()).toList()),
        _buildDataRow('الحمامات',
            widget.items.map((e) => (e['baths'] ?? '-').toString()).toList()),
        _buildDataRow('النوع',
            widget.items.map((e) => (e['type'] ?? '-').toString()).toList()),
        _buildDataRow(
            'الحالة',
            widget.items
                .map((e) => e['furnished'] == true ? 'مفروش' : 'غير مفروش')
                .toList()),
        _buildDataRow('التقييم',
            widget.items.map((e) => '${e['rating'] ?? '4.5'} ⭐').toList()),
      ];
    } else {
      // Car comparison
      return [
        _buildDataRow('السعر اليومي',
            widget.items.map((e) => '${e['price']} ج.م').toList()),
        _buildDataRow(
            'الموديل', widget.items.map((e) => '${e['year'] ?? '-'}').toList()),
        _buildDataRow('النوع',
            widget.items.map((e) => (e['type'] ?? '-').toString()).toList()),
        _buildDataRow('المقاعد',
            widget.items.map((e) => '${e['seats'] ?? '-'}').toList()),
        _buildDataRow(
            'ناقل الحركة',
            widget.items
                .map((e) => (e['transmission'] ?? '-').toString())
                .toList()),
        _buildDataRow('الوقود',
            widget.items.map((e) => (e['fuel'] ?? '-').toString()).toList()),
        _buildDataRow('المسافة',
            widget.items.map((e) => (e['mileage'] ?? '-').toString()).toList()),
        _buildDataRow('اللون',
            widget.items.map((e) => (e['color'] ?? '-').toString()).toList()),
      ];
    }
  }

  DataRow _buildDataRow(String label, List<String> values) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...values.map((value) => DataCell(
              Text(
                value,
                style: const TextStyle(fontSize: 13),
              ),
            )),
      ],
    );
  }
}
