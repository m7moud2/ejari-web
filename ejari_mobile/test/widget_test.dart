import 'package:flutter_test/flutter_test.dart';

import 'package:ejari_mobile/main.dart';
import 'package:ejari_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EjariApp());
    await tester.pump();

    // Verify that the SplashScreen widget is in the widget tree.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the splash screen delay timer fire so there are no pending timers
    await tester.pump(const Duration(seconds: 4));
  });
}
