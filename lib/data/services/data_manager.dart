// lib/data/services/data_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api/auth_api.dart';
import 'package:user_onboarding/data/services/connectivity_service.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';
import 'package:user_onboarding/utils/profile_update_notifier.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  final ConnectivityService _connectivityService = ConnectivityService();
  final AuthApi _apiService = AuthApi();

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
  Future<void> _saveUserProfileLocally(UserProfile userProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(userProfile.toMap());
      await prefs.setString(userProfileKey, profileJson);
      await prefs.setString(userIdKey, userProfile.id ?? '');
    } catch (e) {
      _log('Failed to save user profile locally: $e');
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
          
          // ALWAYS use API service, regardless of platform
          _log('Loading user profile via API');
          userProfile = await _apiService.getUserProfileById(userId);
          
          if (userProfile != null) {
            _log('User profile loaded from API');

            if (userProfile.id == null || userProfile.id!.isEmpty) {
              userProfile = userProfile.copyWith(id: userId);
              _log('Fixed missing ID in remote profile');
            }
          
            // Save the corrected profile locally
            await _saveUserProfileLocally(userProfile);

            return userProfile;
          }
        } catch (e) {
          _log('Failed to load user profile from API: $e');
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
            userId = response['userId']?.toString();
            
            if (userId != null) {
              // Save user ID
              await prefs.setString(userIdKey, userId);
              await prefs.setBool(onboardingCompletedKey, true);
              
              // Fetch the complete user profile from backend
              _log('Fetching user profile after onboarding...');
              final userProfile = await _apiService.getUserProfileById(userId);
              
              if (userProfile != null) {
                // Save to local storage
                await _saveUserProfileLocally(userProfile);
                
                // Set user as logged in with UserManager
                await UserManager.setCurrentUser(userProfile);
                
                _log('User profile fetched and saved after onboarding');
              }
              
              return userId;
            }
          }
        } catch (e) {
          _log('Failed to complete onboarding remotely: $e');
          // Continue with offline mode
        }
      }
      
      // Offline mode: Generate local ID and save data
      if (userId == null) {
        userId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(userIdKey, userId);
        await prefs.setBool(onboardingCompletedKey, true);
        
        // Create and save user profile locally
        final basicInfo = onboardingData['basicInfo'] ?? {};
        final userProfileData = {
          'id': userId,
          'name': basicInfo['name'] ?? '',
          'email': basicInfo['email'] ?? '',
          // ... map other fields from onboardingData
        };
        
        final userProfile = UserProfile.fromMap(userProfileData);
        await _saveUserProfileLocally(userProfile);
        await UserManager.setCurrentUser(userProfile);
        
        _log('Onboarding completed offline with local ID: $userId');
      }
      
      return userId;
    } catch (e) {
      _log('Failed to complete onboarding: $e');
      return null;
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      _log('Starting to update user profile for ${userProfile.name}');

      // Check if connected to the internet
      final isConnected = await _connectivityService.isConnected();
      
      UserProfile updatedProfile = userProfile;
      
      if (isConnected) {
        try {
          // Update via API and get the updated profile back
          _log('Updating user profile via API');
          updatedProfile = await _apiService.updateUserProfile(userProfile);
          _log('User profile updated remotely');
        } catch (e) {
          _log('Failed to update user profile remotely: $e');
          // Don't rethrow - we'll still save locally
        }
      }
      
      // Always update local storage with the latest profile
      await _saveUserProfileLocally(updatedProfile);

      await UserManager.setCurrentUser(updatedProfile);

      ProfileUpdateNotifier().notifyProfileUpdate(updatedProfile);

      _log('User profile updated in local storage and UserManager');

      return updatedProfile; // Return the updated profile
    } catch (e) {
      _log('Failed to update user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _log('=== LOGIN PROCESS STARTED ===');
      _log('Starting login for: $email');
      
      // Check connectivity first
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection');
      }
      
      // Attempt login with timeout. The backend runs on a tier that spins down
      // when idle, so the FIRST request after a quiet period can take 30–50s to
      // cold-start. Allow up to 60s here (matching AuthApi.loginUser) so a cold
      // start doesn't get killed prematurely; the login screen also fires a
      // warm-up ping on open to shrink this window.
      final result = await _apiService.loginUser(email, password).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _log('Login timed out after 60 seconds');
          throw Exception(
            'The server is taking longer than usual to respond (it may be '
            'waking up). Please try again in a moment.',
          );
        },
      );
      
      _log('API Response received: ${result}');
      
      if (result['success'] == true && result['user'] != null) {
        final userData = result['user'];
        final userId = userData['id'];
        
        _log('✅ Login API call successful');
        _log('User ID from API: $userId');
        _log('User data keys: ${userData.keys}');
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        
        // Save user ID
        await prefs.setString(userIdKey, userId);
        _log('✅ Saved user_id to SharedPreferences: $userId');
        
        // Save email
        await prefs.setString('user_email', email);
        _log('✅ Saved user_email to SharedPreferences');
        
        // Mark as logged in
        await prefs.setBool('is_logged_in', true);
        _log('✅ Marked is_logged_in as true');
        
        // Mark onboarding as completed (since they can login, they must have completed onboarding)
        await prefs.setBool(onboardingCompletedKey, true);
        _log('✅ Marked onboarding_completed as true');
        
        // Fetch and save the full user profile
        try {
          _log('Fetching full user profile from API...');
          final userProfile = await _apiService.getUserProfileById(userId);
          
          if (userProfile != null) {
            _log('✅ User profile fetched successfully');
            _log('Profile ID: ${userProfile.id}');
            _log('Profile Name: ${userProfile.name}');
            
            // Save profile locally
            await _saveUserProfileLocally(userProfile);
            _log('✅ User profile saved to local storage');
            
            // Also save via UserManager
            await UserManager.setCurrentUser(userProfile);
            _log('✅ User profile saved via UserManager');
          } else {
            _log('⚠️ getUserProfileById returned null');
          }
        } catch (profileError) {
          _log('❌ Error fetching user profile: $profileError');
          // Don't fail the login if profile fetch fails - we'll try again later
        }
        
        // Debug: Print all SharedPreferences keys
        _log('=== SharedPreferences Keys After Login ===');
        for (var key in prefs.getKeys()) {
          _log('Key: $key = ${prefs.get(key)}');
        }
        _log('=========================================');
        
        _log('=== LOGIN PROCESS COMPLETED SUCCESSFULLY ===');
        return {
          'success': true,
          'user': userData,
          'message': 'Login successful',
        };
      } else {
        _log('❌ Login failed: Invalid response from API');
        throw Exception(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      _log('❌ Login failed with error: $e');
      _log('Error type: ${e.runtimeType}');
      
      // Clear any cached login state
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', false);
        _log('Cleared is_logged_in flag');
      } catch (prefsError) {
        _log('Error clearing prefs: $prefsError');
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Login failed: $e',
      };
    }
  }

  // Check if user has valid login
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