// lib/services/platform_services_mobile.dart
// Mobile (iOS/Android) implementation with actual package usage

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class PlatformServices {
  static PlatformServices? _instance;
  
  static PlatformServices get instance {
    _instance ??= PlatformServices();
    return _instance!;
  }

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  Future<bool> initializeSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _speechAvailable;
    } catch (e) {
      print('Error initializing speech: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_speechAvailable) {
      if (onError != null) {
        onError('Speech recognition not available');
      }
      return;
    }

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      _isListening = false;
      if (onError != null) {
        onError('Error starting speech recognition: $e');
      }
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  bool get isSpeechAvailable => _speechAvailable;
  bool get isListening => _isListening;

  // Pedometer
  Stream<StepCount>? _stepCountStream;
  int _currentStepCount = 0;
  StreamSubscription<StepCount>? _stepSubscription;

  Stream<int> get stepCountStream {
    if (_stepCountStream == null) {
      return Stream.value(0);
    }
    return _stepCountStream!.map((stepCount) {
      _currentStepCount = stepCount.steps;
      return stepCount.steps;
    });
  }

  Future<void> initializePedometer() async {
    try {
      // Request activity recognition permission
      await requestPermission('activityRecognition');
      
      _stepCountStream = Pedometer.stepCountStream;
      _stepSubscription = _stepCountStream!.listen(
        (StepCount stepCount) {
          _currentStepCount = stepCount.steps;
        },
        onError: (error) {
          print('Pedometer error: $error');
        },
      );
    } catch (e) {
      print('Error initializing pedometer: $e');
    }
  }

  int get currentStepCount => _currentStepCount;

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  Future<void> initializeNotifications() async {
    try {
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

      _notificationsInitialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
        },
      ) ?? false;

      // Request notification permission
      await requestPermission('notification');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_notificationsInitialized) {
      await initializeNotifications();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_notificationsInitialized) {
      await initializeNotifications();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Channel',
      channelDescription: 'Scheduled notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Permissions
  Future<bool> requestPermission(String permission) async {
    try {
      Permission permissionToRequest;
      
      switch (permission.toLowerCase()) {
        case 'microphone':
          permissionToRequest = Permission.microphone;
          break;
        case 'notification':
          permissionToRequest = Permission.notification;
          break;
        case 'activityrecognition':
          permissionToRequest = Permission.activityRecognition;
          break;
        case 'storage':
          permissionToRequest = Permission.storage;
          break;
        default:
          print('Unknown permission: $permission');
          return false;
      }

      final status = await permissionToRequest.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> checkPermission(String permission) async {
    try {
      Permission permissionToCheck;
      
      switch (permission.toLowerCase()) {
        case 'microphone':
          permissionToCheck = Permission.microphone;
          break;
        case 'notification':
          permissionToCheck = Permission.notification;
          break;
        case 'activityrecognition':
          permissionToCheck = Permission.activityRecognition;
          break;
        case 'storage':
          permissionToCheck = Permission.storage;
          break;
        default:
          return false;
      }

      final status = await permissionToCheck.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  // Platform check
  bool get isMobilePlatform => true;
  bool get isWebPlatform => false;

  // Cleanup
  void dispose() {
    _stepSubscription?.cancel();
  }
}