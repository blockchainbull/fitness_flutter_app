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
  int _weeklyWorkouts = 0;
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
      // Load today's exercise data
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final exercises = await _apiService.getExerciseLogs(
        widget.userProfile.id,
      );
      
      // Calculate total minutes today
      int totalMinutes = 0;
      if (exercises != null && exercises.isNotEmpty) {
        for (var exercise in exercises) {
          totalMinutes += (exercise['duration'] as num?)?.toInt() ?? 0;
        }
      }
      
      setState(() {
        _todayMinutes = totalMinutes;
        _weeklyWorkouts = exercises?.length ?? 0;
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Today's exercises count
                if (_weeklyWorkouts > 0)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_weeklyWorkouts exercise${_weeklyWorkouts > 1 ? 's' : ''} this week',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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