// lib/data/models/water_entry.dart
class WaterEntry {
  final String? id;
  final String userId;
  final DateTime date;
  final int glassesConsumed;
  final double totalMl;
  final double targetMl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WaterEntry({
    this.id,
    required this.userId,
    required this.date,
    this.glassesConsumed = 0,
    this.totalMl = 0.0,
    this.targetMl = 2000.0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'glasses_consumed': glassesConsumed,
      'total_ml': totalMl,
      'target_ml': targetMl,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      date: DateTime.parse(map['date']).toLocal(),
      glassesConsumed: map['glasses_consumed']?.toInt() ?? 0,
      totalMl: map['total_ml']?.toDouble() ?? 0.0,
      targetMl: map['target_ml']?.toDouble() ?? 2000.0,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null 
      ? DateTime.parse(map['created_at']).toLocal()
      : DateTime.now(),
      updatedAt: map['updated_at'] != null 
      ? DateTime.parse(map['updated_at']).toLocal()
      : DateTime.now(),
    );
  }

  WaterEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? glassesConsumed,
    double? totalMl,
    double? targetMl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      glassesConsumed: glassesConsumed ?? this.glassesConsumed,
      totalMl: totalMl ?? this.totalMl,
      targetMl: targetMl ?? this.targetMl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}