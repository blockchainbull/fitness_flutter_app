import 'package:flutter/material.dart';

class MuscleGroupTracker extends StatelessWidget {
  final List<Map<String, dynamic>> muscleGroups;
  
  const MuscleGroupTracker({
    Key? key,
    required this.muscleGroups,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: muscleGroups.length,
          itemBuilder: (context, index) {
            final muscleGroup = muscleGroups[index];
            final name = muscleGroup['name'] as String;
            final progress = muscleGroup['progress'] as double;
            
            return _buildMuscleGroupTile(name, progress);
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              // TODO: Navigate to detailed muscle progress
            },
            icon: const Icon(
              Icons.fitness_center,
              size: 16,
            ),
            label: const Text('View Detailed Progress'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMuscleGroupTile(String name, double progress) {
    // Determine color based on progress
    Color progressColor;
    if (progress < 0.3) {
      progressColor = Colors.red;
    } else if (progress < 0.6) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Icon(
                _getMuscleIcon(name),
                color: Colors.grey[800],
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: progressColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
    IconData _getMuscleIcon(String muscleName) {
    switch (muscleName.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility;
      case 'arms':
        return Icons.fitness_center;
      case 'shoulders':
        return Icons.accessibility;
      case 'legs':
        return Icons.directions_run;
      case 'core':
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }
}