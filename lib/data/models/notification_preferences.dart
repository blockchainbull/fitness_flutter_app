// lib/data/models/notification_preferences.dart
class NotificationPreferences {
  bool enabled;
  bool mealReminders;
  bool exerciseReminders;
  bool waterReminders;
  bool sleepReminders;
  bool supplementReminders;
  bool weightReminders;
  
  // Custom times
  int breakfastHour;
  int breakfastMinute;
  int lunchHour;
  int lunchMinute;
  int dinnerHour;
  int dinnerMinute;
  int exerciseHour;
  int exerciseMinute;
  int waterReminderFrequency;
  
  NotificationPreferences({
    this.enabled = true,
    this.mealReminders = true,
    this.exerciseReminders = true,
    this.waterReminders = true,
    this.sleepReminders = true,
    this.supplementReminders = true,
    this.weightReminders = true,
    this.breakfastHour = 8,
    this.breakfastMinute = 0,
    this.lunchHour = 13,
    this.lunchMinute = 0,
    this.dinnerHour = 19,
    this.dinnerMinute = 0,
    this.exerciseHour = 18,
    this.exerciseMinute = 0,
    this.waterReminderFrequency = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'meal_reminders': mealReminders,
      'exercise_reminders': exerciseReminders,
      'water_reminders': waterReminders,
      'sleep_reminders': sleepReminders,
      'supplement_reminders': supplementReminders,
      'weight_reminders': weightReminders,
      'breakfast_hour': breakfastHour,
      'breakfast_minute': breakfastMinute,
      'lunch_hour': lunchHour,
      'lunch_minute': lunchMinute,
      'dinner_hour': dinnerHour,
      'dinner_minute': dinnerMinute,
      'exercise_hour': exerciseHour,
      'exercise_minute': exerciseMinute,
      'water_reminder_frequency': waterReminderFrequency,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] ?? true,
      mealReminders: json['meal_reminders'] ?? true,
      exerciseReminders: json['exercise_reminders'] ?? true,
      waterReminders: json['water_reminders'] ?? true,
      sleepReminders: json['sleep_reminders'] ?? true,
      supplementReminders: json['supplement_reminders'] ?? true,
      weightReminders: json['weight_reminders'] ?? true,
      breakfastHour: json['breakfast_hour'] ?? 8,
      breakfastMinute: json['breakfast_minute'] ?? 0,
      lunchHour: json['lunch_hour'] ?? 13,
      lunchMinute: json['lunch_minute'] ?? 0,
      dinnerHour: json['dinner_hour'] ?? 19,
      dinnerMinute: json['dinner_minute'] ?? 0,
      exerciseHour: json['exercise_hour'] ?? 18,
      exerciseMinute: json['exercise_minute'] ?? 0,
      waterReminderFrequency: json['water_reminder_frequency'] ?? 2,
    );
  }
}