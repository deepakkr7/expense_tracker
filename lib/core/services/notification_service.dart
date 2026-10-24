import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<bool> refreshTimeZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(zone.identifier);
      final changed = tz.local.name != location.name;
      tz.setLocalLocation(location);
      if (changed && await dailyEnabled()) await scheduleDailyTenPMReminder();
      return changed;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dailyEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(
        'daily_reminder_enabled',
      ) ??
      false;

  Future<bool> setDailyEnabled(bool enabled) async {
    if (enabled && !(await Permission.notification.request()).isGranted)
      return false;
    if (enabled) {
      await scheduleDailyTenPMReminder();
    } else {
      await cancelNotification(100);
    }
    await (await SharedPreferences.getInstance()).setBool(
      'daily_reminder_enabled',
      enabled,
    );
    return true;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
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
    bool requestPermission = true,
  }) async {
    final permission = requestPermission
        ? await Permission.notification.request()
        : await Permission.notification.status;
    if (!permission.isGranted) return;
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

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Notifications can be disabled in device settings.
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

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 100, // Fixed ID for daily reminder
      title: 'How much did you spend today? 💸',
      body: 'Take 10 seconds to add your daily expenses before the day ends!',
      scheduledDate: nextDailyReminder(tz.TZDateTime.now(tz.local)),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Matches the time every day
    );
  }

  static tz.TZDateTime nextDailyReminder(tz.TZDateTime now) {
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      22,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + 1,
        22,
      );
    }
    return scheduledDate;
  }

  Future<void> cancelAll() => _flutterLocalNotificationsPlugin.cancelAll();

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
