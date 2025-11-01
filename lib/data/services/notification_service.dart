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
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'health_ai_notifications', // id
        'Health AI Notifications', // name
        description: 'Reminders for meals, exercise, water, and more',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImplementation?.createNotificationChannel(channel);

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

  // Request permissions (especially for Android 13+)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation
              <AndroidFlutterLocalNotificationsPlugin>();

      // For Android 13+ (API level 33+), request notification permission
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
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
  }

  // MEAL NOTIFICATIONS
  Future<void> scheduleMealNotifications(String userId, Map<String, dynamic> userProfile) async {
    final int mealsPerDay = userProfile['daily_meals_count'] ?? 3;
    
    // Typical meal times based on meals per day
    List<Map<String, dynamic>> mealTimes = _getMealTimes(mealsPerDay);
    
    for (int i = 0; i < mealTimes.length; i++) {
      final mealTime = mealTimes[i];
      await _scheduleDailyNotification(
        id: mealNotificationIdBase + i,
        title: '🍽️ ${mealTime['name']} Reminder',
        body: 'Don\'t forget to log your ${mealTime['name'].toLowerCase()}!',
        hour: mealTime['hour'],
        minute: mealTime['minute'],
        payload: jsonEncode({
          'type': 'meal',
          'meal_type': mealTime['type'],
          'user_id': userId,
        }),
      );
    }
  }

  List<Map<String, dynamic>> _getMealTimes(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2: // Intermittent fasting style
        return [
          {'name': 'Lunch', 'type': 'lunch', 'hour': 12, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
        ];
      case 3: // Standard 3 meals
        return [
          {'name': 'Breakfast', 'type': 'breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'type': 'lunch', 'hour': 13, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
        ];
      case 4: // 3 meals + snack
        return [
          {'name': 'Breakfast', 'type': 'breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'type': 'lunch', 'hour': 13, 'minute': 0},
          {'name': 'Snack', 'type': 'snack', 'hour': 16, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
        ];
      case 5: // 3 meals + 2 snacks
        return [
          {'name': 'Breakfast', 'type': 'breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Morning Snack', 'type': 'snack', 'hour': 10, 'minute': 30},
          {'name': 'Lunch', 'type': 'lunch', 'hour': 13, 'minute': 0},
          {'name': 'Afternoon Snack', 'type': 'snack', 'hour': 16, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
        ];
      case 6: // Bodybuilder style - 3 meals + 3 snacks
        return [
          {'name': 'Breakfast', 'type': 'breakfast', 'hour': 7, 'minute': 0},
          {'name': 'Morning Snack', 'type': 'snack', 'hour': 10, 'minute': 0},
          {'name': 'Lunch', 'type': 'lunch', 'hour': 13, 'minute': 0},
          {'name': 'Afternoon Snack', 'type': 'snack', 'hour': 16, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
          {'name': 'Evening Snack', 'type': 'snack', 'hour': 21, 'minute': 0},
        ];
      default:
        return [
          {'name': 'Breakfast', 'type': 'breakfast', 'hour': 8, 'minute': 0},
          {'name': 'Lunch', 'type': 'lunch', 'hour': 13, 'minute': 0},
          {'name': 'Dinner', 'type': 'dinner', 'hour': 19, 'minute': 0},
        ];
    }
  }

  // EXERCISE NOTIFICATION (Once per day)
  Future<void> scheduleExerciseNotification(String userId) async {
    // Schedule for 6 PM every day
    await _scheduleDailyNotification(
      id: exerciseNotificationId,
      title: '💪 Exercise Reminder',
      body: 'Time to get moving! Have you logged your workout today?',
      hour: 18,
      minute: 0,
      payload: jsonEncode({
        'type': 'exercise',
        'user_id': userId,
      }),
    );
  }

  // WATER NOTIFICATIONS (2 times, 6 hours apart)
  Future<void> scheduleWaterNotifications(String userId) async {
    // First reminder at 10 AM
    await _scheduleDailyNotification(
      id: waterNotificationId1,
      title: '💧 Water Reminder',
      body: 'Stay hydrated! Have you logged your water intake today?',
      hour: 10,
      minute: 0,
      payload: jsonEncode({
        'type': 'water',
        'user_id': userId,
      }),
    );

    // Second reminder at 4 PM (6 hours later)
    await _scheduleDailyNotification(
      id: waterNotificationId2,
      title: '💧 Water Reminder',
      body: 'Don\'t forget to drink water and log it!',
      hour: 16,
      minute: 0,
      payload: jsonEncode({
        'type': 'water',
        'user_id': userId,
      }),
    );
  }

  // SLEEP NOTIFICATION (1.5 hours after wake time)
  Future<void> scheduleSleepNotification(String userId, Map<String, dynamic> userProfile) async {
    final String? wakeupTime = userProfile['wakeup_time'];
    
    if (wakeupTime == null) {
      // Default to 9:30 AM if no wake time set
      await _scheduleDailyNotification(
        id: sleepNotificationId,
        title: '😴 Sleep Log Reminder',
        body: 'How did you sleep last night? Log your sleep now!',
        hour: 9,
        minute: 30,
        payload: jsonEncode({
          'type': 'sleep',
          'user_id': userId,
        }),
      );
      return;
    }

    // Parse wake time (format: "HH:mm" or "HH:mm:ss")
    try {
      final timeParts = wakeupTime.split(':');
      final int wakeHour = int.parse(timeParts[0]);
      final int wakeMinute = int.parse(timeParts[1]);
      
      // Add 1.5 hours (90 minutes)
      int notificationHour = wakeHour + 1;
      int notificationMinute = wakeMinute + 30;
      
      // Handle minute overflow
      if (notificationMinute >= 60) {
        notificationHour += 1;
        notificationMinute -= 60;
      }
      
      // Handle hour overflow
      if (notificationHour >= 24) {
        notificationHour -= 24;
      }
      
      await _scheduleDailyNotification(
        id: sleepNotificationId,
        title: '😴 Sleep Log Reminder',
        body: 'How did you sleep last night? Log your sleep now!',
        hour: notificationHour,
        minute: notificationMinute,
        payload: jsonEncode({
          'type': 'sleep',
          'user_id': userId,
        }),
      );
    } catch (e) {
      print('Error parsing wake time: $e');
      // Fallback to default time
      await _scheduleDailyNotification(
        id: sleepNotificationId,
        title: '😴 Sleep Log Reminder',
        body: 'How did you sleep last night? Log your sleep now!',
        hour: 9,
        minute: 30,
        payload: jsonEncode({
          'type': 'sleep',
          'user_id': userId,
        }),
      );
    }
  }

  // SUPPLEMENT NOTIFICATION (Once per day)
  Future<void> scheduleSupplementNotification(String userId) async {
    // Schedule for 9 AM every day
    await _scheduleDailyNotification(
      id: supplementNotificationId,
      title: '💊 Supplement Reminder',
      body: 'Time to take your supplements! Don\'t forget to log them.',
      hour: 9,
      minute: 0,
      payload: jsonEncode({
        'type': 'supplement',
        'user_id': userId,
      }),
    );
  }

  // WEIGHT NOTIFICATION (Once per week - Every Monday)
  Future<void> scheduleWeightNotification(String userId) async {
    // Schedule for Monday at 8:00 AM
    await _scheduleWeeklyNotification(
      id: weightNotificationId,
      title: '⚖️ Weekly Weight Check',
      body: 'Time for your weekly weigh-in! Track your progress.',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 0,
      payload: jsonEncode({
        'type': 'weight',
        'user_id': userId,
      }),
    );
  }

  // Helper method to schedule daily notifications
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // Schedule the notification
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
      payload: payload,
    );

    // Log to database when scheduled
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        await _logNotificationToDatabase(
          userId: data['user_id'],
          title: title,
          body: body,
          type: data['type'],
        );
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }

  // Helper method to schedule weekly notifications
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
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
          'health_ai_notifications',
          'Health AI Notifications',
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

    // Add days until we reach the desired weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled time has passed for this week, move to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Check if activity is logged for today
  Future<bool> isActivityLoggedToday(String userId, String activityType) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('https://health-ai-backend-i28b.onrender.com/api/health/check-activity/$userId/$activityType?date=$dateStr'),
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

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Show immediate notification (for testing)
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
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications channel',
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