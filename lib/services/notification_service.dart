import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          """
          window.showWebNotification = function(title, body) {
            if (Notification.permission === 'granted') {
              try {
                new Notification(title, { body: body });
              } catch (e) {
                console.error('Notification creation failed:', e);
              }
            } else if (Notification.permission !== 'denied') {
              Notification.requestPermission().then(function(permission) {
                if (permission === 'granted') {
                  new Notification(title, { body: body });
                }
              });
            }
          };
          if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
            Notification.requestPermission();
          }
          """
        ]);
      } catch (e) {
        print('Web Notification init error: $e');
      }
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('Local notification initialization failed: $e');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (kIsWeb) {
      try {
        js.context.callMethod('showWebNotification', [title, body]);
      } catch (e) {
        print('Web Notification error: $e');
      }
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
