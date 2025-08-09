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
    return SleepEntry(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      bedtime: map['bedtime'] != null ? DateTime.parse(map['bedtime']) : null,
      wakeTime: map['wake_time'] != null ? DateTime.parse(map['wake_time']) : null,
      totalHours: (map['total_hours'] ?? 0.0).toDouble(),
      qualityScore: (map['quality_score'] ?? 0.0).toDouble(),
      deepSleepHours: (map['deep_sleep_hours'] ?? 0.0).toDouble(),
      sleepIssues: map['sleep_issues'] != null 
          ? (map['sleep_issues'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
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