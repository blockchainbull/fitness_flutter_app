// lib/features/reports/screens/today_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/repositories/sleep_repository.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/water_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/sleep_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/exercise_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/steps_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/weight_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/supplements_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/data/services/api_service.dart';


class TodayReportScreen extends StatefulWidget {
  final UserProfile userProfile;

  const TodayReportScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<TodayReportScreen> createState() => _TodayReportScreenState();
}

class _TodayReportScreenState extends State<TodayReportScreen> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  
  // Tracking data for today
  Map<String, TrackingStatus> trackingStatus = {};
  
  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }
  
  Future<void> _loadTodayData() async {
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.userProfile.id ?? '';
      final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      // Load each category with individual error handling
      final futures = [
        _getMealStatus(prefs, todayStr).catchError((e) {
          print('Meal status error: $e');
          return _getEmptyMealStatus();
        }),
        _getWaterStatus(prefs, todayStr).catchError((e) {
          print('Water status error: $e');
          return _getEmptyWaterStatus();
        }),
        _getSleepStatus(prefs, todayStr).catchError((e) {
          print('Sleep status error: $e');
          return _getEmptySleepStatus();
        }),
        _getExerciseStatus(prefs, todayStr).catchError((e) {
          print('Exercise status error: $e');
          return _getEmptyExerciseStatus();
        }),
        _getStepsStatus(userId).catchError((e) {
          print('Steps status error: $e');
          return _getEmptyStepsStatus();
        }),
        _getWeightStatus(prefs, todayStr).catchError((e) {
          print('Weight status error: $e');
          return _getEmptyWeightStatus();
        }),
        _getSupplementStatus(prefs, todayStr).catchError((e) {
          print('Supplement status error: $e');
          return _getEmptySupplementStatus();
        }),
      ];
      
      final results = await Future.wait(futures);
      
      trackingStatus = {
        'meals': results[0],
        'water': results[1],
        'sleep': results[2],
        'exercise': results[3],
        'steps': results[4],
        'weight': results[5],
        'supplements': results[6],
      };
      
    } catch (e) {
      print('Error loading today data: $e');
      // Set all to empty states
      trackingStatus = {
        'meals': _getEmptyMealStatus(),
        'water': _getEmptyWaterStatus(),
        'sleep': _getEmptySleepStatus(),
        'exercise': _getEmptyExerciseStatus(),
        'steps': _getEmptyStepsStatus(),
        'weight': _getEmptyWeightStatus(),
        'supplements': _getEmptySupplementStatus(),
      };
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<TrackingStatus> _getMealStatus(SharedPreferences prefs, String date) async {
    try {
      // Get meal data from API
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      print('🔍 [_getMealStatus] Fetching meals for user: $userId, date: $date');
      
      // Get daily summary which includes meals
      final dailySummary = await apiService.getDailySummary(
        userId,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
      );
      
      print('📊 [_getMealStatus] Daily summary response: $dailySummary');
      
      // Check if response is valid
      if (dailySummary != null && dailySummary['success'] == true) {
        // The meals data is a Map, not a List!
        final mealsData = dailySummary['meals'] as Map<String, dynamic>? ?? {};
        
        // Extract the counts directly from the API response
        final totalMeals = (mealsData['total_count'] as num?)?.toInt() ?? 0;
        final breakfast = (mealsData['breakfast'] as num?)?.toInt() ?? 0;
        final lunch = (mealsData['lunch'] as num?)?.toInt() ?? 0;
        final dinner = (mealsData['dinner'] as num?)?.toInt() ?? 0;
        final snacks = (mealsData['snacks'] as num?)?.toInt() ?? 0;
        final totalCalories = (mealsData['calories_consumed'] as num?)?.toDouble() ?? 0.0;
        
        print('✅ [_getMealStatus] Total meals from API: $totalMeals');
        print('   Breakfast: $breakfast, Lunch: $lunch, Dinner: $dinner, Snacks: $snacks');
        
        // BUT the counts are all 0, so let's also fetch the actual meal list
        if (totalMeals > 0 && breakfast == 0 && lunch == 0 && dinner == 0 && snacks == 0) {
          // The meal type counts aren't working, let's get the actual meals
          final meals = await apiService.getMealHistory(
            userId,
            date: DateFormat('yyyy-MM-dd').format(selectedDate),
          );
          
          // Recount from the actual meals
          int actualBreakfast = 0;
          int actualLunch = 0;
          int actualDinner = 0;
          int actualSnacks = 0;
          
          for (var meal in meals) {
            final mealType = meal['meal_type']?.toString() ?? '';
            switch (mealType) {
              case 'Breakfast':
                actualBreakfast++;
                break;
              case 'Lunch':
                actualLunch++;
                break;
              case 'Dinner':
                actualDinner++;
                break;
              case 'Snack':
                actualSnacks++;
                break;
            }
          }
          
          // Store in SharedPreferences as backup
          await prefs.setInt('meal_count_$date', totalMeals);
          await prefs.setDouble('meal_calories_$date', totalCalories);
          
          return TrackingStatus(
            category: 'Meals',
            icon: Icons.restaurant,
            color: Colors.green,
            completed: totalMeals,
            total: 3,
            details: {
              'Breakfast': actualBreakfast,
              'Lunch': actualLunch,
              'Dinner': actualDinner,
              'Snacks': actualSnacks,
              'Calories': totalCalories.toInt(),
              'Status': totalMeals >= 3 ? 'Complete' : 'In Progress',
            },
            unit: 'meals',
            isComplete: totalMeals >= 3,
            excludeFromProgress: false,
          );
        }
        
        // Store in SharedPreferences as backup
        await prefs.setInt('meal_count_$date', totalMeals);
        await prefs.setDouble('meal_calories_$date', totalCalories);
        
        return TrackingStatus(
          category: 'Meals',
          icon: Icons.restaurant,
          color: Colors.green,
          completed: totalMeals,
          total: 3,
          details: {
            'Breakfast': breakfast,
            'Lunch': lunch,
            'Dinner': dinner,
            'Snacks': snacks,
            'Calories': totalCalories.toInt(),
            'Status': totalMeals >= 3 ? 'Complete' : 'In Progress',
          },
          unit: 'meals',
          isComplete: totalMeals >= 3,
          excludeFromProgress: false,
        );
      } else {
        // If daily summary fails, fall back to getMealHistory
        throw Exception('Daily summary not available');
      }
      
    } catch (e) {
      print('⚠️ [_getMealStatus] Falling back to getMealHistory due to: $e');
      
      // Fallback: Get meals directly from meal history
      try {
        final apiService = ApiService();
        final userId = widget.userProfile.id ?? '';
        
        final meals = await apiService.getMealHistory(
          userId,
          date: DateFormat('yyyy-MM-dd').format(selectedDate),
        );
        
        print('📋 [_getMealStatus] Meal history response: ${meals.length} meals');
        
        // Count meals by type from meal history
        int breakfast = 0;
        int lunch = 0;
        int dinner = 0;
        int snacks = 0;
        double totalCalories = 0;
        
        for (var meal in meals) {
          final mealType = meal['meal_type']?.toString() ?? '';
          final calories = (meal['calories'] as num?)?.toDouble() ?? 0;
          totalCalories += calories;
          
          switch (mealType) {
            case 'Breakfast':
              breakfast++;
              break;
            case 'Lunch':
              lunch++;
              break;
            case 'Dinner':
              dinner++;
              break;
            case 'Snack':
              snacks++;
              break;
          }
        }
        
        final totalMeals = meals.length;
        print('✅ [_getMealStatus] Total meals counted: $totalMeals');
        
        // Store in SharedPreferences
        await prefs.setInt('meal_count_$date', totalMeals);
        await prefs.setDouble('meal_calories_$date', totalCalories);
        
        return TrackingStatus(
          category: 'Meals',
          icon: Icons.restaurant,
          color: Colors.green,
          completed: totalMeals,
          total: 3,
          details: {
            'Breakfast': breakfast,
            'Lunch': lunch,
            'Dinner': dinner,
            'Snacks': snacks,
            'Calories': totalCalories.toInt(),
            'Status': totalMeals >= 3 ? 'Complete' : 'In Progress',
          },
          unit: 'meals',
          isComplete: totalMeals >= 3,
          excludeFromProgress: false,
        );
        
      } catch (e2) {
        print('❌ [_getMealStatus] getMealHistory also failed: $e2');
        
        // Final fallback to SharedPreferences
        final mealCount = prefs.getInt('meal_count_$date') ?? 0;
        final calories = prefs.getDouble('meal_calories_$date') ?? 0;
        
        print('📦 [_getMealStatus] Using cached data: $mealCount meals');
        
        return TrackingStatus(
          category: 'Meals',
          icon: Icons.restaurant,
          color: Colors.green,
          completed: mealCount,
          total: 3,
          details: {
            'Calories': calories.toInt(),
            'Status': mealCount >= 3 ? 'Complete' : 'In Progress',
          },
          unit: 'meals',
          isComplete: mealCount >= 3,
          excludeFromProgress: false,
        );
      }
    }
  }

  TrackingStatus _getEmptyMealStatus() {
    return TrackingStatus(
      category: 'Meals',
      icon: Icons.restaurant,
      color: Colors.green,
      completed: 0,
      total: 3,
      details: {'Status': 'Not logged'},
      unit: 'meals',
      isComplete: false,
      excludeFromProgress: false,
    );
  }

  TrackingStatus _getEmptySupplementStatus() {
    return TrackingStatus(
      category: 'Supplements',
      icon: Icons.medication,
      color: Colors.teal,
      completed: 0,
      total: 0,
      details: {'Status': 'Not configured'},
      unit: 'pills',
      isComplete: false,
      excludeFromProgress: true,
    );
  }

  TrackingStatus _getEmptyWaterStatus() {
    return TrackingStatus(
      category: 'Water',
      icon: Icons.water_drop,
      color: Colors.blue,
      completed: 0,
      total: 8,
      details: {
        'Consumed': 0,
        'Target': 8,
        'Remaining': 8,
        'Status': 'Not logged',
      },
      unit: 'glasses',
      isComplete: false,
      excludeFromProgress: false,
    );
  }

  TrackingStatus _getEmptySleepStatus() {
    return TrackingStatus(
      category: 'Sleep',
      icon: Icons.bedtime,
      color: Colors.purple,
      completed: 0,
      total: 8,
      details: {
        'Status': 'Not logged',
        'Target': '8 hours',
      },
      unit: 'hours',
      isComplete: false,
      excludeFromProgress: false,
    );
  }

  TrackingStatus _getEmptyExerciseStatus() {
    return TrackingStatus(
      category: 'Exercise',
      icon: Icons.fitness_center,
      color: Colors.orange,
      completed: 0,
      total: 30,
      details: {
        'Duration': '0 min',
        'Target': '30 min',
        'Calories': 'Not tracked',
        'Sessions': 0,
        'Status': 'Not logged',
      },
      unit: 'min',
      isComplete: false,
      excludeFromProgress: false,
    );
  }

  TrackingStatus _getEmptyStepsStatus() {
    return TrackingStatus(
      category: 'Steps',
      icon: Icons.directions_walk,
      color: Colors.green.shade700,
      completed: 0,
      total: 10000,
      details: {
        'Steps': '0',
        'Goal': '10000',
        'Distance': '0.0 km',
        'Calories': '0 cal',
        'Status': 'Not tracked',
      },
      unit: 'steps',
      isComplete: false,
      excludeFromProgress: false,
    );
  }

  TrackingStatus _getEmptyWeightStatus() {
    return TrackingStatus(
      category: 'Weight',
      icon: Icons.monitor_weight,
      color: Colors.indigo,
      completed: 0,
      total: 1,
      details: {
        'Status': 'Not logged',
      },
      unit: '',
      isComplete: false,
      excludeFromProgress: false,
    );
  }
  
  Future<TrackingStatus> _getWaterStatus(SharedPreferences prefs, String date) async {
    try {
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      print('[Reports] Getting water status for $userId on $date');
      
      final waterData = await apiService.getTodaysWater(userId);
      
      // Cast num to int explicitly
      final glasses = (waterData['glasses'] as num? ?? 0).toInt();
      final totalMl = (waterData['total_ml'] as num? ?? 0.0).toDouble();
      
      print('[Reports] API returned: $glasses glasses, ${totalMl}ml');
      
      final targetGlasses = 8;
      final remaining = (targetGlasses - glasses).clamp(0, targetGlasses);
      
      // Store in SharedPreferences as backup
      await prefs.setInt('water_glasses_$date', glasses);
      
      return TrackingStatus(
        category: 'Water',
        icon: Icons.water_drop,
        color: Colors.blue,
        completed: glasses,
        total: targetGlasses,
        details: {
          'Consumed': '$glasses glasses',
          'Target': '$targetGlasses glasses',
          'Remaining': '$remaining glasses',
          'Volume': '${totalMl.toInt()}ml',
          'Status': glasses >= targetGlasses ? 'Complete' : 'In Progress',
        },
        unit: 'glasses',
        isComplete: glasses >= targetGlasses,
        excludeFromProgress: false,
      );
      
    } catch (e) {
      print('[Reports] Error getting water status: $e');
      
      // Fallback to SharedPreferences
      final glasses = prefs.getInt('water_glasses_$date') ?? 0;
      final targetGlasses = 8;
      
      return TrackingStatus(
        category: 'Water',
        icon: Icons.water_drop,
        color: Colors.blue,
        completed: glasses,
        total: targetGlasses,
        details: {
          'Consumed': '$glasses glasses',
          'Target': '$targetGlasses glasses',
          'Status': 'Cached data',
        },
        unit: 'glasses',
        isComplete: glasses >= targetGlasses,
        excludeFromProgress: false,
      );
    }
  }
  
  Future<TrackingStatus> _getSleepStatus(SharedPreferences prefs, String date) async {
    try {
      // Try to get from repository first (which checks both API and local storage)
      final entry = await SleepRepository().getSleepEntryByDate(
        widget.userProfile.id ?? '',
        selectedDate,
      );
      
      if (entry != null) {
        final sleepHours = entry.totalHours;
        final targetHours = 8.0;
        
        // Build details map with null checks
        final details = <String, dynamic>{
          'Hours': '${sleepHours.toStringAsFixed(1)}h',
          'Target': '${targetHours}h',
          'Quality': '${(entry.qualityScore * 100).toInt()}%',
        };
        
        // Add bedtime if available
        if (entry.bedtime != null) {
          details['Bedtime'] = DateFormat('hh:mm a').format(entry.bedtime!);
        }
        
        // Add wake time if available
        if (entry.wakeTime != null) {
          details['Wake'] = DateFormat('hh:mm a').format(entry.wakeTime!);
        }
        
        return TrackingStatus(
          category: 'Sleep',
          icon: Icons.bedtime,
          color: Colors.purple,
          completed: sleepHours.toInt(),
          total: targetHours.toInt(),
          details: details,
          unit: 'hours',
          isComplete: sleepHours >= 7,
          excludeFromProgress: false,
        );
      }
      
      // Fallback to SharedPreferences (legacy check)
      final hasEntry = prefs.getBool('sleep_logged_$date') ?? false;
      final sleepHours = prefs.getDouble('sleep_hours_$date') ?? 0;
      
      if (hasEntry) {
        return TrackingStatus(
          category: 'Sleep',
          icon: Icons.bedtime,
          color: Colors.purple,
          completed: sleepHours.toInt(),
          total: 8,
          details: {
            'Hours': '${sleepHours.toStringAsFixed(1)}h',
            'Target': '8h',
            'Quality': 'Logged',
          },
          unit: 'hours',
          isComplete: sleepHours >= 7,
          excludeFromProgress: false,
        );
      }
      
      // No entry found
      return TrackingStatus(
        category: 'Sleep',
        icon: Icons.bedtime,
        color: Colors.purple,
        completed: 0,
        total: 8,
        details: {
          'Status': 'Not logged',
          'Target': '8 hours',
        },
        unit: 'hours',
        isComplete: false,
        excludeFromProgress: false,
      );
    } catch (e) {
      print('Error getting sleep status: $e');
      return TrackingStatus(
        category: 'Sleep',
        icon: Icons.bedtime,
        color: Colors.purple,
        completed: 0,
        total: 8,
        unit: 'hours',
        isComplete: false,
        excludeFromProgress: false,
      );
    }
  }
  
  Future<TrackingStatus> _getExerciseStatus(SharedPreferences prefs, String date) async {
    try {
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      print('[Reports] Getting exercise status for user: $userId, date: $date');
      
      // ✅ Use getExerciseLogs instead of getExerciseHistory
      final exercises = await apiService.getExerciseLogs(
        userId,
        startDate: date,
        endDate: date,
        limit: 50,
      );
      
      print('[Reports] Found ${exercises.length} exercises for $date');
      
      // Calculate totals
      int totalMinutes = 0;
      double totalCalories = 0;
      
      for (var exercise in exercises) {
        final duration = exercise['duration_minutes'] as int? ?? 0;
        final calories = (exercise['calories_burned'] as num? ?? 0).toDouble();
        
        totalMinutes += duration;
        totalCalories += calories;
        
        print('[Reports] Exercise: ${exercise['exercise_name']} - ${duration} min, ${calories} cal');
      }
      
      final targetMinutes = 30;
      final sessionCount = exercises.length;
      
      print('[Reports] Totals - Minutes: $totalMinutes, Calories: $totalCalories, Sessions: $sessionCount');
      
      // Store in SharedPreferences as backup
      await prefs.setInt('exercise_minutes_$date', totalMinutes);
      await prefs.setDouble('exercise_calories_$date', totalCalories);
      await prefs.setInt('exercise_count_$date', sessionCount);
      
      return TrackingStatus(
        category: 'Exercise',
        icon: Icons.fitness_center,
        color: Colors.orange,
        completed: totalMinutes,
        total: targetMinutes,
        details: {
          'Duration': '$totalMinutes min',
          'Target': '$targetMinutes min',
          'Calories': totalCalories > 0 ? '${totalCalories.toInt()} cal' : 'Not tracked',
          'Sessions': sessionCount,
          'Status': totalMinutes >= targetMinutes ? 'Complete' : 'In Progress',
        },
        unit: 'min',
        isComplete: totalMinutes >= targetMinutes,
        excludeFromProgress: false,
      );
      
    } catch (e) {
      print('[Reports] Error in _getExerciseStatus: $e');
      
      // Fallback to SharedPreferences if API fails
      final minutes = prefs.getInt('exercise_minutes_$date') ?? 0;
      final calories = prefs.getDouble('exercise_calories_$date') ?? 0;
      final count = prefs.getInt('exercise_count_$date') ?? 0;
      final targetMinutes = 30;
      
      print('[Reports] Fallback - Minutes: $minutes, Calories: $calories, Sessions: $count');
      
      return TrackingStatus(
        category: 'Exercise',
        icon: Icons.fitness_center,
        color: Colors.orange,
        completed: minutes,
        total: targetMinutes,
        details: {
          'Duration': '$minutes min',
          'Target': '$targetMinutes min',
          'Calories': calories > 0 ? '${calories.toInt()} cal' : 'Not tracked',
          'Sessions': count,
          'Status': minutes >= targetMinutes ? 'Complete' : 'In Progress',
        },
        unit: 'min',
        isComplete: minutes >= targetMinutes,
        excludeFromProgress: false,
      );
    }
  }
  
  Future<TrackingStatus> _getStepsStatus(String userId) async {
    try {
      final entry = await StepRepository.getTodayStepEntry(userId);
      final steps = entry?.steps ?? 0;
      final goal = entry?.goal ?? 10000;
      
      return TrackingStatus(
        category: 'Steps',
        icon: Icons.directions_walk,
        color: Colors.green.shade700,
        completed: steps,
        total: goal,
        details: {
          'Steps': steps.toString(),
          'Goal': goal.toString(),
          'Distance': '${(steps * 0.0008).toStringAsFixed(1)} km',
          'Calories': '${entry?.caloriesBurned.toStringAsFixed(0) ?? "0"} cal',
        },
        unit: 'steps',
        isComplete: steps >= goal,
      );
    } catch (e) {
      print('Error getting steps status: $e');
      return TrackingStatus(
        category: 'Steps',
        icon: Icons.directions_walk,
        color: Colors.green.shade700,
        completed: 0,
        total: 10000,
        unit: 'steps',
        isComplete: false,
      );
    }
  }
  
  Future<TrackingStatus> _getWeightStatus(SharedPreferences prefs, String date) async {
    try {
      // Try to get from DataManager/Repository first
      final dataManager = DataManager();
      final history = await dataManager.getWeightHistory(
        widget.userProfile.id ?? '',
        limit: 30,
      );
      
      // Check if there's an entry for today
      final todayEntry = history.firstWhere(
        (entry) => 
          entry.date.year == selectedDate.year &&
          entry.date.month == selectedDate.month &&
          entry.date.day == selectedDate.day,
        orElse: () => WeightEntry(
          userId: '',
          date: DateTime(1900), // Dummy date to indicate not found
          weight: 0,
        ),
      );
      
      if (todayEntry.date.year != 1900) {
        return TrackingStatus(
          category: 'Weight',
          icon: Icons.monitor_weight,
          color: Colors.indigo,
          completed: 1,
          total: 1,
          details: {
            'Weight': '${todayEntry.weight.toStringAsFixed(1)} kg',
            'BMI': _calculateBMI(todayEntry.weight),
            'Status': 'Logged',
            'Time': DateFormat('hh:mm a').format(todayEntry.date),
          },
          unit: '',
          isComplete: true,
          excludeFromProgress: false,
        );
      }
      
      // Fallback to SharedPreferences
      final hasEntry = prefs.getBool('weight_logged_$date') ?? false;
      final weight = prefs.getDouble('weight_$date') ?? 0;
      
      if (hasEntry) {
        return TrackingStatus(
          category: 'Weight',
          icon: Icons.monitor_weight,
          color: Colors.indigo,
          completed: 1,
          total: 1,
          details: {
            'Weight': '${weight.toStringAsFixed(1)} kg',
            'Status': 'Logged',
          },
          unit: '',
          isComplete: true,
          excludeFromProgress: false,
        );
      }
      
      // No entry found
      return TrackingStatus(
        category: 'Weight',
        icon: Icons.monitor_weight,
        color: Colors.indigo,
        completed: 0,
        total: 1,
        details: {
          'Status': 'Not logged',
        },
        unit: '',
        isComplete: false,
        excludeFromProgress: false,
      );
    } catch (e) {
      print('Error getting weight status: $e');
      return TrackingStatus(
        category: 'Weight',
        icon: Icons.monitor_weight,
        color: Colors.indigo,
        completed: 0,
        total: 1,
        unit: '',
        isComplete: false,
        excludeFromProgress: false,
      );
    }
  }

  // Helper method to calculate BMI
  String _calculateBMI(double weight) {
    final height = widget.userProfile.height ?? 170; // Default height
    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);
    return 'BMI: ${bmi.toStringAsFixed(1)}';
  }
  
  Future<TrackingStatus> _getSupplementStatus(SharedPreferences prefs, String date) async {
    try {
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      print('[Reports] Getting supplement status for $userId on $date');
      
      final preferences = await apiService.getSupplementPreferences(userId);
      final totalSupplements = preferences.length;
      
      print('[Reports] Found $totalSupplements total supplements');
      
      final statusData = await apiService.getSupplementStatus(userId, date: date);
      
      int takenCount = 0;
      if (statusData is Map && statusData['status'] != null) {
        final statusMap = statusData['status'] as Map<String, dynamic>;
        takenCount = statusMap.values.where((taken) => taken == true).length;
      }
      
      print('[Reports] $takenCount/$totalSupplements supplements taken');
      
      int remaining = totalSupplements - takenCount;
      if (remaining < 0) remaining = 0;
      
      await prefs.setInt('supplements_taken_$date', takenCount);
      await prefs.setInt('supplements_total_$date', totalSupplements);
      
      return TrackingStatus(
        category: 'Supplements',
        icon: Icons.medication,
        color: Colors.teal,
        completed: takenCount,
        total: totalSupplements,
        details: {
          'Taken': takenCount,  // Store as int, not string
          'Total': totalSupplements,  // Store as int, not string
          'Remaining': remaining,  // Store as int, not string
          'Status': takenCount >= totalSupplements ? 'Complete' : 'In Progress',
        },
        unit: 'pills',
        isComplete: takenCount >= totalSupplements,
        excludeFromProgress: false,
      );
      
    } catch (e) {
      print('[Reports] Error getting supplement status: $e');
      return TrackingStatus(
        category: 'Supplements',
        icon: Icons.medication,
        color: Colors.teal,
        completed: 0,
        total: 0,
        details: {
          'Status': 'Error loading',
        },
        unit: 'pills',
        isComplete: false,
        excludeFromProgress: true,  // Exclude from progress when error
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Report'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildOverallProgress(),
                    _buildTrackingGrid(),
                    _buildMissingActivities(),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getCompletionMessage(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverallProgress() {
    final completed = trackingStatus.values.where((s) => s.isComplete).length;
    final total = trackingStatus.length;
    final percentage = total > 0 ? (completed / total) : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(percentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(percentage),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toInt()}% Complete',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        itemCount: trackingStatus.length,
        itemBuilder: (context, index) {
          final key = trackingStatus.keys.elementAt(index);
          final status = trackingStatus[key]!;
          return _buildTrackingCard(status);
        },
      ),
    );
  }
  
  Widget _buildTrackingCard(TrackingStatus status) {
    final progress = status.total > 0 
        ? (status.completed / status.total).clamp(0.0, 1.0) 
        : 0.0;
    
    // Special handling for unconfigured/disabled items
    final isUnconfigured = status.excludeFromProgress;
    final isSupplementsUnconfigured = status.category == 'Supplements' && status.total == 0;
    
    return InkWell(
      onTap: () => _navigateToTracking(status.category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isUnconfigured || isSupplementsUnconfigured) 
              ? Colors.grey.shade50 
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isUnconfigured || isSupplementsUnconfigured)
                ? Colors.grey.shade300
                : status.isComplete 
                    ? status.color.withOpacity(0.3)
                    : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  status.icon,
                  color: (isUnconfigured || isSupplementsUnconfigured) 
                      ? Colors.grey 
                      : status.color,
                  size: 24,
                ),
                if (status.isComplete && !isUnconfigured && !isSupplementsUnconfigured)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  )
                else if (isSupplementsUnconfigured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Setup',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              status.category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (isUnconfigured || isSupplementsUnconfigured) 
                    ? Colors.grey 
                    : Colors.black87,
              ),
            ),
            Text(
              _getStatusDisplay(status),
              style: TextStyle(
                fontSize: 10,
                color: (isUnconfigured || isSupplementsUnconfigured)
                    ? Colors.grey.shade500 
                    : Colors.grey.shade600,
              ),
            ),
            if (!isUnconfigured && !isSupplementsUnconfigured && status.total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(status.color),
                ),
              )
            else
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusDisplay(TrackingStatus status) {
    if (status.category == 'Weight') {
      return status.isComplete ? 'Logged' : 'Not logged';
    } else if (status.category == 'Supplements') {
      if (status.total == 0) {
        if (status.details['Status'] == 'Tracking disabled') {
          return 'Disabled';
        }
        return 'Not configured';
      }
      return '${status.completed}/${status.total} ${status.unit}';
    } else if (status.total > 0) {
      return '${status.completed}/${status.total} ${status.unit}';
    } else {
      return status.isComplete ? 'Complete' : 'Pending';
    }
  }
  
  Widget _buildMissingActivities() {
    // Get items that are incomplete and should be tracked
    final missing = trackingStatus.entries
        .where((e) => !e.value.isComplete && !e.value.excludeFromProgress)
        .toList();
    
    // Check supplements status
    final supplementsEntry = trackingStatus['supplements'];
    final supplementsNotConfigured = supplementsEntry != null && 
        supplementsEntry.total == 0 && 
        supplementsEntry.details['Status'] == 'Not configured';
    
    if (missing.isEmpty && !supplementsNotConfigured) {
      // Success state - everything complete
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfect Day! 🌟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'All activities completed',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Build the missing activities card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                missing.isNotEmpty ? 'Missing Activities' : 'Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            
            // Show missing tracked activities (including configured supplements)
            ...missing.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: InkWell(
                onTap: () => _navigateToTracking(entry.value.category),
                child: Row(
                  children: [
                    Icon(
                      entry.value.icon,
                      color: entry.value.color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                          // Show which supplements are remaining if applicable
                          if (entry.value.category == 'Supplements' && 
                              entry.value.details.containsKey('Remaining'))
                            Text(
                              '${entry.value.details['Remaining']} supplements remaining',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            )
                          else if (entry.value.details.containsKey('Status'))
                            Text(
                              entry.value.details['Status'].toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            )),
          ],
          
          // Show supplements setup suggestion ONLY if not configured
          if (supplementsNotConfigured) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _navigateToTracking('Supplements'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.teal.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up supplement tracking',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Track daily vitamins and supplements',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.teal.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.teal.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivityLoggingMenu(
                      userProfile: widget.userProfile,
                    ),
                  ),
                ).then((_) => _loadTodayData());
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Log Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareProgress,
              icon: const Icon(Icons.share),
              label: const Text('Share Progress'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadTodayData();
    }
  }
  
  void _navigateToTracking(String category) {
    Widget? page;
    
    switch (category.toLowerCase()) {
      case 'meals':
        page = MealLoggingPage(userProfile: widget.userProfile);
        break;
      case 'water':
        page = WaterLoggingPage(userProfile: widget.userProfile);
        break;
      case 'sleep':
        page = SleepLoggingPage(userProfile: widget.userProfile);
        break;
      case 'exercise':
        page = EnhancedExerciseLoggingPage(userProfile: widget.userProfile);
        break;
      case 'steps':
        page = StepsLoggingPage(userProfile: widget.userProfile);
        break;
      case 'weight':
        page = WeightLoggingPage(userProfile: widget.userProfile);
        break;
      case 'supplements':
        page = SupplementLoggingPage(userProfile: widget.userProfile);
        break;
    }
    
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      ).then((_) => _loadTodayData());
    }
  }
  
  void _shareProgress() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }
  
  String _getCompletionMessage() {
    final completed = trackingStatus.values.where((s) => s.isComplete).length;
    final total = trackingStatus.length;
    
    if (completed == total) {
      return '🎉 All activities completed!';
    } else if (completed >= total * 0.7) {
      return '💪 Almost there! ${total - completed} activities left';
    } else if (completed >= total * 0.5) {
      return '📈 Good progress! Keep going';
    } else {
      return '🚀 Let\'s track your activities';
    }
  }
  
  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.7) return Colors.lightGreen;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
  
  String _getMissingDescription(TrackingStatus status) {
    if (status.total > 0) {
      final remaining = status.total - status.completed;
      return '$remaining ${status.unit} needed';
    }
    return 'Not logged';
  }
}

// Data model for tracking status
class TrackingStatus {
  final String category;
  final IconData icon;
  final Color color;
  final int completed;
  final int total;
  final Map<String, dynamic> details;
  final String unit;
  final bool isComplete;
  final bool excludeFromProgress; 

  TrackingStatus({
    required this.category,
    required this.icon,
    required this.color,
    required this.completed,
    required this.total,
    this.details = const {},
    this.unit = '',
    required this.isComplete,
    this.excludeFromProgress = false,
  });
}