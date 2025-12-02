import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationConfig {
  //* Singleton pattern — ensures only one instance exists throughout app

  static final NotificationConfig _instance = NotificationConfig._internal();
  factory NotificationConfig() => _instance;
  NotificationConfig._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //* Initialize notification settings
  Future<void> init(BuildContext context) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // CustomSnackBar.show(
    //   context: context,
    //   icon: Icons.notifications,
    //   title: "Notifications Initialized",
    // );
  }

  //* Show an instant notification
  Future<void> showInstantNotification(
      {required String receiver,
      required String message,
      required String id}) async {
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notification_channel_id',
        'Instant Notifications',
        channelDescription: 'Instant notification channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          message,
          contentTitle: receiver,
          htmlFormatContent: true,
          htmlFormatTitle: true,
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id.hashCode,
      receiver,
      message,
      notificationDetails,
    );
  }

  // //* Schedule a notification
  // Future<void> scheduleReminder(
  //     {required PushNotificationModel notify, required int hours}) async {
  //   TZDateTime now = TZDateTime.now(local);
  //   TZDateTime scheduledDate = now.add(
  //     Duration(seconds: hours),
  //   );

  //   await _notificationsPlugin.zonedSchedule(
  //       int.parse(notify.id),
  //       notify.title,
  //       notify.body,
  //       scheduledDate,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //             'daily_reminder_channel_id', 'Daily Reminders',
  //             channelDescription: 'Reminder for tracked medicines',
  //             importance: Importance.max,
  //             priority: Priority.high,
  //             icon: '@mipmap/ic_launcher',
  //             styleInformation: BigTextStyleInformation(
  //               notify.body,
  //               contentTitle: notify.title,
  //               htmlFormatContent: true,
  //               htmlFormatTitle: true,
  //             )), // AndroidNotificationDetails
  //         iOS: DarwinNotificationDetails(),
  //       ), // NotificationDetails
  //       androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  //       matchDateTimeComponents:
  //           DateTimeComponents.dayOfWeekAndTime, // or dateAndTime,
  //       uiLocalNotificationDateInterpretation:
  //           UILocalNotificationDateInterpretation.absoluteTime);
  // }

  //* Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  //* Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
