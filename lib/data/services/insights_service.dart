import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class InsightsService {
  final _supabase = Supabase.instance.client;
  
  Future<List<String>> generateDailyInsights(
    UserProfile userProfile,
    Map<String, dynamic> todayMetrics,
  ) async {
    List<String> insights = [];
    final userId = userProfile.id;
    
    try {
      // Get last 7 days data for pattern analysis
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekAgoStr = DateFormat('yyyy-MM-dd').format(weekAgo);
      
      // Fetch historical steps
      final stepsHistory = await _supabase
          .from('daily_steps')
          .select()
          .eq('user_id', userId)
          .gte('date', weekAgoStr)
          .order('date');
      
      // Fetch historical water
      final waterHistory = await _supabase
          .from('daily_water')
          .select()
          .eq('user_id', userId)
          .gte('date', weekAgoStr)
          .order('date');
      
      // Analyze step patterns
      if (stepsHistory.isNotEmpty) {
        int avgSteps = 0;
        for (var day in stepsHistory) {
          avgSteps += (day['step_count'] as int?) ?? 0;
        }
        avgSteps = (avgSteps / stepsHistory.length).round();
        
        int currentSteps = todayMetrics['steps'] ?? 0;
        
        if (currentSteps < avgSteps * 0.5 && DateTime.now().hour > 12) {
          insights.add("📊 You're at ${currentSteps} steps - typically you have $avgSteps by now. Try a quick walk!");
        } else if (currentSteps > avgSteps * 1.2) {
          insights.add("🎉 Amazing! You're ${currentSteps - avgSteps} steps above your daily average!");
        }
      }
      
      // Water intake insights
      if (waterHistory.isNotEmpty && DateTime.now().hour > 10) {
        int avgWater = 0;
        for (var day in waterHistory) {
          avgWater += (day['glasses'] as int?) ?? 0;
        }
        avgWater = (avgWater / waterHistory.length).round();
        
        int currentWater = todayMetrics['water'] ?? 0;
        int waterGoal = userProfile.waterIntakeGlasses ?? 8;
        
        if (currentWater < waterGoal / 2 && DateTime.now().hour > 14) {
          insights.add("💧 You're behind on hydration - aim for a glass every hour to reach your goal!");
        }
        
        // Check for patterns
        final dayOfWeek = DateTime.now().weekday;
        
        dynamic sameDayLastWeek;
        try {
          sameDayLastWeek = waterHistory.firstWhere(
            (d) => DateTime.parse(d['date']).weekday == dayOfWeek,
          );
        } catch (e) {
          sameDayLastWeek = null;
        }

        if (sameDayLastWeek != null) {
          int lastWeekWater = sameDayLastWeek['glasses'] ?? 0;
          if (currentWater < lastWeekWater && DateTime.now().hour > 12) {
            insights.add("📈 Last ${DateFormat('EEEE').format(DateTime.now())}, you had $lastWeekWater glasses by now");
          }
        }
      
      // Exercise insights
      final exerciseHistory = await _supabase
          .from('exercise_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', weekAgoStr);
      
      if (exerciseHistory.isNotEmpty) {
        // Count workout days this week
        Set<String> workoutDays = {};
        for (var exercise in exerciseHistory) {
          workoutDays.add(exercise['date']);
        }
        
        if (workoutDays.length < userProfile.workoutFrequency! && 
            DateTime.now().weekday < 7) {
          int remaining = userProfile.workoutFrequency! - workoutDays.length;
          insights.add("💪 $remaining more workout${remaining > 1 ? 's' : ''} to hit your weekly goal!");
        }
      }
      
      // Period insights for women
      if (userProfile.gender == 'Female' && userProfile.hasPeriods == true) {
        final periodData = await _supabase
            .from('period_entries')
            .select()
            .eq('user_id', userId)
            .order('start_date', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (periodData != null) {
          final lastPeriod = DateTime.parse(periodData['start_date']);
          final cycleLength = userProfile.cycleLength ?? 28;
          final nextPeriod = lastPeriod.add(Duration(days: cycleLength));
          final daysUntil = nextPeriod.difference(DateTime.now()).inDays;
          
          if (daysUntil <= 3 && daysUntil > 0) {
            insights.add("🌸 Period expected in $daysUntil day${daysUntil > 1 ? 's' : ''} - consider lighter workouts");
          } else if (daysUntil == 0) {
            insights.add("🌸 Period may start today - stay hydrated and listen to your body");
          }
        }
      }
      
      // Time-based insights
      final hour = DateTime.now().hour;
      
      if (hour >= 20 && userProfile.bedtime != null) {
        final bedtimeParts = userProfile.bedtime!.split(':');
        final bedtimeHour = int.parse(bedtimeParts[0]);
        if (hour >= bedtimeHour - 1) {
          insights.add("🌙 Time to wind down - your bedtime is ${userProfile.bedtime}");
        }
      }
      
      // Goal-specific insights
      if (userProfile.weightGoal == 'lose_weight') {
        int netCalories = todayMetrics['netCalories'] ?? 0;
        int tdee = userProfile.tdee?.toInt() ?? 2000;
        int targetDeficit = tdee - 500; // 500 cal deficit for weight loss
        
        if (netCalories > targetDeficit && hour > 18) {
          insights.add("⚖️ Consider a light dinner to maintain your calorie deficit");
        }
      }
      
      // Limit to top 3 most relevant insights
      if (insights.length > 3) {
        insights = insights.take(3).toList();
      }
      
      // Add a motivational message if no other insights
      if (insights.isEmpty) {
        insights.add(_getMotivationalMessage(todayMetrics, userProfile));
      }
    }
      
      } catch (e) {
        print('Error generating insights: $e');
        insights.add("💪 Keep going! You're doing great today!");
      }
    
    return insights;
    
  }
  
  String _getMotivationalMessage(Map<String, dynamic> metrics, UserProfile profile) {
    final messages = [
      "🌟 Every step counts towards your ${profile.primaryGoal ?? 'goal'}!",
      "💪 You're building healthy habits one day at a time!",
      "🎯 Stay focused - consistency is key to success!",
      "✨ Small progress is still progress - keep it up!",
      "🏆 You're on track for a great day!",
    ];
    
    // Pick based on time of day
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "☀️ Great morning! Make today count!";
    } else if (hour < 17) {
      return messages[hour % messages.length];
    } else {
      return "🌅 Finish strong! You've got this!";
    }
  }
}