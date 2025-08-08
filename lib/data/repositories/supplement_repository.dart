// lib/data/repositories/supplement_repository.dart
import 'package:flutter/foundation.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'dart:math';

class SupplementRepository {
  static final Random _random = Random();
  static final ApiService _apiService = ApiService();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(9999).toString().padLeft(4, '0');
  }

  static Future<List<Map<String, dynamic>>> getSupplementPreferences(String userId) async {
    try {
      if (kIsWeb) {
        final response = await _apiService.getSupplementPreferences(userId);
        print('📋 Retrieved ${response.length} supplement preferences via API');
        return response;
      } else {
        print('⚠️ Mobile database support not implemented yet');
        return [];
      }
    } catch (e) {
      print('❌ Error getting supplement preferences: $e');
      return [];
    }
  }

  // Save supplement preferences
  static Future<void> saveSupplementPreferences(
    String userId, 
    List<Map<String, dynamic>> supplements
  ) async {
    try {
      if (kIsWeb) {
        // Use API service for web
        await _apiService.saveSupplementPreferences(userId, supplements);
        print('✅ Saved ${supplements.length} supplement preferences via API');
      } else {
        // For mobile, we'll implement direct database later
        print('⚠️ Mobile database support not implemented yet');
      }
    } catch (e) {
      print('❌ Error saving supplement preferences: $e');
      // Don't rethrow - let the app continue with local storage
    }
  }

  // Log supplement intake
  static Future<void> logSupplementIntake({
    required String userId,
    required String date,
    required String supplementName,
    required bool taken,
    String? dosage,
    String? timeTaken,
  }) async {
    try {
      if (kIsWeb) {
        // Use API service for web
        final logData = {
          'user_id': userId,
          'date': date,
          'supplement_name': supplementName,
          'dosage': dosage,
          'taken': taken,
          'time_taken': timeTaken,
        };
        
        await _apiService.logSupplementIntake(logData);
        print('✅ Logged supplement via API: $supplementName = $taken on $date');
      } else {
        // For mobile, we'll implement direct database later
        print('⚠️ Mobile database support not implemented yet');
      }
    } catch (e) {
      print('❌ Error logging supplement: $e');
      // Don't rethrow - let the app continue with local storage
    }
  }

  // Get today's supplement status
  static Future<Map<String, bool>> getTodaysSupplementStatus(String userId) async {
    try {
      if (kIsWeb) {
        // Use API service for web
        final response = await _apiService.getTodaysSupplementStatus(userId);
        print('📱 Retrieved today\'s status via API: ${response.length} items');
        return response;
      } else {
        // For mobile, we'll implement direct database later
        print('⚠️ Mobile database support not implemented yet');
        return {};
      }
    } catch (e) {
      print('❌ Error getting today\'s supplement status: $e');
      return {};
    }
  }

  // Get supplement history
  static Future<List<Map<String, dynamic>>> getSupplementHistory(
    String userId, {
    int days = 30
  }) async {
    try {
      if (kIsWeb) {
        // Use API service for web
        final results = await _apiService.getSupplementHistory(userId, days: days);
        print('📊 Retrieved ${results.length} supplement records via API');
        return results;
      } else {
        // For mobile, we'll implement direct database later
        print('⚠️ Mobile database support not implemented yet');
        return [];
      }
    } catch (e) {
      print('❌ Error getting supplement history: $e');
      return [];
    }
  }
}