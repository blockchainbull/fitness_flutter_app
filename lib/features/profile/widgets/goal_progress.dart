import 'package:flutter/material.dart';

class GoalProgress extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  
  const GoalProgress({
    Key? key,
    required this.goals,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Progress Towards Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...goals.map((goal) => _buildGoalItem(context, goal)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildGoalItem(BuildContext context, Map<String, dynamic> goal) {
    final current = goal['current'] as num;
    final target = goal['target'] as num;
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${current.toString()} / ${target.toString()} ${goal['unit']}',
                style: TextStyle(
                  color: Colors.grey[600],
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
              // Actual progress
              Container(
                height: 10,
                width: MediaQuery.of(context).size.width * 0.88 * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getProgressColors(progress),
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  List<Color> _getProgressColors(double progress) {
    if (progress < 0.3) {
      return [Colors.red.shade300, Colors.red.shade500];
    } else if (progress < 0.7) {
      return [Colors.orange.shade300, Colors.orange.shade500];
    } else {
      return [Colors.green.shade300, Colors.green.shade500];
    }
  }
}