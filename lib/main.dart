// lib/main.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/app.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataManager = DataManager();
  await dataManager.initialize();
  
  // Check if user has valid login
  final bool hasValidLogin = await dataManager.hasValidLogin();
  
  print('Has valid login: $hasValidLogin');
  
  UserProfile? userProfile;
  if (hasValidLogin) {
    userProfile = await dataManager.loadUserProfile();
    if (userProfile != null) {
      print('Successfully loaded profile for: ${userProfile.name}');
    }
  }
  
  runApp(HealthAIApp(
    hasValidLogin: hasValidLogin,
    userProfile: userProfile,
  ));
}