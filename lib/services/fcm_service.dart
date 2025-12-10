// lib/services/fcm_service.dart
// Firebase Cloud Messaging Service for Flutter

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 [FCM BACKGROUND] Handling message: ${message.messageId}');
  print('📱 [FCM BACKGROUND] Title: ${message.notification?.title}');
  print('📱 [FCM BACKGROUND] Body: ${message.notification?.body}');
}

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

    // Request permission (iOS mainly, Android auto-grants)
    await _requestPermission();

    // Initialize local notifications for foreground display
    await _initializeLocalNotifications();

    // Get FCM token
    await _getToken();

    // Set up message handlers
    _setupMessageHandlers();

    print('✅ [FCM] Initialization complete');
  }

  /// Request notification permissions
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ [FCM] Provisional permission granted');
    } else {
      print('❌ [FCM] Permission denied');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    print('📱 [FCM] Initializing local notifications...');

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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_default_channel',
      'FCM Notifications',
      description: 'Firebase Cloud Messaging notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ [FCM] Local notifications initialized');
  }

  /// Get FCM token
  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('✅ [FCM] Token obtained: ${_fcmToken?.substring(0, 20)}...');

      // Save token to backend
      await _saveTokenToBackend(_fcmToken!);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 [FCM] Token refreshed');
        _fcmToken = newToken;
        _saveTokenToBackend(newToken);
      });
    } catch (e) {
      print('❌ [FCM] Error getting token: $e');
    }
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('⚠️ [FCM] No user ID, skipping token save');
        return;
      }

      print('📤 [FCM] Saving token to backend for user: $userId');

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
        print('⚠️ [FCM] Failed to save token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Error saving token to backend: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    print('📱 [FCM] Setting up message handlers...');

    // Handle foreground messages (app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Check if app was opened from terminated state
    _checkInitialMessage();

    print('✅ [FCM] Message handlers set up');
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 [FCM FOREGROUND] Message received');
    print('📱 [FCM FOREGROUND] Title: ${message.notification?.title}');
    print('📱 [FCM FOREGROUND] Body: ${message.notification?.body}');
    print('📱 [FCM FOREGROUND] Data: ${message.data}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    
    if (notification == null) return;

    print('🔔 [FCM] Showing local notification');

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'FCM Notifications',
          channelDescription: 'Firebase Cloud Messaging notifications',
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
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap when app was in background
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('📱 [FCM] App opened from notification');
    print('📱 [FCM] Data: ${message.data}');
    
    // TODO: Navigate to appropriate screen based on message.data
    // Example: if (message.data['type'] == 'meal') { navigate to meal logging }
  }

  /// Check if app was opened from terminated state
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('📱 [FCM] App opened from terminated state via notification');
      print('📱 [FCM] Data: ${initialMessage.data}');
      // TODO: Handle navigation
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 [FCM] Notification tapped');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        print('📱 [FCM] Payload: $data');
        // TODO: Navigate based on data
      } catch (e) {
        print('❌ [FCM] Error parsing payload: $e');
      }
    }
  }

  /// Test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (_fcmToken == null) {
      print('❌ [FCM] No token available');
      return;
    }

    try {
      print('📤 [FCM] Sending test notification...');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('❌ [FCM] No user ID');
        return;
      }

      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Test notification sent!');
      } else {
        print('❌ [FCM] Failed to send test: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Error sending test: $e');
    }
  }

  /// Subscribe to notification scheduling
  Future<void> subscribeToNotifications(String userId) async {
    try {
      print('📤 [FCM] Subscribing to notifications for user: $userId');

      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Subscribed to notifications');
      } else {
        print('⚠️ [FCM] Failed to subscribe: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Error subscribing: $e');
    }
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribeFromNotifications(String userId) async {
    try {
      print('📤 [FCM] Unsubscribing from notifications for user: $userId');

      final response = await http.post(
        Uri.parse('$backendUrl/api/fcm/unsubscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ [FCM] Unsubscribed from notifications');
      } else {
        print('⚠️ [FCM] Failed to unsubscribe: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Error unsubscribing: $e');
    }
  }
}