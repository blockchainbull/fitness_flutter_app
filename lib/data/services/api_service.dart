// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/utils/timezone_helper.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  static final String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';


  // Updated API base URL to match unified backend
  // static final String baseUrl = kDebugMode 
  //   ? 'http://localhost:8000/api/health'  // For local development
  //   : 'https://health-ai-backend-i28b.onrender.com/api/health';  // For production

  Map<String, String> get headers {
    final timezoneInfo = TimezoneHelper.getTimezoneInfo();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Timezone-Offset': timezoneInfo['offset_minutes'].toString(),
      'X-Timezone-String': timezoneInfo['offset_string'],
    };
  }

  //  static final String baseUrl = kDebugMode 
  //    ? 'http://10.0.2.2:8000/api/health'  // Android emulator
  //    : 'https://your-production-api.com/api/health';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Complete onboarding using unified backend format
  Future<Map<String, dynamic>> completeOnboarding(Map<String, dynamic> onboardingData) async {
    try {

      // Ensure water_intake_glasses is included
      if (onboardingData['dietaryPreferences'] != null) {
        final dietPrefs = onboardingData['dietaryPreferences'] as Map<String, dynamic>;
        
        // Ensure both water intake values are present
        if (!dietPrefs.containsKey('waterIntakeGlasses') && dietPrefs.containsKey('waterIntake')) {
          dietPrefs['waterIntakeGlasses'] = ((dietPrefs['waterIntake'] as double) * 4).round();
        } else if (dietPrefs.containsKey('waterIntakeGlasses') && !dietPrefs.containsKey('waterIntake')) {
          dietPrefs['waterIntake'] = (dietPrefs['waterIntakeGlasses'] as int) / 4.0;
        }
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/onboarding/complete'),
        headers: headers,
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

  // Update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      print('[ApiService] Updating profile for user: ${userProfile.id}');
      
      // Use the correct endpoint - your backend appears to have this at /api/health/users/{id}
      final response = await http.put(
        Uri.parse('$baseUrl/users/update-user/${userProfile.id}'),  
        headers: headers,
        body: jsonEncode({
          'height': userProfile.height,
          'weight': userProfile.weight,
          'activity_level': userProfile.activityLevel,
          'primary_goal': userProfile.primaryGoal,
          'weight_goal': userProfile.weightGoal,
          'target_weight': userProfile.targetWeight,
          'goal_timeline': userProfile.goalTimeline,
          'sleep_hours': userProfile.sleepHours,
          'bedtime': userProfile.bedtime,
          'wakeup_time': userProfile.wakeupTime,
          'sleep_issues': userProfile.sleepIssues,
          'dietary_preferences': userProfile.dietaryPreferences,
          'water_intake': userProfile.waterIntake,
          'water_intake_glasses': userProfile.waterIntakeGlasses,
          'medical_conditions': userProfile.medicalConditions,
          'other_medical_condition': userProfile.otherMedicalCondition,
          'preferred_workouts': userProfile.preferredWorkouts,
          'workout_frequency': userProfile.workoutFrequency,
          'workout_duration': userProfile.workoutDuration,
          'workout_location': userProfile.workoutLocation,
          'available_equipment': userProfile.availableEquipment,
          'fitness_level': userProfile.fitnessLevel,
          'has_trainer': userProfile.hasTrainer,
          // Add the step goal
          'daily_step_goal': userProfile.formData['dailyStepGoal'] as int? ?? 10000,
        }),
      );

      print('[ApiService] Update response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('[ApiService] API error updating profile: $e');
      rethrow;
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('[ApiService] Attempting login for: $email');
      
      final uri = Uri.parse('$baseUrl/auth/login');
      print('[ApiService] Login URL: $uri');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final body = jsonEncode({
        'email': email,
        'password': password,
      });
      
      print('[ApiService] Headers: $headers');
      print('[ApiService] Body: $body');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('[ApiService] ❌ Request timed out');
          throw Exception('Request timed out');
        },
      );

      print('[ApiService] Response status: ${response.statusCode}');
      print('[ApiService] Response headers: ${response.headers}');
      print('[ApiService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'user': data['user'],
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('[ApiService] ❌ Login failed: ${errorData}');
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      print('[ApiService] ❌ Login error: $e');
      rethrow;
    }
  }

  Future<String> sendChatMessage(String userId, String message) async {
    try {
      print('[ApiService] Sending chat message for user: $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'message': message,
        }),
      );

      print('[ApiService] Chat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        throw Exception('Failed to send chat message: ${response.body}');
      }
    } catch (e) {
      print('[ApiService] Chat error: $e');
      return 'I\'m having trouble connecting right now. Please try again later.';
    }
  }

  Future<Map<String, dynamic>> getUserChatContext(String userId) async {
    try {
      print('[ApiService] Getting chat context for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/chat/context/$userId'),
        headers: headers,
      );

      print('[ApiService] Chat context response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Safe null checking
        if (data != null && data is Map<String, dynamic>) {
          return data['context'] ?? {};
        }
        return {};
      } else {
        print('[ApiService] Chat context error response: ${response.body}');
        return {};
      }
    } catch (e) {
      print('[ApiService] Chat context error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserFramework(String userId) async {
    try {
      print('[ApiService] Getting user framework for: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/framework'),
        headers: headers,
      );

      print('[ApiService] Framework response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Safe null checking
        if (data != null && data is Map<String, dynamic>) {
          return data; // Return the whole response
        }
        return {'success': false, 'framework': null};
      } else {
        print('[ApiService] Framework error response: ${response.body}');
        return {'success': false, 'framework': null};
      }
    } catch (e) {
      print('[ApiService] Framework error: $e');
      return {'success': false, 'framework': null};
    }
}

  Future<Map<String, dynamic>> compareFrameworks() async {
    try {
      print('[ApiService] Getting framework comparison');
      
      final response = await http.get(
        Uri.parse('$baseUrl/frameworks/compare'),
        headers: headers,
      );

      print('[ApiService] Framework comparison response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['frameworks'] ?? {};
      } else {
        throw Exception('Failed to get framework comparison: ${response.body}');
      }
    } catch (e) {
      print('[ApiService] Framework comparison error: $e');
      return {};
    }
  }

  // Save weight entry
  Future<String> saveWeightEntry(WeightEntry weightEntry) async {
    try {
      print('[ApiService] Saving weight entry: ${weightEntry.weight} kg');
      
      final response = await http.post(
        Uri.parse('$baseUrl/weight'),
        headers: headers,
        body: jsonEncode({
          'user_id': weightEntry.userId,
          'date': weightEntry.date.toIso8601String(),
          'weight': weightEntry.weight,
          'notes': weightEntry.notes,
          'body_fat_percentage': weightEntry.bodyFatPercentage,
          'muscle_mass_kg': weightEntry.muscleMassKg,
        }),
      );

      print('[ApiService] Weight entry response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final entryId = data['id'] ?? weightEntry.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        print('[ApiService] Weight entry saved with ID: $entryId');
        return entryId;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save weight entry');
      }
    } catch (e) {
      print('[ApiService] Weight entry error: $e');
      rethrow;
    }
  }

  // Get weight history
  Future<List<WeightEntry>> getWeightHistory(String userId, {int limit = 50}) async {
    try {
      print('[ApiService] Getting weight history for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/weight/$userId?limit=$limit'), 
        headers: headers,
      );

      print('[ApiService] Weight history response status: ${response.statusCode}');
      print('[ApiService] Weight history URL: $baseUrl/weight/$userId?limit=$limit');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['weights'] != null && data['weights'] is List) {
          return (data['weights'] as List)
              .map((item) => WeightEntry.fromMap(item))
              .toList();
        }
        return [];
      } else {
        print('[ApiService] Weight history error response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get weight history');
      }
    } catch (e) {
      print('[ApiService] Weight history error: $e');
      return [];
    }
  }

  // Get latest weight entry
  Future<WeightEntry?> getLatestWeight(String userId) async {
    try {
      print('[ApiService] Getting latest weight for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/weight/$userId/latest'),
        headers: headers,
      );

      print('[ApiService] Latest weight response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['weight'] != null) {
          return WeightEntry.fromMap(data['weight']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get latest weight');
      }
    } catch (e) {
      print('[ApiService] Latest weight error: $e');
      return null;
    }
  }

  // Delete weight entry
  Future<bool> deleteWeightEntry(String entryId) async {
    try {
      print('[ApiService] Deleting weight entry: $entryId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/weight/$entryId'),
        headers: headers,
      );

      print('[ApiService] Delete weight response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Delete weight error: $e');
      return false;
    }
  }

  // Update user's current weight in profile
  Future<void> updateUserWeight(String userId, double newWeight) async {
    try {
      print('[ApiService] Updating user weight to $newWeight kg');
      
      final response = await http.patch(
        Uri.parse('http://localhost:8000/api/health/user/$userId/weight'),
        headers: headers,
        body: jsonEncode({
          'weight': newWeight,
        }),
      );

      print('[ApiService] Update weight response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update user weight');
      }
    } catch (e) {
      print('[ApiService] Update weight error: $e');
      rethrow;
    }
  }

  Future<bool> setStartingWeight(String userId, double startingWeight) async {
    try {
      print('[ApiService] Setting starting weight: $startingWeight kg for user: $userId');
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/health/user/$userId/set-starting-weight'),
        headers: headers,
        body: jsonEncode({
          'starting_weight': startingWeight,
        }),
      );

      print('[ApiService] Set starting weight response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ApiService] Starting weight set successfully');
        return true;
      } else {
        print('[ApiService] Failed to set starting weight: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ApiService] Starting weight error: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['success'] == true && data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
      }
      return [];
    } catch (e) {
      print('[ApiService] Chat history error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/messages/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
      }
      return [];
    } catch (e) {
      print('[ApiService] Get chat messages error: $e');
      return [];
    }
  }

  Future<bool> clearChatMessages(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/messages/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('[ApiService] Clear chat messages error: $e');
      return false;
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

  Future<bool> clearChatHistory(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/history/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('[ApiService] Clear chat history error: $e');
      return false;
    }
  }

  Future<UserProfile> getUserProfileById(String userId) async {
    try {
      print('[ApiService] Getting user profile for ID: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      print('[ApiService] User profile response status: ${response.statusCode}');
      print('[ApiService] User profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug the sleep-related fields specifically
        print('[ApiService] 🛏️ Sleep data from API:');
        print('  bedtime: "${data['userProfile']?['bedtime']}"');
        print('  wakeup_time: "${data['userProfile']?['wakeup_time']}"');
        print('  sleep_hours: ${data['userProfile']?['sleep_hours']}');
        
        if (data['success'] == true && data['userProfile'] != null) {
          final userProfile = UserProfile.fromMap(data['userProfile']);
          
          // Debug the parsed profile
          print('[ApiService] 🛏️ Parsed UserProfile sleep data:');
          print('  bedtime: "${userProfile.bedtime}"');
          print('  wakeupTime: "${userProfile.wakeupTime}"');
          print('  sleepHours: ${userProfile.sleepHours}');
          
          return userProfile;
        } else {
          // Try to create UserProfile from direct user data
          return UserProfile.fromApiResponse(data);
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
        headers: headers,
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

  // Supplement logging functions
  Future<Map<String, dynamic>> saveSupplementPreferences(String userId, List<Map<String, dynamic>> supplements) async {
    try {
      print('[ApiService] Saving supplement preferences for user: $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/supplements/preferences'),
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'supplements': supplements,
        }),
      );

      print('[ApiService] Save preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save supplement preferences');
      }
    } catch (e) {
      print('[ApiService] Error saving supplement preferences: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSupplementStatus(String userId, {String? date}) async {
    try {
      print('[ApiService] 💊 Getting supplement status for user: $userId');
      
      String url = '$baseUrl/supplements/status/$userId';
      if (date != null) {
        url += '?date=$date';
      }
      
      print('[ApiService] 💊 Status URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('[ApiService] 💊 Status response status: ${response.statusCode}');
      print('[ApiService] 💊 Status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('[ApiService] 💊 Status error response: ${response.body}');
        return {'success': false, 'status': {}};
      }
    } catch (e) {
      print('[ApiService] 💊 Status error: $e');
      return {'success': false, 'status': {}};
    }
  }

  Future<List<Map<String, dynamic>>> getSupplementPreferences(String userId) async {
    try {
      print('[ApiService] Getting supplement preferences for user: $userId');
      print('[ApiService] URL: $baseUrl/supplements/preferences/$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/preferences/$userId'),
        headers: headers,
      );

      print('[ApiService] Get preferences response status: ${response.statusCode}');
      print('[ApiService] Get preferences response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['preferences'] != null) {
          print('[ApiService] Successfully parsed ${data['preferences'].length} preferences');
          return List<Map<String, dynamic>>.from(data['preferences']);
        }
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get supplement preferences');
      }
    } catch (e) {
      print('[ApiService] Error getting supplement preferences: $e');
      return []; // Return empty list on error instead of throwing
    }
  }

  // Log daily supplement intake
  Future<Map<String, dynamic>> logSupplementIntake(Map<String, dynamic> logData) async {
    try {
      print('[ApiService] Logging supplement intake: ${logData['supplement_name']} = ${logData['taken']}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/supplements/log'),
        headers: headers,
        body: jsonEncode(logData),
      );

      print('[ApiService] Log supplement response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to log supplement intake');
      }
    } catch (e) {
      print('[ApiService] Error logging supplement intake: $e');
      rethrow;
    }
  }

  

  // Get supplement history
  Future<List<Map<String, dynamic>>> getSupplementHistory(String userId, {String? supplementName, int days = 30}) async {
    try {
      print('[ApiService] Getting supplement history for user: $userId');
      
      String url = '$baseUrl/supplements/history/$userId?days=$days';
      if (supplementName != null) {
        url += '&supplement_name=$supplementName';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('[ApiService] Supplement history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get supplement history');
      }
    } catch (e) {
      print('[ApiService] Supplement history error: $e');
      return [];
    }
  }

  Future<Map<String, bool>> getTodaysSupplementStatus(String userId) async {
    try {
      print('[ApiService] Getting today\'s supplement status for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/status/$userId'),
        headers: headers,
      );

      print('[ApiService] Supplement status response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['status'] != null) {
          // Convert the status map to Map<String, bool>
          final Map<String, dynamic> statusData = data['status'];
          final Map<String, bool> status = {};
          
          statusData.forEach((key, value) {
            status[key] = value == true;
          });
          
          return status;
        }
        return {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get supplement status');
      }
    } catch (e) {
      print('[ApiService] Error getting supplement status: $e');
      return {}; // Return empty map on error instead of throwing
    }
  }

  // Water logging/entry 
  Future<String> saveWaterEntry(WaterEntry waterEntry) async {
    try {
      print('[ApiService] Saving water entry: ${waterEntry.glassesConsumed} glasses');
      
      final response = await http.post(
        Uri.parse('$baseUrl/water'),
        headers: headers,
        body: jsonEncode(waterEntry.toMap()),
      );

      print('[ApiService] Water entry response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entryId = data['id'] ?? waterEntry.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        print('[ApiService] Water entry saved with ID: $entryId');
        return entryId;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to save water entry');
      }
    } catch (e) {
      print('[ApiService] Water entry error: $e');
      rethrow;
    }
  }

  // Get water history
  Future<List<WaterEntry>> getWaterHistory(String userId, {int limit = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/water/$userId?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['entries'] != null) {
          return (data['entries'] as List)
              .map((entry) => WaterEntry.fromMap(entry))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting water history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getWaterStats(String userId, {int days = 7}) async {
    try {
      print('[ApiService] Getting water stats for user: $userId, days: $days');
      
      final response = await http.get(
        Uri.parse('$baseUrl/water/$userId/stats?days=$days'),
        headers: headers,
      );

      print('[ApiService] Water stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get water stats');
      }
    } catch (e) {
      print('[ApiService] Water stats error: $e');
      return {};
    }
  }

  // Get today's water entry
  Future<Map<String, dynamic>> getTodaysWater(String userId) async {
    try {
      print('[ApiService] 💧 Getting today\'s water for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/water/$userId/today'),
        headers: headers,
      );

      print('[ApiService] 💧 Water response status: ${response.statusCode}');
      print('[ApiService] 💧 Water response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic>) {
          final entry = data['entry'];
          
          if (entry == null) {
            // No water logged today - return default structure
            return {
              'success': true,
              'glasses': 0,
              'total_ml': 0.0,
              'target_ml': 2000.0,
              'entry': null,
            };
          }
          
          // Parse the entry safely
          return {
            'success': true,
            'glasses': (entry['glasses_consumed'] ?? 0).toInt(),
            'total_ml': (entry['total_ml'] ?? 0.0).toDouble(),
            'target_ml': (entry['target_ml'] ?? 2000.0).toDouble(),
            'entry': entry,
          };
        }
      }
      
      // Error case
      return {
        'success': false,
        'glasses': 0,
        'total_ml': 0.0,
        'target_ml': 2000.0,
        'entry': null,
      };
    } catch (e) {
      print('[ApiService] 💧 Water error: $e');
      return {
        'success': false,
        'glasses': 0,
        'total_ml': 0.0,
        'target_ml': 2000.0,
        'entry': null,
      };
    }
  }

  // Sleep logging endpoint

  // Create sleep entry
  Future<Map<String, dynamic>> createSleepEntry(Map<String, dynamic> sleepData) async {
    try {
      print('[ApiService] Creating sleep entry for date: ${sleepData['date']}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/sleep/entries'),  // This becomes /api/health/sleep/entries
        headers: headers,
        body: jsonEncode(sleepData),
      );

      print('[ApiService] Sleep entry response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ApiService] Sleep entry saved successfully');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create sleep entry');
      }
    } catch (e) {
      print('[ApiService] Sleep entry error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSleepEntryByDate(String userId, String date) async {
    try {
      print('[ApiService] Getting sleep entry for user: $userId, date: $date');
      
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/entries/$userId/$date'),
        headers: headers,
      );

      print('[ApiService] Sleep entry response status: ${response.statusCode}');
      print('[ApiService] Sleep entry response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print('[ApiService] No sleep entry found for date: $date');
        return null;
      } else {
        print('[ApiService] Sleep entry error response: ${response.body}');
        throw Exception('Failed to get sleep entry: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiService] Get sleep entry error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateSleepEntry(String entryId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sleep/entries/$entryId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update sleep entry');
      }
    } catch (e) {
      print('[ApiService] Update sleep entry error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSleepHistory(String userId, {int limit = 30}) async {
    try {
      print('[ApiService] Getting sleep history for user: $userId');
      
      // Make sure to use the correct URL
      final url = '$baseUrl/sleep/entries/$userId?limit=$limit';
      print('[ApiService] Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('[ApiService] Sleep history response status: ${response.statusCode}');
      print('[ApiService] Sleep history response body: ${response.body}');

      if (response.statusCode == 200) {
        // The backend returns an array directly
        final dynamic decodedBody = jsonDecode(response.body);
        print('[ApiService] Decoded body type: ${decodedBody.runtimeType}');
        
        if (decodedBody is List) {
          final List<Map<String, dynamic>> result = [];
          for (var item in decodedBody) {
            result.add(Map<String, dynamic>.from(item));
          }
          print('[ApiService] Returning ${result.length} entries');
          return result;
        } else {
          print('[ApiService] ERROR: Response is not a List, it is: ${decodedBody.runtimeType}');
          return [];
        }
      } else {
        print('[ApiService] Failed to get sleep history. Status: ${response.statusCode}');
        print('[ApiService] Error body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[ApiService] Sleep history error: $e');
      print('[ApiService] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> deleteSleepEntry(String entryId) async {
    try {
      print('[ApiService] Deleting sleep entry: $entryId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/sleep/entries/$entryId'),
        headers: headers,
      );

      print('[ApiService] Delete sleep response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Delete sleep error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getSleepStats(String userId, {int days = 30}) async {
    try {
      print('[ApiService] Getting sleep stats for user: $userId, days: $days');
      
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/stats/$userId?days=$days'),
        headers: headers,
      );

      print('[ApiService] Sleep stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get sleep stats');
      }
    } catch (e) {
      print('[ApiService] Sleep stats error: $e');
      return {};
    }
  }

  //Meal logging Funtions
  // Analyze and log a meal
  Future<Map<String, dynamic>> analyzeMeal(Map<String, dynamic> mealData) async {
    try {
      print('[ApiService] Analyzing meal: ${mealData['food_item']}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/meals/analyze'),
        headers: headers,
        body: jsonEncode(mealData),
      );

      print('[ApiService] Meal analysis response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to analyze meal');
      }
    } catch (e) {
      print('[ApiService] Meal analysis error: $e');
      rethrow;
    }
  }

  // Get meal history
  Future<List<Map<String, dynamic>>> getMealHistory(String userId, {String? date}) async {
    try {
      String url = '$baseUrl/meals/history/$userId';
      if (date != null) {
        url += '?date=$date';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['meals'] != null) {
          final meals = List<Map<String, dynamic>>.from(data['meals']);
          return meals;
        }
      }
      
      throw Exception('Failed to load meal history');
    } catch (e) {
      print('❌ Error getting meal history: $e');
      return [];
    }
  }

  // Get daily nutrition summary
  Future<Map<String, dynamic>> getDailySummary(String userId, {String? date}) async {
    try {
      final dateParam = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await http.get(
        Uri.parse('$baseUrl/daily-summary/$userId?date=$dateParam'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle the response structure - check multiple possible paths
        final mealsData = data['meals'] ?? data['totals'] ?? {};
        final totalsData = data['totals'] ?? data['meals'] ?? {};
        
        final result = {
          'totals': {
            'calories': (totalsData['calories'] ?? 
                        totalsData['total_calories'] ?? 
                        totalsData['calories_consumed'] ?? 0.0).toDouble(),
            'protein_g': (totalsData['protein_g'] ?? 
                        totalsData['total_protein'] ?? 0.0).toDouble(),
            'carbs_g': (totalsData['carbs_g'] ?? 
                      totalsData['total_carbs'] ?? 0.0).toDouble(),
            'fat_g': (totalsData['fat_g'] ?? 
                    totalsData['total_fat'] ?? 0.0).toDouble(),
            'fiber_g': (totalsData['fiber_g'] ?? 
                      totalsData['total_fiber'] ?? 0.0).toDouble(),
            'sugar_g': (totalsData['sugar_g'] ?? 
                      totalsData['total_sugar'] ?? 0.0).toDouble(),
            'sodium_mg': (totalsData['sodium_mg'] ?? 
                        totalsData['total_sodium'] ?? 0.0).toDouble(),
          },
          'meals_count': mealsData['meals_count'] ?? mealsData['total_count'] ?? 0,
        };
        
        return result;
      }
      
      throw Exception('Failed to load daily summary: ${response.statusCode}');
    } catch (e) {
      print('❌ Error getting daily summary: $e');
      return {
        'totals': {
          'calories': 0.0,
          'protein_g': 0.0,
          'carbs_g': 0.0,
          'fat_g': 0.0,
          'fiber_g': 0.0,
          'sugar_g': 0.0,
          'sodium_mg': 0.0,
        },
        'meals_count': 0,
      };
    }
  }

  // Delete a meal
  Future<bool> deleteMeal(String mealId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/meals/$mealId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Delete meal error: $e');
      return false;
    }
  }

  // Update a meal
  Future<Map<String, dynamic>> updateMeal(String mealId, Map<String, dynamic> mealData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/meals/$mealId'),
        headers: headers,
        body: json.encode(mealData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Failed to update meal');
    } catch (e) {
      print('Error updating meal: $e');
      throw e;
    }
  }

  // Period Logging Functions
  Future<String> savePeriodEntry(PeriodEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/period'),
        headers: headers,
        body: jsonEncode({
          'id': entry.id,
          'user_id': entry.userId,
          'start_date': entry.startDate.toIso8601String(),
          'end_date': entry.endDate?.toIso8601String(),
          'flow_intensity': entry.flowIntensity,
          'symptoms': entry.symptoms,
          'mood': entry.mood,
          'notes': entry.notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] ?? entry.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      } else {
        throw Exception('Failed to save period entry: ${response.body}');
      }
    } catch (e) {
      print('Error saving period entry to API: $e');
      rethrow;
    }
  }

  Future<List<PeriodEntry>> getPeriodHistory(String userId, {int limit = 12}) async {
    try {
      print('[ApiService] Getting period history for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/period/$userId?limit=$limit'),
        headers: headers,
      );

      print('[ApiService] Period history response status: ${response.statusCode}');
      print('[ApiService] Period history response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        // ✅ Handle different response formats
        List<dynamic> periodsData = [];
        
        if (responseData is Map<String, dynamic>) {
          // If response is wrapped in an object
          if (responseData['periods'] != null && responseData['periods'] is List) {
            periodsData = responseData['periods'];
          } else if (responseData['success'] == true && responseData['periods'] is List) {
            periodsData = responseData['periods'];
          }
        } else if (responseData is List) {
          // If response is directly a list
          periodsData = responseData;
        }
        
        return periodsData
            .where((item) => item is Map<String, dynamic>)
            .map<PeriodEntry>((item) => PeriodEntry.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        print('[ApiService] Period history error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Period history error: $e');
      return [];
    }
  }

  Future<PeriodEntry?> getCurrentPeriod(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/period/$userId/current'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return PeriodEntry.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching current period from API: $e');
      return null;
    }
  }

  Future<void> deletePeriodEntry(String entryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/period/$entryId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete period entry: ${response.body}');
      }
    } catch (e) {
      print('Error deleting period entry from API: $e');
      rethrow;
    }
  }

  // Exercise Logging Functions
  Future<Map<String, dynamic>> createExerciseEntry(Map<String, dynamic> exerciseData) async {
    // This just calls the existing logExercise method
    return await logExercise(exerciseData);
  }


  Future<Map<String, dynamic>> logExercise(Map<String, dynamic> exerciseData) async {
    try {
      print('[ApiService] Logging exercise: ${exerciseData['exercise_name']}');
      print('[ApiService] Exercise data: $exerciseData'); // Debug print
      
      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: headers,
        body: jsonEncode(exerciseData),
      );

      print('[ApiService] Exercise log response: ${response.statusCode}');
      print('[ApiService] Exercise log response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        print('[ApiService] Exercise log error details: $errorData'); // Debug print
        throw Exception(errorData['detail'] ?? 'Failed to log exercise');
      }
    } catch (e) {
      print('[ApiService] Exercise log error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseLogs(
    String userId, {
    String? startDate,
    String? endDate,
    String? exerciseType,
    int limit = 50,
  }) async {
    try {
      print('[ApiService] Getting exercise logs for user: $userId');
      
      String url = '$baseUrl/exercise/logs/$userId?limit=$limit';
      
      if (startDate != null) url += '&start_date=$startDate';
      if (endDate != null) url += '&end_date=$endDate';
      if (exerciseType != null) url += '&exercise_type=$exerciseType';
      
      print('[ApiService] Exercise logs URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('[ApiService] Exercise logs response status: ${response.statusCode}');
      print('[ApiService] Exercise logs response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ Handle different response formats
        if (data is Map<String, dynamic>) {
          if (data['exercises'] != null && data['exercises'] is List) {
            return List<Map<String, dynamic>>.from(data['exercises']);
          }
          if (data['success'] == true && data['exercises'] is List) {
            return List<Map<String, dynamic>>.from(data['exercises']);
          }
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        
        print('[ApiService] No exercises found in response');
        return [];
      } else {
        print('[ApiService] Exercise logs error: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Exercise logs error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getExerciseStats(String userId, {int days = 30}) async {
    try {
      print('[ApiService] Getting exercise stats for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/stats/$userId?days=$days'),
        headers: headers,
      );

      print('[ApiService] Exercise stats response status: ${response.statusCode}');
      print('[ApiService] Exercise stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ Handle different response formats
        if (data is Map<String, dynamic>) {
          if (data['stats'] != null && data['stats'] is Map) {
            return Map<String, dynamic>.from(data['stats']);
          }
        }
        
        // ✅ Return default stats if response is unexpected format
        print('[ApiService] Unexpected stats response format, returning defaults');
        return _getDefaultStats();
      } else {
        print('[ApiService] Exercise stats error: ${response.body}');
        return _getDefaultStats();
      }
    } catch (e) {
      print('[ApiService] Exercise stats error: $e');
      return _getDefaultStats();
    }
  }

  Map<String, dynamic> _getDefaultStats() {
    return {
      'total_workouts': 0,
      'total_minutes': 0,
      'total_calories': 0.0,
      'avg_duration': 0.0,
      'most_common_type': null,
      'type_breakdown': <String, int>{},
    };
  }

  Future<void> deleteExerciseLog(String exerciseId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/exercise/log/$exerciseId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete exercise: ${response.body}');
      }
    } catch (e) {
      print('Error deleting exercise: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExerciseHistory(
    String userId, {
    String? date,
    int limit = 20,
  }) async {
    try {
      String url = '$baseUrl/exercise/history/$userId?limit=$limit';
      if (date != null) {
        url += '&date=$date';
      }

      print('[ApiService] Fetching exercise history: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('[ApiService] Exercise history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      } else {
        print('[ApiService] Failed to get exercise history: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Get exercise history error: $e');
      return [];
    }
  }

  // Add method to get weekly summary
  Future<Map<String, dynamic>> getWeeklyExerciseSummary(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/weekly-summary/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] ?? {};
      } else {
        print('[ApiService] Weekly summary error: ${response.body}');
        return {};
      }
    } catch (e) {
      print('[ApiService] Weekly summary error: $e');
      return {};
    }
  }

  // Add method to delete exercise
  Future<bool> deleteExercise(String exerciseId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/exercise/$exerciseId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('[ApiService] Delete exercise error: $e');
      return false;
    }
  }

  // Add method to update exercise
  Future<Map<String, dynamic>> updateExercise(
    String exerciseId, 
    Map<String, dynamic> updateData
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/exercise/$exerciseId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update exercise');
      }
    } catch (e) {
      print('[ApiService] Update exercise error: $e');
      return {'success': false};
    }
  }

  // steps Logging Functions
  Future<StepEntry?> getTodaySteps(String userId) async {
    try {
      print('[ApiService] Getting today\'s steps for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps/$userId/today'),
        headers: headers,
      );

      print('[ApiService] Today\'s steps response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        // Handle if response is a Map with 'entry' field
        if (responseData is Map<String, dynamic>) {
          final Map<String, dynamic> data = responseData;
          
          if (data['entry'] != null && data['entry'] is Map<String, dynamic>) {
            return StepEntry.fromJson(data['entry'] as Map<String, dynamic>);
          }
        }
        
        // Handle if response is directly a StepEntry object
        if (responseData is Map<String, dynamic>) {
          return StepEntry.fromJson(responseData);
        }
        
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('[ApiService] Today\'s steps HTTP Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[ApiService] Today\'s steps error: $e');
      return null;
    }
  }

  Future<List<StepEntry>> getStepsInRange(String userId, DateTime startDate, DateTime endDate) async {
    try {
      print('[ApiService] Getting steps in range for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps/$userId/range?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}'),
        headers: headers,
      );

      print('[ApiService] Steps range response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        // Handle if response is directly a List
        if (responseData is List) {
          return responseData
              .where((item) => item is Map<String, dynamic>)
              .map<StepEntry>((item) => StepEntry.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        
        // Handle if response is a Map with 'entries' field
        if (responseData is Map<String, dynamic>) {
          final Map<String, dynamic> data = responseData;
          
          if (data['entries'] != null && data['entries'] is List) {
            final List<dynamic> entries = data['entries'] as List<dynamic>;
            
            return entries
                .where((item) => item is Map<String, dynamic>)
                .map<StepEntry>((item) => StepEntry.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
        
        return [];
      } else {
        print('[ApiService] Steps range HTTP Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Steps range error: $e');
      return [];
    }
  }

  Future<void> saveStepEntry(StepEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/steps'),
        headers: headers,
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save step entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to save step entry: $e');
    }
  }

  Future<List<StepEntry>> getAllSteps(String userId) async {
    try {
      print('[ApiService] Getting all steps for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps/$userId'),
        headers: headers,
      );

      print('[ApiService] All steps response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        // Handle if response is directly a List
        if (responseData is List) {
          print('[ApiService] Response is a direct list with ${responseData.length} items');
          return responseData
              .where((item) => item is Map<String, dynamic>)
              .map<StepEntry>((item) => StepEntry.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        
        // Handle if response is a Map with 'entries' field
        if (responseData is Map<String, dynamic>) {
          final Map<String, dynamic> data = responseData;
          
          if (data['entries'] != null && data['entries'] is List) {
            final List<dynamic> entries = data['entries'] as List<dynamic>;
            print('[ApiService] Found ${entries.length} step entries in entries field');
            
            return entries
                .where((item) => item is Map<String, dynamic>)
                .map<StepEntry>((item) => StepEntry.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
        
        print('[ApiService] No valid entries found in response');
        print('[ApiService] Response structure: ${responseData.runtimeType}');
        return [];
      } else {
        print('[ApiService] HTTP Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Get all steps error: $e');
      return [];
    }
  }

  Future<void> deleteStepEntry(String userId, DateTime date) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/steps/$userId/${date.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete step entry: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete step entry: $e');
    }
  }

  Future<Map<String, dynamic>> getStepStats(String userId, {int days = 7}) async {
    try {
      print('[ApiService] Getting step stats for user: $userId, days: $days');
      
      final response = await http.get(
        Uri.parse('$baseUrl/steps/$userId/stats?days=$days'),
        headers: headers,
      );

      print('[ApiService] Step stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get step stats');
      }
    } catch (e) {
      print('[ApiService] Step stats error: $e');
      return {};
    }
  }

}
