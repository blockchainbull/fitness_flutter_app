// lib/data/services/data_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/user_repository.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/data/services/connectivity_service.dart';
import 'package:user_onboarding/data/services/database_service.dart';
import 'package:user_onboarding/data/services/exercise_data_service.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiService _apiService = ApiService();

  // Local storage keys
  static const String userIdKey = 'user_id';
  static const String userProfileKey = 'user_profile';
  static const String onboardingCompletedKey = 'onboarding_completed';

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  // Helper method for logging
  void _log(String message) {
    print('[DataManager] $message');
  }

  // Initialize data manager
  Future<void> initialize() async {
    try {
      // Initialize database service if not running on web and connected to the internet
      final isConnected = await _connectivityService.isConnected();
      if (isConnected) {
        if (kIsWeb) {
          _log('Web platform detected, using API service');
        } else {
          _log('Native platform detected, initializing direct database connection');
          await DatabaseService.initialize();
        }
      } else {
        _log('No internet connection, using local storage only');
      }
    } catch (e) {
      _log('Failed to initialize data manager: $e');
    }
  }

  // Save user profile
  Future<String?> saveUserProfile(UserProfile userProfile) async {
    try {
      _log('Starting to save user profile for ${userProfile.name}');
      
      // Save to backend/database first
      final userId = await completeOnboarding(userProfile.toOnboardingFormat());
      
      if (userId != null) {
        // Also save to local storage for offline access
        await _saveUserProfileLocally(userProfile.copyWith(id: userId));
        _log('User profile saved both remotely and locally');
      }
      
      return userId;
    } catch (e) {
      _log('Failed to save user profile: $e');
      rethrow;
    }
  }

  Future<void> _saveUserProfileLocally(UserProfile userProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert UserProfile to Map
      final userProfileMap = userProfile.toMap();
      
      // Ensure the ID is included in the saved data
      if (userProfile.id != null && userProfile.id!.isNotEmpty) {
        userProfileMap['id'] = userProfile.id;
        // Also save the user ID separately for easy access
        await prefs.setString(userIdKey, userProfile.id!);
      }
      
      // Save the user profile as JSON
      await prefs.setString(userProfileKey, jsonEncode(userProfileMap));
      
      _log('User profile saved to local storage');
    } catch (e) {
      _log('Failed to save user profile locally: $e');
      // Don't rethrow here - local storage failure shouldn't break the main flow
    }
  }

  // Load user profile
  Future<UserProfile?> loadUserProfile() async {
    try {
      _log('Loading user profile');
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID from shared preferences
      final userId = prefs.getString(userIdKey);
      
      // Check if connected to the internet and if user ID exists
      final isConnected = await _connectivityService.isConnected();
      
      // Add null check for userId
      if (isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Try to load from remote source
          UserProfile? userProfile;
          
          if (kIsWeb) {
            _log('Loading user profile via API (web platform)');
            userProfile = await _apiService.getUserProfileById(userId);
          } else {
            _log('Loading user profile via direct database connection');
            userProfile = await UserRepository.getUserProfileById(userId);
          }
          
          if (userProfile != null) {
            _log('User profile loaded from remote source');

            if (userProfile.id == null || userProfile.id!.isEmpty) {
              userProfile = userProfile.copyWith(id: userId);
              _log('Fixed missing ID in remote profile');
            }
          
            // Save the corrected profile locally
            await _saveUserProfileLocally(userProfile);

            return userProfile;
          }
        } catch (e) {
          _log('Failed to load user profile from remote: $e');
          _log('Falling back to local storage...');
        }
      }
      
      // Fall back to local storage
      final userProfileJson = prefs.getString(userProfileKey);
      
      if (userProfileJson != null && userProfileJson.isNotEmpty) {
        try {
          // Load user profile from local storage
          final userProfileData = jsonDecode(userProfileJson);

          if (userId != null && userId.isNotEmpty) {
            userProfileData['id'] = userId; // Add the user ID to the profile data
          }

          final userProfile = UserProfile.fromMap(userProfileData);
          _log('User profile loaded from local storage');
          _log('UserProfile ID: ${userProfile.id}');
          return userProfile;
        } catch (e) {
          _log('Failed to load user profile from local storage: $e');
        }
      }
    
      _log('No user profile found');
      return null;
    } catch (e) {
      _log('Failed to load user profile: $e');
      return null;
    }
  }

  Future<String?> completeOnboarding(Map<String, dynamic> onboardingData) async {
    try {
      _log('Starting onboarding completion');
      
      final prefs = await SharedPreferences.getInstance();
      final isConnected = await _connectivityService.isConnected();
      
      String? userId;
      
      if (isConnected) {
        try {
          // Complete onboarding via API
          final response = await _apiService.completeOnboarding(onboardingData);
          
          if (response['success'] == true) {
            final responseUserId = response['userId'];
            if (responseUserId != null) {
              userId = responseUserId.toString(); // Ensure it's a String
              
              // Save user ID to shared preferences
              await prefs.setString(userIdKey, userId);
              await prefs.setBool(onboardingCompletedKey, true);
              
              _log('Onboarding completed remotely with user ID: $userId');
              
              // Try to get and save the user profile locally
              try {
                final userProfile = await _apiService.getUserProfileById(userId);
                await prefs.setString(userProfileKey, jsonEncode(userProfile.toMap()));
                _log('User profile saved locally after onboarding');
              } catch (e) {
                _log('Could not save user profile locally after onboarding: $e');
              }
            }
          }
        } catch (e) {
          _log('Failed to complete onboarding remotely: $e');
          // Fall back to local storage
        }
      }
      
      if (userId == null) {
        // Fallback: save locally and generate a temporary ID
        userId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(userIdKey, userId);
        await prefs.setBool(onboardingCompletedKey, true);
        
        // Create a UserProfile from onboarding data and save locally
        try {
          final basicInfo = onboardingData['basicInfo'] ?? {};
          final weightGoal = onboardingData['weightGoal'] ?? {};
          final sleepInfo = onboardingData['sleepInfo'] ?? {};
          final dietaryPrefs = onboardingData['dietaryPreferences'] ?? {};
          final workoutPrefs = onboardingData['workoutPreferences'] ?? {};
          final exerciseSetup = onboardingData['exerciseSetup'] ?? {};
          
          final userProfileData = {
            'id': userId, // FIXED: Include the ID in the profile data
            'name': basicInfo['name'] ?? '',
            'email': basicInfo['email'] ?? '',
            'password': basicInfo['password'],
            'gender': basicInfo['gender'] ?? '',
            'age': basicInfo['age'] ?? 0,
            'height': basicInfo['height'] ?? 0.0,
            'weight': basicInfo['weight'] ?? 0.0,
            'activityLevel': basicInfo['activityLevel'] ?? '',
            'primaryGoal': onboardingData['primaryGoal'] ?? '',
            'weightGoal': weightGoal['weightGoal'] ?? '',
            'targetWeight': weightGoal['targetWeight'] ?? 0.0,
            'goalTimeline': weightGoal['timeline'] ?? '',
            'sleepHours': sleepInfo['sleepHours'] ?? 7.0,
            'bedtime': sleepInfo['bedtime'] ?? '',
            'wakeupTime': sleepInfo['wakeupTime'] ?? '',
            'sleepIssues': sleepInfo['sleepIssues'] ?? [],
            'dietaryPreferences': dietaryPrefs['dietaryPreferences'] ?? [],
            'waterIntake': dietaryPrefs['waterIntake'] ?? 2.0,
            'medicalConditions': dietaryPrefs['medicalConditions'] ?? [],
            'otherMedicalCondition': dietaryPrefs['otherCondition'] ?? '',
            'preferredWorkouts': workoutPrefs['workoutTypes'] ?? [],
            'workoutFrequency': workoutPrefs['frequency'] ?? 3,
            'workoutDuration': workoutPrefs['duration'] ?? 30,
            'workoutLocation': exerciseSetup['workoutLocation'] ?? '',
            'availableEquipment': exerciseSetup['equipment'] ?? [],
            'fitnessLevel': exerciseSetup['fitnessLevel'] ?? 'Beginner',
            'hasTrainer': exerciseSetup['hasTrainer'] ?? false,
            'formData': {
              'bmi': basicInfo['bmi'] ?? 0.0,
              'bmr': basicInfo['bmr'] ?? 0.0,
              'tdee': basicInfo['tdee'] ?? 0.0,
            }
          };
          
          await prefs.setString(userProfileKey, jsonEncode(userProfileData));
          _log('User profile saved locally as fallback');
        } catch (e) {
          _log('Error saving user profile locally: $e');
        }
      }
      
      return userId;
    } catch (e) {
      _log('Error completing onboarding: $e');
      return null;
    }
  }

  // FIXED: Update user profile method
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      _log('Starting to update user profile for ${userProfile.name}');
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Check if connected to the internet
      final isConnected = await _connectivityService.isConnected();
      
      if (isConnected) {
        try {
          // FIXED: Use the new ApiService method signature (single parameter)
          _log('Updating user profile via API');
          await _apiService.updateUserProfile(userProfile);
          _log('User profile updated remotely');
        } catch (e) {
          _log('Failed to update user profile remotely: $e');
          // Don't rethrow - we'll still save locally
        }
      }
      
      // Always update local storage
      await _saveUserProfileLocally(userProfile);
      _log('User profile updated in local storage');
    } catch (e) {
      _log('Failed to update user profile: $e');
      rethrow;
    }
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(onboardingCompletedKey) ?? false;
    } catch (e) {
      _log('Failed to check if onboarding is completed: $e');
      return false;
    }
  }

  // FIXED: Synchronize local data with remote
  Future<void> synchronizeData() async {
    try {
      _log('Starting data synchronization');
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Check if connected to the internet
      final isConnected = await _connectivityService.isConnected();
      
      if (!isConnected) {
        _log('No internet connection. Skipping synchronization.');
        return;
      }
      
      // Get user ID from shared preferences
      final userId = prefs.getString(userIdKey);
      
      // Get user profile from local storage
      final userProfileJson = prefs.getString(userProfileKey);
      
      if (userProfileJson == null || userProfileJson.isEmpty) {
        _log('No local user profile found. Skipping synchronization.');
        return;
      }
      
      // Parse user profile
      UserProfile userProfile = UserProfile.fromMap(jsonDecode(userProfileJson));
      
      // Ensure the profile has the correct ID
      if (userId != null && userId.isNotEmpty) {
        if (userProfile.id == null || userProfile.id!.isEmpty) {
          userProfile = userProfile.copyWith(id: userId);
        }
      }
      
      // Add null check for userId
      if (userId != null && userId.isNotEmpty) {
        // User already exists remotely, update it
        try {
          _log('Synchronizing user profile via API');
          await _apiService.updateUserProfile(userProfile); // FIXED: Use new method signature
          _log('User profile synchronized with remote source');
        } catch (e) {
          _log('Failed to synchronize user profile: $e');
        }
      } else {
        // User does not exist remotely, create it
        try {
          _log('Creating new user profile via API');
          final newUserId = await _apiService.saveUserProfile(userProfile);
          
          // Save user ID to shared preferences
          await prefs.setString(userIdKey, newUserId);
          
          _log('New user profile created remotely with ID: $newUserId');
        } catch (e) {
          _log('Failed to create new user profile: $e');
        }
      }
    } catch (e) {
      _log('Failed to synchronize data: $e');
    }
  }

  Future<bool> saveExercises(String userId, List<Map<String, dynamic>> exercises) async {
    final exerciseService = ExerciseDataService();
    return await exerciseService.saveExercises(userId, exercises);
  }

  // Load exercises
  Future<List<Map<String, dynamic>>> loadExercises(String userId) async {
    final exerciseService = ExerciseDataService();
    return await exerciseService.loadExercises(userId);
  }

  // Add exercise
  Future<bool> addExercise(String userId, Map<String, dynamic> exercise) async {
    final exerciseService = ExerciseDataService();
    return await exerciseService.addExercise(userId, exercise);
  }

  // FIXED: Clear all data method
  Future<void> clearData() async {
    try {
      _log('Clearing all user data');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID from shared preferences
      final userId = prefs.getString(userIdKey);
      
      // Check if connected to the internet and if user ID exists
      final isConnected = await _connectivityService.isConnected();
      
      // Add null check for userId
      if (isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Note: deleteUserProfile method doesn't exist in current ApiService
          // We'll skip this for now since it's not implemented
          _log('Remote user profile deletion not implemented');
        } catch (e) {
          _log('Failed to delete user profile from remote source: $e');
        }
      }
      
      // Clear shared preferences
      await prefs.clear();
      _log('Local data cleared');
    } catch (e) {
      _log('Failed to clear data: $e');
      rethrow;
    }
  }

  // Login user method
  Future<String?> loginUser(String email, String password) async {
    try {
      _log('Starting login for: $email');
      
      final prefs = await SharedPreferences.getInstance();
      final isConnected = await _connectivityService.isConnected();
      
      if (!isConnected) {
        _log('No internet connection for login');
        throw Exception('No internet connection');
      }
      
      // Call login API
      final response = await _apiService.loginUser(email, password);
      
      if (response['success'] == true) {
        final userId = response['userId'];
        
        // Save login info locally
        await prefs.setString(userIdKey, userId);
        await prefs.setBool(onboardingCompletedKey, true);
        
        // Try to get and save user profile
        try {
          final userProfile = await _apiService.getUserProfileById(userId);
          await prefs.setString(userProfileKey, jsonEncode(userProfile.toMap()));
          _log('User profile saved after login');
        } catch (e) {
          _log('Could not save user profile after login: $e');
        }
        
        _log('Login successful for: $email');
        return userId;
      }
      
      return null;
    } catch (e) {
      _log('Login failed: $e');
      rethrow;
    }
  }

  // Check if user has valid login
  Future<bool> hasValidLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(userIdKey);
      final onboardingCompleted = prefs.getBool(onboardingCompletedKey) ?? false;
      
      return userId != null && userId.isNotEmpty && onboardingCompleted;
    } catch (e) {
      _log('Error checking login status: $e');
      return false;
    }
  }

  // Clear login data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _log('User logged out');
    } catch (e) {
      _log('Error during logout: $e');
    }
  }
}