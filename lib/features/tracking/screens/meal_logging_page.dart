// lib/features/tracking/screens/meal_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/calorie_tracker.dart';
import 'package:user_onboarding/features/home/widgets/protein_intake_tracker.dart';

class MealLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const MealLoggingPage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<MealLoggingPage> createState() => _MealLoggingPageState();
}

class _MealLoggingPageState extends State<MealLoggingPage> {
  final List<Map<String, dynamic>> _todayMeals = [
    {
      'type': 'Breakfast',
      'time': '8:00 AM',
      'food': 'Oatmeal with berries',
      'calories': 320,
      'icon': Icons.breakfast_dining,
      'color': Colors.orange,
    },
    {
      'type': 'Lunch',
      'time': '12:30 PM',
      'food': 'Grilled chicken salad',
      'calories': 450,
      'icon': Icons.lunch_dining,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meal history coming soon!')),
              );
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTodaysSummary(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calorie Tracking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CalorieTracker(userProfile: widget.userProfile),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
            
            _buildMealsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeal,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodaysSummary() {
    final totalCalories = _todayMeals.fold<int>(0, (sum, meal) => sum + (meal['calories'] as int));
    const dailyGoal = 2000;
    final progress = totalCalories / dailyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Nutrition',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalCalories / $dailyGoal cal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNutritionStat('Meals', '${_todayMeals.length}'),
              _buildNutritionStat('Protein', '${(totalCalories * 0.15 / 4).round()}g'),
              _buildNutritionStat('Carbs', '${(totalCalories * 0.55 / 4).round()}g'),
              _buildNutritionStat('Fat', '${(totalCalories * 0.30 / 9).round()}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMealsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Meals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._todayMeals.map((meal) => _buildMealCard(meal)),
          _buildAddMealCard('Dinner', Icons.dinner_dining, Colors.purple),
          _buildAddMealCard('Snack', Icons.cookie, Colors.brown),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (meal['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meal['icon'] as IconData,
              color: meal['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meal['type'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      meal['time'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal['food'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${meal['calories']} calories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: meal['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () => _editMeal(meal),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMealCard(String mealType, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _addSpecificMeal(mealType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Add $mealType',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.add_circle_outline, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _addMeal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add meal functionality coming soon!')),
    );
  }

  void _addSpecificMeal(String mealType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add $mealType functionality coming soon!')),
    );
  }

  void _editMeal(Map<String, dynamic> meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${meal['type']} functionality coming soon!')),
    );
  }
}