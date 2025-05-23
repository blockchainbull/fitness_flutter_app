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
  Future<void> saveUserProfile(UserProfile userProfile) async {
    try {
      _log('Starting to save user profile for ${userProfile.name}');
      
      // Get shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Check if connected to the internet
      final isConnected = await _connectivityService.isConnected();
      
      String userId = '';
      
      if (isConnected) {
        try {
          // Try to save to the remote source
          if (kIsWeb) {
            _log('Saving user profile via API (web platform)');
            userId = await _apiService.saveUserProfile(userProfile);
          } else {
            _log('Saving user profile via direct database connection');
            userId = await UserRepository.saveUserProfile(userProfile);
          }
          
          // Save user ID to shared preferences
          await prefs.setString(userIdKey, userId);
          
          _log('User profile saved remotely with ID: $userId');
        } catch (e) {
          _log('Failed to save user profile remotely: $e');
          _log('Falling back to local storage only...');
          
          // Fall back to local storage only
          userId = '';
        }
      } else {
        _log('No internet connection, saving to local storage only');
      }
      
      // Always save to local storage as a backup
      await prefs.setString(userProfileKey, jsonEncode(userProfile.toMap()));
      await prefs.setBool(onboardingCompletedKey, true);
      
      _log('User profile saved to local storage');
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
      
      if (isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Try to update the remote source
          if (kIsWeb) {
            _log('Updating user profile via API (web platform)');
            await _apiService.updateUserProfile(userId, userProfile);
          } else {
            _log('Updating user profile via direct database connection');
            await UserRepository.updateUserProfile(userId, userProfile);
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
      
      if (userId != null && userId.isNotEmpty) {
        // User already exists remotely, update it
        if (kIsWeb) {
          _log('Synchronizing user profile via API (web platform)');
          await _apiService.updateUserProfile(userId, userProfile);
        } else {
          _log('Synchronizing user profile via direct database connection');
          await UserRepository.updateUserProfile(userId, userProfile);
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
      
      if (isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Try to delete from remote source
          if (kIsWeb) {
            _log('Deleting user profile via API (web platform)');
            await _apiService.deleteUserProfile(userId);
          } else {
            _log('Deleting user profile via direct database connection');
            await UserRepository.deleteUserProfile(userId);
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
}