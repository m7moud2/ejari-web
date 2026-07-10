import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

class ServiceProviderProfileScreen extends StatefulWidget {
  const ServiceProviderProfileScreen({super.key});

  @override
  State<ServiceProviderProfileScreen> createState() =>
      _ServiceProviderProfileScreenState();
}

class _ServiceProviderProfileScreenState
    extends State<ServiceProviderProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    final stats = await DataService.getProviderStats(user?['email'] ?? '');
    setState(() {
      _userData = user;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('الملف الشخصي المهني'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const ColoredBox(
              color: AppTheme.backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildAvailabilityCard(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildExpertiseSection(),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      AuthService.logout();
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('تسجيل الخروج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.errorColor,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).cardColor,
                  shape: BoxShape.circle),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.backgroundColor,
                child: Icon(Icons.engineering_rounded,
                    size: 50, color: AppTheme.primaryColor),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _userData?['name'] ?? 'فني إيجاري',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text(
          'متخصص صيانة أنظمة تبريد وكهرباء',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded,
                color: AppTheme.borderColor, size: 20),
            const SizedBox(width: 4),
            Text(
              '${_stats?['rating']} (156 تقييم)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [],
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable
                ? Icons.check_circle_rounded
                : Icons.pause_circle_rounded,
            color: _isAvailable ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'متاح لاستقبال الطلبات' : 'غير متاح حالياً',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _isAvailable
                      ? 'سيتم تحويل الطلبات الجديدة إليك'
                      : 'تم تعليق استقبال الطلبات مؤقتاً',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) => setState(() => _isAvailable = val),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        _buildStatItem('سنوات الخبرة', '8 سنوات', Icons.history_rounded),
        const SizedBox(width: 16),
        _buildStatItem('مهام مكتملة', '${_stats?['completedCount']}',
            Icons.task_alt_rounded),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertiseSection() {
    final skills = ['صيانة تكييف', 'كهرباء منازل', 'أنظمة ذكية', 'طوارئ 24/7'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مهارات وتخصصات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map((skill) => Chip(
                    label: Text(skill),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
