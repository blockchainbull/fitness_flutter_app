// lib/services/platform_services_web.dart
// Web implementation - provides stubs since features aren't available

import 'dart:async';

class PlatformServices {
  static PlatformServices? _instance;
  
  static PlatformServices get instance {
    _instance ??= PlatformServices();
    return _instance!;
  }

  // Speech to Text - Not available on web
  Future<bool> initializeSpeech() async {
    print('Speech to Text is not available on web');
    return false;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    print('Speech to Text is not available on web');
    if (onError != null) {
      onError('Speech to Text is not available on web platform');
    }
  }

  Future<void> stopListening() async {
    // No-op on web
  }

  bool get isSpeechAvailable => false;
  bool get isListening => false;

  // Pedometer - Not available on web
  Stream<int> get stepCountStream => Stream.value(0);

  Future<void> initializePedometer() async {
    print('Pedometer is not available on web');
  }

  int get currentStepCount => 0;

  // Notifications - Limited on web
  Future<void> initializeNotifications() async {
    print('Native notifications are limited on web');
    // Could implement browser notifications here if needed
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print('Notification on web: $title - $body');
    // Could use browser Notification API here if needed
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    print('Scheduled notifications not available on web');
  }

  Future<void> cancelNotification(int id) async {
    // No-op on web
  }

  Future<void> cancelAllNotifications() async {
    // No-op on web
  }

  // Permissions - Different on web
  Future<bool> requestPermission(String permission) async {
    print('Permission $permission - auto-granted on web');
    return true; // Web has different permission model
  }

  Future<bool> checkPermission(String permission) async {
    return true; // Most permissions auto-granted on web
  }

  // Platform check
  bool get isMobilePlatform => false;
  bool get isWebPlatform => true;
}