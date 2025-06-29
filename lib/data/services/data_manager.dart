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
import 'package:shared_preferences/shared_preferences.dart';


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
      
      // Use the new onboarding completion format
      return await completeOnboarding(userProfile.toOnboardingFormat());
    } catch (e) {
      _log('Failed to save user profile: $e');
      rethrow;
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
            userProfile = await _apiService.getUserProfileById(userId); // userId is guaranteed non-null here
          } else {
            _log('Loading user profile via direct database connection');
            userProfile = await UserRepository.getUserProfileById(userId); // userId is guaranteed non-null here
          }
          
          if (userProfile != null) {
            _log('User profile loaded from remote source');
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
          final userProfile = UserProfile.fromMap(jsonDecode(userProfileJson));
          _log('User profile loaded from local storage');
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

  // Update user profile
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      _log('Starting to update user profile for ${userProfile.name}');
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID from shared preferences
      final userId = prefs.getString(userIdKey);
      
      // Check if connected to the internet and if user ID exists
      final isConnected = await _connectivityService.isConnected();
      
      // Add null check for userId
      if (isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Try to update the remote source
          if (kIsWeb) {
            _log('Updating user profile via API (web platform)');
            await _apiService.updateUserProfile(userId, userProfile); // userId is guaranteed non-null here
          } else {
            _log('Updating user profile via direct database connection');
            await UserRepository.updateUserProfile(userId, userProfile); // userId is guaranteed non-null here
          }
          
          _log('User profile updated remotely');
        } catch (e) {
          _log('Failed to update user profile remotely: $e');
        }
      }
      
      // Always update local storage
      await prefs.setString(userProfileKey, jsonEncode(userProfile.toMap()));
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

  // Synchronize local data with remote
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
      final userProfile = UserProfile.fromMap(jsonDecode(userProfileJson));
      
      // Add null check for userId
      if (userId != null && userId.isNotEmpty) {
        // User already exists remotely, update it
        if (kIsWeb) {
          _log('Synchronizing user profile via API (web platform)');
          await _apiService.updateUserProfile(userId, userProfile); // userId is guaranteed non-null here
        } else {
          _log('Synchronizing user profile via direct database connection');
          await UserRepository.updateUserProfile(userId, userProfile); // userId is guaranteed non-null here
        }
        
        _log('User profile synchronized with remote source');
      } else {
        // User does not exist remotely, create it
        String newUserId;
        
        if (kIsWeb) {
          _log('Creating new user profile via API (web platform)');
          newUserId = await _apiService.saveUserProfile(userProfile);
        } else {
          _log('Creating new user profile via direct database connection');
          newUserId = await UserRepository.saveUserProfile(userProfile);
        }
        
        // Save user ID to shared preferences
        await prefs.setString(userIdKey, newUserId);
        
        _log('New user profile created remotely with ID: $newUserId');
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

  // Clear all data
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
          // Try to delete from remote source
          if (kIsWeb) {
            _log('Deleting user profile via API (web platform)');
            await _apiService.deleteUserProfile(userId); // userId is guaranteed non-null here
          } else {
            _log('Deleting user profile via direct database connection');
            await UserRepository.deleteUserProfile(userId); // userId is guaranteed non-null here
          }
          
          _log('User profile deleted from remote source');
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