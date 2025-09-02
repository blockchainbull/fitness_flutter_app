// lib/data/repositories/step_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/services/api_service.dart';

class StepRepository {
  static const String _stepsKey = 'step_entries';

  static Future<StepEntry?> getTodayStepEntry(String userId) async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    try {
      // Try to get from API first
      final apiEntry = await ApiService().getTodaySteps(userId);
      if (apiEntry != null) {
        await _saveToLocal(apiEntry);
        return apiEntry;
      }
    } catch (e) {
      print('Error getting today steps from API: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final stepsJson = prefs.getString('${_stepsKey}_${userId}_$todayKey');
    
    if (stepsJson != null) {
      return StepEntry.fromMap(jsonDecode(stepsJson));
    }
    
    return null;
  }

  static Future<List<StepEntry>> getStepEntriesInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Try to get from API first
      final apiEntries = await ApiService().getStepsInRange(userId, startDate, endDate);
      if (apiEntries.isNotEmpty) {
        // Save to local storage
        for (final entry in apiEntries) {
          await _saveToLocal(entry);
        }
        return apiEntries;
      }
    } catch (e) {
      print('Error getting steps range from API: $e');
    }

    // Fallback to local storage
    final entries = <StepEntry>[];
    final prefs = await SharedPreferences.getInstance();
    
    for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final entryJson = prefs.getString('${_stepsKey}_${userId}_$dateKey');
      
      if (entryJson != null) {
        entries.add(StepEntry.fromMap(jsonDecode(entryJson)));
      }
    }
    
    return entries;
  }

  static Future<void> saveStepEntry(StepEntry entry) async {
    try {
      // Save to API
      await ApiService().saveStepEntry(entry);
    } catch (e) {
      print('Error saving step entry to API: $e');
    }

    // Always save to local storage
    await _saveToLocal(entry);
  }

  static Future<void> _saveToLocal(StepEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
    final key = '${_stepsKey}_${entry.userId}_$dateKey';
    
    await prefs.setString(key, jsonEncode(entry.toMap()));
  }

  static Future<List<StepEntry>> getAllStepEntries(String userId) async {
    try {
      final apiEntries = await ApiService().getAllSteps(userId);
      return apiEntries;
    } catch (e) {
      print('Error getting all steps from API: $e');
      return [];
    }
  }

  static Future<void> deleteStepEntry(String userId, DateTime date) async {
    try {
      await ApiService().deleteStepEntry(userId, date);
    } catch (e) {
      print('Error deleting step entry from API: $e');
    }

    // Remove from local storage
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final key = '${_stepsKey}_${userId}_$dateKey';
    await prefs.remove(key);
  }
}