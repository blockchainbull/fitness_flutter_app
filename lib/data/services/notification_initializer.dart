// lib/data/services/notification_initializer.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'daily_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationInitializer {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications when app starts
  static Future<void> initialize() async {
    print('🔔 Initializing notifications system...');

    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Set local timezone
    final String timeZoneName = 'Asia/Karachi'; // Lahore timezone
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    print('✅ Notifications system initialized');
  }

  static Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on notification type
  }

  /// Setup daily notifications for a user (call this after login/signup)
  static Future<void> setupDailyNotifications(String userId) async {
    print('🔧 Setting up daily notifications for user: $userId');
    
    // Save user ID for future use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_user_id', userId);
    
    // Schedule all daily notifications
    await DailyNotificationScheduler.scheduleDailyNotifications(userId);
    
    // Mark that notifications have been set up
    await prefs.setBool('notifications_configured', true);
    await prefs.setString('last_notification_setup', DateTime.now().toIso8601String());
    
    print('✅ Daily notifications configured');
  }

  /// Check if notifications need to be rescheduled (call on app start)
  static Future<void> checkAndRescheduleIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final configured = prefs.getBool('notifications_configured') ?? false;
    final userId = prefs.getString('notification_user_id');
    
    if (!configured || userId == null) {
      print('⚠️ Notifications not configured yet');
      return;
    }

    // Check if we need to reschedule (e.g., device was restarted)
    final lastSetup = prefs.getString('last_notification_setup');
    if (lastSetup != null) {
      final lastSetupDate = DateTime.parse(lastSetup);
      final daysSinceSetup = DateTime.now().difference(lastSetupDate).inDays;
      
      // Reschedule if more than 1 day has passed
      if (daysSinceSetup > 1) {
        print('🔄 Rescheduling notifications (${daysSinceSetup} days since last setup)');
        await setupDailyNotifications(userId);
      }
    }
  }

  /// Show a test notification to verify setup
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      999,
      '🧪 Test Notification',
      'If you see this, notifications are working perfectly!',
      details,
    );

    print('✅ Test notification sent');
  }
}