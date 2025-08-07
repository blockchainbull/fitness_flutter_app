// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';

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

  // Update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      print('[ApiService] Updating profile for user: ${userProfile.id}');
      
      // Use the correct backend endpoint that exists
      final response = await http.put(
        Uri.parse('http://localhost:8000/update-user/${userProfile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Only send the fields that can be updated
          'height': userProfile.height,
          'weight': userProfile.weight,
          'activityLevel': userProfile.activityLevel,
          'primaryGoal': userProfile.primaryGoal,
          'weightGoal': userProfile.weightGoal,
          'targetWeight': userProfile.targetWeight,
          'goalTimeline': userProfile.goalTimeline,
          'sleepHours': userProfile.sleepHours,
          'bedtime': userProfile.bedtime,
          'wakeupTime': userProfile.wakeupTime,
          'sleepIssues': userProfile.sleepIssues,
          'dietaryPreferences': userProfile.dietaryPreferences,
          'waterIntake': userProfile.waterIntake,
          'medicalConditions': userProfile.medicalConditions,
          'otherMedicalCondition': userProfile.otherMedicalCondition,
          'preferredWorkouts': userProfile.preferredWorkouts,
          'workoutFrequency': userProfile.workoutFrequency,
          'workoutDuration': userProfile.workoutDuration,
          'workoutLocation': userProfile.workoutLocation,
          'availableEquipment': userProfile.availableEquipment,
          'fitnessLevel': userProfile.fitnessLevel,
          'hasTrainer': userProfile.hasTrainer,
        }),
      );

      print('[ApiService] Update response status: ${response.statusCode}');
      print('[ApiService] Update response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      debugPrint('API error updating profile: $e');
      rethrow;
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('[ApiService] Attempting login for: $email');
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/auth/login'), 
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('[ApiService] Login response status: ${response.statusCode}');
      print('[ApiService] Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'userId': data['user']?['id'] ?? data['userId'], 
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      print('[ApiService] Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(String userId, String message) async {
    try {
      print('[ApiService] Sending chat message for user: $userId');
      print('[ApiService] Message: $message');
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/submit-prompt'), 
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'user_prompt': message,
          'agent_name': 'health_coach',
        }),
      );

      print('[ApiService] Chat response status: ${response.statusCode}');
      print('[ApiService] Chat response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'response': data['response'] ?? 'Sorry, I couldn\'t process your message.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Chat message failed');
      }
    } catch (e) {
      print('[ApiService] Chat error: $e');
      rethrow;
    }
  }

  // Save weight entry
  Future<String> saveWeightEntry(WeightEntry weightEntry) async {
    try {
      print('[ApiService] Saving weight entry: ${weightEntry.weight} kg');
      print('[ApiService] User ID: ${weightEntry.userId}');
      print('[ApiService] Date: ${weightEntry.date.toIso8601String()}');
      
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/health/weight'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': weightEntry.userId,
          'date': weightEntry.date.toIso8601String(),
          'weight': weightEntry.weight,
          'notes': weightEntry.notes,
        }),
      );

      print('[ApiService] Weight entry response status: ${response.statusCode}');
      print('[ApiService] Weight entry response body: ${response.body}');

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
        Uri.parse('http://localhost:8000/api/health/weight/$userId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiService] Weight history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['weights'] != null && data['weights'] is List) {
          return (data['weights'] as List)
              .map((item) => WeightEntry.fromMap(item))
              .toList();
        }
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get weight history');
      }
    } catch (e) {
      print('[ApiService] Weight history error: $e');
      return []; // Return empty list on error
    }
  }

  // Get latest weight entry
  Future<WeightEntry?> getLatestWeight(String userId) async {
    try {
      print('[ApiService] Getting latest weight for user: $userId');
      
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/health/weight/$userId/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiService] Latest weight response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['weight'] != null) {
          return WeightEntry.fromMap(data['weight']);
        }
        return null;
      } else if (response.statusCode == 404) {
        // No weight entries found
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
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiService] Delete weight response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete weight entry');
      }
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
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
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
      print('[ApiService] Getting chat history for user: $userId');
      
      final response = await http.get(
        Uri.parse('http://localhost:8000/get-conversation/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('[ApiService] Chat history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['conversation'] != null && data['conversation'] is List) {
          List<Map<String, dynamic>> formattedHistory = [];
          
          for (var message in data['conversation']) {
            if (message is Map<String, dynamic>) {
              formattedHistory.add({
                'content': message['content'] ?? '',
                'role': message['role'] ?? 'assistant',
                'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
          
          return formattedHistory;
        }
        return [];
      } else {
        print('[ApiService] Failed to get chat history: ${response.body}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Chat history error: $e');
      return [];
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

  // Supplement logging functions
  Future<Map<String, dynamic>> saveSupplementPreferences(String userId, List<Map<String, dynamic>> supplements) async {
    try {
      print('[ApiService] Saving supplement preferences for user: $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/supplements/preferences'),
        headers: {'Content-Type': 'application/json'},
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


  // Log daily supplement intake
  Future<Map<String, dynamic>> logSupplementIntake(Map<String, dynamic> logData) async {
    try {
      print('[ApiService] Logging supplement intake: ${logData['supplement_name']} = ${logData['taken']}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/supplements/log'),
        headers: {'Content-Type': 'application/json'},
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
  Future<List<Map<String, dynamic>>> getSupplementHistory(String userId, {int days = 30}) async {
    try {
      print('[ApiService] Getting supplement history for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/history/$userId?days=$days'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ApiService] Supplement history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['history'] != null) {
          return List<Map<String, dynamic>>.from(data['history']);
        }
        return [];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to get supplement history');
      }
    } catch (e) {
      print('[ApiService] Error getting supplement history: $e');
      return []; // Return empty list on error instead of throwing
    }
  }

  Future<Map<String, bool>> getTodaysSupplementStatus(String userId) async {
    try {
      print('[ApiService] Getting today\'s supplement status for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/status/$userId'),
        headers: {'Content-Type': 'application/json'},
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

}