import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/nutrition_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_card.dart';
import 'package:user_onboarding/features/home/widgets/metrics_card.dart';
import 'package:user_onboarding/features/home/widgets/water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/protein_intake_tracker.dart';
import 'package:user_onboarding/features/home/widgets/strength_progress_card.dart';
import 'package:user_onboarding/features/home/widgets/body_measurement_tracker.dart';
import 'package:user_onboarding/features/home/widgets/recovery_timer.dart';
import 'package:user_onboarding/features/home/widgets/workout_split_calendar.dart';

// Define custom deep purple color for the background
const Color kPurpleBackgroundColor = Color(0xFF673AB7); // Material Deep Purple 500
const Color kPurpleBackgroundColorDark = Color(0xFF4527A0); // Material Deep Purple 800

class MuscleGainHome extends StatelessWidget {
  final UserProfile userProfile;
  
  const MuscleGainHome({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPurpleBackgroundColor.withOpacity(0.4), // Light purple background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: kPurpleBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Welcome, ${userProfile.name.split(' ')[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPurpleBackgroundColor, kPurpleBackgroundColorDark],
                    ),
                  ),
                ),
              ),
              actions: [
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
                    // Strength Progress Section
                    const Text(
                      'Strength Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Strength Progress Card
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
                    
                    // Body Measurements Section
                    const Text(
                      'Body Measurements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Body Measurement Tracker
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
                    
                    // Workout Split Section
                    const Text(
                      'Weekly Training Split',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Workout Split Calendar
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
                    
                    // Recovery Section
                    const Text(
                      'Muscle Recovery',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Recovery Timer
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
                    
                    // Protein Intake Section
                    const Text(
                      'Protein Intake',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Protein Intake Tracker
                    const ProteinIntakeTracker(
                      proteinGoal: 180,
                      proteinConsumed: 120,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Water Intake Section
                    const Text(
                      'Water Intake',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Water Tracker
                    const WaterTracker(
                      waterGoal: 12,
                      waterConsumed: 8,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Today's Workout Section
                    const Text(
                      'Today\'s Workout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Workout Card
                    const WorkoutCard(
                      title: 'Upper Body Strength Workout',
                      duration: '60 min',
                      caloriesBurn: 320,
                      exercises: [
                        {
                          'name': 'Bench Press',
                          'sets': '4 sets',
                          'duration': '6-8 reps',
                          'rest': '2 min',
                        },
                        {
                          'name': 'Bent Over Rows',
                          'sets': '4 sets',
                          'duration': '8-10 reps',
                          'rest': '90 sec',
                        },
                        {
                          'name': 'Overhead Press',
                          'sets': '3 sets',
                          'duration': '8-10 reps',
                          'rest': '90 sec',
                        },
                        {
                          'name': 'Bicep Curls',
                          'sets': '3 sets',
                          'duration': '10-12 reps',
                          'rest': '60 sec',
                        },
                        {
                          'name': 'Tricep Extensions',
                          'sets': '3 sets',
                          'duration': '10-12 reps',
                          'rest': '60 sec',
                        },
                        {
                          'name': 'Lateral Raises',
                          'sets': '3 sets',
                          'duration': '12-15 reps',
                          'rest': '60 sec',
                        },
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Nutrition & Meals Section
                    const Text(
                      'Muscle Building Meal Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nutrition Card
                    const NutritionCard(
                      title: 'Today\'s High-Protein Meals',
                      meals: [
                        {
                          'name': 'Breakfast',
                          'description': 'Eggs, oatmeal with protein powder and berries',
                          'calories': 650,
                          'time': '7:00 AM',
                        },
                        {
                          'name': 'Mid-Morning',
                          'description': 'Protein shake with banana and almond butter',
                          'calories': 350,
                          'time': '10:00 AM',
                        },
                        {
                          'name': 'Lunch',
                          'description': 'Grilled chicken breast with quinoa and vegetables',
                          'calories': 700,
                          'time': '1:00 PM',
                        },
                        {
                          'name': 'Pre-Workout',
                          'description': 'Rice cakes with tuna and apple',
                          'calories': 350,
                          'time': '4:00 PM',
                        },
                        {
                          'name': 'Post-Workout',
                          'description': 'Whey protein shake with fast-acting carbs',
                          'calories': 300,
                          'time': '6:30 PM',
                        },
                        {
                          'name': 'Dinner',
                          'description': 'Salmon with sweet potatoes and broccoli',
                          'calories': 700,
                          'time': '7:30 PM',
                        },
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Metrics Section
                    const Text(
                      'Key Health Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Metrics Card
                    const MetricsCard(
                      metrics: [
                        {'name': 'BMI', 'value': '22.8', 'status': 'Normal'},
                        {'name': 'Body Fat', 'value': '14%', 'status': 'Athletic'},
                        {'name': 'Resting HR', 'value': '62', 'status': 'bpm'},
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}