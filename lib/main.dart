// lib/main.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/app.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/data/services/database_service.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';

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

  try {
    await DataManager().initialize();
  } catch (e) {
    print('❌ Data manager initialization failed: $e');
  }

  final bool hasValidLogin = await UserManager.isLoggedIn();
  UserProfile? userProfile;

  if (hasValidLogin) {
    userProfile = await UserManager.getCurrentUser();
    if (userProfile != null) {
      print('Successfully loaded profile for: ${userProfile.name}');
    }
  }

  runApp(HealthAIApp(
    hasValidLogin: hasValidLogin,
    userProfile: userProfile,
  ));
}