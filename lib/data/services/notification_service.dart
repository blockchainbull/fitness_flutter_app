// lib/data/services/notification_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import your app screens for navigation
import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/features/notifications/screens/notifications_screen.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String backendUrl = 'https://health-ai-backend-i28b.onrender.com';
  
  // ⭐ Global navigator key - allows navigation from background notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
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

  // Handle notification tap with proper navigation
  void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload);
      final String type = data['type'] ?? '';
      final String userId = data['user_id'] ?? '';
      final String? notificationId = data['notification_id'];
      
      print('📱 Notification tapped - Type: $type, User: $userId');
      
      // Mark notification as read if we have the ID
      if (notificationId != null) {
        markAsRead(notificationId);
      }
      
      // Navigate based on notification type
      _handleNotificationNavigation(type, data);
      
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  // ⭐ FIXED: Handle navigation with proper UserProfile loading
  void _handleNotificationNavigation(String type, Map<String, dynamic> data) async {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Navigation context not available');
      return;
    }

    // Load user profile from SharedPreferences
    UserProfile? userProfile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final profileJson = prefs.getString('user_profile');
      
      if (userId != null && profileJson != null) {
        userProfile = UserProfile.fromMap(jsonDecode(profileJson));
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }

    if (userProfile == null) {
      print('❌ User profile not found, cannot navigate');
      // Just open notifications screen as fallback
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const NotificationsScreen(),
        ),
      );
      return;
    }

    // Navigate based on notification type
    switch (type.toLowerCase()) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
      case 'snack':
      case 'meal':
        // Navigate to meal logging screen with userProfile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnhancedMealLoggingPage(
              userProfile: userProfile!,
            ),
          ),
        );
        break;
        
      case 'exercise':
      case 'workout':
      case 'water':
      case 'sleep':
      case 'supplement':
      case 'supplements':
      case 'weight':
        // Navigate to activity logging menu with userProfile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityLoggingMenu(
              userProfile: userProfile!,
            ),
          ),
        );
        break;
        
      case 'steps_50':
      case 'steps_100':
      case 'milestone':
        // Just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${data['title'] ?? 'Milestone achieved!'}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        break;
        
      default:
        // Default: navigate to notifications screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
        break;
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
        activityType: mealTime['name'].toLowerCase(),
        userId: userId,
      );
    }
  }

  List<Map<String, dynamic>> _getMealTimes(int mealsPerDay) {
    if (mealsPerDay == 6) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Snack 1', 'hour': 10, 'minute': 30},
        {'name': 'Lunch', 'hour': 13, 'minute': 0},
        {'name': 'Snack 2', 'hour': 15, 'minute': 30},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
        {'name': 'Snack 3', 'hour': 21, 'minute': 0},
      ];
    } else if (mealsPerDay == 5) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Snack 1', 'hour': 10, 'minute': 30},
        {'name': 'Lunch', 'hour': 13, 'minute': 0},
        {'name': 'Snack 2', 'hour': 16, 'minute': 0},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    } else if (mealsPerDay == 4) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Lunch', 'hour': 12, 'minute': 30},
        {'name': 'Snack', 'hour': 15, 'minute': 30},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    } else {
      // Default 3 meals
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Lunch', 'hour': 13, 'minute': 0},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    }
  }

  // EXERCISE NOTIFICATION - Once a day
  Future<void> scheduleExerciseNotification(String userId) async {
    await _scheduleSmartNotification(
      id: exerciseNotificationId,
      title: '💪 Exercise Reminder',
      body: 'Don\'t forget to log your workout for today!',
      hour: 18,
      minute: 0,
      activityType: 'exercise',
      userId: userId,
    );
  }

  // WATER NOTIFICATIONS - 2 times, 6 hours apart
  Future<void> scheduleWaterNotifications(String userId) async {
    await _scheduleSmartNotification(
      id: waterNotificationId1,
      title: '💧 Hydration Check',
      body: 'Remember to log your water intake!',
      hour: 10,
      minute: 0,
      activityType: 'water',
      userId: userId,
    );
    
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

  // SUPPLEMENT NOTIFICATION
  Future<void> scheduleSupplementNotification(String userId) async {
    await _scheduleSmartNotification(
      id: supplementNotificationId,
      title: '💊 Supplement Reminder',
      body: 'Time to take your supplements!',
      hour: 8,
      minute: 30,
      activityType: 'supplement',
      userId: userId,
    );
  }

  // WEIGHT NOTIFICATION - Weekly
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

  // Smart notification that logs to database when scheduled
  Future<void> _scheduleSmartNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String activityType,
    required String userId,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
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

    // Log to database FIRST to get notification ID
    final notificationId = await _logNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: activityType,
    );

    // Schedule with notification ID in payload
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Reminders to log your daily activities',
          importance: Importance.high,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': activityType,
        'user_id': userId,
        'title': title,
        'body': body,
        'notification_id': notificationId,
      }),
    );

    print('✅ Scheduled $activityType notification for $hour:${minute.toString().padLeft(2, '0')}');
  }

  // Helper method for weekly notifications
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    var scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, hour, minute);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Weekly reminders',
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // MILESTONE NOTIFICATIONS
  Future<void> checkStepMilestone({
    required int currentSteps,
    required int goalSteps,
    required String userId,
  }) async {
    if (goalSteps == 0) return;

    final double progress = (currentSteps / goalSteps) * 100;

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
        'title': title,
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

  // Log notification to database and return ID
  Future<String?> _logNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/notifications/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'message': body,
          'type': type,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationId = data['notification']?['id'];
        print('✅ Notification logged to DB with ID: $notificationId');
        return notificationId;
      }
      
      return null;
    } catch (e) {
      print('❌ Error logging notification: $e');
      return null;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$backendUrl/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await http.put(
        Uri.parse('$backendUrl/notifications/$userId/mark-all-read'),
        headers: {'Content-Type': 'application/json'},
      );
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await http.delete(
        Uri.parse('$backendUrl/notifications/$notificationId'),
        headers: {'Content-Type': 'application/json'},
      );
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
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

  // ⭐ FIXED: Renamed from showTestNotification to showImmediateNotification
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notification channel',
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

  // Also keep the old name for compatibility
  Future<void> showTestNotification() async {
    await showImmediateNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'If you see this, notifications are working!',
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

  // Get unread notification count
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

  // Get all notifications
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