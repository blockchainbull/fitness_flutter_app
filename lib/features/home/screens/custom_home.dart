import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/nutrition_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_card.dart';
import 'package:user_onboarding/features/home/widgets/metrics_card.dart';
import 'package:user_onboarding/features/home/widgets/water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/daily_step_tracker.dart';
import 'package:user_onboarding/features/home/widgets/calorie_tracker.dart';
import 'package:user_onboarding/features/home/widgets/protein_intake_tracker.dart';
import 'package:user_onboarding/features/home/widgets/sleep_quality_tracker.dart';
import 'package:user_onboarding/features/home/widgets/muscle_group_tracker.dart';
import 'package:user_onboarding/features/home/widgets/strength_progress_card.dart';
import 'package:user_onboarding/features/home/widgets/body_measurement_tracker.dart';
import 'package:user_onboarding/features/home/widgets/recovery_timer.dart';
import 'package:user_onboarding/features/home/widgets/workout_split_calendar.dart';

class CustomHome extends StatefulWidget {
  final UserProfile userProfile;
  
  const CustomHome({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<CustomHome> createState() => _CustomHomeState();
}

class _CustomHomeState extends State<CustomHome> {
  // List to track which widgets are enabled
  final List<String> _enabledWidgets = [
    'calories',
    'water',
    'steps',
    'workout',
    'nutrition',
    'protein',
    'sleep',
    'strength',
    'measurements',
    'recovery',
    'split',
    'muscles',
    'metrics',
    'weight_goal',
  ];

  // List of all available widgets
  final List<Map<String, dynamic>> _availableWidgets = [
    {'id': 'calories', 'name': 'Calorie Tracker', 'icon': Icons.local_fire_department},
    {'id': 'water', 'name': 'Water Intake', 'icon': Icons.water_drop},
    {'id': 'steps', 'name': 'Step Counter', 'icon': Icons.directions_walk},
    {'id': 'workout', 'name': 'Workout Plan', 'icon': Icons.fitness_center},
    {'id': 'nutrition', 'name': 'Meal Plan', 'icon': Icons.restaurant},
    {'id': 'protein', 'name': 'Protein Tracker', 'icon': Icons.egg},
    {'id': 'sleep', 'name': 'Sleep Quality', 'icon': Icons.nightlight_round},
    {'id': 'strength', 'name': 'Strength Progress', 'icon': Icons.trending_up},
    {'id': 'measurements', 'name': 'Body Measurements', 'icon': Icons.straighten},
    {'id': 'recovery', 'name': 'Recovery Timer', 'icon': Icons.update},
    {'id': 'split', 'name': 'Training Split', 'icon': Icons.calendar_today},
    {'id': 'muscles', 'name': 'Muscle Progress', 'icon': Icons.accessibility_new},
    {'id': 'metrics', 'name': 'Health Metrics', 'icon': Icons.monitor_heart},
    {'id': 'weight_goal', 'name': 'Weight Goal', 'icon': Icons.monitor_weight},
  ];

  void _toggleWidget(String widgetId) {
    setState(() {
      if (_enabledWidgets.contains(widgetId)) {
        _enabledWidgets.remove(widgetId);
      } else {
        _enabledWidgets.add(widgetId);
      }
    });
  }

  void _openWidgetSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Your Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select the widgets you want to see on your home screen',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _availableWidgets.length,
                      itemBuilder: (context, index) {
                        final widget = _availableWidgets[index];
                        final isEnabled = _enabledWidgets.contains(widget['id']);
                        
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _toggleWidget(widget['id']);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: isEnabled
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget['icon'],
                                  color: isEnabled ? Colors.blue : Colors.grey[700],
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isEnabled ? Colors.blue : Colors.black,
                                    fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // The changes are already applied to _enabledWidgets
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a custom color for our custom home - light and dark variant for gradient
    final Color customPrimaryColor = Colors.teal;
    final Color customPrimaryColorDark = Colors.teal.shade800;

    return Scaffold(
      backgroundColor: customPrimaryColor.withOpacity(0.4),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: customPrimaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Welcome, ${widget.userProfile.name.split(' ')[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [customPrimaryColor, customPrimaryColorDark],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white),
                  onPressed: _openWidgetSelector,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications,
                    color: Colors.white),
                  onPressed: () {
                    // TODO: Implement notifications
                  },
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show widgets based on enabled list
                    if (_enabledWidgets.contains('weight_goal'))
                      _buildWeightGoalSection(),
                      
                    if (_enabledWidgets.contains('calories'))
                      _buildCalorieSection(),
                    
                    if (_enabledWidgets.contains('water'))
                      _buildWaterSection(),
                    
                    if (_enabledWidgets.contains('steps'))
                      _buildStepsSection(),
                    
                    if (_enabledWidgets.contains('protein'))
                      _buildProteinTracker(),
                    
                    if (_enabledWidgets.contains('sleep'))
                      _buildSleepTracker(),
                    
                    if (_enabledWidgets.contains('strength'))
                      _buildStrengthProgressSection(),
                    
                    if (_enabledWidgets.contains('measurements'))
                      _buildBodyMeasurementsSection(),
                    
                    if (_enabledWidgets.contains('recovery'))
                      _buildRecoverySection(),
                    
                    if (_enabledWidgets.contains('split'))
                      _buildWorkoutSplitSection(),
                    
                    if (_enabledWidgets.contains('muscles'))
                      _buildMuscleTracker(),
                    
                    if (_enabledWidgets.contains('workout'))
                      _buildWorkoutSection(),
                      
                    if (_enabledWidgets.contains('nutrition'))
                      _buildNutritionSection(),
                      
                    if (_enabledWidgets.contains('metrics'))
                      _buildMetricsSection(),
                      
                    // Empty state if no widgets are enabled
                    if (_enabledWidgets.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // New widget for setting and tracking weight goal
  Widget _buildWeightGoalSection() {
    // Get user's current weight and target weight
    final currentWeight = widget.userProfile.weight;
    final targetWeight = widget.userProfile.targetWeight;
    
    // Determine if we're trying to gain or lose weight
    final isWeightLoss = currentWeight > targetWeight;
    final progressPercentage = _calculateWeightProgressPercentage();
    
    final Color progressColor = isWeightLoss ? Colors.purple.shade300 : Colors.green.shade500;
    final String goalType = isWeightLoss ? 'Weight Loss' : 'Weight Gain';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$goalType Progress',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    goalType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showWeightGoalEditor(context);
                    },
                    tooltip: 'Edit goal',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeightStat(
                    'Starting',
                    '${currentWeight.toStringAsFixed(1)} kg',
                    Colors.grey,
                  ),
                  _buildWeightStat(
                    'Current',
                    '${currentWeight.toStringAsFixed(1)} kg',
                    progressColor,
                  ),
                  _buildWeightStat(
                    'Goal',
                    '${targetWeight.toStringAsFixed(1)} kg',
                    progressColor.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(1)}% of your goal achieved',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isWeightLoss 
                    ? 'You need to lose ${(currentWeight - targetWeight).toStringAsFixed(1)} kg to reach your goal'
                    : 'You need to gain ${(targetWeight - currentWeight).toStringAsFixed(1)} kg to reach your goal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  // Helper method to build weight stat item
  Widget _buildWeightStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Weight goal progress calculation
  double _calculateWeightProgressPercentage() {
    final startingWeight = widget.userProfile.weight;
    final targetWeight = widget.userProfile.targetWeight;
    
    // If they're equal, we're at 100%
    if (startingWeight == targetWeight) {
      return 1.0;
    }
    
    // For weight loss goal
    if (startingWeight > targetWeight) {
      // Calculate weight to lose
      final totalWeightToLose = startingWeight - targetWeight;
      // Assume no progress yet since we don't have tracking
      final weightLost = 0;
      
      // Calculate percentage
      if (totalWeightToLose <= 0) return 0.0;
      final progress = weightLost / totalWeightToLose;
      return progress.clamp(0.0, 1.0);
    } 
    // For weight gain goal
    else {
      // Calculate weight to gain
      final totalWeightToGain = targetWeight - startingWeight;
      // Assume no progress yet since we don't have tracking
      final weightGained = 0;
      
      // Calculate percentage
      if (totalWeightToGain <= 0) return 0.0;
      final progress = weightGained / totalWeightToGain;
      return progress.clamp(0.0, 1.0);
    }
  }
  
  // Dialog to edit weight goal
  void _showWeightGoalEditor(BuildContext context) {
    final TextEditingController targetWeightController = TextEditingController();
    targetWeightController.text = widget.userProfile.targetWeight.toString();
    
    String goalType = 'maintain';
    if (widget.userProfile.weight > widget.userProfile.targetWeight) {
      goalType = 'lose';
    } else if (widget.userProfile.weight < widget.userProfile.targetWeight) {
      goalType = 'gain';
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Weight Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What is your weight goal?'),
                  const SizedBox(height: 12),
                  // Goal type radio buttons
                  ListTile(
                    title: const Text('Lose Weight'),
                    leading: Radio<String>(
                      value: 'lose',
                      groupValue: goalType,
                      onChanged: (value) {
                        setState(() {
                          goalType = value!;
                          if (goalType == 'lose') {
                            targetWeightController.text = 
                                (widget.userProfile.weight * 0.9).toStringAsFixed(1);
                          }
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Maintain Weight'),
                    leading: Radio<String>(
                      value: 'maintain',
                      groupValue: goalType,
                      onChanged: (value) {
                        setState(() {
                          goalType = value!;
                          if (goalType == 'maintain') {
                            targetWeightController.text = 
                                widget.userProfile.weight.toString();
                          }
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Gain Weight'),
                    leading: Radio<String>(
                      value: 'gain',
                      groupValue: goalType,
                      onChanged: (value) {
                        setState(() {
                          goalType = value!;
                          if (goalType == 'gain') {
                            targetWeightController.text = 
                                (widget.userProfile.weight * 1.1).toStringAsFixed(1);
                          }
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Target Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Convert to proper types
                    double targetWeight = double.tryParse(targetWeightController.text) ?? 
                        widget.userProfile.weight;
                    
                    // TODO: Save the changes to user profile
                    // This would need a proper implementation to update the user profile
                    // For now, we'll just print to console
                    print('Updated weight goal: $goalType, Target: $targetWeight kg');
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Widget _buildCalorieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calorie Tracker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const CalorieTracker(
          calorieGoal: 2200,
          caloriesConsumed: 1850,
          caloriesBurned: 380,
          carbs: 0.45,
          protein: 0.30,
          fat: 0.25,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildWaterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Water Intake',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const WaterTracker(
          waterGoal: 10,
          waterConsumed: 6,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const DailyStepTracker(
          stepGoal: 10000,
          stepsWalked: 8540,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildProteinTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Protein Intake',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const ProteinIntakeTracker(
          proteinGoal: 165,
          proteinConsumed: 95,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildSleepTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sleep Quality',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const SleepQualityTracker(
          sleepHours: 7.5,
          sleepQuality: 0.85,
          deepSleepPercentage: 0.22,
          remSleepPercentage: 0.18,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildStrengthProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Strength Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const StrengthProgressCard(
          lifts: [
            {
              'name': 'Bench Press',
              'current': 100.0,
              'previous': 95.0,
              'unit': 'kg',
            },
            {
              'name': 'Squat',
              'current': 140.0,
              'previous': 130.0,
              'unit': 'kg',
            },
            {
              'name': 'Deadlift',
              'current': 160.0,
              'previous': 155.0,
              'unit': 'kg',
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildBodyMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body Measurements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const BodyMeasurementTracker(
          measurements: [
            {
              'name': 'Chest',
              'current': 105.0,
              'previous': 103.5,
              'unit': 'cm',
              'icon': Icons.accessibility,
            },
            {
              'name': 'Arms',
              'current': 38.5,
              'previous': 37.8,
              'unit': 'cm',
              'icon': Icons.accessibility,
            },
            {
              'name': 'Waist',
              'current': 83.0,
              'previous': 84.5,
              'unit': 'cm',
              'icon': Icons.accessibility,
            },
            {
              'name': 'Thighs',
              'current': 62.0,
              'previous': 60.5,
              'unit': 'cm',
              'icon': Icons.accessibility,
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildRecoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muscle Recovery',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const RecoveryTimer(
          muscleGroups: [
            {
              'name': 'Chest',
              'lastTrainedDays': 2,
              'recoveryDays': 3,
              'icon': Icons.accessibility,
            },
            {
              'name': 'Back',
              'lastTrainedDays': 1,
              'recoveryDays': 3,
              'icon': Icons.accessibility,
            },
            {
              'name': 'Legs',
              'lastTrainedDays': 3,
              'recoveryDays': 3,
              'icon': Icons.accessibility,
            },
            {
              'name': 'Shoulders',
              'lastTrainedDays': 4,
              'recoveryDays': 3,
              'icon': Icons.accessibility,
            },
            {
              'name': 'Arms',
              'lastTrainedDays': 0,
              'recoveryDays': 2,
              'icon': Icons.accessibility,
            },
            {
              'name': 'Core',
              'lastTrainedDays': 1,
              'recoveryDays': 1,
              'icon': Icons.accessibility,
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildWorkoutSplitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Training Split',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        WorkoutSplitCalendar(
          currentDayIndex: DateTime.now().weekday - 1,
          weekSchedule: const [
            {
              'muscleGroup': 'Chest & Triceps',
              'isRestDay': false,
              'exercises': [
                'Bench Press',
                'Incline Dumbbell Press',
                'Tricep Pushdowns',
              ],
            },
            {
              'muscleGroup': 'Back & Biceps',
              'isRestDay': false,
              'exercises': [
                'Pull-ups',
                'Barbell Rows',
                'Bicep Curls',
              ],
            },
            {
              'muscleGroup': 'Rest Day',
              'isRestDay': true,
              'exercises': [],
            },
            {
              'muscleGroup': 'Shoulders',
              'isRestDay': false,
              'exercises': [
                'Overhead Press',
                'Lateral Raises',
                'Face Pulls',
              ],
            },
            {
              'muscleGroup': 'Legs',
              'isRestDay': false,
              'exercises': [
                'Squats',
                'Romanian Deadlifts',
                'Leg Press',
              ],
            },
            {
              'muscleGroup': 'Arms Focus',
              'isRestDay': false,
              'exercises': [
                'Skull Crushers',
                'Dumbbell Curls',
                'Cable Extensions',
              ],
            },
            {
              'muscleGroup': 'Rest Day',
              'isRestDay': true,
              'exercises': [],
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildMuscleTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muscle Group Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const MuscleGroupTracker(
          muscleGroups: [
            {'name': 'Chest', 'progress': 0.7},
            {'name': 'Back', 'progress': 0.8},
            {'name': 'Arms', 'progress': 0.6},
            {'name': 'Shoulders', 'progress': 0.5},
            {'name': 'Legs', 'progress': 0.65},
            {'name': 'Core', 'progress': 0.75},
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildWorkoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Workout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const WorkoutCard(
          title: 'Full Body Circuit',
          duration: '45 min',
          caloriesBurn: 380,
          exercises: [
            {
              'name': 'Push-ups',
              'sets': '3 sets',
              'duration': '12-15 reps',
              'rest': '30 sec',
            },
            {
              'name': 'Bodyweight Squats',
              'sets': '3 sets',
              'duration': '15-20 reps',
              'rest': '30 sec',
            },
            {
              'name': 'Dumbbell Rows',
              'sets': '3 sets',
              'duration': '12 reps each arm',
              'rest': '30 sec',
            },
            {
              'name': 'Walking Lunges',
              'sets': '3 sets',
              'duration': '10 each leg',
              'rest': '30 sec',
            },
            {
              'name': 'Plank',
              'sets': '3 sets',
              'duration': '45 seconds',
              'rest': '30 sec',
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildNutritionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Meals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const NutritionCard(
          title: 'Today\'s Meal Plan',
          meals: [
            {
              'name': 'Breakfast',
              'description': 'Oatmeal with banana, walnuts and honey',
              'calories': 420,
              'time': '7:30 AM',
            },
            {
              'name': 'Lunch',
              'description': 'Grilled chicken salad with olive oil dressing',
              'calories': 550,
              'time': '12:30 PM',
            },
            {
              'name': 'Snack',
              'description': 'Greek yogurt with berries',
              'calories': 200,
              'time': '3:30 PM',
            },
            {
              'name': 'Dinner',
              'description': 'Baked salmon with quinoa and roasted vegetables',
              'calories': 650,
              'time': '7:00 PM',
            },
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const MetricsCard(
          metrics: [
            {'name': 'BMI', 'value': '22.8', 'status': 'Normal'},
            {'name': 'Body Fat', 'value': '18%', 'status': 'Good'},
            {'name': 'Resting HR', 'value': '62', 'status': 'bpm'},
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.dashboard_customize,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your dashboard is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the edit button in the top right to add widgets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openWidgetSelector,
            icon: const Icon(Icons.add),
            label: const Text('Add Widgets'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}