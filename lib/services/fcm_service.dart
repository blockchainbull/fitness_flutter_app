// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const String backendUrl = 'https://health-ai-backend-i28b.onrender.com';

  /// Initialize FCM
  Future<void> initialize() async {
    print('🔔 [FCM] Initializing Firebase Cloud Messaging...');

    await _requestPermission();
    await _initializeLocalNotifications();
    await _getToken();
    _setupMessageHandlers();

    print('✅ [FCM] Initialization complete');
  }

  Future<void> _requestPermission() async {
    print('📱 [FCM] Requesting permission...');
    
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [FCM] Permission granted');
    } else {
      print('❌ [FCM] Permission denied');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    print('📱 [FCM] Initializing local notifications...');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel - FIXED SYNTAX
    const channel = AndroidNotificationChannel(
      'fcm_default_channel',
      'FCM Notifications',
      description: 'Firebase Cloud Messaging notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      await android.createNotificationChannel(channel);
    }

    print('✅ [FCM] Local notifications initialized');
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('✅ [FCM] Token obtained: ${_fcmToken?.substring(0, 20)}...');

      await _saveTokenToBackend(_fcmToken!);
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);
    } catch (e) {
      print('❌ [FCM] Error getting token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('⚠️ [FCM] No user ID found, skipping token save');
        return;
      }

      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
          'platform': 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Token saved to backend');
      } else {
        print('❌ [FCM] Failed to save token: ${response.body}');
      }
    } catch (e) {
      print('❌ [FCM] Error saving token: $e');
    }
  }

  void _setupMessageHandlers() {
    print('📨 [FCM] Setting up message handlers...');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 [FCM] Foreground message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 [FCM] Notification opened (background)');
      _handleNotificationTap(message);
    });

    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = 
        await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print('📬 [FCM] App opened from notification (terminated state)');
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'FCM Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nufitionist',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('👆 [FCM] Notification tapped');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(null, data: data);
      } catch (e) {
        print('❌ [FCM] Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(RemoteMessage? message, {Map<String, dynamic>? data}) {
    final notificationData = data ?? message?.data ?? {};
    final type = notificationData['type'] ?? '';

    print('🔔 [FCM] Handling notification tap, type: $type');

    switch (type) {
      case 'meal':
        print('   → Navigate to Meals screen');
        break;
      case 'hydration':
        print('   → Navigate to Water tracking');
        break;
      case 'exercise':
        print('   → Navigate to Exercise screen');
        break;
      case 'sleep':
        print('   → Navigate to Sleep tracking');
        break;
      default:
        print('   → Navigate to Home screen');
    }
  }

  /// Subscribe to notifications - FIXED METHOD NAME
  Future<void> subscribeToNotifications(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Subscribed to notifications');
      }
    } catch (e) {
      print('❌ [FCM] Error subscribing: $e');
    }
  }

  /// Legacy method name for compatibility
  Future<void> subscribe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        await subscribeToNotifications(userId);
      }
    } catch (e) {
      print('❌ [FCM] Error subscribing: $e');
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Test notification sent');
      }
    } catch (e) {
      print('❌ [FCM] Error sending test: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM] Background message received');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
}