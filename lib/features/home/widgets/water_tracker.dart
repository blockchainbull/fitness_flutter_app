import 'package:flutter/material.dart';

class WaterTracker extends StatelessWidget {
  final int waterGoal;
  final int waterConsumed;
  
  const WaterTracker({
    Key? key,
    required this.waterGoal,
    required this.waterConsumed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final progress = (waterConsumed / waterGoal).clamp(0.0, 1.0);
    
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
            children: [
              const Icon(
                Icons.water_drop,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Water Intake',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$waterConsumed/$waterGoal glasses',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: 10,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Foreground progress
                  Container(
                    height: 10,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Water drop icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(waterGoal, (index) {
              bool isFilled = index < waterConsumed;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.water_drop,
                  color: isFilled ? Colors.blue : Colors.blue.withOpacity(0.2),
                  size: 18,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Add glass button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Add water functionality
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Glass'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}