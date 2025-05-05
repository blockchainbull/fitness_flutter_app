// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:user_onboarding/app.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

void main() async {
  // This line is critical - don't forget it
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for saved profile
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  print('Onboarding completed: $onboardingCompleted');
  
  // Try to load user profile
  UserProfile? userProfile;
  if (onboardingCompleted) {
    final profileJson = prefs.getString('user_profile');
    print('Found profile data: $profileJson');
    
    if (profileJson != null) {
      try {
        userProfile = UserProfile.fromMap(jsonDecode(profileJson));
        print('Successfully loaded profile for: ${userProfile.name}');
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }
  
  runApp(HealthAIApp(
    onboardingCompleted: onboardingCompleted,
    userProfile: userProfile,
  ));
}