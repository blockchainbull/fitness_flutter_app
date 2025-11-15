// lib/services/platform_services_stub.dart
// This file should never actually be used - it's just a fallback

class PlatformServices {
  static PlatformServices? _instance;
  
  static PlatformServices get instance {
    _instance ??= PlatformServices();
    return _instance!;
  }

  // Speech to Text
  Future<bool> initializeSpeech() async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> stopListening() async {
    throw UnimplementedError('Platform not supported');
  }

  bool get isSpeechAvailable => false;
  bool get isListening => false;

  // Pedometer
  Stream<int> get stepCountStream {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> initializePedometer() async {
    throw UnimplementedError('Platform not supported');
  }

  int get currentStepCount => 0;

  // Notifications
  Future<void> initializeNotifications() async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> cancelNotification(int id) async {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> cancelAllNotifications() async {
    throw UnimplementedError('Platform not supported');
  }

  // Permissions
  Future<bool> requestPermission(String permission) async {
    throw UnimplementedError('Platform not supported');
  }

  Future<bool> checkPermission(String permission) async {
    throw UnimplementedError('Platform not supported');
  }

  // Platform check
  bool get isMobilePlatform => false;
  bool get isWebPlatform => true;
}