import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Conditional import: uses the stub on non-web, and the real dart:js version on web.
import 'notification_service_stub.dart'
    if (dart.library.js) 'notification_service_web.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) {
      initWebNotifications();
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      await _notificationsPlugin.initialize(initializationSettings);

      // Request notification permission on Android 13+ (API 33+).
      // Without this runtime request, notifications are silently blocked.
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      print('Local notification initialization failed: $e');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (kIsWeb) {
      showWebNotification(title, body);
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reviews_channel_id',
      'Review Notifications',
      channelDescription: 'Notifikasi ketika postingan review game berhasil dikirim',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }
}
