import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/nutrition_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_card.dart';
import 'package:user_onboarding/features/home/widgets/metrics_card.dart';
import 'package:user_onboarding/features/home/widgets/water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/calorie_tracker.dart';
import 'package:user_onboarding/features/home/widgets/protein_intake_tracker.dart';

// Define custom green colors for the background
const Color kGreenBackgroundColor = Color(0xFF4CAF50); // Material Green 500
const Color kGreenBackgroundColorDark = Color(0xFF2E7D32); // Material Green 800

class WeightGainHome extends StatelessWidget {
  final UserProfile userProfile;
  
  const WeightGainHome({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGreenBackgroundColor.withOpacity(0.4), // Light green background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: kGreenBackgroundColor,
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
                      colors: [kGreenBackgroundColor, kGreenBackgroundColorDark],
                    ),
                  ),
                ),
              ),
              actions: [
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
                            'Weight Gain Progress',
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
                                kGreenBackgroundColor,
                              ),
                              _buildProgressStat(
                                'Goal',
                                '${userProfile.targetWeight.toStringAsFixed(1)} kg',
                                kGreenBackgroundColorDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                              value: 0.0, // Default to 0 for now
                              minHeight: 12,
                              backgroundColor: Color(0xFFE8F5E9), // Light green
                              valueColor: AlwaysStoppedAnimation<Color>(kGreenBackgroundColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '0.0% of your goal achieved',
                            style: TextStyle(
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
                    const CalorieTracker(
                      calorieGoal: 3000,
                      caloriesConsumed: 1800,
                      caloriesBurned: 250,
                      carbs: 0.45,
                      protein: 0.35,
                      fat: 0.20,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Protein Intake Section - Full width
                    const Text(
                      'Protein Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const ProteinIntakeTracker(
                      proteinGoal: 150,
                      proteinConsumed: 85,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Water Intake Section - Full width
                    const Text(
                      'Water Intake',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const WaterTracker(
                      waterGoal: 10,
                      waterConsumed: 6,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Nutrition & Meals Section (MOVED UP)
                    const Text(
                      'High-Calorie Meal Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nutrition Card for Weight Gain
                    const NutritionCard(
                      title: 'Today\'s Recommended Meals',
                      meals: [
                        {
                          'name': 'Breakfast',
                          'description': 'Protein-rich smoothie with banana, oats, and peanut butter',
                          'calories': 550,
                          'time': '7:00 AM',
                        },
                        {
                          'name': 'Mid-Morning',
                          'description': 'Greek yogurt with honey and granola',
                          'calories': 300,
                          'time': '10:00 AM',
                        },
                        {
                          'name': 'Lunch',
                          'description': 'Chicken and avocado wrap with sweet potato fries',
                          'calories': 750,
                          'time': '1:00 PM',
                        },
                        {
                          'name': 'Snack',
                          'description': 'Protein shake with almonds',
                          'calories': 350,
                          'time': '4:00 PM',
                        },
                        {
                          'name': 'Dinner',
                          'description': 'Steak with roasted potatoes and vegetables',
                          'calories': 850,
                          'time': '7:30 PM',
                        },
                        {
                          'name': 'Before Bed',
                          'description': 'Casein protein shake or cottage cheese',
                          'calories': 200,
                          'time': '9:30 PM',
                        },
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Workout Section (MOVED DOWN)
                    const Text(
                      'Today\'s Workout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Workout Card for Weight Gain
                    const WorkoutCard(
                      title: 'Muscle Building Lower Body Workout',
                      duration: '45 min',
                      caloriesBurn: 280,
                      exercises: [
                        {
                          'name': 'Barbell Squats',
                          'sets': '4 sets',
                          'duration': '8-10 reps',
                          'rest': '90 sec',
                        },
                        {
                          'name': 'Romanian Deadlifts',
                          'sets': '3 sets',
                          'duration': '10-12 reps',
                          'rest': '90 sec',
                        },
                        {
                          'name': 'Leg Press',
                          'sets': '3 sets',
                          'duration': '12-15 reps',
                          'rest': '60 sec',
                        },
                        {
                          'name': 'Walking Lunges',
                          'sets': '3 sets',
                          'duration': '10 each leg',
                          'rest': '60 sec',
                        },
                        {
                          'name': 'Seated Calf Raises',
                          'sets': '4 sets',
                          'duration': '15-20 reps',
                          'rest': '45 sec',
                        },
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Metrics Section (MOVED TO END)
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
                        {'name': 'BMI', 'value': '20.5', 'status': 'Normal'},
                        {'name': 'Body Fat', 'value': '15%', 'status': 'Good'},
                        {'name': 'Metabolic Rate', 'value': '2,250', 'status': 'kcal/day'},
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
  
  // Keeping this method for later implementation
  double _calculateProgressPercentage() {
    // Calculate the progress percentage based on starting weight, current weight, and target weight
    if (userProfile.weight >= userProfile.targetWeight) {
      return 1.0; // Already reached or exceeded target
    }
    
    // Assume starting weight is the current weight in the user profile
    final startingWeight = userProfile.weight;
    final targetWeight = userProfile.targetWeight;
    
    // No change needed case
    if (startingWeight == targetWeight) {
      return 1.0;
    }
    
    // Calculate percentage for weight gain
    final totalWeightToGain = targetWeight - startingWeight;
    final weightGained = 0; // This would be: currentWeight - startingWeight, but we don't have current weight tracking yet
    
    // Prevent division by zero and clamp between 0 and 1
    if (totalWeightToGain <= 0) {
      return 0.0;
    }
    
    final progress = weightGained / totalWeightToGain;
    return progress.clamp(0.0, 1.0);
  }
}