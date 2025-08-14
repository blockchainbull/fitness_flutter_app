// lib/data/models/step_entry.dart
class StepEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final int steps;
  final int goal;
  final double caloriesBurned;
  final double distanceKm;
  final int activeMinutes;
  final String sourceType; // 'manual', 'health_app', 'pedometer'
  final DateTime? lastSynced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StepEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.steps,
    required this.goal,
    this.caloriesBurned = 0.0,
    this.distanceKm = 0.0,
    this.activeMinutes = 0,
    this.sourceType = 'manual',
    this.lastSynced,
    this.createdAt,
    this.updatedAt,
  });

  StepEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    int? goal,
    double? caloriesBurned,
    double? distanceKm,
    int? activeMinutes,
    String? sourceType,
    DateTime? lastSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StepEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceKm: distanceKm ?? this.distanceKm,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      sourceType: sourceType ?? this.sourceType,
      lastSynced: lastSynced ?? this.lastSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'goal': goal,
      'caloriesBurned': caloriesBurned,
      'distanceKm': distanceKm,
      'activeMinutes': activeMinutes,
      'sourceType': sourceType,
      'lastSynced': lastSynced?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory StepEntry.fromJson(Map<String, dynamic> json) {
    return StepEntry(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      steps: json['steps'] ?? 0,
      goal: json['goal'] ?? 10000,
      caloriesBurned: (json['caloriesBurned'] ?? 0.0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      activeMinutes: json['activeMinutes'] ?? 0,
      sourceType: json['sourceType'] ?? 'manual',
      lastSynced: json['lastSynced'] != null 
          ? DateTime.parse(json['lastSynced']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}