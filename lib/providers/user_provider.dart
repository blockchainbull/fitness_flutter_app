// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';

class UserProvider extends ChangeNotifier {
  final DataManager _dataManager = DataManager();
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userProfile != null;
  String? get error => _error;
  
  // Initialize user on app start
  Future<void> initUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if user is logged in
      final isLoggedIn = await UserManager.isLoggedIn();
      if (isLoggedIn) {
        _userProfile = await _dataManager.loadUserProfile();
      }
    } catch (e) {
      print('Error initializing user: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load or refresh user profile
  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _userProfile = await _dataManager.loadUserProfile();
      if (_userProfile != null) {
        await UserManager.setCurrentUser(_userProfile!);
      }
    } catch (e) {
      print('Error loading user: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      _error = null;
      final updatedProfile = await _dataManager.updateUserProfile(profile);
      _userProfile = updatedProfile;
      notifyListeners();
      return updatedProfile;
    } catch (e) {
      print('Error updating profile: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Set user after login or onboarding
  Future<void> setUser(UserProfile profile) async {
    _userProfile = profile;
    await UserManager.setCurrentUser(profile);
    notifyListeners();
  }
  
  // Complete onboarding
  Future<String?> completeOnboarding(Map<String, dynamic> onboardingData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userId = await _dataManager.completeOnboarding(onboardingData);
      if (userId != null) {
        // Load the created profile
        _userProfile = await _dataManager.loadUserProfile();
        if (_userProfile != null) {
          await UserManager.setCurrentUser(_userProfile!);
        }
      }
      return userId;
    } catch (e) {
      print('Error completing onboarding: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userId = await _dataManager.login(email, password);
      if (userId != null) {
        _userProfile = await _dataManager.loadUserProfile();
        if (_userProfile != null) {
          await UserManager.setCurrentUser(_userProfile!);
          notifyListeners();
          return true;
        }
      }
      _error = 'Invalid credentials';
      return false;
    } catch (e) {
      print('Error during login: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    await UserManager.logout();
    await _dataManager.logout();
    _userProfile = null;
    _error = null;
    notifyListeners();
  }
  
  // Refresh profile from backend
  Future<void> refreshProfile() async {
    if (_userProfile == null) return;
    
    try {
      _error = null;
      final refreshedProfile = await _dataManager.loadUserProfile();
      if (refreshedProfile != null) {
        _userProfile = refreshedProfile;
        await UserManager.setCurrentUser(refreshedProfile);
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing profile: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}