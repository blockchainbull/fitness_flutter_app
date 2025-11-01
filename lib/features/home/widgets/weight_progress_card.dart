// lib/features/home/widgets/weight_progress_card.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class WeightProgressCard extends StatelessWidget {
  final UserProfile userProfile;
  
  const WeightProgressCard({
    Key? key,
    required this.userProfile,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final current = userProfile.weight ?? 0;
    final target = userProfile.targetWeight ?? current;
    final start = current; // Simplified - in reality you'd get from first weight entry
    
    double percentage = 0;
    if (target != start) {
      final totalChange = (target - start).abs();
      final currentChange = (current - start).abs();
      percentage = (currentChange / totalChange * 100).clamp(0, 100);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Goal: ${userProfile.weightGoal?.replaceAll('_', ' ').toUpperCase() ?? "Maintain"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Current', current, Colors.blue),
              Icon(Icons.arrow_forward, color: Colors.grey[400]),
              _buildMetric('Target', target, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Colors.blue),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetric(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}