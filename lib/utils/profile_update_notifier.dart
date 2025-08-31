// lib/utils/profile_update_notifier.dart
import 'dart:async';
import 'package:user_onboarding/data/models/user_profile.dart';

class ProfileUpdateNotifier {
  static final ProfileUpdateNotifier _instance = ProfileUpdateNotifier._internal();
  factory ProfileUpdateNotifier() => _instance;
  ProfileUpdateNotifier._internal();

  final _profileUpdateController = StreamController<UserProfile>.broadcast();
  final _profileRefreshController = StreamController<void>.broadcast();
  
  Stream<UserProfile> get profileUpdates => _profileUpdateController.stream;
  Stream<void> get refreshRequests => _profileRefreshController.stream;
  
  void notifyProfileUpdate(UserProfile profile) {
    if (!_profileUpdateController.isClosed) {
      _profileUpdateController.add(profile);
    }
  }
  
  void requestRefresh() {
    if (!_profileRefreshController.isClosed) {
      _profileRefreshController.add(null);
    }
  }
  
  void dispose() {
    _profileUpdateController.close();
    _profileRefreshController.close();
  }
}