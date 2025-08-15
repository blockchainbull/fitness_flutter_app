// lib/features/reports/screens/today_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/water_repository.dart';
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
import 'package:user_onboarding/data/repositories/supplement_repository.dart';
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
      
      // Check each tracking category
      trackingStatus = {
        'meals': await _getMealStatus(prefs, todayStr),
        'water': await _getWaterStatus(userId),
        'sleep': await _getSleepStatus(prefs, todayStr),
        'exercise': await _getExerciseStatus(prefs, todayStr),
        'steps': await _getStepsStatus(userId),
        'weight': await _getWeightStatus(prefs, todayStr),
        'supplements': await _getSupplementStatus(prefs, todayStr),
      };
      
    } catch (e) {
      print('Error loading today data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<TrackingStatus> _getMealStatus(SharedPreferences prefs, String date) async {
    try {
      // Try to get meal data from API first
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      // Get today's meals from database
      final meals = await apiService.getMealHistory(
        userId,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
      );
      
      // Count meals by type
      int breakfast = 0;
      int lunch = 0;
      int dinner = 0;
      int snacks = 0;
      double totalCalories = 0;
      
      for (var meal in meals) {
        final mealType = meal['meal_type']?.toString().toLowerCase() ?? '';
        totalCalories += (meal['calories'] ?? 0).toDouble();
        
        switch (mealType) {
          case 'breakfast':
            breakfast++;
            break;
          case 'lunch':
            lunch++;
            break;
          case 'dinner':
            dinner++;
            break;
          case 'snack':
          case 'snacks':
            snacks++;
            break;
        }
      }
      
      // Consider a meal logged if any food was logged for that meal type
      final breakfastLogged = breakfast > 0;
      final lunchLogged = lunch > 0;
      final dinnerLogged = dinner > 0;
      
      int completed = 0;
      if (breakfastLogged) completed++;
      if (lunchLogged) completed++;
      if (dinnerLogged) completed++;
      
      // If we got data from API, also save to SharedPreferences for offline
      if (meals.isNotEmpty) {
        await prefs.setBool('meal_breakfast_$date', breakfastLogged);
        await prefs.setBool('meal_lunch_$date', lunchLogged);
        await prefs.setBool('meal_dinner_$date', dinnerLogged);
        await prefs.setBool('meal_snacks_$date', snacks > 0);
        await prefs.setDouble('meal_calories_$date', totalCalories);
      }
      
      return TrackingStatus(
        category: 'Meals',
        icon: Icons.restaurant,
        color: Colors.green,
        completed: completed,
        total: 3, // Breakfast, Lunch, Dinner
        details: {
          'Breakfast': breakfastLogged,
          'Lunch': lunchLogged,
          'Dinner': dinnerLogged,
          'Snacks': snacks > 0,
          'Calories': '${totalCalories.toInt()} cal',
          'Items': meals.length,
        },
        unit: 'meals',
        isComplete: completed >= 3,
        excludeFromProgress: false,
      );
      
    } catch (e) {
      print('Error getting meals from API: $e');
      
      // Fallback to SharedPreferences
      final breakfast = prefs.getBool('meal_breakfast_$date') ?? false;
      final lunch = prefs.getBool('meal_lunch_$date') ?? false;
      final dinner = prefs.getBool('meal_dinner_$date') ?? false;
      final snacks = prefs.getBool('meal_snacks_$date') ?? false;
      final calories = prefs.getDouble('meal_calories_$date') ?? 0;
      
      int completed = 0;
      if (breakfast) completed++;
      if (lunch) completed++;
      if (dinner) completed++;
      
      return TrackingStatus(
        category: 'Meals',
        icon: Icons.restaurant,
        color: Colors.green,
        completed: completed,
        total: 3,
        details: {
          'Breakfast': breakfast,
          'Lunch': lunch,
          'Dinner': dinner,
          'Snacks': snacks,
          'Calories': calories > 0 ? '${calories.toInt()} cal' : 'Not tracked',
        },
        unit: 'meals',
        isComplete: completed >= 3,
        excludeFromProgress: false,
      );
    }
  }
  
  Future<TrackingStatus> _getWaterStatus(String userId) async {
    try {
      final entry = await WaterRepository.getTodayWaterEntry(userId);
      final goal = entry?.targetMl ?? 2000.0; // Use targetMl from the entry
      final consumed = entry?.totalMl ?? 0.0; // Use totalMl instead of totalAmount
      
      return TrackingStatus(
        category: 'Water',
        icon: Icons.water_drop,
        color: Colors.blue,
        completed: consumed.toInt(),
        total: goal.toInt(),
        details: {
          'Amount': '${consumed.toInt()}ml',
          'Goal': '${goal.toInt()}ml',
          'Glasses': '${entry?.glassesConsumed ?? 0}',
          'Percentage': '${goal > 0 ? ((consumed / goal) * 100).toInt() : 0}%',
        },
        unit: 'ml',
        isComplete: consumed >= goal,
      );
    } catch (e) {
      print('Error getting water status: $e');
      return TrackingStatus(
        category: 'Water',
        icon: Icons.water_drop,
        color: Colors.blue,
        completed: 0,
        total: 2000,
        unit: 'ml',
        isComplete: false,
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
      // Try to get exercise data from API first
      final apiService = ApiService();
      final userId = widget.userProfile.id ?? '';
      
      // Get today's exercises from database
      final exercises = await apiService.getExerciseLogs(
        userId,
        startDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        endDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      );
      
      // Calculate total minutes and calories
      int totalMinutes = 0;
      double totalCalories = 0;
      List<String> exerciseNames = [];
      
      for (var exercise in exercises) {
        totalMinutes += (exercise['duration_minutes'] ?? 0) as int;
        totalCalories += (exercise['calories_burned'] ?? 0).toDouble();
        exerciseNames.add(exercise['exercise_name'] ?? 'Unknown');
      }
      
      final targetMinutes = 30;
      final hasEntry = exercises.isNotEmpty;
      
      // Save to SharedPreferences for offline access
      if (hasEntry) {
        await prefs.setBool('exercise_logged_$date', true);
        await prefs.setInt('exercise_minutes_$date', totalMinutes);
        await prefs.setDouble('exercise_calories_$date', totalCalories);
        await prefs.setInt('exercise_count_$date', exercises.length);
      }
      
      return TrackingStatus(
        category: 'Exercise',
        icon: Icons.fitness_center,
        color: Colors.orange,
        completed: totalMinutes,
        total: targetMinutes,
        details: {
          'Duration': '$totalMinutes min',
          'Target': '$targetMinutes min',
          'Calories': '${totalCalories.toInt()} cal',
          'Sessions': exercises.length,
          'Activities': exerciseNames.take(2).join(', ') + 
                      (exerciseNames.length > 2 ? '...' : ''),
          'Status': hasEntry 
              ? (totalMinutes >= targetMinutes ? 'Complete' : 'In Progress')
              : 'Pending',
        },
        unit: 'min',
        isComplete: hasEntry && totalMinutes >= targetMinutes,
        excludeFromProgress: false,
      );
      
    } catch (e) {
      print('Error getting exercise from API: $e');
      
      // Fallback to SharedPreferences
      final hasEntry = prefs.getBool('exercise_logged_$date') ?? false;
      final minutes = prefs.getInt('exercise_minutes_$date') ?? 0;
      final calories = prefs.getDouble('exercise_calories_$date') ?? 0;
      final count = prefs.getInt('exercise_count_$date') ?? 0;
      final targetMinutes = 30;
      
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
          'Status': hasEntry 
              ? (minutes >= targetMinutes ? 'Complete' : 'In Progress')
              : 'Pending',
        },
        unit: 'min',
        isComplete: hasEntry && minutes >= targetMinutes,
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
      // Check if supplements tracking is explicitly disabled
      final isDisabled = prefs.getBool('supplement_tracking_disabled') ?? false;
      
      if (isDisabled) {
        return TrackingStatus(
          category: 'Supplements',
          icon: Icons.medication,
          color: Colors.teal,
          completed: 0,
          total: 0,
          details: {
            'Status': 'Tracking disabled',
          },
          unit: '',
          isComplete: false,
          excludeFromProgress: true,
        );
      }
      
      // Check database for user's supplement preferences
      List<Map<String, dynamic>> dbPreferences = [];
      List<String> supplementNames = [];
      
      try {
        // Get supplement preferences from database
        dbPreferences = await SupplementRepository.getSupplementPreferences(
          widget.userProfile.id ?? ''
        );
        
        if (dbPreferences.isNotEmpty) {
          // User has configured supplements in database
          supplementNames = dbPreferences.map((pref) => 
            pref['supplement_name']?.toString() ?? pref['name']?.toString() ?? ''
          ).where((name) => name.isNotEmpty).toList();
          
          print('Found ${supplementNames.length} supplements from database: $supplementNames');
        }
      } catch (e) {
        print('Error fetching supplement preferences from database: $e');
      }
      
      // Fallback to SharedPreferences if database is empty
      if (supplementNames.isEmpty) {
        final supplementsList = prefs.getString('supplement_tracking_list') ?? 
                              prefs.getString('user_supplements_list');
        
        if (supplementsList != null && supplementsList.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(supplementsList);
            final userSupplements = decoded.cast<Map<String, dynamic>>();
            supplementNames = userSupplements.map((s) => s['name'] as String).toList();
            print('Found ${supplementNames.length} supplements from SharedPreferences: $supplementNames');
          } catch (e) {
            print('Error parsing supplements from SharedPreferences: $e');
          }
        }
      }
      
      // If still no supplements found, they're not configured
      if (supplementNames.isEmpty) {
        return TrackingStatus(
          category: 'Supplements',
          icon: Icons.medication,
          color: Colors.teal,
          completed: 0,
          total: 0,
          details: {
            'Status': 'Not configured',
          },
          unit: '',
          isComplete: false,
          excludeFromProgress: true,
        );
      }
      
      // User has configured supplements - check today's intake status
      int taken = 0;
      List<String> remaining = [];
      Map<String, bool> todayStatus = {};
      
      // First try to get today's status from database
      try {
        todayStatus = await SupplementRepository.getTodaysSupplementStatus(
          widget.userProfile.id ?? ''
        );
        print('Got today\'s status from database: $todayStatus');
      } catch (e) {
        print('Error getting today\'s status from database: $e');
      }
      
      // Check status for each supplement
      for (var supplementName in supplementNames) {
        bool isTaken = false;
        
        // Check database status first
        if (todayStatus.containsKey(supplementName)) {
          isTaken = todayStatus[supplementName] ?? false;
        } else {
          // Fallback to SharedPreferences
          final key1 = 'supplement_${supplementName}_$date';
          final key2 = 'supplement_${supplementName.replaceAll(' ', '_')}_$date';
          isTaken = prefs.getBool(key1) ?? prefs.getBool(key2) ?? false;
        }
        
        if (isTaken) {
          taken++;
        } else {
          remaining.add(supplementName);
        }
      }
      
      print('Supplements status: $taken/${supplementNames.length} taken');
      print('Remaining: $remaining');
      
      // Return the tracking status
      return TrackingStatus(
        category: 'Supplements',
        icon: Icons.medication,
        color: Colors.teal,
        completed: taken,
        total: supplementNames.length,
        details: {
          'Taken': '$taken/${supplementNames.length}',
          'Status': taken == supplementNames.length ? 'Complete' : 'Incomplete',
          'Remaining': remaining,
          'Names': supplementNames,
        },
        unit: supplementNames.length == 1 ? 'pill' : 'pills',
        isComplete: taken == supplementNames.length,
        excludeFromProgress: false, // COUNT in daily progress when configured
      );
      
    } catch (e) {
      print('Error in _getSupplementStatus: $e');
      return TrackingStatus(
        category: 'Supplements',
        icon: Icons.medication,
        color: Colors.teal,
        completed: 0,
        total: 0,
        details: {
          'Status': 'Error loading',
        },
        unit: '',
        isComplete: false,
        excludeFromProgress: true,
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
                              entry.value.details['Remaining'] != null &&
                              (entry.value.details['Remaining'] as List).isNotEmpty)
                            Text(
                              (entry.value.details['Remaining'] as List).take(2).join(', ') +
                                  ((entry.value.details['Remaining'] as List).length > 2 
                                      ? '...' 
                                      : ''),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _getMissingDescription(entry.value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            )),
          ],
          
          // Show supplements setup suggestion ONLY if not configured
          if (supplementsNotConfigured) ...[
            if (missing.isNotEmpty) 
              Divider(height: 16, color: Colors.orange.shade200),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _navigateToTracking('Supplements'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: Colors.teal.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up Supplements',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Track your daily vitamins',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Colors.grey.shade400,
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
        page = ExerciseLoggingPage(userProfile: widget.userProfile);
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