import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'data_service.dart';
import '../config/app_config.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const int _promoBaseId = 8000;
  static const int _promoCount = 84; // 2-hour promos for 7 days

  static Future<void> initialize() async {
    try {
      if (AppConfig.demoMode) {
        debugPrint('Push notifications skipped in demo mode.');
        return;
      }
      // 1. Request Permission
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // 2. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Configure Local Notifications for Foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsIOS);

      await _localNotificationsPlugin.initialize(initializationSettings);
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

      // 4. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // 5. Get FCM Token if Firebase Installations is ready
      try {
        final String? token = await _messaging.getToken();
        debugPrint("FCM Token: $token");
      } catch (e) {
        debugPrint('FCM token unavailable right now: $e');
      }

      await _schedulePromotions();
      // In a real app, save this token to the user's document in Firestore.
    } catch (e) {
      debugPrint('Push notifications disabled for now: $e');
    }
  }

  static Future<void> _schedulePromotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('promo_notifications_scheduled') == true) {
        await _cancelPromoNotifications();
      }

      final properties = await DataService.getAllProperties(approvedOnly: false);
      final propertyCount = properties.length;
      final now = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));
      final messages = <Map<String, String>>[
        {
          'title': 'عرض جديد على إيجاري',
          'body': 'استكشف وحدات وعروض جديدة قبل ما تخلص بسرعة.'
        },
        {
          'title': 'خدمة مفيدة لك',
          'body': 'فعّل التذكيرات وخلّي متابعة الإيجار أسهل وأوضح.'
        },
        {
          'title': 'عقارات جديدة انضافت',
          'body': 'تمت إضافة $propertyCount عقار/وحدة داخل المنصة مؤخرًا.'
        },
        {
          'title': 'خصم أوفر',
          'body': 'تابع العروض الحالية وقد تلاقي سعر أفضل في منطقتك.'
        },
        {
          'title': 'متابعة عقدك',
          'body': 'راجع الأقساط والدفعات القادمة من شاشة الكشوفات.'
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      await prefs.setBool('promo_notifications_scheduled', true);
    } catch (e) {
      debugPrint('Promo notifications scheduling failed: $e');
    }
  }

  static Future<void> _cancelPromoNotifications() async {
    for (var i = 0; i < _promoCount; i++) {
      await _localNotificationsPlugin.cancel(_promoBaseId + i);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }
}
