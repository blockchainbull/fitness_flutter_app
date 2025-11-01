// lib/data/models/supplement_models.dart
class SupplementPreference {
  final String id;
  final String userId;
  final String supplementName;
  final String dosage;
  final String frequency;
  final String preferredTime;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  SupplementPreference({
    required this.id,
    required this.userId,
    required this.supplementName,
    required this.dosage,
    this.frequency = 'Daily',
    this.preferredTime = '9:00 AM',
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'supplement_name': supplementName,
      'dosage': dosage,
      'frequency': frequency,
      'preferred_time': preferredTime,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupplementPreference.fromMap(Map<String, dynamic> map) {
    return SupplementPreference(
      id: map['id'],
      userId: map['user_id'],
      supplementName: map['supplement_name'],
      dosage: map['dosage'],
      frequency: map['frequency'] ?? 'Daily',
      preferredTime: map['preferred_time'] ?? '9:00 AM',
      notes: map['notes'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null 
      ? DateTime.parse(map['created_at']).toLocal()
      : DateTime.now(),
    );
  }
}

class SupplementLog {
  final String id;
  final String userId;
  final DateTime date;
  final String supplementName;
  final String? dosage;
  final bool taken;
  final DateTime? timeTaken;
  final DateTime createdAt;

  SupplementLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.supplementName,
    this.dosage,
    required this.taken,
    this.timeTaken,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'supplement_name': supplementName,
      'dosage': dosage,
      'taken': taken,
      'time_taken': timeTaken?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      supplementName: map['supplement_name'],
      dosage: map['dosage'],
      taken: map['taken'],
      timeTaken: map['time_taken'] != null ? DateTime.parse(map['time_taken']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}