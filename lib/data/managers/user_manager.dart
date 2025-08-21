import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class UserManager {
  static const String _userIdKey = 'user_id';
  static const String _userProfileKey = 'user_profile';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // Set user as logged in after onboarding/login
  static Future<void> setCurrentUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_userIdKey, user.id ?? '');
    await prefs.setString(_userProfileKey, jsonEncode(user.toMap()));
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user profile
  static Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isAuthenticated) return null;
    
    final userProfileJson = prefs.getString(_userProfileKey);
    if (userProfileJson != null) {
      try {
        final userMap = jsonDecode(userProfileJson);
        return UserProfile.fromMap(userMap);
      } catch (e) {
        print('Error parsing user profile: $e');
        return null;
      }
    }
    return null;
  }

  // Get user ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userProfileKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Check if onboarding is completed
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }
}