import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<Map<String, dynamic>> _allFeedback = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('app_feedback') ?? [];

    setState(() {
      _allFeedback = list
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('تقييمات المستخدمين (${_allFeedback.length}) ⭐'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allFeedback.isEmpty
              ? const Center(child: Text('لا توجد تقييمات حالياً'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _allFeedback.length,
                  itemBuilder: (context, index) {
                    final item = _allFeedback[index];
                    final int rating = item['rating'] ?? 0;
                    final String type = item['type'] ?? 'general';
                    final String date = item['createdAt']?.split('T')[0] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ??
                            Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  );
                                }),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: type == 'general'
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  type == 'general'
                                      ? 'تقييم عام'
                                      : 'بعد معاملة',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: type == 'general'
                                        ? AppTheme.primaryColor
                                        : AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['comment'] ?? 'بدون تعليق',
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.primaryColor),
                              ),
                              const Text(
                                'إيجاري - نظام الملاحظات',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
