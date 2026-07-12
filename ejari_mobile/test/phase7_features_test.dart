import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ejari_mobile/services/auth_service.dart';
import 'package:ejari_mobile/services/data_service.dart';
import 'package:ejari_mobile/services/live_sync_service.dart';
import 'package:ejari_mobile/services/deep_link_service.dart';
import 'package:ejari_mobile/services/operations_feed_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LiveSyncService.resetForTests();
    DeepLinkService.clearPending();
    await AuthService.initDemoAccounts();
    await DataService.initProperties();
    await DataService.initDemoBookings();
    await OperationsFeedService.initDemoFeed();
  });

  group('Phase 7 — live sync', () {
    test('bumpRevision increments sync generation', () async {
      final before = LiveSyncService.instance.syncGeneration;
      await LiveSyncService.bumpRevision();
      expect(LiveSyncService.instance.syncGeneration, before + 1);
    });

    test('fingerprint changes after booking status update', () async {
      final before = await LiveSyncService.fingerprintForTests();
      await DataService.updateRequestStatus('demo_req_1', 'approved');
      await LiveSyncService.bumpRevision();
      final after = await LiveSyncService.fingerprintForTests();
      expect(after, isNot(equals(before)));
    });

    test('poll interval is 3 seconds', () {
      expect(LiveSyncService.pollInterval.inSeconds, 3);
    });
  });

  group('Phase 7 — deep links', () {
    test('parses ejari://booking/{id}', () {
      final target = DeepLinkService.parseUri('ejari://booking/demo_req_1');
      expect(target?.type, DeepLinkType.booking);
      expect(target?.id, 'demo_req_1');
    });

    test('parses ejari://property/{id}', () {
      final target = DeepLinkService.parseUri('ejari://property/shared_egy1');
      expect(target?.type, DeepLinkType.property);
      expect(target?.id, 'shared_egy1');
    });

    test('parses ejari://payment/{id}', () {
      final target = DeepLinkService.parseUri('ejari://payment/demo_req_1');
      expect(target?.type, DeepLinkType.payment);
      expect(target?.id, 'demo_req_1');
    });

    test('parses web query params', () {
      final targets = DeepLinkService.parseQueryParams({
        'booking': 'demo_req_1',
        'property': 'shared_egy1',
      });
      expect(targets.length, 2);
      expect(targets[0].type, DeepLinkType.booking);
      expect(targets[1].type, DeepLinkType.property);
    });

    test('enqueue stores pending targets', () {
      DeepLinkService.enqueue(
        const DeepLinkTarget(type: DeepLinkType.booking, id: 'demo_req_1'),
      );
      expect(DeepLinkService.pendingTargets.length, 1);
    });
  });

  group('Phase 7 — notification tap payloads', () {
    test('maps booking payload to deep link', () {
      final target =
          DeepLinkService.parseNotificationPayload('booking:demo_flow_bed_1');
      expect(target?.type, DeepLinkType.booking);
      expect(target?.id, 'demo_flow_bed_1');
    });

    test('maps payment payload to deep link', () {
      final target =
          DeepLinkService.parseNotificationPayload('payment:demo_req_1');
      expect(target?.type, DeepLinkType.payment);
      expect(target?.id, 'demo_req_1');
    });

    test('maps subscription payload to deep link', () {
      final target = DeepLinkService.parseNotificationPayload('subscription');
      expect(target?.type, DeepLinkType.subscription);
    });

    test('demo tap payload resolves to booking deep link', () {
      final target = DeepLinkService.parseNotificationPayload(
        'booking:demo_flow_bed_1',
      );
      expect(target?.type, DeepLinkType.booking);
      expect(target?.id, 'demo_flow_bed_1');
    });
  });
}
