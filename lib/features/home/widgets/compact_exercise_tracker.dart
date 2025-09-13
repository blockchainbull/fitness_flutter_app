import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/tracking/screens/exercise_logging_page.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:intl/intl.dart';

class CompactExerciseTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const CompactExerciseTracker({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CompactExerciseTracker> createState() => _CompactExerciseTrackerState();
}

class _CompactExerciseTrackerState extends State<CompactExerciseTracker> {
  final ApiService _apiService = ApiService();
  int _todayMinutes = 0;
  int _todayExercises = 0;
  int _weeklyExercises = 0;
  Set<String> _weeklyMuscleGroups = {};
  bool _isLoading = true;
  late int _dailyGoal;

  @override
  void initState() {
    super.initState();
    _initializeExerciseGoal();
    _loadExerciseData();
  }

  void _initializeExerciseGoal() {
    // Get exercise goal from user profile
    if (widget.userProfile.workoutDuration != null) {
      _dailyGoal = widget.userProfile.workoutDuration;
    } else {
      // Default fallback if no exercise goal is set
      _dailyGoal = 30; // 30 minutes default
    }
    
    // Ensure exercise goal is reasonable (between 10 and 180 minutes)
    _dailyGoal = _dailyGoal.clamp(10, 180);
  }

  @override
  void didUpdateWidget(CompactExerciseTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _initializeExerciseGoal();
      _loadExerciseData();
    }
  }

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      
      // Calculate start of week (Monday)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);
      
      // Load today's exercise data
      final todayExercises = await _apiService.getExerciseLogs(
        widget.userProfile.id,
        startDate: today,
        endDate: today,
      );
      
      // Load this week's exercise data
      final weekExercises = await _apiService.getExerciseLogs(
        widget.userProfile.id,
        startDate: weekStartStr,
        endDate: today,
      );
      
      // Calculate today's total minutes
      int todayMinutes = 0;
      int todayCount = 0;
      if (todayExercises != null && todayExercises.isNotEmpty) {
        for (var exercise in todayExercises) {
          // Check if the exercise date is actually today
          final exerciseDate = exercise['exercise_date'] ?? exercise['created_at'];
          if (exerciseDate != null && exerciseDate.toString().startsWith(today)) {
            // Check if it's a cardio exercise with duration
            if (exercise['duration_minutes'] != null) {
              todayMinutes += (exercise['duration_minutes'] as num?)?.toInt() ?? 0;
            } else {
              // For strength exercises, estimate duration based on sets
              // Typically, a set takes about 1-2 minutes including rest
              final sets = (exercise['sets'] as num?)?.toInt() ?? 0;
              final exerciseType = exercise['exercise_type'] as String?;
              
              if (sets > 0) {
                // Estimate: 2 minutes per set for strength training (includes rest)
                // This is a reasonable approximation for tracking purposes
                final estimatedMinutes = sets * 2;
                todayMinutes += estimatedMinutes;
              }
            }
            todayCount++;
          }
        }
      }
      
      // Calculate weekly stats and muscle groups
      int weeklyCount = 0;
      Set<String> muscleGroups = {};
      
      if (weekExercises != null && weekExercises.isNotEmpty) {
        for (var exercise in weekExercises) {
          final exerciseDate = exercise['exercise_date'] ?? exercise['created_at'];
          if (exerciseDate != null) {
            final exDate = DateTime.parse(exerciseDate.toString());
            // Only count exercises from this week
            if (exDate.isAfter(weekStart.subtract(Duration(days: 1)))) {
              weeklyCount++;
              
              // Track muscle groups
              final muscleGroup = exercise['muscle_group'] as String?;
              if (muscleGroup != null && muscleGroup != 'general') {
                muscleGroups.add(muscleGroup);
              }
            }
          }
        }
      }
      
      setState(() {
        _todayMinutes = todayMinutes;
        _todayExercises = todayCount;
        _weeklyExercises = weeklyCount;
        _weeklyMuscleGroups = muscleGroups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exercise data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToExerciseLogging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedExerciseLoggingPage(
          userProfile: widget.userProfile,
        ),
      ),
    ).then((_) {
      _loadExerciseData();
      widget.onUpdate?.call();
    });
  }

  Widget _buildMuscleGroupChips() {
    if (_weeklyMuscleGroups.isEmpty) {
      return SizedBox.shrink();
    }

    // Map muscle group names to icons
    final muscleIcons = {
      'chest': Icons.fitness_center,
      'back': Icons.rowing,
      'shoulders': Icons.accessibility,
      'arms': Icons.sports_handball,
      'legs': Icons.directions_run,
      'core': Icons.self_improvement,
      'cardio': Icons.favorite,
    };

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _weeklyMuscleGroups.map((muscle) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  muscleIcons[muscle.toLowerCase()] ?? Icons.fitness_center,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  muscle.substring(0, 1).toUpperCase() + muscle.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_todayMinutes / _dailyGoal).clamp(0.0, 1.0);
    final bool goalMet = _todayMinutes >= _dailyGoal;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35),
            const Color(0xFFFF9558),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToExerciseLogging,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exercise Tracker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Daily goal: $_dailyGoal min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (goalMet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Goal Met!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Progress section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Activity',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '$_todayMinutes / $_dailyGoal min',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goalMet ? Colors.green : Colors.white,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      if (_todayExercises > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$_todayExercises exercise${_todayExercises > 1 ? 's' : ''} today',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Weekly stats
                if (_weeklyExercises > 0)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'This week: $_weeklyExercises workout${_weeklyExercises > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (_weeklyMuscleGroups.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Muscle groups trained:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          _buildMuscleGroupChips(),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Log button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToExerciseLogging,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}