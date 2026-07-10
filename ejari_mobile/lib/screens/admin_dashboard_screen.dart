import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/property_provider.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/mock_data_seeder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _seedData(BuildContext context) async {
    if (AppConfig.demoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الضخ المباشر غير متاح في وضع العرض التجريبي')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    try {
      final properties = MockDataSeeder.getEgyptianProperties();
      for (var p in properties) {
        // Remove 'id' if it exists to let Firestore generate one
        p.remove('id');
        p['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('properties').add(p);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم ضخ البيانات بنجاح!')),
        );
        // Refresh properties
        context.read<PropertyProvider>().fetchAllProperties();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentProps = context.watch<PropertyProvider>().rentProperties;
    final saleProps = context.watch<PropertyProvider>().saleProperties;
    final properties = [...rentProps, ...saleProps];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قاعدة البيانات (فارغة؟)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _seedData(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('ضخ شقق مصر'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('جميع العقارات المضافة:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                return ListTile(
                  leading: const Icon(Icons.home, color: AppTheme.primaryColor),
                  title: Text(p['title'] ?? ''),
                  subtitle: Text(p['location'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                    onPressed: () async {
                      if (AppConfig.demoMode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الحذف المباشر غير متاح في وضع العرض التجريبي'),
                          ),
                        );
                        return;
                      }
                      if (p['id'] != null) {
                        // In a real app, you'd confirm first
                        await FirebaseFirestore.instance
                            .collection('properties')
                            .doc(p['id'])
                            .delete();
                        if (context.mounted) {
                          context.read<PropertyProvider>().fetchAllProperties();
                        }
                      }
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
