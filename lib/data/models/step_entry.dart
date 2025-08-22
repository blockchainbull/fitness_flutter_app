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
      'user_id': userId,  // Backend expects snake_case
      'date': date.toIso8601String().split('T')[0],  // Just the date part
      'steps': steps,
      'goal': goal,
      'calories_burned': caloriesBurned,  // Backend expects snake_case
      'distance_km': distanceKm,  // Backend expects snake_case
      'active_minutes': activeMinutes,  // Backend expects snake_case
      'source_type': sourceType,  // Backend expects snake_case
      'last_synced': lastSynced?.toIso8601String(),
    };
  }

  factory StepEntry.fromJson(Map<String, dynamic> json) {
    try {
      return StepEntry(
        id: json['id']?.toString(),
        userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        steps: (json['steps'] ?? 0) is int ? json['steps'] : int.tryParse(json['steps'].toString()) ?? 0,
        goal: (json['goal'] ?? 10000) is int ? json['goal'] : int.tryParse(json['goal'].toString()) ?? 10000,
        caloriesBurned: (json['caloriesBurned'] ?? json['calories_burned'] ?? 0.0).toDouble(),
        distanceKm: (json['distanceKm'] ?? json['distance_km'] ?? 0.0).toDouble(),
        activeMinutes: (json['activeMinutes'] ?? json['active_minutes'] ?? 0) is int 
            ? json['activeMinutes'] ?? json['active_minutes'] 
            : int.tryParse((json['activeMinutes'] ?? json['active_minutes'] ?? 0).toString()) ?? 0,
        sourceType: json['sourceType']?.toString() ?? json['source_type']?.toString() ?? 'manual',
        lastSynced: json['lastSynced'] != null || json['last_synced'] != null
            ? DateTime.tryParse(json['lastSynced']?.toString() ?? json['last_synced']?.toString() ?? '')
            : null,
        createdAt: json['createdAt'] != null || json['created_at'] != null
            ? DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '')
            : null,
        updatedAt: json['updatedAt'] != null || json['updated_at'] != null
            ? DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '')
            : null,
      );
    } catch (e) {
      print('Error parsing StepEntry from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}