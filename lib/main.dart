// lib/main.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/app.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';

void main() async {
  // This line is critical - don't forget it
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize data manager
  final dataManager = DataManager();
  await dataManager.initialize();
  
  // Check if onboarding is completed
  final bool onboardingCompleted = await dataManager.isOnboardingCompleted();
  
  print('Onboarding completed: $onboardingCompleted');
  
  // Try to load user profile
  UserProfile? userProfile;
  if (onboardingCompleted) {
    userProfile = await dataManager.loadUserProfile();
    if (userProfile != null) {
      print('Successfully loaded profile for: ${userProfile.name}');
    } else {
      print('No user profile found');
    }
  }
  
  // Synchronize data with remote source if needed (in background)
  if (onboardingCompleted) {
    dataManager.synchronizeData();
  }
  
  runApp(HealthAIApp(
    onboardingCompleted: onboardingCompleted,
    userProfile: userProfile,
  ));
}