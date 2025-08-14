// lib/features/reports/screens/today_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/water_repository.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';
import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/water_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/sleep_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/exercise_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/steps_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/weight_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/supplements_logging_page.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';

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
    final breakfast = prefs.getBool('meal_breakfast_$date') ?? false;
    final lunch = prefs.getBool('meal_lunch_$date') ?? false;
    final dinner = prefs.getBool('meal_dinner_$date') ?? false;
    final snacks = prefs.getBool('meal_snacks_$date') ?? false;
    
    int completed = 0;
    if (breakfast) completed++;
    if (lunch) completed++;
    if (dinner) completed++;
    // Snacks are optional, so we don't count them in the total
    
    return TrackingStatus(
      category: 'Meals',
      icon: Icons.restaurant,
      color: Colors.green,
      completed: completed,
      total: 3, // Breakfast, Lunch, Dinner
      details: {
        'Breakfast': breakfast,
        'Lunch': lunch,
        'Dinner': dinner,
        'Snacks': snacks,
      },
      unit: 'meals',
      isComplete: completed >= 3,
    );
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
    final hasEntry = prefs.getBool('sleep_logged_$date') ?? false;
    final sleepHours = prefs.getDouble('sleep_hours_$date') ?? 0;
    final targetHours = 8.0;
    
    return TrackingStatus(
      category: 'Sleep',
      icon: Icons.bedtime,
      color: Colors.purple,
      completed: sleepHours.toInt(),
      total: targetHours.toInt(),
      details: {
        'Hours': '${sleepHours.toStringAsFixed(1)}h',
        'Target': '${targetHours}h',
        'Quality': hasEntry ? 'Logged' : 'Not logged',
      },
      unit: 'hours',
      isComplete: hasEntry && sleepHours >= 7,
    );
  }
  
  Future<TrackingStatus> _getExerciseStatus(SharedPreferences prefs, String date) async {
    final hasEntry = prefs.getBool('exercise_logged_$date') ?? false;
    final minutes = prefs.getInt('exercise_minutes_$date') ?? 0;
    final targetMinutes = 30;
    
    return TrackingStatus(
      category: 'Exercise',
      icon: Icons.fitness_center,
      color: Colors.orange,
      completed: minutes,
      total: targetMinutes,
      details: {
        'Duration': '${minutes} min',
        'Target': '${targetMinutes} min',
        'Status': hasEntry ? 'Completed' : 'Pending',
      },
      unit: 'min',
      isComplete: hasEntry && minutes >= targetMinutes,
    );
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
    final hasEntry = prefs.getBool('weight_logged_$date') ?? false;
    final weight = prefs.getDouble('weight_$date') ?? 0;
    
    return TrackingStatus(
      category: 'Weight',
      icon: Icons.monitor_weight,
      color: Colors.indigo,
      completed: hasEntry ? 1 : 0,
      total: 1,
      details: {
        'Weight': hasEntry ? '${weight.toStringAsFixed(1)} kg' : 'Not logged',
        'Status': hasEntry ? 'Logged' : 'Pending',
      },
      unit: '',
      isComplete: hasEntry,
    );
  }
  
  Future<TrackingStatus> _getSupplementStatus(SharedPreferences prefs, String date) async {
    final supplements = prefs.getStringList('user_supplements') ?? [];
    int taken = 0;
    
    if (supplements.isEmpty) {
      return TrackingStatus(
        category: 'Supplements',
        icon: Icons.medication,
        color: Colors.teal,
        completed: 0,
        total: 0,
        details: {
          'Status': 'No supplements configured',
        },
        unit: '',
        isComplete: true, // Consider complete if no supplements configured
      );
    }
    
    for (var supplement in supplements) {
      final key = 'supplement_${supplement}_$date';
      if (prefs.getBool(key) ?? false) {
        taken++;
      }
    }
    
    return TrackingStatus(
      category: 'Supplements',
      icon: Icons.medication,
      color: Colors.teal,
      completed: taken,
      total: supplements.length,
      details: {
        'Taken': '$taken/${supplements.length}',
        'Status': taken == supplements.length ? 'Complete' : 'Incomplete',
      },
      unit: 'pills',
      isComplete: taken == supplements.length,
    );
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
      padding: const EdgeInsets.all(20),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCompletionMessage(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
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
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
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
    
    return InkWell(
      onTap: () => _navigateToTracking(status.category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.isComplete 
                ? status.color.withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: status.color,
                  size: 28,
                ),
                if (status.isComplete)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            Text(
              status.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getStatusDisplay(status),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(status.color),
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
    } else if (status.category == 'Supplements' && status.total == 0) {
      return 'Not configured';
    } else if (status.total > 0) {
      return '${status.completed}/${status.total} ${status.unit}';
    } else {
      return status.isComplete ? 'Complete' : 'Pending';
    }
  }
  
  Widget _buildMissingActivities() {
    final missing = trackingStatus.entries
        .where((e) => !e.value.isComplete && 
               !(e.value.category == 'Supplements' && e.value.total == 0))
        .toList();
    
    if (missing.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great job!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You\'ve completed all activities for today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
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
              ),
              const SizedBox(width: 8),
              Text(
                'Missing Activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...missing.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => _navigateToTracking(entry.value.category),
              child: Row(
                children: [
                  Icon(
                    entry.value.icon,
                    color: entry.value.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    _getMissingDescription(entry.value),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          )),
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

  TrackingStatus({
    required this.category,
    required this.icon,
    required this.color,
    required this.completed,
    required this.total,
    this.details = const {},
    this.unit = '',
    required this.isComplete,
  });
}