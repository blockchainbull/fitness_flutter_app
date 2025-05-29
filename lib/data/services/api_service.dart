// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:user_onboarding/data/models/user_profile.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // API base URL - change this to your actual API URL when deployed
  static final String baseUrl = kDebugMode 
    ? 'http://localhost:8000/api/health' 
    : 'https://your-production-api.com/api';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Save user profile
  Future<String> saveUserProfile(UserProfile userProfile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userProfile.toMap()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['userId'];
      } else {
        throw Exception('Failed to save user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when saving user profile: $e');
      rethrow;
    }
  }

  // Get user profile by ID
  Future<UserProfile> getUserProfileById(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromMap(data['userProfile']);
      } else {
        throw Exception('Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when getting user profile: $e');
      rethrow;
    }
  }

  // Get user profile by email
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/email/${Uri.encodeComponent(email)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromMap(data['userProfile']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get user profile by email: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when getting user profile by email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, UserProfile userProfile) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userProfile.toMap()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when updating user profile: $e');
      rethrow;
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('API error when deleting user profile: $e');
      rethrow;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/check-email/${Uri.encodeComponent(email)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('API error when checking email: $e');
      return false;
    }
  }
}