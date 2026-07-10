import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/owner_booking_requests_panel.dart';
import '../widgets/ejari_section.dart';

/// شاشة طلبات الحجز الواردة للمالك.
class OwnerBookingRequestsScreen extends StatelessWidget {
  const OwnerBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('طلبات الحجز'),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: const [
          EjariSectionHeader(
            title: 'طلبات بانتظار المراجعة',
            subtitle: 'راجع درجة المستأجر قبل القبول أو الرفض',
          ),
          SizedBox(height: AppTheme.spaceSm),
          OwnerBookingRequestsPanel(),
        ],
      ),
    );
  }
}
