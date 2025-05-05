import 'package:flutter/material.dart';

class CalorieTracker extends StatelessWidget {
  final int calorieGoal;
  final int caloriesConsumed;
  final int caloriesBurned;
  final double carbs;
  final double protein;
  final double fat;
  
  const CalorieTracker({
    Key? key,
    required this.calorieGoal,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.carbs,
    required this.protein,
    required this.fat,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final int caloriesRemaining = calorieGoal - caloriesConsumed + caloriesBurned;
    final double consumedPercentage = (caloriesConsumed / calorieGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              const Text(
                'Calories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: caloriesRemaining >= 0 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  caloriesRemaining >= 0 
                      ? '$caloriesRemaining remaining'
                      : '${caloriesRemaining.abs()} over',
                  style: TextStyle(
                    color: caloriesRemaining >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calorie bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal: $calorieGoal',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Consumed: $caloriesConsumed',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background progress bar
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Consumed progress
                  FractionallySizedBox(
                    widthFactor: consumedPercentage,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: caloriesRemaining >= 0 
                              ? [Colors.blue.shade300, Colors.blue.shade600]
                              : [Colors.orange.shade300, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Macros section
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCircle('Carbs', carbs, Colors.blue),
              _buildMacroCircle('Protein', protein, Colors.red),
              _buildMacroCircle('Fat', fat, Colors.yellow.shade800),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                'Food',
                caloriesConsumed.toString(),
                Icons.restaurant,
                Colors.orange,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatColumn(
                'Exercise',
                caloriesBurned.toString(),
                Icons.fitness_center,
                Colors.green,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatColumn(
                'Net',
                (caloriesConsumed - caloriesBurned).toString(),
                Icons.calculate,
                Colors.blue,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Add meal/exercise buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add meal functionality
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Meal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add exercise functionality
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Exercise'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroCircle(String label, double percentage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}