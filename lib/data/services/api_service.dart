// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:user_onboarding/data/models/user_profile.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // Updated API base URL to match unified backend
  static final String baseUrl = kDebugMode 
    ? 'http://localhost:8000/api/health'  // For local development
    : 'https://your-production-api.com/api/health';  // For production

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Complete onboarding using unified backend format
  Future<Map<String, dynamic>> completeOnboarding(Map<String, dynamic> onboardingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/onboarding/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(onboardingData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to complete onboarding');
      }
    } catch (e) {
      debugPrint('API error completing onboarding: $e');
      rethrow;
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // Save user profile using the new unified format
  Future<String> saveUserProfile(UserProfile userProfile) async {
    try {
      // Convert UserProfile to onboarding format
      final onboardingData = _convertUserProfileToOnboardingFormat(userProfile);
      
      final response = await completeOnboarding(onboardingData);
      
      if (response['success'] == true) {
        return response['userId'];
      } else {
        throw Exception('Failed to save user profile');
      }
    } catch (e) {
      debugPrint('API error when saving user profile: $e');
      rethrow;
    }
  }

  // Get user profile by ID using unified backend
  Future<UserProfile> getUserProfileById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['userProfile'] != null) {
          return UserProfile.fromMap(data['userProfile']);
        } else {
          throw Exception('User profile not found');
        }
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when getting user profile: $e');
      rethrow;
    }
  }

  // Check if email exists (you'll need to add this endpoint to your backend)
  Future<bool> emailExists(String email) async {
    try {
      // Try to login with a dummy password to check if email exists
      // This is a workaround since we don't have a dedicated email check endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': 'dummy_password_for_check',
        }),
      );

      // If we get a 401, it means the email exists but password is wrong
      // If we get a different error, email might not exist
      return response.statusCode == 401;
    } catch (e) {
      debugPrint('API error when checking email: $e');
      return false;
    }
  }

  // Helper method to convert UserProfile to onboarding format
  Map<String, dynamic> _convertUserProfileToOnboardingFormat(UserProfile userProfile) {
    return {
      'basicInfo': {
        'name': userProfile.name,
        'email': userProfile.email,
        'password': userProfile.password ?? 'defaultpassword123', // You might want to handle this differently
        'gender': userProfile.gender,
        'age': userProfile.age,
        'height': userProfile.height,
        'weight': userProfile.weight,
        'activityLevel': userProfile.activityLevel,
        'bmi': userProfile.formData?['bmi'] ?? 0.0,
        'bmr': userProfile.formData?['bmr'] ?? 0.0,
        'tdee': userProfile.formData?['tdee'] ?? 0.0,
      },
      'primaryGoal': userProfile.primaryGoal,
      'weightGoal': {
        'weightGoal': userProfile.weightGoal,
        'targetWeight': userProfile.targetWeight,
        'timeline': userProfile.goalTimeline ?? '',
      },
      'sleepInfo': {
        'sleepHours': userProfile.sleepHours,
        'bedtime': userProfile.bedtime,
        'wakeupTime': userProfile.wakeupTime,
        'sleepIssues': userProfile.sleepIssues,
      },
      'dietaryPreferences': {
        'dietaryPreferences': userProfile.dietaryPreferences,
        'waterIntake': userProfile.waterIntake,
        'medicalConditions': userProfile.medicalConditions,
        'otherCondition': userProfile.otherMedicalCondition,
      },
      'workoutPreferences': {
        'workoutTypes': userProfile.preferredWorkouts,
        'frequency': userProfile.workoutFrequency,
        'duration': userProfile.workoutDuration,
      },
      'exerciseSetup': {
        'workoutLocation': userProfile.workoutLocation,
        'equipment': userProfile.availableEquipment,
        'fitnessLevel': userProfile.fitnessLevel,
        'hasTrainer': userProfile.hasTrainer,
      },
    };
  }

  // Legacy methods for backward compatibility (these will just call the new methods)
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    // This would require a backend endpoint that doesn't exist yet
    // For now, return null
    return null;
  }

  Future<void> updateUserProfile(String userId, UserProfile userProfile) async {
    // For now, this would be the same as creating a new profile
    // You might want to add an update endpoint to your backend
    throw UnimplementedError('Update profile not implemented yet');
  }

  Future<void> deleteUserProfile(String userId) async {
    // You might want to add a delete endpoint to your backend
    throw UnimplementedError('Delete profile not implemented yet');
  }
}