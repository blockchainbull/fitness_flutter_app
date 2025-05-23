import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseDataService {
  static final ExerciseDataService _instance = ExerciseDataService._internal();
  static const String _exerciseDataKey = 'exercise_data';
  
  // Singleton pattern
  factory ExerciseDataService() {
    return _instance;
  }
  
  ExerciseDataService._internal();
  
  // Load all exercises for a user
  Future<List<Map<String, dynamic>>> loadExercises(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('${_exerciseDataKey}_$userId');
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      // Parse the JSON data
      final List<dynamic> jsonData = jsonDecode(jsonString);
      
      // Convert the dynamic list to the expected format with proper date parsing
      final exercisesList = jsonData.map((item) {
        Map<String, dynamic> exercise = Map<String, dynamic>.from(item);
        
        // Convert date string back to DateTime
        if (exercise.containsKey('date') && exercise['date'] is String) {
          exercise['date'] = DateTime.parse(exercise['date']);
        }
        
        return exercise;
      }).toList();
      
      return exercisesList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      return [];
    }
  }
  
  // Save exercises for a user
  Future<bool> saveExercises(String userId, List<Map<String, dynamic>> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Prepare exercises for JSON serialization (handling DateTime)
      final exercisesToSave = exercises.map((exercise) {
        final Map<String, dynamic> serializable = Map<String, dynamic>.from(exercise);
        
        // Convert DateTime to ISO string for serialization
        if (serializable.containsKey('date') && serializable['date'] is DateTime) {
          serializable['date'] = (serializable['date'] as DateTime).toIso8601String();
        }
        
        return serializable;
      }).toList();
      
      // Save as JSON
      final jsonString = jsonEncode(exercisesToSave);
      await prefs.setString('${_exerciseDataKey}_$userId', jsonString);
      
      return true;
    } catch (e) {
      debugPrint('Error saving exercises: $e');
      return false;
    }
  }
  
  // Add a new exercise for a user
  Future<bool> addExercise(String userId, Map<String, dynamic> exercise) async {
    try {
      // Load existing exercises
      final exercises = await loadExercises(userId);
      
      // Add the new exercise
      exercises.add(exercise);
      
      // Save the updated list
      return await saveExercises(userId, exercises);
    } catch (e) {
      debugPrint('Error adding exercise: $e');
      return false;
    }
  }
  
  // Delete an exercise for a user
  Future<bool> deleteExercise(String userId, Map<String, dynamic> exerciseToDelete) async {
    try {
      // Load existing exercises
      final exercises = await loadExercises(userId);
      
      // Find and remove the exercise
      exercises.removeWhere((exercise) => 
        exercise['name'] == exerciseToDelete['name'] &&
        exercise['time'] == exerciseToDelete['time'] &&
        exercise['date'].toString() == exerciseToDelete['date'].toString()
      );
      
      // Save the updated list
      return await saveExercises(userId, exercises);
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      return false;
    }
  }
  
  // Update an exercise for a user
  Future<bool> updateExercise(
    String userId, 
    Map<String, dynamic> oldExercise, 
    Map<String, dynamic> newExercise
  ) async {
    try {
      // Load existing exercises
      final exercises = await loadExercises(userId);
      
      // Find the exercise to update
      final index = exercises.indexWhere((exercise) => 
        exercise['name'] == oldExercise['name'] &&
        exercise['time'] == oldExercise['time'] &&
        exercise['date'].toString() == oldExercise['date'].toString()
      );
      
      if (index != -1) {
        // Update the exercise
        exercises[index] = newExercise;
        
        // Save the updated list
        return await saveExercises(userId, exercises);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating exercise: $e');
      return false;
    }
  }
  
  // Get exercise statistics for a user
  Future<Map<String, dynamic>> getExerciseStats(String userId) async {
    try {
      final exercises = await loadExercises(userId);
      
      if (exercises.isEmpty) {
        return {
          'totalExercises': 0,
          'totalDuration': 0,
          'totalCalories': 0,
          'avgCaloriesPerWorkout': 0,
          'mostFrequentCategory': 'N/A',
        };
      }
      
      final totalExercises = exercises.length;
      final totalDuration = exercises.fold<int>(0, (sum, e) => sum + (e['duration'] as int));
      final totalCalories = exercises.fold<int>(0, (sum, e) => sum + (e['caloriesBurned'] as int));
      final avgCaloriesPerWorkout = totalCalories / totalExercises;
      
      // Find most frequent category
      final categoryCount = <String, int>{};
      for (final exercise in exercises) {
        final category = exercise['category'] as String;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      String mostFrequentCategory = 'N/A';
      int maxCount = 0;
      categoryCount.forEach((category, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentCategory = category;
        }
      });
      
      return {
        'totalExercises': totalExercises,
        'totalDuration': totalDuration,
        'totalCalories': totalCalories,
        'avgCaloriesPerWorkout': avgCaloriesPerWorkout,
        'mostFrequentCategory': mostFrequentCategory,
        'categories': categoryCount,
      };
    } catch (e) {
      debugPrint('Error getting exercise stats: $e');
      return {
        'totalExercises': 0,
        'totalDuration': 0,
        'totalCalories': 0,
        'avgCaloriesPerWorkout': 0,
        'mostFrequentCategory': 'N/A',
      };
    }
  }
  
  // Get today's exercises for a user
  Future<List<Map<String, dynamic>>> getTodaysExercises(String userId) async {
    try {
      final exercises = await loadExercises(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return exercises.where((exercise) {
        final exerciseDate = exercise['date'] as DateTime;
        final exerciseDateOnly = DateTime(exerciseDate.year, exerciseDate.month, exerciseDate.day);
        return exerciseDateOnly.isAtSameMomentAs(today);
      }).toList();
    } catch (e) {
      debugPrint('Error getting today\'s exercises: $e');
      return [];
    }
  }
  
  // Get filtered exercises based on date range
  Future<List<Map<String, dynamic>>> getFilteredExercises(
    String userId, 
    {required DateTime startDate, required DateTime endDate}
  ) async {
    try {
      final exercises = await loadExercises(userId);
      
      return exercises.where((exercise) {
        final exerciseDate = exercise['date'] as DateTime;
        return exerciseDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
               exerciseDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      debugPrint('Error getting filtered exercises: $e');
      return [];
    }
  }
}