// lib/data/models/sleep_entry.dart
class SleepEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final DateTime? bedtime;
  final DateTime? wakeTime;
  final double totalHours;
  final double qualityScore;
  final double deepSleepHours;
  final List<String> sleepIssues;
  final String? notes;
  final DateTime createdAt;

  @override
  String toString() {
    return 'SleepEntry(id: $id, userId: $userId, date: $date, totalHours: $totalHours)';
  }

  SleepEntry({
    this.id,
    required this.userId,
    required this.date,
    this.bedtime,
    this.wakeTime,
    required this.totalHours,
    required this.qualityScore,
    required this.deepSleepHours,
    this.sleepIssues = const [],
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'bedtime': bedtime?.toIso8601String(),
      'wake_time': wakeTime?.toIso8601String(),
      'total_hours': totalHours,
      'quality_score': qualityScore,
      'deep_sleep_hours': deepSleepHours,
      'sleep_issues': sleepIssues.join(','),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    // Get userId and ensure it's not null
    final String? userIdValue = map['user_id']?.toString() ?? map['userId']?.toString();
    if (userIdValue == null || userIdValue.isEmpty) {
      throw ArgumentError('userId is required but was not found in map: $map');
    }

    return SleepEntry(
      id: map['id']?.toString(),
      userId: userIdValue,
      date: map['date'] != null 
        ? (map['date'] is String 
            ? DateTime.parse(map['date']) 
            : map['date'] as DateTime)
        : DateTime.now(),
      bedtime: map['bedtime'] != null 
        ? (map['bedtime'] is String 
            ? DateTime.parse(map['bedtime']) 
            : map['bedtime'] as DateTime)
        : null,
      wakeTime: map['wake_time'] != null 
        ? (map['wake_time'] is String 
            ? DateTime.parse(map['wake_time']) 
            : map['wake_time'] as DateTime)
        : null,
      totalHours: (map['total_hours'] ?? 0).toDouble(),
      qualityScore: (map['quality_score'] ?? 0).toDouble(),
      deepSleepHours: (map['deep_sleep_hours'] ?? 0).toDouble(),
      sleepIssues: map['sleep_issues'] != null
        ? List<String>.from(map['sleep_issues'])
        : [],
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null 
        ? (map['created_at'] is String 
            ? DateTime.parse(map['created_at']) 
            : map['created_at'] as DateTime)
        : DateTime.now(),
    );
  }

  SleepEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    double? totalHours,
    double? qualityScore,
    double? deepSleepHours,
    List<String>? sleepIssues,
    String? notes,
    DateTime? createdAt,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      totalHours: totalHours ?? this.totalHours,
      qualityScore: qualityScore ?? this.qualityScore,
      deepSleepHours: deepSleepHours ?? this.deepSleepHours,
      sleepIssues: sleepIssues ?? this.sleepIssues,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}