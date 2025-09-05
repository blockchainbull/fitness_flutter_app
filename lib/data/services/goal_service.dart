import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:user_onboarding/data/models/user_profile.dart';

class GoalService {
  final _supabase = Supabase.instance.client;
  
  Future<Map<String, dynamic>> getGoalProgress(UserProfile userProfile) async {
    Map<String, dynamic> progress = {
      'type': userProfile.primaryGoal,
      'current': 0.0,
      'target': 0.0,
      'percentage': 0.0,
      'trend': 'stable',
      'message': '',
      'milestones': [],
      'streaks': {},
    };
    
    try {
      final userId = userProfile.id;
      
      // Get weight progress if weight goal
      if (userProfile.weightGoal != null && 
          (userProfile.weightGoal!.contains('weight'))) {
        
        final weightEntries = await _supabase
            .from('weight_entries')
            .select()
            .eq('user_id', userId)
            .order('date', ascending: false)
            .limit(30);
        
        if (weightEntries.isNotEmpty) {
          double currentWeight = weightEntries[0]['weight'].toDouble();
          double startWeight = userProfile.weight ?? currentWeight;
          double targetWeight = userProfile.targetWeight ?? currentWeight;
          
          progress['current'] = currentWeight;
          progress['target'] = targetWeight;
          progress['start'] = startWeight;
          
          // Calculate percentage
          if (startWeight != targetWeight) {
            double totalChange = (targetWeight - startWeight).abs();
            double currentChange = (currentWeight - startWeight).abs();
            progress['percentage'] = (currentChange / totalChange * 100).clamp(0, 100);
          }
          
          // Determine trend (compare last 7 days)
          if (weightEntries.length >= 2) {
            double lastWeek = weightEntries[min(6, weightEntries.length - 1)]['weight'].toDouble();
            if (currentWeight < lastWeek) {
              progress['trend'] = userProfile.weightGoal == 'lose_weight' ? 'good' : 'bad';
            } else if (currentWeight > lastWeek) {
              progress['trend'] = userProfile.weightGoal == 'gain_weight' ? 'good' : 'bad';
            }
          }
          
          // Calculate ETA
          if (weightEntries.length >= 7) {
            double weeklyChange = _calculateWeeklyChange(weightEntries);
            if (weeklyChange != 0) {
              double remaining = (targetWeight - currentWeight).abs();
              int weeksToGoal = (remaining / weeklyChange.abs()).round();
              progress['eta'] = DateTime.now().add(Duration(days: weeksToGoal * 7));
              progress['message'] = 'At current rate: ${weeksToGoal} weeks to goal';
            }
          }
        }
      }
      
      // Get streaks
      progress['streaks'] = await _getStreaks(userId);
      
      // Get achievements
      progress['achievements'] = await _getAchievements(userId);
      
    } catch (e) {
      print('Error getting goal progress: $e');
    }
    
    return progress;
  }
  
  double _calculateWeeklyChange(List<dynamic> entries) {
    if (entries.length < 7) return 0;
    
    double current = entries[0]['weight'].toDouble();
    double weekAgo = entries[6]['weight'].toDouble();
    
    return current - weekAgo;
  }
  
  Future<Map<String, dynamic>> _getStreaks(String userId) async {
    Map<String, int> streaks = {
      'steps': 0,
      'water': 0,
      'workout': 0,
      'logging': 0,
    };
    
    try {
      // Check consecutive days of meeting goals
      final today = DateTime.now();
      
      // Steps streak
      int stepStreak = 0;
      for (int i = 0; i < 30; i++) {
        final date = DateFormat('yyyy-MM-dd').format(
          today.subtract(Duration(days: i))
        );
        
        final steps = await _supabase
            .from('daily_steps')
            .select('steps')
            .eq('user_id', userId)
            .eq('date', date)
            .maybeSingle();
        
        if (steps != null && steps['steps'] >= 10000) {
          stepStreak++;
        } else if (i > 0) {
          break;
        }
      }
      streaks['steps'] = stepStreak;
      
      // Water streak
      int waterStreak = 0;
      for (int i = 0; i < 30; i++) {
        final date = DateFormat('yyyy-MM-dd').format(
          today.subtract(Duration(days: i))
        );
        
        final water = await _supabase
            .from('daily_water')
            .select('glasses')
            .eq('user_id', userId)
            .eq('date', date)
            .maybeSingle();
        
        if (water != null && water['glasses'] >= 8) {
          waterStreak++;
        } else if (i > 0) {
          break;
        }
      }
      streaks['water'] = waterStreak;
      
    } catch (e) {
      print('Error calculating streaks: $e');
    }
    
    return streaks;
  }
  
  Future<List<Map<String, dynamic>>> _getAchievements(String userId) async {
    List<Map<String, dynamic>> achievements = [];
    
    try {
      // Check for milestone achievements
      final allSteps = await _supabase
          .from('daily_steps')
          .select('steps')
          .eq('user_id', userId);
      
      int totalSteps = 0;
      for (var day in allSteps) {
        totalSteps += (day['steps'] as int?) ?? 0;
      }
      
      // Step milestones
      if (totalSteps >= 10000) {
        achievements.add({
          'title': 'First 10K',
          'icon': '🚶',
          'earned': true,
        });
      }
      if (totalSteps >= 100000) {
        achievements.add({
          'title': '100K Club',
          'icon': '🏃',
          'earned': true,
        });
      }
      if (totalSteps >= 1000000) {
        achievements.add({
          'title': 'Million Stepper',
          'icon': '🏆',
          'earned': true,
        });
      }
      
    } catch (e) {
      print('Error getting achievements: $e');
    }
    
    return achievements;
  }
}