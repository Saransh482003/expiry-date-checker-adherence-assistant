import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    AndroidInitializationSettings androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    
    DarwinInitializationSettings iosSettings = const DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'medicine_reminder',
      'Medicine Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }
}