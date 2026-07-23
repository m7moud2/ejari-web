import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/screens/changelog_screen.dart';
import 'package:ejari_mobile/config/app_config.dart';
import 'package:ejari_mobile/utils/booking_validator.dart';
import 'package:ejari_mobile/models/rental_duration_tier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
  });

  test('demo tenant is pre-verified for booking QA', () async {
    final status =
        await DataService.getIdentityVerificationStatus('user@ejari.app');
    expect(status['status'], 'approved');
    expect(DataService.isProfileDocsComplete(status), isTrue);
    expect(
      await DataService.hasCompletedProfileDocuments('user@ejari.app'),
      isTrue,
    );
  });

  test('new user without docs is incomplete', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_new@ejari.app',
      '{"email":"new@ejari.app","name":"جديد","role":"tenant","isVerified":false}',
    );
    final status =
        await DataService.getIdentityVerificationStatus('new@ejari.app');
    expect(status['status'], 'none');
    expect(status['label'], 'ناقص');
    expect(DataService.isProfileDocsComplete(status), isFalse);
  });

  test('booking validator requires profile docs, not inline ID images', () {
    final err = BookingValidator.validateDocuments(
      tier: RentalDurationTier.daily,
      verification: {},
      profileDocsComplete: false,
    );
    expect(err, isNotNull);
    expect(err!['message'].toString(), contains('الملف الشخصي'));

    final ok = BookingValidator.validateDocuments(
      tier: RentalDurationTier.daily,
      verification: {'docsUploaded': true, 'status': 'pending'},
      profileDocsComplete: true,
    );
    expect(ok, isNull);
  });

  test('booking identity snapshot omits re-upload fields', () async {
    final snap =
        await DataService.getBookingIdentitySnapshot('user@ejari.app');
    expect(snap['verified'], isTrue);
    expect(snap['docsUploaded'], isTrue);
    expect(snap.containsKey('idFront'), isFalse);
    expect(snap.containsKey('selfie'), isFalse);
  });

  test('version and changelog are 1.3.15', () {
    expect(AppConfig.appVersion, '1.3.15');
    expect(AppConfig.buildNumber, 31);
    expect(ChangelogScreen.releases.first.version, '1.3.15');
    expect(
      ChangelogScreen.releases.first.items.any((i) => i.contains('ملف الشخصي')),
      isTrue,
    );
  });
}
