import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> showLimitExceededNotification(
    double limit,
    double currentTotal,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'expense_alerts',
          'Expense Alerts',
          channelDescription: 'Notifications for monthly limits',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Monthly Limit Exceeded!',
      body:
          'You have exceeded your monthly limit of ₹${limit.toStringAsFixed(0)}. Current total: ₹${currentTotal.toStringAsFixed(0)}',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleBillReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'bill_reminders',
          'Bill Reminders',
          channelDescription: 'Notifications for upcoming bills',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Don't schedule if the date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('Failed to schedule bill reminder notification: $e');
    }
  }

  Future<void> scheduleDailyTenPMReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily 10 PM reminder to log expenses',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 100, // Fixed ID for daily reminder
        title: 'How much did you spend today? 💸',
        body: 'Take 10 seconds to add your daily expenses before the day ends!',
        scheduledDate: _nextInstanceOfTenPM(),
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // Matches the time every day
      );
    } catch (e) {
      print('Failed to schedule daily reminder notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTenPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> showLocationBasedExpenseReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'location_reminders',
          'Location Reminders',
          channelDescription: 'Reminders when leaving a store',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 200, // Fixed ID
      title: 'Did you just make a purchase? 🛒',
      body: 'You are on the move! Tap here to quickly log any expenses.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
