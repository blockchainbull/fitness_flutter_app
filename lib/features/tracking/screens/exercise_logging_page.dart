// lib/features/tracking/screens/exercise_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/exercise_tracker.dart';
import 'package:user_onboarding/features/home/widgets/strength_progress_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_split_calendar.dart';

class ExerciseLoggingPage extends StatelessWidget {
  final UserProfile userProfile;

  const ExerciseLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracking'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add workout coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercise Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Use existing ExerciseTracker widget
            ExerciseTracker(userProfile: userProfile),
            
            const SizedBox(height: 30),
            
            const Text(
              'Strength Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Use existing StrengthProgressCard widget
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
            
            const SizedBox(height: 30),
            
            const Text(
              'Workout Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // FIXED: Provide the required weekSchedule parameter
            WorkoutSplitCalendar(
              weekSchedule: _getWeekSchedule(),
              currentDayIndex: DateTime.now().weekday - 1, // Monday = 0, Sunday = 6
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Method to provide mock workout schedule data
  List<Map<String, dynamic>> _getWeekSchedule() {
    return [
      // Monday
      {
        'muscleGroup': 'Chest & Triceps',
        'isRestDay': false,
        'exercises': [
          'Bench Press',
          'Incline Dumbbell Press',
          'Tricep Dips',
          'Push-ups',
        ],
      },
      // Tuesday
      {
        'muscleGroup': 'Back & Biceps',
        'isRestDay': false,
        'exercises': [
          'Pull-ups',
          'Barbell Rows',
          'Bicep Curls',
          'Lat Pulldowns',
        ],
      },
      // Wednesday
      {
        'muscleGroup': 'Legs',
        'isRestDay': false,
        'exercises': [
          'Squats',
          'Deadlifts',
          'Leg Press',
          'Calf Raises',
        ],
      },
      // Thursday
      {
        'muscleGroup': 'Shoulders & Abs',
        'isRestDay': false,
        'exercises': [
          'Shoulder Press',
          'Lateral Raises',
          'Plank',
          'Russian Twists',
        ],
      },
      // Friday
      {
        'muscleGroup': 'Full Body HIIT',
        'isRestDay': false,
        'exercises': [
          'Burpees',
          'Mountain Climbers',
          'Jump Squats',
          'High Knees',
        ],
      },
      // Saturday
      {
        'muscleGroup': 'Active Recovery',
        'isRestDay': true,
        'exercises': [],
      },
      // Sunday
      {
        'muscleGroup': 'Rest Day',
        'isRestDay': true,
        'exercises': [],
      },
    ];
  }
}