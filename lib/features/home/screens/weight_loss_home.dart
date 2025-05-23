import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/nutrition_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_card.dart';
import 'package:user_onboarding/features/home/widgets/metrics_card.dart';
import 'package:user_onboarding/features/home/widgets/water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/daily_step_tracker.dart';
import 'package:user_onboarding/features/home/widgets/calorie_tracker.dart';
import 'package:user_onboarding/features/home/widgets/exercise_tracker.dart';

// Define custom lilac/purple colors for the background to match other screens
const Color kLilacColor = Color(0xFFCE93D8); // Material Purple 200
const Color kLilacColorDark = Color(0xFFBA68C8); // Material Purple 300

class WeightLossHome extends StatelessWidget {
  final UserProfile userProfile;
  
  const WeightLossHome({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLilacColor.withOpacity(0.4), // Light lilac background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: kLilacColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Welcome, ${userProfile.name.split(' ')[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kLilacColor, kLilacColorDark],
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
                    // Progress Summary Card
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
                          const Text(
                            'Weight Loss Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildProgressStat(
                                'Starting',
                                '${userProfile.weight.toStringAsFixed(1)} kg',
                                Colors.grey,
                              ),
                              _buildProgressStat(
                                'Current',
                                '${userProfile.weight.toStringAsFixed(1)} kg',
                                kLilacColor,
                              ),
                              _buildProgressStat(
                                'Goal',
                                '${userProfile.targetWeight.toStringAsFixed(1)} kg',
                                kLilacColorDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _calculateProgressPercentage(),
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(kLilacColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_calculateProgressPercentage() * 100).toStringAsFixed(1)}% of your goal achieved',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Today's Summary Section
                    const Text(
                      'Today\'s Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Calorie & Macros Tracker
                    CalorieTracker(
                      userProfile: userProfile,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Water Intake Section - Now full width
                    const Text(
                      'Water Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Water Tracker
                    WaterTracker(
                      userProfile: userProfile,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Steps Section - Now full width
                    const Text(
                      'Daily Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Steps Tracker
                    const DailyStepTracker(
                      stepGoal: 10000,
                      stepsWalked: 6500,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Exercise Tracker Section
                    const Text(
                      'Exercise Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exercise Tracker
                    ExerciseTracker(
                      userProfile: userProfile,
                    ),
                    
                    // Nutrition & Meals Section
                    const Text(
                      'Meal Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nutrition Card
                    const NutritionCard(
                      title: 'Today\'s Recommended Meals',
                      meals: [
                        {
                          'name': 'Breakfast',
                          'description': 'Greek yogurt with berries and almonds',
                          'calories': 320,
                          'time': '7:30 AM',
                        },
                        {
                          'name': 'Lunch',
                          'description': 'Grilled chicken salad with olive oil dressing',
                          'calories': 450,
                          'time': '12:30 PM',
                        },
                        {
                          'name': 'Dinner',
                          'description': 'Baked salmon with steamed vegetables',
                          'calories': 480,
                          'time': '7:00 PM',
                        },
                        {
                          'name': 'Snack',
                          'description': 'Apple with a tablespoon of peanut butter',
                          'calories': 150,
                          'time': '4:00 PM',
                        },
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Workout Section
                    const Text(
                      'Today\'s Workout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Workout Card for Weight Loss
                    const WorkoutCard(
                      title: 'Fat Burning HIIT Workout',
                      duration: '35 min',
                      caloriesBurn: 350,
                      exercises: [
                        {
                          'name': 'Jumping Jacks',
                          'sets': '3 sets',
                          'duration': '45 sec',
                          'rest': '15 sec',
                        },
                        {
                          'name': 'Mountain Climbers',
                          'sets': '3 sets',
                          'duration': '45 sec',
                          'rest': '15 sec',
                        },
                        {
                          'name': 'Burpees',
                          'sets': '3 sets',
                          'duration': '45 sec',
                          'rest': '15 sec',
                        },
                        {
                          'name': 'High Knees',
                          'sets': '3 sets',
                          'duration': '45 sec',
                          'rest': '15 sec',
                        },
                        {
                          'name': 'Plank',
                          'sets': '3 sets',
                          'duration': '45 sec',
                          'rest': '15 sec',
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
                    MetricsCard(
                      userProfile: userProfile,
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
  
  Widget _buildProgressStat(String label, String value, Color color) {
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
  
  double _calculateProgressPercentage() {
    // Calculate the progress percentage based on starting weight, current weight, and target weight
    if (userProfile.weight <= userProfile.targetWeight) {
      return 1.0; // Already reached or exceeded target
    }
    
    // Assume starting weight is the current weight in the user profile
    final startingWeight = userProfile.weight;
    final targetWeight = userProfile.targetWeight;
    
    // No change needed case
    if (startingWeight == targetWeight) {
      return 1.0;
    }
    
    // Calculate percentage
    final totalWeightToLose = startingWeight - targetWeight;
    final weightLost = 0; // This would be: startingWeight - currentWeight, but we don't have current weight tracking yet
    
    // Prevent division by zero and clamp between 0 and 1
    if (totalWeightToLose <= 0) {
      return 0.0;
    }
    
    final progress = weightLost / totalWeightToLose;
    return progress.clamp(0.0, 1.0);
  }
}