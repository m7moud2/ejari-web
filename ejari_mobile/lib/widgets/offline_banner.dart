import 'package:flutter/material.dart';

/// شريط «وضع بدون اتصال — بيانات محفوظة».
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.orange.shade800.withOpacity(0.92),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'وضع بدون اتصال — بيانات محفوظة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// غلاف يضيف الشريط فوق المحتوى عند الحاجة.
class OfflineAwareScaffoldBody extends StatelessWidget {
  final bool showOfflineBanner;
  final Widget child;

  const OfflineAwareScaffoldBody({
    super.key,
    required this.showOfflineBanner,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!showOfflineBanner) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}
