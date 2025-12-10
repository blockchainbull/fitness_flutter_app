// lib/data/services/notification_service_MINIMAL.dart
// ⭐ MINIMAL VERSION - Guaranteed to work without crashes

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/features/notifications/screens/notifications_screen.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String backendUrl = 'https://health-ai-backend-i28b.onrender.com';
  
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

  Future<void> initialize() async {
    print('🔔 [INIT] Starting notification service initialization...');
    
    tz.initializeTimeZones();
    
    // Auto-detect timezone
    final String currentTimeZone = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      print('✅ [INIT] Timezone set to: $currentTimeZone');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('⚠️ [INIT] Using UTC timezone');
    }
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Create ONE main channel with correct settings
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'health_reminders',
            'Health Reminders',
            description: 'Daily health tracking reminders',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        
        print('✅ [INIT] Notification channel created');
      }
    }

    print('✅ [INIT] Notification service initialized');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      final exactAlarmGranted = await androidImpl?.requestExactAlarmsPermission();
      
      print('📱 Permissions - Notification: $granted, Exact Alarm: $exactAlarmGranted');
      return granted ?? false;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload);
      final String type = data['type'] ?? '';
      print('📱 Notification tapped - Type: $type');
      _handleNotificationNavigation(type, data);
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  void _handleNotificationNavigation(String type, Map<String, dynamic> data) async {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    UserProfile? userProfile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');
      if (profileJson != null) {
        userProfile = UserProfile.fromMap(jsonDecode(profileJson));
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }

    if (userProfile == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
      return;
    }

    switch (type.toLowerCase()) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
      case 'snack':
      case 'meal':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnhancedMealLoggingPage(userProfile: userProfile!),
          ),
        );
        break;
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityLoggingMenu(userProfile: userProfile!),
          ),
        );
        break;
    }
  }

  // ⭐ MINIMAL SCHEDULE - Only essential parameters, no complex styling
  Future<void> scheduleAllNotifications(String userId, Map<String, dynamic> userProfile) async {
    print('📱 [SCHEDULE] Starting for user: $userId');
    
    await cancelAllNotifications();
    
    await scheduleMealNotifications(userId, userProfile);
    await scheduleExerciseNotification(userId);
    await scheduleWaterNotifications(userId);
    await scheduleSleepNotification(userId, userProfile);
    await scheduleSupplementNotification(userId);
    
    final pending = await getPendingNotifications();
    print('✅ [SCHEDULE] Complete! ${pending.length} notifications scheduled');
  }

  Future<void> scheduleMealNotifications(String userId, Map<String, dynamic> userProfile) async {
    print('🍽️ [MEALS] Scheduling notifications');
    
    final int mealsPerDay = userProfile['daily_meals_count'] ?? 
                            userProfile['dailyMealsCount'] ?? 
                            3;
    
    List<Map<String, dynamic>> mealTimes = _getMealTimes(mealsPerDay);
    
    for (int i = 0; i < mealTimes.length; i++) {
      final mealTime = mealTimes[i];
      await _scheduleNotification(
        id: mealNotificationIdBase + i,
        title: '🍽️ ${mealTime['name']} Reminder',
        body: 'Time to log your ${mealTime['name'].toLowerCase()}!',
        hour: mealTime['hour'],
        minute: mealTime['minute'],
        userId: userId,
      );
    }
  }

  List<Map<String, dynamic>> _getMealTimes(int mealsPerDay) {
    if (mealsPerDay == 2) {
      return [
        {'name': 'First Meal', 'hour': 11, 'minute': 0},
        {'name': 'Second Meal', 'hour': 18, 'minute': 0},
      ];
    } else if (mealsPerDay == 3) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Lunch', 'hour': 13, 'minute': 0},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    } else if (mealsPerDay == 4) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Lunch', 'hour': 12, 'minute': 30},
        {'name': 'Snack', 'hour': 15, 'minute': 30},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    } else if (mealsPerDay >= 5) {
      return [
        {'name': 'Breakfast', 'hour': 8, 'minute': 0},
        {'name': 'Snack 1', 'hour': 10, 'minute': 30},
        {'name': 'Lunch', 'hour': 13, 'minute': 0},
        {'name': 'Snack 2', 'hour': 16, 'minute': 0},
        {'name': 'Dinner', 'hour': 19, 'minute': 0},
      ];
    }
    
    return [
      {'name': 'Breakfast', 'hour': 8, 'minute': 0},
      {'name': 'Lunch', 'hour': 13, 'minute': 0},
      {'name': 'Dinner', 'hour': 19, 'minute': 0},
    ];
  }

  Future<void> scheduleExerciseNotification(String userId) async {
    await _scheduleNotification(
      id: exerciseNotificationId,
      title: '💪 Exercise Reminder',
      body: 'Don\'t forget to log your workout!',
      hour: 18,
      minute: 0,
      userId: userId,
    );
  }

  Future<void> scheduleWaterNotifications(String userId) async {
    await _scheduleNotification(
      id: waterNotificationId1,
      title: '💧 Hydration Check',
      body: 'Remember to log your water intake!',
      hour: 10,
      minute: 0,
      userId: userId,
    );
    
    await _scheduleNotification(
      id: waterNotificationId2,
      title: '💧 Stay Hydrated',
      body: 'Time to log your water!',
      hour: 16,
      minute: 0,
      userId: userId,
    );
  }

  Future<void> scheduleSleepNotification(String userId, Map<String, dynamic> userProfile) async {
    await _scheduleNotification(
      id: sleepNotificationId,
      title: '😴 Sleep Log Reminder',
      body: 'How was your sleep last night?',
      hour: 9,
      minute: 0,
      userId: userId,
    );
  }

  Future<void> scheduleSupplementNotification(String userId) async {
    await _scheduleNotification(
      id: supplementNotificationId,
      title: '💊 Supplement Reminder',
      body: 'Time to take your supplements!',
      hour: 8,
      minute: 30,
      userId: userId,
    );
  }

  // ⭐ MINIMAL NOTIFICATION - Only required parameters
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String userId,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      print('⏰ [SCHEDULE] ID $id at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

      // ⭐ MINIMAL settings - only what's required
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'health_reminders',  // Use the channel we created
            'Health Reminders',
            channelDescription: 'Daily health tracking reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({'type': 'reminder', 'user_id': userId}),
      );

      // Log to database (non-blocking)
      _logNotificationToDatabase(
        userId: userId,
        title: title,
        body: body,
        type: 'reminder',
      ).catchError((e) => print('⚠️ DB log failed: $e'));

      print('✅ [SCHEDULE] ID $id scheduled successfully');
    } catch (e) {
      print('❌ [SCHEDULE ERROR] ID $id failed: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? userId,        
    String type = 'test',
  }) async {
    print('🔔 [IMMEDIATE] Showing: $title');
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Health reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    if (userId != null) {
      _logNotificationToDatabase(
        userId: userId,
        title: title,
        body: body,
        type: type,
      ).catchError((e) => print('⚠️ DB log failed: $e'));
    }
  }

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
        return data['notification']?['id'];
      }
      return null;
    } catch (e) {
      print('❌ Error logging notification: $e');
      return null;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🔕 All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
    await showImmediateNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'If you see this, notifications are working!',
    );
  }

  // Get unread notification count from backend
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/notifications/unread/$userId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Show milestone notification (for achievements like step goals)
  Future<void> showMilestoneNotification({
    required int id,
    required String title,
    required String body,
    required String userId,
    required String milestoneType,
  }) async {
    print('🎉 [MILESTONE] Showing: $title');
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'health_reminders',
          'Health Reminders',
          channelDescription: 'Milestone achievements',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    // Log to database
    await _logNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: milestoneType,
    );
  }
}