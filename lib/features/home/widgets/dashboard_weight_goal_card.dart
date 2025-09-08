// lib/features/home/widgets/dashboard_weight_goal_card.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/tracking/screens/weight_logging_page.dart';

class DashboardWeightGoalCard extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;
  
  const DashboardWeightGoalCard({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final weightGoal = userProfile.weightGoal;
    if (weightGoal == null || weightGoal.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentWeight = userProfile.weight ?? 70.0;
    final targetWeight = userProfile.targetWeight ?? currentWeight;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and goal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getWeightGoalColor(weightGoal).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getWeightGoalColor(weightGoal).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getWeightGoalIcon(weightGoal),
                  color: _getWeightGoalColor(weightGoal),
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatWeightGoal(weightGoal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getWeightGoalDescription(weightGoal),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weight stats and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Weight stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeightStat('Current', currentWeight, Colors.blue),
                    if (weightGoal != 'maintain_weight') 
                      _buildWeightStat('Target', targetWeight, Colors.green),
                  ],
                ),
              ),
              // Log Weight button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeightLoggingPage(
                        userProfile: userProfile,
                      ),
                    ),
                  ).then((_) {
                    // Call the refresh callback if provided
                    onUpdate?.call();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getWeightGoalColor(weightGoal),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          
          // Progress bar for non-maintenance goals
          if (weightGoal != 'maintain_weight') ...[
            const SizedBox(height: 16),
            _buildProgressBar(currentWeight, targetWeight, weightGoal),
          ],
          
          // Timeline if exists
          if (userProfile.goalTimeline != null && weightGoal != 'maintain_weight') ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Timeline: ${_formatTimeline(userProfile.goalTimeline!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWeightStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar(double current, double target, String goal) {
    double progress = 0;
    String progressText = '';
    
    if (goal == 'lose_weight') {
      // For weight loss, progress increases as weight decreases
      if (current > target) {
        progress = 0;
        progressText = '${(current - target).toStringAsFixed(1)} kg to go';
      } else {
        progress = 1.0;
        progressText = 'Goal achieved! 🎉';
      }
    } else if (goal == 'gain_weight') {
      // For weight gain, progress increases as weight increases
      if (current < target) {
        progress = 0;
        progressText = '${(target - current).toStringAsFixed(1)} kg to go';
      } else {
        progress = 1.0;
        progressText = 'Goal achieved! 🎉';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(_getWeightGoalColor(goal)),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          progressText,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  IconData _getWeightGoalIcon(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return Icons.trending_down;
      case 'gain_weight':
        return Icons.trending_up;
      case 'maintain_weight':
        return Icons.horizontal_rule;
      default:
        return Icons.fitness_center;
    }
  }
  
  Color _getWeightGoalColor(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return Colors.orange;
      case 'gain_weight':
        return Colors.green;
      case 'maintain_weight':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  String _formatWeightGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return 'Weight Loss Goal';
      case 'gain_weight':
        return 'Weight Gain Goal';
      case 'maintain_weight':
        return 'Maintain Weight';
      default:
        return 'Weight Goal';
    }
  }
  
  String _getWeightGoalDescription(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
        return 'Working towards a healthier weight';
      case 'gain_weight':
        return 'Building mass and strength';
      case 'maintain_weight':
        return 'Keeping steady at current weight';
      default:
        return 'Tracking weight progress';
    }
  }
  
  String _formatTimeline(String timeline) {
    switch (timeline.toLowerCase().replaceAll('_', '')) {
      case '1month':
        return '1 Month';
      case '3months':
        return '3 Months';
      case '6months':
        return '6 Months';
      case '1year':
        return '1 Year';
      case '12weeks':
        return '12 Weeks';
      case '24weeks':
        return '24 Weeks';
      default:
        // For any other format, replace underscores with spaces and capitalize
        return timeline.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }
}