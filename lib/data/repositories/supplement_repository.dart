// lib/data/repositories/supplement_repository.dart
import 'package:flutter/foundation.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class SupplementRepository {
  static final Random _random = Random();
  static final ApiService _apiService = ApiService();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(9999).toString().padLeft(4, '0');
  }

  static Future<List<Map<String, dynamic>>> getSupplementPreferences(String userId) async {
    try {
      print('📋 [SupplementRepository] Getting supplement preferences for user: $userId');
      print('📋 [SupplementRepository] Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      // ✅ FIX: Use API service for BOTH web and mobile
      final response = await _apiService.getSupplementPreferences(userId);
      print('📋 [SupplementRepository] Retrieved ${response.length} supplement preferences via API');
      return response;
    } catch (e) {
      print('❌ [SupplementRepository] Error getting supplement preferences: $e');
      return [];
    }
  }

  static Future<Map<String, bool>> getSupplementStatusByDate(
    String userId, 
    DateTime date
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      print('📅 [SupplementRepository] Getting supplement status for $dateStr');
      
      // ✅ FIX: Use API service for BOTH web and mobile
      final status = await _apiService.getSupplementStatusByDate(userId, dateStr);
      print('📅 [SupplementRepository] Status retrieved: ${status.length} supplements');
      return status;
    } catch (e) {
      print('❌ [SupplementRepository] Error getting supplement status by date: $e');
      return {};
    }
  }

  // Get today's supplement status
  static Future<Map<String, bool>> getTodaysSupplementStatus(String userId) async {
    return await getSupplementStatusByDate(userId, DateTime.now());
  }

  // Get supplement history for date range
  static Future<List<Map<String, dynamic>>> getSupplementHistoryInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('📊 [SupplementRepository] Getting supplement history from ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');
      
      // Use API service for BOTH web and mobile
      final history = await _apiService.getSupplementHistoryInRange(
        userId, 
        startDate, 
        endDate
      );
      print('📊 [SupplementRepository] Retrieved ${history.length} history records');
      return history;
    } catch (e) {
      print('❌ [SupplementRepository] Error getting supplement history: $e');
      return [];
    }
  }

  // Save supplement preferences
  static Future<void> saveSupplementPreferences(
    String userId, 
    List<Map<String, dynamic>> supplements
  ) async {
    try {
      print('💾 [SupplementRepository] Saving ${supplements.length} supplement preferences');
      
      // ✅ FIX: Use API service for BOTH web and mobile
      await _apiService.saveSupplementPreferences(userId, supplements);
      print('✅ [SupplementRepository] Saved ${supplements.length} supplement preferences via API');
    } catch (e) {
      print('❌ [SupplementRepository] Error saving supplement preferences: $e');
      rethrow; // Re-throw to let caller handle the error
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
    String? notes,
  }) async {
    try {
      print('📝 [SupplementRepository] Logging supplement: $supplementName = $taken for $date');
      
      final logData = {
        'user_id': userId,
        'date': date,
        'supplement_name': supplementName,
        'taken': taken,
        'dosage': dosage,
        'time_taken': timeTaken,
        'notes': notes,
      };

      // ✅ FIX: Use API service for BOTH web and mobile
      await _apiService.logSupplementIntake(logData);
      print('✅ [SupplementRepository] Logged supplement intake successfully');
    } catch (e) {
      print('❌ [SupplementRepository] Error logging supplement intake: $e');
      rethrow;
    }
  }

  // Get supplement logs for a specific date
  static Future<Map<String, bool>> getSupplementLogsByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      print('📖 [SupplementRepository] Getting supplement logs for $dateStr');
      
      // ✅ FIX: Use API service for BOTH web and mobile
      return await _apiService.getSupplementStatusByDate(userId, dateStr);
    } catch (e) {
      print('❌ [SupplementRepository] Error getting supplement logs: $e');
      return {};
    }
  }

  // Delete a supplement preference
  static Future<bool> deleteSupplementPreference(
    String userId,
    String supplementId,
  ) async {
    try {
      print('🗑️ [SupplementRepository] Deleting supplement preference: $supplementId');
      
      // This would need to be implemented in the API service
      // For now, return false as not implemented
      print('⚠️ [SupplementRepository] Delete functionality not yet implemented in API');
      return false;
    } catch (e) {
      print('❌ [SupplementRepository] Error deleting supplement preference: $e');
      return false;
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