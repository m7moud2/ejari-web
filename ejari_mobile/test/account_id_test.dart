import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/utils/account_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initDemoAccounts();
  });

  group('Account ID generation', () {
    test('demo accounts receive stable EJR IDs', () async {
      final users = await AuthService.getAllUsers();
      final byEmail = {
        for (final user in users)
          user['email']?.toString(): user['accountId']?.toString(),
      };

      expect(byEmail['admin@ejari.app'], 'EJR-100001');
      expect(byEmail['user@ejari.app'], 'EJR-100002');
      expect(byEmail['owner@ejari.app'], 'EJR-100003');
      expect(byEmail['tech@ejari.app'], 'EJR-100004');
    });

    test('generated IDs are unique', () async {
      final ids = <String>{};
      for (var i = 0; i < 5; i++) {
        ids.add(await AccountIdService.generateNextAccountId());
      }
      expect(ids.length, 5);
      for (final id in ids) {
        expect(id.startsWith(AccountIdService.prefix), isTrue);
      }
    });

    test('signup assigns accountId to new users', () async {
      await AuthService.signUp({
        'name': 'مستخدم جديد',
        'email': 'newuser@ejari.app',
        'password': 'pass123',
        'type': 'tenant',
      });

      final users = await AuthService.getAllUsers();
      final newUser = users.firstWhere(
        (user) => user['email'] == 'newuser@ejari.app',
      );
      expect(newUser['accountId']?.toString().startsWith('EJR-'), isTrue);

      final found =
          await AccountIdService.findUserByAccountId(newUser['accountId']);
      expect(found?['email'], 'newuser@ejari.app');
    });
  });

  group('Account ID search', () {
    test('findUserByAccountId resolves demo tenant', () async {
      final user = await AccountIdService.findUserByAccountId('EJR-100002');
      expect(user, isNotNull);
      expect(user!['email'], 'user@ejari.app');
      expect(user['name'], 'مستأجر تجريبي');
    });

    test('adminGlobalSearch finds users by accountId', () async {
      final results = await DataService.adminGlobalSearch('EJR-100001');
      expect(results.any((r) => r['type'] == 'user'), isTrue);
      final match = results.firstWhere((r) => r['type'] == 'user');
      expect(match['data']['email'], 'admin@ejari.app');
      expect(match['data']['accountId'], 'EJR-100001');
    });

    test('public profile hides private fields', () async {
      final user = await AccountIdService.findUserByAccountId('EJR-100002');
      expect(user, isNotNull);

      final publicProfile = AccountIdService.toPublicProfile(user!);
      expect(publicProfile.containsKey('email'), isFalse);
      expect(publicProfile.containsKey('phone'), isFalse);
      expect(publicProfile.containsKey('password'), isFalse);
      expect(publicProfile['name'], 'مستأجر تجريبي');
      expect(publicProfile['accountId'], 'EJR-100002');
    });
  });
}
