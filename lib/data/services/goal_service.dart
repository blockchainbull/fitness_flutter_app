// lib/data/services/goal_service.dart
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/weight_repository.dart';

class GoalService {
  
  Future<Map<String, dynamic>> getGoalProgress(UserProfile userProfile) async {
    Map<String, dynamic> progress = {
      'type': userProfile.primaryGoal,
      'current': userProfile.weight ?? 0,
      'target': userProfile.targetWeight ?? 0,
      'percentage': 0.0,
      'trend': 'stable',
      'message': '',
    };
    
    try {
      // Get weight progress if it's a weight goal
      if (userProfile.weightGoal != null && userProfile.targetWeight != null) {
        double currentWeight = userProfile.weight ?? 0;
        double targetWeight = userProfile.targetWeight ?? 0;
        double startWeight = currentWeight; // Simplified - use current as start
        
        progress['current'] = currentWeight;
        progress['target'] = targetWeight;
        
        // Calculate percentage (simplified)
        if (targetWeight != currentWeight) {
          double totalChange = (targetWeight - currentWeight).abs();
          double progressMade = 0; // Start at 0 for now
          progress['percentage'] = 0.0; // Simplified version
        }
        
        // Add simple message
        if (userProfile.weightGoal == 'lose_weight') {
          progress['message'] = 'Keep pushing towards your weight loss goal!';
        } else if (userProfile.weightGoal == 'gain_weight') {
          progress['message'] = 'Stay consistent with your nutrition plan!';
        } else {
          progress['message'] = 'Maintain your healthy habits!';
        }
      }
      
      // Simple streaks (without database)
      progress['streaks'] = {
        'steps': 0,
        'water': 0,
        'workout': 0,
        'logging': 0,
      };
      
    } catch (e) {
      print('Error getting goal progress: $e');
    }
    
    return progress;
  }
}