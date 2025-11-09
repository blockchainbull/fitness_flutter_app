// lib/services/notification_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String backendUrl = 'https://health-ai-backend-i28b.onrender.com';
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int mealNotificationIdBase = 1000; 
  static const int exerciseNotificationId = 2000;
  static const int waterNotificationId1 = 3000;
  static const int waterNotificationId2 = 3001;
  static const int sleepNotificationId = 4000;
  static const int supplementNotificationId = 5000;
  static const int weightNotificationId = 6000;
  static const int stepMilestone50Id = 7000;
  static const int stepMilestone100Id = 7001;

  // Track last step notification to prevent duplicates
  int? _lastStepCount50;
  int? _lastStepCount100;

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation
              <AndroidFlutterLocalNotificationsPlugin>();

      // Create main notification channel
      const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
        'activity_reminders',
        'Activity Reminders',
        description: 'Reminders to log your daily activities',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation?.createNotificationChannel(mainChannel);

      // Milestone notification channel
      const AndroidNotificationChannel milestoneChannel = AndroidNotificationChannel(
        'milestone_notifications',
        'Milestone Achievements',
        description: 'Notifications for reaching your fitness milestones',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation?.createNotificationChannel(milestoneChannel);

      // Create test notification channel
      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'Test notifications channel',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(testChannel);
    }
  }

  // Request permissions (especially for Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation
              <AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      
      // Also request exact alarm permission for Android 12+
      final bool? exactAlarmGranted = await androidImplementation?.requestExactAlarmsPermission();
      
      print('📱 Android notification permission: $granted');
      print('📱 Android exact alarm permission: $exactAlarmGranted');
      
      return granted ?? false;
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation
              <IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      print('📱 iOS notification permission: $granted');
      return granted ?? false;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    final String? payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      // Navigate based on notification type
      // You can use a navigation service or callback here
      print('Notification tapped: ${data['type']}');
    }
  }

  // Schedule all notifications for a user
  Future<void> scheduleAllNotifications(String userId, Map<String, dynamic> userProfile) async {
    print('📱 Scheduling all notifications for user: $userId');
    
    // Cancel all existing notifications first
    await cancelAllNotifications();
    
    // Schedule meal notifications
    await scheduleMealNotifications(userId, userProfile);
    
    // Schedule exercise notification
    await scheduleExerciseNotification(userId);
    
    // Schedule water notifications
    await scheduleWaterNotifications(userId);
    
    // Schedule sleep notification
    await scheduleSleepNotification(userId, userProfile);
    
    // Schedule supplement notification
    await scheduleSupplementNotification(userId);
    
    // Schedule weight notification (weekly)
    await scheduleWeightNotification(userId);
    
    print('✅ All notifications scheduled successfully');
  }

  // MEAL NOTIFICATIONS
  Future<void> scheduleMealNotifications(String userId, Map<String, dynamic> userProfile) async {
    final int mealsPerDay = userProfile['daily_meals_count'] ?? 3;
    
    List<Map<String, dynamic>> mealTimes = _getMealTimes(mealsPerDay);
    
    for (int i = 0; i < mealTimes.length; i++) {
      final mealTime = mealTimes[i];
      await _scheduleSmartNotification(
        id: mealNotificationIdBase + i,
        title: '🍽️ ${mealTime['name']} Reminder',
        body: 'Time to log your ${mealTime['name'].toLowerCase()}!',
        hour: mealTime['hour'],
        minute: mealTime['minute'],
        activityType: 'meal',
        userId: userId,
      );
    }
  }

  List<Map<String, dynamic>> _getMealTimes(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return [
          {'name': 'Breakfast', 'hour': 9, 'minute': 0},
          {'name': 'Dinner', 'hour': 19, 'minute': 0},
        ];
      case 3:
        return [
          {'name': 'Breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'hour': 13, 'minute': 0},
          {'name': 'Dinner', 'hour': 19, 'minute': 0},
        ];
      case 4:
        return [
          {'name': 'Breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'hour': 12, 'minute': 30},
          {'name': 'Snack', 'hour': 16, 'minute': 0},
          {'name': 'Dinner', 'hour': 19, 'minute': 30},
        ];
      case 5:
        return [
          {'name': 'Breakfast', 'hour': 7, 'minute': 30},
          {'name': 'Morning Snack', 'hour': 10, 'minute': 0},
          {'name': 'Lunch', 'hour': 13, 'minute': 0},
          {'name': 'Afternoon Snack', 'hour': 16, 'minute': 0},
          {'name': 'Dinner', 'hour': 19, 'minute': 0},
        ];
      case 6:
        return [
          {'name': 'Breakfast', 'hour': 7, 'minute': 0},
          {'name': 'Morning Snack', 'hour': 9, 'minute': 30},
          {'name': 'Lunch', 'hour': 12, 'minute': 0},
          {'name': 'Afternoon Snack', 'hour': 15, 'minute': 0},
          {'name': 'Dinner', 'hour': 18, 'minute': 30},
          {'name': 'Evening Snack', 'hour': 21, 'minute': 0},
        ];
      default:
        return [
          {'name': 'Breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'hour': 13, 'minute': 0},
          {'name': 'Dinner', 'hour': 19, 'minute': 0},
        ];
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Test notification',
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
      payload: payload,
    );
  }

  // EXERCISE NOTIFICATION - Once a day
  Future<void> scheduleExerciseNotification(String userId) async {
    await _scheduleSmartNotification(
      id: exerciseNotificationId,
      title: '💪 Exercise Reminder',
      body: 'Don\'t forget to log your workout for today!',
      hour: 18, // 6 PM
      minute: 0,
      activityType: 'exercise',
      userId: userId,
    );
  }

  // WATER NOTIFICATIONS - 2 times, 6 hours apart
  Future<void> scheduleWaterNotifications(String userId) async {
    // First water reminder at 10 AM
    await _scheduleSmartNotification(
      id: waterNotificationId1,
      title: '💧 Hydration Check',
      body: 'Remember to log your water intake!',
      hour: 10,
      minute: 0,
      activityType: 'water',
      userId: userId,
    );
    
    // Second water reminder at 4 PM (6 hours later)
    await _scheduleSmartNotification(
      id: waterNotificationId2,
      title: '💧 Stay Hydrated',
      body: 'Time to log your water intake again!',
      hour: 16,
      minute: 0,
      activityType: 'water',
      userId: userId,
    );
  }

  // SLEEP NOTIFICATION - 1.5 hours after wake up time
  Future<void> scheduleSleepNotification(String userId, Map<String, dynamic> userProfile) async {
    final String? wakeTime = userProfile['usual_wake_time'];
    
    if (wakeTime != null) {
      final timeParts = wakeTime.split(':');
      int wakeHour = int.parse(timeParts[0]);
      int wakeMinute = int.parse(timeParts[1]);
      
      // Add 1.5 hours (90 minutes)
      wakeMinute += 90;
      if (wakeMinute >= 60) {
        wakeHour += wakeMinute ~/ 60;
        wakeMinute = wakeMinute % 60;
      }
      
      await _scheduleSmartNotification(
        id: sleepNotificationId,
        title: '😴 Sleep Log Reminder',
        body: 'How was your sleep last night? Log it now!',
        hour: wakeHour,
        minute: wakeMinute,
        activityType: 'sleep',
        userId: userId,
      );
    } else {
      // Default to 9 AM if no wake time set
      await _scheduleSmartNotification(
        id: sleepNotificationId,
        title: '😴 Sleep Log Reminder',
        body: 'How was your sleep last night? Log it now!',
        hour: 9,
        minute: 0,
        activityType: 'sleep',
        userId: userId,
      );
    }
  }

  // SUPPLEMENT NOTIFICATION - Once a day
  Future<void> scheduleSupplementNotification(String userId) async {
    await _scheduleSmartNotification(
      id: supplementNotificationId,
      title: '💊 Supplement Reminder',
      body: 'Time to log your supplements!',
      hour: 8,
      minute: 30,
      activityType: 'supplement',
      userId: userId,
    );
  }

  // WEIGHT NOTIFICATION - Once a week (Monday morning)
  Future<void> scheduleWeightNotification(String userId) async {
    await _scheduleWeeklyNotification(
      id: weightNotificationId,
      title: '⚖️ Weekly Weigh-In',
      body: 'It\'s time for your weekly weigh-in! Track your progress.',
      dayOfWeek: DateTime.monday,
      hour: 7,
      minute: 0,
      payload: jsonEncode({
        'type': 'weight',
        'user_id': userId,
      }),
    );
  }

  // SMART NOTIFICATION - Checks if activity is logged before showing
  Future<void> _scheduleSmartNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String activityType,
    required String userId,
  }) async {
    // Schedule the notification with a repeating daily pattern
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Reminders to log your daily activities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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
      payload: jsonEncode({
        'type': activityType,
        'user_id': userId,
      }),
    );

    print('✅ Scheduled $activityType notification at $hour:${minute.toString().padLeft(2, '0')}');
  }

  // Helper method to schedule weekly notifications
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(dayOfWeek, hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Weekly reminders to track your progress',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
    
    print('✅ Scheduled weekly notification on day $dayOfWeek');
  }

  // Calculate next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Calculate next instance of a specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // STEP MILESTONE NOTIFICATIONS
  Future<void> checkAndNotifyStepMilestone(String userId, int currentSteps, int goalSteps) async {
    final progress = (currentSteps / goalSteps * 100).round();
    
    // Check 50% milestone
    if (progress >= 50 && progress < 100 && _lastStepCount50 != currentSteps) {
      _lastStepCount50 = currentSteps;
      await showMilestoneNotification(
        id: stepMilestone50Id,
        title: '🎯 Halfway There!',
        body: 'You\'ve reached 50% of your step goal! Keep going!',
        userId: userId,
        milestoneType: 'steps_50',
      );
    }
    
    // Check 100% milestone
    if (progress >= 100 && _lastStepCount100 != currentSteps) {
      _lastStepCount100 = currentSteps;
      await showMilestoneNotification(
        id: stepMilestone100Id,
        title: '🎉 Goal Achieved!',
        body: 'Congratulations! You\'ve reached your daily step goal!',
        userId: userId,
        milestoneType: 'steps_100',
      );
    }
  }

  Future<void> showMilestoneNotification({
    required int id,
    required String title,
    required String body,
    required String userId,
    required String milestoneType,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone_notifications',
          'Milestone Achievements',
          channelDescription: 'Notifications for reaching your fitness milestones',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': milestoneType,
        'user_id': userId,
      }),
    );

    // Log to database
    await _logNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: milestoneType,
    );
  }

  // Check if activity is logged for today
  Future<bool> isActivityLoggedToday(String userId, String activityType) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$backendUrl/api/health/check-activity/$userId/$activityType?date=$dateStr'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['logged'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking activity: $e');
      return false;
    }
  }

  // Method to log notifications to database when shown
  Future<void> _logNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/notifications/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'message': body,
          'type': type,
        }),
      );
    } catch (e) {
      print('Error logging notification: $e');
    }
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      999,
      '🧪 Test Notification',
      'If you see this, notifications are working!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Test notification',
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
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🔕 All notifications cancelled');
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Method to get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/notifications/unread-count/$userId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Method to mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await http.put(
        Uri.parse('$backendUrl/notifications/$notificationId/read'),
      );
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Method to get all notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/notifications/$userId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications']);
      }
      return [];
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }
}