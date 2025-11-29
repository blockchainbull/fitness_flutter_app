// lib/data/services/daily_notification_scheduler.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

class DailyNotificationScheduler {
  static const String backendUrl = 'https://health-ai-backend.onrender.com';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Schedule all daily notifications for a user
  static Future<void> scheduleDailyNotifications(String userId) async {
    print('📅 Scheduling daily notifications for user: $userId');

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get user's meal times (default if not set)
      final breakfastTime = prefs.getString('breakfast_time') ?? '08:00';
      final lunchTime = prefs.getString('lunch_time') ?? '12:30';
      final dinnerTime = prefs.getString('dinner_time') ?? '19:00';
      
      // Get user's preferences
      final waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? true;
      final supplementReminderEnabled = prefs.getBool('supplement_reminder_enabled') ?? true;
      final sleepReminderEnabled = prefs.getBool('sleep_reminder_enabled') ?? true;

      // Cancel all existing notifications
      await _notificationsPlugin.cancelAll();

      // Schedule Breakfast Reminder
      await _scheduleNotification(
        id: 1,
        title: '🍳 Breakfast Reminder',
        body: 'Time to log your breakfast!',
        hour: int.parse(breakfastTime.split(':')[0]),
        minute: int.parse(breakfastTime.split(':')[1]),
        userId: userId,
        type: 'breakfast',
      );

      // Schedule Lunch Reminder
      await _scheduleNotification(
        id: 2,
        title: '🍽️ Lunch Reminder',
        body: 'Time to log your lunch!',
        hour: int.parse(lunchTime.split(':')[0]),
        minute: int.parse(lunchTime.split(':')[1]),
        userId: userId,
        type: 'lunch',
      );

      // Schedule Dinner Reminder
      await _scheduleNotification(
        id: 3,
        title: '🌙 Dinner Reminder',
        body: 'Time to log your dinner!',
        hour: int.parse(dinnerTime.split(':')[0]),
        minute: int.parse(dinnerTime.split(':')[1]),
        userId: userId,
        type: 'dinner',
      );

      // Schedule Water Reminders (every 2 hours from 9 AM to 9 PM)
      if (waterReminderEnabled) {
        int waterNotifId = 10;
        for (int hour = 9; hour <= 21; hour += 2) {
          await _scheduleNotification(
            id: waterNotifId++,
            title: '💧 Hydration Check',
            body: 'Remember to log your water intake!',
            hour: hour,
            minute: 0,
            userId: userId,
            type: 'hydration',
          );
        }
      }

      // Schedule Supplement Reminder
      if (supplementReminderEnabled) {
        final supplementTime = prefs.getString('supplement_time') ?? '09:00';
        await _scheduleNotification(
          id: 20,
          title: '💊 Supplement Reminder',
          body: 'Time to take your supplements!',
          hour: int.parse(supplementTime.split(':')[0]),
          minute: int.parse(supplementTime.split(':')[1]),
          userId: userId,
          type: 'supplement',
        );
      }

      // Schedule Sleep Log Reminder (evening)
      if (sleepReminderEnabled) {
        await _scheduleNotification(
          id: 30,
          title: '😴 Sleep Log Reminder',
          body: 'How was your sleep last night? Log it now!',
          hour: 8,
          minute: 0,
          userId: userId,
          type: 'sleep',
        );
      }

      print('✅ All daily notifications scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling daily notifications: $e');
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String userId,
    required String type,
  }) async {
    try {
      // Calculate notification time for today
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            '${type}_channel',
            '${type.substring(0, 1).toUpperCase()}${type.substring(1)} Notifications',
            channelDescription: '$type notification channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Log to backend
      await _logNotificationToBackend(
        userId: userId,
        title: title,
        message: body,
        type: type,
      );

      print('✅ Scheduled $type notification (ID: $id) for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Error scheduling notification $id: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  static Future<void> _logNotificationToBackend({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/notifications/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
        }),
      );
    } catch (e) {
      print('❌ Error logging notification to backend: $e');
    }
  }

  // Update notification schedules when user changes preferences
  static Future<void> updateSchedules(String userId) async {
    await scheduleDailyNotifications(userId);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🔕 All notifications cancelled');
  }
}