import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'data_service.dart';
import 'auth_service.dart';
import 'subscription_service.dart';
import 'deep_link_service.dart';
import '../config/app_config.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

/// فئات الإشعارات القابلة للتفعيل من الإعدادات.
enum PushNotificationCategory {
  paymentOverdue('payment_overdue', 'دفعات متأخرة'),
  subscriptionExpiring('subscription_expiring', 'انتهاء الاشتراك'),
  bookingCheckIn('booking_checkin', 'موعد الدخول'),
  newBookingRequest('new_booking', 'طلبات حجز جديدة'),
  promotions('promotions', 'العروض والترويج');

  const PushNotificationCategory(this.key, this.labelAr);
  final String key;
  final String labelAr;
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const int _promoBaseId = 8000;
  static const int _promoCount = 84;

  static const int _idPaymentOverdueTenant = 1001;
  static const int _idPaymentOverdueOwner = 1002;
  static const int _idSubscriptionExpiring = 1003;
  static const int _idBookingCheckIn = 1004;
  static const int _idNewBookingRequest = 1005;

  static const String _enabledKey = 'notifications_enabled';
  static const String _demoScheduledKey = 'demo_reminders_scheduled_v1';

  static DeepLinkTarget? Function(String? payload)? _onNotificationTap;

  static Future<void> initialize({
    DeepLinkTarget? Function(String? payload)? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    try {
      await _initLocalNotifications();

      if (!await isEnabled()) {
        debugPrint('Push notifications disabled by user preference.');
        return;
      }

      if (!AppConfig.demoMode) {
        await _initFirebaseMessaging();
      } else {
        debugPrint('Demo mode: local notifications only (FCM skipped).');
      }

      await scheduleDemoReminders();
    } catch (e) {
      debugPrint('Push notifications init failed: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
  }

  static Future<void> _initFirebaseMessaging() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted FCM permission');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.hashCode,
          message.notification?.title,
          message.notification?.body,
        );
      }
    });

    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('FCM token unavailable: $e');
    }

    if (await isCategoryEnabled(PushNotificationCategory.promotions)) {
      await _schedulePromotions();
    }
  }

  /// جدولة تنبيهات تجريبية للعرض (محلية).
  static Future<void> scheduleDemoReminders() async {
    if (!await isEnabled()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_demoScheduledKey) == true) {
        await _cancelDemoReminders();
      }

      final now = tz.TZDateTime.now(tz.local);
    final base = now.add(const Duration(minutes: 2));

    if (await isCategoryEnabled(PushNotificationCategory.paymentOverdue)) {
      await _scheduleZoned(
        _idPaymentOverdueTenant,
        base,
        'دفعة متأخرة 💳',
        'يرجى سداد قسط الإيجار في أقرب وقت — تنبيه للمستأجر',
        'reminders_channel',
        payload: 'payment:demo_req_1',
      );
      await _scheduleZoned(
        _idPaymentOverdueOwner,
        base.add(const Duration(minutes: 1)),
        'مستأجر متأخر في الدفع ⚠️',
        'أحد مستأجرينك متأخر في السداد — تنبيه للمالك',
        'reminders_channel',
        payload: 'payment:demo_req_1',
      );
    }

    if (await isCategoryEnabled(PushNotificationCategory.subscriptionExpiring)) {
      final days = await SubscriptionService.getDaysUntilExpiry();
      await _scheduleZoned(
        _idSubscriptionExpiring,
        base.add(const Duration(minutes: 2)),
        'اشتراكك ينتهي قريباً 📅',
        days != null
            ? 'باقتك تنتهي خلال $days أيام — جدّد الآن'
            : 'باقتك تنتهي خلال 7 أيام — جدّد الآن',
        'reminders_channel',
        payload: 'subscription',
      );
    }

    if (await isCategoryEnabled(PushNotificationCategory.bookingCheckIn)) {
      await _scheduleZoned(
        _idBookingCheckIn,
        base.add(const Duration(minutes: 3)),
        'موعد الدخول قريب 🏠',
        'حجزك يبدأ خلال 3 أيام — جهّز مستنداتك',
        'reminders_channel',
        payload: 'booking:demo_flow_bed_1',
      );
    }

    if (await isCategoryEnabled(PushNotificationCategory.newBookingRequest)) {
      await _scheduleZoned(
        _idNewBookingRequest,
        base.add(const Duration(minutes: 4)),
        'طلب حجز جديد 📩',
        'مستأجر جديد يريد حجز وحدتك — راجع الطلب',
        'reminders_channel',
        payload: 'booking:demo_req_1',
      );
    }

    if (await isCategoryEnabled(PushNotificationCategory.promotions) &&
        AppConfig.demoMode) {
      await _schedulePromotions();
    }

    await prefs.setBool(_demoScheduledKey, true);
    } catch (e) {
      debugPrint('Demo reminders scheduling skipped: $e');
    }
  }

  static Future<void> _scheduleZoned(
    int id,
    tz.TZDateTime when,
    String title,
    String body,
    String channelId, {
    String? payload,
  }) async {
    try {
      await _localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Ejari Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Zoned schedule skipped: $e');
    }
  }

  static Future<void> _schedulePromotions() async {
    try {
      final properties =
          await DataService.getAllProperties(approvedOnly: false);
      final propertyCount = properties.length;
      final now = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
      final messages = <Map<String, String>>[
        {
          'title': 'عرض جديد على إيجاري',
          'body': 'استكشف وحدات وعروض جديدة قبل ما تخلص بسرعة.',
        },
        {
          'title': 'خدمة مفيدة لك',
          'body': 'فعّل التذكيرات وخلّي متابعة الإيجار أسهل وأوضح.',
        },
        {
          'title': 'عقارات جديدة انضافت',
          'body': 'تمت إضافة $propertyCount عقار/وحدة داخل المنصة مؤخرًا.',
        },
      ];

      for (var i = 0; i < _promoCount; i++) {
        final scheduledTime = now.add(Duration(hours: i * 2));
        final message = messages[i % messages.length];
        await _localNotificationsPlugin.zonedSchedule(
          _promoBaseId + i,
          message['title'],
          message['body'],
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'promo_channel',
              'Promotions',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Promo notifications scheduling failed: $e');
    }
  }

  static Future<void> _cancelPromoNotifications() async {
    try {
      for (var i = 0; i < _promoCount; i++) {
        await _localNotificationsPlugin.cancel(_promoBaseId + i);
      }
    } catch (e) {
      debugPrint('Cancel promo notifications skipped: $e');
    }
  }

  static Future<void> _cancelDemoReminders() async {
    try {
      for (final id in [
        _idPaymentOverdueTenant,
        _idPaymentOverdueOwner,
        _idSubscriptionExpiring,
        _idBookingCheckIn,
        _idNewBookingRequest,
      ]) {
        await _localNotificationsPlugin.cancel(id);
      }
    } catch (e) {
      debugPrint('Cancel demo reminders skipped: $e');
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) {
      await _cancelPromoNotifications();
      await _cancelDemoReminders();
      await prefs.setBool(_demoScheduledKey, false);
      await prefs.setBool('promo_notifications_scheduled', false);
    } else {
      await scheduleDemoReminders();
    }
  }

  static String _categoryKey(PushNotificationCategory cat) =>
      'notif_cat_${cat.key}';

  static Future<bool> isCategoryEnabled(PushNotificationCategory cat) async {
    if (!await isEnabled()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_categoryKey(cat)) ?? true;
  }

  static Future<void> setCategoryEnabled(
    PushNotificationCategory cat,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_categoryKey(cat), enabled);
    await prefs.setBool(_demoScheduledKey, false);
    if (await isEnabled()) {
      await scheduleDemoReminders();
    }
  }

  static Future<Map<PushNotificationCategory, bool>>
      getCategoryStates() async {
    final map = <PushNotificationCategory, bool>{};
    for (final cat in PushNotificationCategory.values) {
      map[cat] = await isCategoryEnabled(cat);
    }
    return map;
  }

  /// إعادة جدولة بعد تسجيل الدخول (حسب دور المستخدم).
  static Future<void> refreshForCurrentUser() async {
    if (!await isEnabled()) return;
    final user = await AuthService.getCurrentUser();
    final role = user?['role']?.toString() ?? 'tenant';
    debugPrint('Rescheduling push reminders for role: $role');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoScheduledKey, false);
    await scheduleDemoReminders();
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final resolver = _onNotificationTap ?? DeepLinkService.parseNotificationPayload;
    final target = resolver(payload);
    if (target != null) {
      DeepLinkService.enqueue(target);
      DeepLinkService.processPending();
    }
  }

  /// للاختبار — يحاكي نقر إشعار مجدول.
  static Future<void> handleDemoTapPayload(String payload) async {
    _handleNotificationResponse(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    ));
  }

  static Future<void> _showLocalNotification(
    int id,
    String? title,
    String? body,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}
