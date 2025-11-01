import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleService {
  List<Map<String, dynamic>> generateDailySchedule(UserProfile userProfile) {
    List<Map<String, dynamic>> events = [];
    final now = DateTime.now();
    
    // Parse wake up time
    if (userProfile.wakeupTime != null) {
      final wakeupParts = userProfile.wakeupTime!.split(' ');
      final timeParts = wakeupParts[0].split(':');
      int hour = int.parse(timeParts[0]);
      if (wakeupParts[1] == 'PM' && hour != 12) hour += 12;
      if (wakeupParts[1] == 'AM' && hour == 12) hour = 0;
      
      final wakeupTime = DateTime(now.year, now.month, now.day, hour, 0);
      
      // Morning water reminder (30 min after waking)
      if (now.isBefore(wakeupTime.add(const Duration(minutes: 30)))) {
        events.add({
          'time': wakeupTime.add(const Duration(minutes: 30)),
          'title': 'Morning Hydration',
          'subtitle': 'Start your day with a glass of water',
          'icon': Icons.water_drop,
          'type': 'water',
        });
      }
    }
    
    // Meal times based on daily meals count
    int mealCount = userProfile.dailyMealsCount ?? 3;
    List<Map<String, dynamic>> mealTimes = [];
    
    if (mealCount >= 3) {
      mealTimes = [
        {'time': DateTime(now.year, now.month, now.day, 8, 0), 'meal': 'Breakfast'},
        {'time': DateTime(now.year, now.month, now.day, 13, 0), 'meal': 'Lunch'},
        {'time': DateTime(now.year, now.month, now.day, 19, 0), 'meal': 'Dinner'},
      ];
    } else if (mealCount == 2) {
      mealTimes = [
        {'time': DateTime(now.year, now.month, now.day, 11, 0), 'meal': 'Brunch'},
        {'time': DateTime(now.year, now.month, now.day, 18, 0), 'meal': 'Dinner'},
      ];
    }
    
    for (var meal in mealTimes) {
      if (now.isBefore(meal['time'])) {
        events.add({
          'time': meal['time'],
          'title': meal['meal'],
          'subtitle': 'Time for your scheduled meal',
          'icon': Icons.restaurant,
          'type': 'meal',
        });
      }
    }
    
    // Water reminders (every 2 hours from 9 AM to 7 PM)
    for (int hour = 9; hour <= 19; hour += 2) {
      final waterTime = DateTime(now.year, now.month, now.day, hour, 0);
      if (now.isBefore(waterTime) && hour != 13) { // Skip lunch time
        events.add({
          'time': waterTime,
          'title': 'Water Reminder',
          'subtitle': 'Stay hydrated! 💧',
          'icon': Icons.water_drop_outlined,
          'type': 'water',
        });
      }
    }
    
    // Workout time (based on preference or default to 6 PM)
    int workoutHour = 18; // Default
    if (userProfile.preferredWorkouts != null && userProfile.preferredWorkouts!.isNotEmpty) {
      // Morning person vs evening person heuristic
      if (userProfile.wakeupTime != null && userProfile.wakeupTime!.contains('AM')) {
        final wakeupParts = userProfile.wakeupTime!.split(':');
        int wakeHour = int.parse(wakeupParts[0]);
        if (wakeHour <= 6) {
          workoutHour = 7; // Morning workout
        }
      }
    }
    
    final workoutTime = DateTime(now.year, now.month, now.day, workoutHour, 0);
    if (now.isBefore(workoutTime)) {
      events.add({
        'time': workoutTime,
        'title': 'Workout Time',
        'subtitle': '${userProfile.workoutDuration ?? 30} min session',
        'icon': Icons.fitness_center,
        'type': 'workout',
      });
    }
    
    // Bedtime reminder (30 min before)
    if (userProfile.bedtime != null) {
      final bedtimeParts = userProfile.bedtime!.split(' ');
      final timeParts = bedtimeParts[0].split(':');
      int hour = int.parse(timeParts[0]);
      if (bedtimeParts[1] == 'PM' && hour != 12) hour += 12;
      
      final bedtime = DateTime(now.year, now.month, now.day, hour, 0);
      final reminderTime = bedtime.subtract(const Duration(minutes: 30));
      
      if (now.isBefore(reminderTime)) {
        events.add({
          'time': reminderTime,
          'title': 'Wind Down Time',
          'subtitle': 'Prepare for sleep in 30 minutes',
          'icon': Icons.bedtime,
          'type': 'sleep',
        });
      }
    }
    
    // Sort by time
    events.sort((a, b) => a['time'].compareTo(b['time']));
    
    // Return only next 5 events
    return events.take(5).toList();
  }
}