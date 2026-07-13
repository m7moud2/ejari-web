import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../screens/booking_track_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/owner_booking_requests_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/property_details_screen.dart';
import '../screens/receipt_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../utils/safe_parse.dart';
import 'auth_service.dart';
import 'data_service.dart';

enum DeepLinkType { booking, property, payment, subscription }

class DeepLinkTarget {
  final DeepLinkType type;
  final String? id;

  const DeepLinkTarget({required this.type, this.id});

  @override
  bool operator ==(Object other) =>
      other is DeepLinkTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// يُعالج ejari:// ومعاملات الويب وحمولات الإشعارات.
class DeepLinkService {
  DeepLinkService._();

  static final List<DeepLinkTarget> _pending = [];

  static List<DeepLinkTarget> get pendingTargets => List.unmodifiable(_pending);

  static void clearPending() => _pending.clear();

  static void enqueue(DeepLinkTarget target) {
    if (!_pending.contains(target)) {
      _pending.add(target);
    }
  }

  static void enqueueAll(Iterable<DeepLinkTarget> targets) {
    for (final target in targets) {
      enqueue(target);
    }
  }

  static DeepLinkTarget? parseUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.scheme == 'ejari') {
      // ejari://booking/{id} → host=booking, path=/{id}
      // ejari:///booking/{id} → path=/booking/{id}
      final segments = <String>[
        if (uri.host.isNotEmpty) uri.host,
        ...uri.pathSegments.where((s) => s.isNotEmpty),
      ];
      if (segments.isEmpty) return null;
      final type = _typeFromSegment(segments.first);
      if (type == null) return null;
      final id = segments.length > 1 ? segments[1] : null;
      return DeepLinkTarget(type: type, id: id);
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final targets = parseQueryParams(uri.queryParameters);
      return targets.isEmpty ? null : targets.first;
    }

    return null;
  }

  static List<DeepLinkTarget> parseQueryParams(Map<String, String> params) {
    final targets = <DeepLinkTarget>[];
    final booking = params['booking']?.trim();
    final property = params['property']?.trim();
    final payment = params['payment']?.trim();
    final subscription = params['subscription']?.trim();

    if (booking != null && booking.isNotEmpty) {
      targets.add(DeepLinkTarget(type: DeepLinkType.booking, id: booking));
    }
    if (property != null && property.isNotEmpty) {
      targets.add(DeepLinkTarget(type: DeepLinkType.property, id: property));
    }
    if (payment != null && payment.isNotEmpty) {
      targets.add(DeepLinkTarget(type: DeepLinkType.payment, id: payment));
    }
    if (subscription != null && subscription.isNotEmpty) {
      targets.add(const DeepLinkTarget(type: DeepLinkType.subscription));
    }
    return targets;
  }

  static DeepLinkTarget? parseNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    final trimmed = payload.trim();

    if (trimmed.startsWith('ejari://') || trimmed.contains('://')) {
      return parseUri(trimmed);
    }

    final parts = trimmed.split(':');
    final type = _typeFromSegment(parts.first);
    if (type != null) {
      final id = parts.length >= 2 ? parts.sublist(1).join(':') : null;
      return DeepLinkTarget(
        type: type,
        id: (id == null || id.isEmpty) ? null : id,
      );
    }

    return parseUri('ejari://$trimmed');
  }

  static List<DeepLinkTarget> parseWebLaunchTargets() {
    if (!kIsWeb) return const [];
    return parseQueryParams(Uri.base.queryParameters);
  }

  static Future<void> processPending() async {
    if (_pending.isEmpty) return;
    final targets = List<DeepLinkTarget>.from(_pending);
    _pending.clear();
    for (final target in targets) {
      await navigate(target);
    }
  }

  static Future<void> navigate(DeepLinkTarget target) async {
    final ctx = AppNavigator.context;
    if (ctx == null) {
      enqueue(target);
      return;
    }

    switch (target.type) {
      case DeepLinkType.booking:
        await _openBooking(ctx, target.id);
      case DeepLinkType.property:
        await _openProperty(ctx, target.id);
      case DeepLinkType.payment:
        await _openPayment(target.id);
      case DeepLinkType.subscription:
        await AppNavigator.push(
          MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
        );
    }
  }

  static Future<void> _openBooking(BuildContext ctx, String? id) async {
    if (id == null || id.isEmpty) {
      await AppNavigator.push(
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
      );
      return;
    }

    final booking = await DataService.findBookingById(id);
    if (booking == null) {
      await AppNavigator.push(
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
      );
      return;
    }

    final role = await AuthService.getUserRole();
    if (role == 'owner') {
      await AppNavigator.push(
        MaterialPageRoute(builder: (_) => const OwnerBookingRequestsScreen()),
      );
      return;
    }

    await AppNavigator.push(
      MaterialPageRoute(
        builder: (_) => BookingTrackScreen(
          bookingId: id,
          booking: booking,
        ),
      ),
    );
  }

  static Future<void> _openProperty(BuildContext ctx, String? id) async {
    if (id == null || id.isEmpty) return;
    final property = await DataService.findPropertyById(id);
    if (property == null) return;
    await AppNavigator.push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailsScreen(property: property),
      ),
    );
  }

  static Future<void> _openPayment(String? id) async {
    if (id == null || id.isEmpty) return;

    if (id.startsWith('RCP-')) {
      final receipt = await DataService.getReceiptById(id);
      if (receipt == null) return;
      final navCtx = AppNavigator.context;
      if (navCtx == null || !navCtx.mounted) return;
      await ReceiptScreen.showDialogFor(navCtx, receipt);
      return;
    }

    final booking = await DataService.findBookingById(id);
    if (booking == null) return;

    final monthly = safeDouble(booking['monthlyRent'] ?? booking['price']);
    final deposit = safeDouble(booking['depositAmount']);
    final leaseTotal = safeDouble(
      booking['leaseTotal'] ?? booking['totalAmount'] ?? monthly,
    );
    final stage = booking['paymentPhase']?.toString() == 'deposit'
        ? 'deposit'
        : 'rent';
    final amount = stage == 'deposit'
        ? (deposit > 0 ? deposit : monthly * 0.2)
        : leaseTotal;

    await AppNavigator.push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          itemType: 'booking',
          itemData: booking,
          amount: amount,
          paymentStage: stage,
          totalAmount: leaseTotal,
          depositAmount: deposit,
          remainingAmount: amount,
        ),
      ),
    );
  }

  static DeepLinkType? _typeFromSegment(String segment) {
    switch (segment.toLowerCase()) {
      case 'booking':
        return DeepLinkType.booking;
      case 'property':
        return DeepLinkType.property;
      case 'payment':
        return DeepLinkType.payment;
      case 'subscription':
        return DeepLinkType.subscription;
      default:
        return null;
    }
  }
}
