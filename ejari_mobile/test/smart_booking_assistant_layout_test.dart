import 'package:ejari_mobile/models/rental_duration_tier.dart';
import 'package:ejari_mobile/models/tenant_type.dart';
import 'package:ejari_mobile/widgets/smart_booking_assistant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SmartBookingAssistant keeps title readable under tight width (no letter stack)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: SmartBookingAssistant(
                  tier: RentalDurationTier.shortTerm,
                  tenantType: TenantType.individual,
                  durationType: 'شهر',
                  duration: 3,
                  checkInDate: DateTime.now().add(const Duration(days: 5)),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleFinder = find.text('ملخص الحجز');
      expect(titleFinder, findsOneWidget);

      final titleSize = tester.getSize(titleFinder);
      // Letter-by-letter vertical wrap (~14px * 12 glyphs) would be ~160+ tall
      // and very narrow. Two-line wrap under a Flexible chip is OK.
      expect(titleSize.width, greaterThan(80));
      expect(titleSize.height, lessThan(80));
      expect(find.textContaining('قصير المدى'), findsOneWidget);
    },
  );
}
