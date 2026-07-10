import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = 'user@ejari.app';
  const tinyImage = 'aGVsbG8='; // base64 "hello"

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
  });

  group('Identity verification', () {
    test('submit stores request and notifies admin', () async {
      final result = await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01012345678',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      expect(result['success'], isTrue);

      final requests = await DataService.getAllIdentityVerifications();
      expect(requests.length, 1);
      expect(requests.first['status'], 'pending');
      expect(requests.first['idFront'], tinyImage);

      final pending = await DataService.getPendingIdentityVerificationsCount();
      expect(pending, 1);

      final prefs = await SharedPreferences.getInstance();
      final notes = prefs.getStringList('notifications') ?? [];
      final adminNote = notes
          .map((n) => jsonDecode(n) as Map<String, dynamic>)
          .where((n) => n['userEmail'] == 'admin@ejari.app')
          .toList();
      expect(adminNote.isNotEmpty, isTrue);
      expect(adminNote.first['title'], contains('توثيق'));
    });

    test('blocks duplicate pending submission', () async {
      await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01012345678',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      final second = await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01099999999',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      expect(second['success'], isFalse);
    });

    test('approve marks user verified and notifies user', () async {
      await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01012345678',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      final request = (await DataService.getAllIdentityVerifications()).first;
      final ok = await DataService.approveIdentityVerification(
        request['id'].toString(),
        adminNote: 'مطابق للهوية',
      );
      expect(ok, isTrue);

      final status = await DataService.getIdentityVerificationStatus(testEmail);
      expect(status['label'], 'موافق');

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_$testEmail');
      expect(userJson, isNotNull);
      final user = jsonDecode(userJson!) as Map<String, dynamic>;
      expect(user['isVerified'], isTrue);
    });

    test('reject requires reason and notifies user with reason', () async {
      await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01012345678',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      final request = (await DataService.getAllIdentityVerifications()).first;
      final emptyReject = await DataService.rejectIdentityVerification(
        request['id'].toString(),
        '   ',
      );
      expect(emptyReject, isFalse);

      final ok = await DataService.rejectIdentityVerification(
        request['id'].toString(),
        'الصورة غير واضحة',
      );
      expect(ok, isTrue);

      final status = await DataService.getIdentityVerificationStatus(testEmail);
      expect(status['label'], 'مرفوض');
      expect(status['reason'], 'الصورة غير واضحة');

      final prefs = await SharedPreferences.getInstance();
      final notes = prefs.getStringList('notifications') ?? [];
      final userNote = notes
          .map((n) => jsonDecode(n) as Map<String, dynamic>)
          .where((n) => n['userEmail'] == testEmail)
          .last;
      expect(userNote['body'], contains('الصورة غير واضحة'));
    });

    test('rejected user can resubmit', () async {
      await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01012345678',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      final request = (await DataService.getAllIdentityVerifications()).first;
      await DataService.rejectIdentityVerification(
        request['id'].toString(),
        'أعد المحاولة',
      );

      final resubmit = await DataService.submitIdentityVerification(
        userId: testEmail,
        userName: 'مستأجر تجريبي',
        userType: 'tenant',
        email: testEmail,
        phone: '01055555555',
        idFront: tinyImage,
        idBack: tinyImage,
        selfie: tinyImage,
      );

      expect(resubmit['success'], isTrue);
      final updated = await DataService.getIdentityVerificationForUser(testEmail);
      expect(updated?['status'], 'pending');
      expect(updated?['phone'], '01055555555');
    });
  });
}
