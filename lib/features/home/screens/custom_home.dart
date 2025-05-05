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
    'summary',
    'calories',
    'water',
    'steps',
    'workout',
    'nutrition',
  ];

  // List of all available widgets
  final List<Map<String, dynamic>> _availableWidgets = [
    {'id': 'summary', 'name': 'Daily Summary', 'icon': Icons.dashboard},
    {'id': 'calories', 'name': 'Calorie Tracker', 'icon': Icons.local_fire_department},
    {'id': 'water', 'name': 'Water Intake', 'icon': Icons.water_drop},
    {'id': 'steps', 'name': 'Step Counter', 'icon': Icons.directions_walk},
    {'id': 'workout', 'name': 'Workout Plan', 'icon': Icons.fitness_center},
    {'id': 'nutrition', 'name': 'Meal Plan', 'icon': Icons.restaurant},
    {'id': 'protein', 'name': 'Protein Tracker', 'icon': Icons.egg},
    {'id': 'sleep', 'name': 'Sleep Quality', 'icon': Icons.nightlight_round},
    {'id': 'muscles', 'name': 'Muscle Progress', 'icon': Icons.accessibility_new},
    {'id': 'metrics', 'name': 'Health Metrics', 'icon': Icons.monitor_heart},
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Colors.blue,
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
                      colors: [Colors.teal.shade400, Colors.teal.shade800],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _openWidgetSelector,
                ),
                IconButton(
                  icon: const Icon(Icons.notifications),
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
                    if (_enabledWidgets.contains('summary'))
                      _buildSummaryCard(),
                    
                    if (_enabledWidgets.contains('calories'))
                      _buildCalorieSection(),
                    
                    if (_enabledWidgets.contains('water') || _enabledWidgets.contains('steps'))
                      _buildWaterAndStepsRow(),
                    
                    if (_enabledWidgets.contains('protein'))
                      _buildProteinTracker(),
                    
                    if (_enabledWidgets.contains('sleep'))
                      _buildSleepTracker(),
                    
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
  
  Widget _buildSummaryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
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
              const Text(
                'Daily Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                      children: [
                        // Water Intake Tracker
                        Expanded(
                          child: Container(
                            height: 260, // Match the height of the steps tracker
                            child: WaterTracker(
                              waterGoal: 8,
                              waterConsumed: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Steps Tracker
                        Expanded(
                          child: Container(
                            height: 260, // Same height as water tracker
                            child: DailyStepTracker(
                              stepGoal: 10000,
                              stepsWalked: 6500,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              const Text(
                'Today\'s Focus: Upper Body Strength',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your goals and progress, we recommend focusing on protein intake and completing your strength workout today.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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
  
  Widget _buildWaterAndStepsRow() {
    return Column(
      children: [
        Row(
          children: [
            if (_enabledWidgets.contains('water'))
              const Expanded(
                child: WaterTracker(
                  waterGoal: 10,
                  waterConsumed: 6,
                ),
              ),
            if (_enabledWidgets.contains('water') && _enabledWidgets.contains('steps'))
              const SizedBox(width: 16),
            if (_enabledWidgets.contains('steps'))
              const Expanded(
                child: DailyStepTracker(
                  stepGoal: 10000,
                  stepsWalked: 8540,
                ),
              ),
          ],
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
  
  Widget _buildMuscleTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muscle Group Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
  
  Widget _buildSummaryStat(String label, String value, String target, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          target,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}