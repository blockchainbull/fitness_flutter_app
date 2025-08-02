// lib/data/models/daily_metrics.dart
import 'package:equatable/equatable.dart';

class DailyMetrics extends Equatable {
  final String userId;
  final DateTime date;
  final int steps;
  final double caloriesConsumed;
  final double caloriesBurned;
  final int activeMinutes;
  final double waterIntake;
  final double sleepHours;
  final bool workoutCompleted;
  final double weight;

  const DailyMetrics({
    required this.userId,
    required this.date,
    this.steps = 0,
    this.caloriesConsumed = 0.0,
    this.caloriesBurned = 0.0,
    this.activeMinutes = 0,
    this.waterIntake = 0.0,
    this.sleepHours = 0.0,
    this.workoutCompleted = false,
    this.weight = 0.0,
  });

  @override
  List<Object?> get props => [
    userId, date, steps, caloriesConsumed, caloriesBurned,
    activeMinutes, waterIntake, sleepHours, workoutCompleted, weight
  ];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'caloriesConsumed': caloriesConsumed,
      'caloriesBurned': caloriesBurned,
      'activeMinutes': activeMinutes,
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'workoutCompleted': workoutCompleted,
      'weight': weight,
    };
  }

  factory DailyMetrics.fromMap(Map<String, dynamic> map) {
    return DailyMetrics(
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      steps: map['steps']?.toInt() ?? 0,
      caloriesConsumed: map['caloriesConsumed']?.toDouble() ?? 0.0,
      caloriesBurned: map['caloriesBurned']?.toDouble() ?? 0.0,
      activeMinutes: map['activeMinutes']?.toInt() ?? 0,
      waterIntake: map['waterIntake']?.toDouble() ?? 0.0,
      sleepHours: map['sleepHours']?.toDouble() ?? 0.0,
      workoutCompleted: map['workoutCompleted'] ?? false,
      weight: map['weight']?.toDouble() ?? 0.0,
    );
  }
}

class WorkoutSession extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String workoutType;
  final int durationMinutes;
  final double caloriesBurned;
  final String intensity;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.date,
    required this.workoutType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
  });

  @override
  List<Object?> get props => [id, userId, date, workoutType, durationMinutes, caloriesBurned, intensity];
}