// lib/data/models/weight_entry.dart
class WeightEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final double weight;
  final String? notes;
  final DateTime createdAt;

  WeightEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      weight: map['weight']?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  WeightEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}