import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يُحدّث الشاشات تلقائياً عند تغيّر بيانات الحجوزات أو البث المباشر.
class LiveSyncService extends ChangeNotifier {
  LiveSyncService._();

  static LiveSyncService? _instance;
  static LiveSyncService get instance => _instance ??= LiveSyncService._();

  static const String revisionKey = 'live_sync_revision';
  static const Duration pollInterval = Duration(seconds: 3);

  Timer? _timer;
  String? _lastFingerprint;
  bool _started = false;

  int syncGeneration = 0;
  bool isSyncing = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _lastFingerprint = await _computeFingerprint();
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> _poll() async {
    final fingerprint = await _computeFingerprint();
    if (fingerprint == _lastFingerprint) return;
    isSyncing = true;
    notifyListeners();
    _lastFingerprint = fingerprint;
    syncGeneration++;
    isSyncing = false;
    notifyListeners();
  }

  static Future<void> bumpRevision() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(revisionKey) ?? 0) + 1;
    await prefs.setInt(revisionKey, next);
    instance.isSyncing = true;
    instance.notifyListeners();
    instance.syncGeneration++;
    instance._lastFingerprint = await instance._computeFingerprint();
    instance.isSyncing = false;
    instance.notifyListeners();
  }

  static Future<String> fingerprintForTests() => instance._computeFingerprint();

  static void resetForTests() {
    instance._timer?.cancel();
    _instance = LiveSyncService._();
  }

  Future<String> _computeFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getStringList('bookings') ?? [];
    final requests = prefs.getStringList('requests') ?? [];
    final feed = prefs.getString('admin_operations_feed_v1') ?? '';
    final notifications = prefs.getStringList('notifications') ?? [];
    final rev = prefs.getInt(revisionKey) ?? 0;
    return [
      rev,
      bookings.length,
      requests.length,
      bookings.isNotEmpty ? bookings.last : '',
      requests.isNotEmpty ? requests.last : '',
      feed.length,
      notifications.length,
      notifications.isNotEmpty ? notifications.first : '',
    ].join('::');
  }
}
