// lib/data/services/insights_service.dart
import 'package:user_onboarding/data/models/user_profile.dart';

class InsightsService {
  
  Future<List<String>> generateDailyInsights(
    UserProfile userProfile,
    Map<String, dynamic> todayMetrics,
  ) async {
    List<String> insights = [];
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Time-based insights
    if (currentHour >= 5 && currentHour < 9) {
      insights.add('🌅 Good morning! Start your day with water and light stretches');
    } else if (currentHour >= 9 && currentHour < 12) {
      insights.add('💧 Stay hydrated - aim for a glass of water every hour');
    } else if (currentHour >= 12 && currentHour < 14) {
      insights.add('🍽️ Lunch time! Remember to log your meal');
    } else if (currentHour >= 14 && currentHour < 17) {
      insights.add('☀️ Perfect time for your workout session');
    } else if (currentHour >= 17 && currentHour < 20) {
      insights.add('🌙 Evening wind down - consider light activity');
    } else if (currentHour >= 20 && currentHour < 22) {
      insights.add('😴 Prepare for sleep - avoid screens');
    } else {
      insights.add('🌜 Rest well for tomorrow\'s activities');
    }
    
    // Progress-based insights
    int currentSteps = todayMetrics['steps'] ?? 0;
    int stepsGoal = todayMetrics['stepsGoal'] ?? 10000;
    int currentWater = todayMetrics['water'] ?? 0;
    int waterGoal = todayMetrics['waterGoal'] ?? 8;
    
    // Steps insight
    if (currentSteps < stepsGoal / 2 && currentHour > 14) {
      insights.add("📊 You're at $currentSteps steps - try a quick walk!");
    } else if (currentSteps >= stepsGoal) {
      insights.add("🎉 Amazing! You've hit your step goal!");
    }
    
    // Water insight
    if (currentWater < waterGoal / 2 && currentHour > 14) {
      insights.add("💧 You're behind on hydration - catch up!");
    } else if (currentWater >= waterGoal) {
      insights.add("💧 Great hydration today!");
    }
    
    // Calories insight
    int caloriesConsumed = todayMetrics['caloriesConsumed'] ?? 0;
    int caloriesGoal = todayMetrics['caloriesGoal'] ?? 2000;
    
    if (caloriesConsumed > caloriesGoal * 1.2) {
      insights.add("🔥 High calorie intake today - consider lighter meals");
    }
    
    return insights.take(3).toList(); // Return top 3 insights
  }
}