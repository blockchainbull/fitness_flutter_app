import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class MetricsService {
  final _supabase = Supabase.instance.client;
  
  Future<Map<String, dynamic>> getTodayMetrics(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      // Fetch steps
      final stepsResponse = await _supabase
          .from('daily_steps')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();
      
      // Fetch water
      final waterResponse = await _supabase
          .from('daily_water')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();
      
      // Fetch exercises
      final exercisesResponse = await _supabase
          .from('exercise_logs')
          .select()
          .eq('user_id', userId)
          .eq('exercise_date', today);
      
      // Fetch meals
      final mealsResponse = await _supabase
          .from('meal_entries')
          .select()
          .eq('user_id', userId)
          .eq('meal_date', today);
      
      // Calculate totals
      int steps = stepsResponse?['steps'] ?? 0;
      int water = waterResponse?['glasses'] ?? 0;
      
      int activeMinutes = 0;
      int caloriesBurned = 0;
      if (exercisesResponse != null) {
        for (var exercise in exercisesResponse) {
          activeMinutes += (exercise['duration'] as int?) ?? 0;
          caloriesBurned += (exercise['calories_burned'] as int?) ?? 0;
        }
      }
      
      int caloriesConsumed = 0;
      if (mealsResponse != null) {
        for (var meal in mealsResponse) {
          caloriesConsumed += (meal['calories'] as int?) ?? 0;
        }
      }
      
      // Add calories from steps (rough estimate: 0.04 calories per step)
      caloriesBurned += (steps * 0.04).round();
      
      return {
        'steps': steps,
        'water': water,
        'activeMinutes': activeMinutes,
        'caloriesBurned': caloriesBurned,
        'caloriesConsumed': caloriesConsumed,
        'netCalories': caloriesConsumed - caloriesBurned,
      };
    } catch (e) {
      print('Error fetching metrics: $e');
      return {
        'steps': 0,
        'water': 0,
        'activeMinutes': 0,
        'caloriesBurned': 0,
        'caloriesConsumed': 0,
        'netCalories': 0,
      };
    }
  }
  
  Future<void> updateSteps(String userId, int steps) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      await _supabase.from('daily_steps').upsert({
        'user_id': userId,
        'date': today,
        'steps': steps,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
    } catch (e) {
      print('Error updating steps: $e');
      rethrow;
    }
  }
  
  Future<void> updateWater(String userId, int glasses) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      await _supabase.from('daily_water').upsert({
        'user_id': userId,
        'date': today,
        'glasses': glasses,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
    } catch (e) {
      print('Error updating water: $e');
      rethrow;
    }
  }
  
  Future<void> logQuickActivity(String userId, String activityType, int duration, int calories) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      await _supabase.from('exercise_logs').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId,
        'date': today,
        'exercise_type': activityType,
        'duration': duration,
        'calories_burned': calories,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging activity: $e');
      rethrow;
    }
  }
}