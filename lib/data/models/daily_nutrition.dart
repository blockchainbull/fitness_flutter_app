class DailyNutrition {
  final String? id;
  final String userId;
  final String date;
  final int caloriesConsumed;
  final int calorieGoal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final int sodiumMg;
  final int mealsLogged;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyNutrition({
    this.id,
    required this.userId,
    required this.date,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    required this.mealsLogged,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyNutrition.fromMap(Map<String, dynamic> map) {
    return DailyNutrition(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      caloriesConsumed: _parseToInt(map['calories_consumed']),
      calorieGoal: _parseToInt(map['calorie_goal'] ?? 2000),
      proteinG: _parseToDouble(map['protein_g']),
      carbsG: _parseToDouble(map['carbs_g']),
      fatG: _parseToDouble(map['fat_g']),
      fiberG: _parseToDouble(map['fiber_g']),
      sugarG: _parseToDouble(map['sugar_g']),
      sodiumMg: _parseToInt(map['sodium_mg']),
      mealsLogged: _parseToInt(map['meals_logged']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']).toLocal()
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date,
      'calories_consumed': caloriesConsumed,
      'calorie_goal': calorieGoal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'meals_logged': mealsLogged,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods for safe type conversion
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.round() ?? 0;
    }
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}