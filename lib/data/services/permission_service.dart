// lib/data/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Singleton pattern
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Request microphone permission for speech-to-text
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  // Request activity recognition for step counter
  Future<bool> requestActivityRecognition() async {
    final status = await Permission.activityRecognition.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    final result = await Permission.activityRecognition.request();
    return result.isGranted;
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  // Check if microphone permission is granted
  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  // Check if activity recognition is granted
  Future<bool> isActivityRecognitionGranted() async {
    return await Permission.activityRecognition.isGranted;
  }

  // Check if notification permission is granted
  Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  // Check if permission is permanently denied
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Request all permissions at once
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = await [
      Permission.microphone,
      Permission.activityRecognition,
      Permission.notification,
    ].request();

    return {
      'microphone': results[Permission.microphone]?.isGranted ?? false,
      'activity': results[Permission.activityRecognition]?.isGranted ?? false,
      'notification': results[Permission.notification]?.isGranted ?? false,
    };
  }

  // Check status of all permissions
  Future<Map<String, PermissionStatus>> checkAllPermissionsStatus() async {
    return {
      'microphone': await Permission.microphone.status,
      'activity': await Permission.activityRecognition.status,
      'notification': await Permission.notification.status,
    };
  }

  // Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}