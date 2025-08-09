// lib/main.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/app.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/data/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database service
  try {
    print('🚀 Initializing database service...');
    await DatabaseService.initialize();
    print('✅ Database service initialized');
  } catch (e) {
    print('❌ Database initialization failed: $e');
    print('⚠️ App will continue with local storage only');
  }

  final dataManager = DataManager();
  try {
    await DataManager().initialize();
  } catch (e) {
    print('❌ Data manager initialization failed: $e');
  }

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