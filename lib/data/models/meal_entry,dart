// lib/data/models/meal_entry.dart
import 'package:uuid/uuid.dart';

class MealEntry {
  final String? id;
  final String userId;
  final String foodItem;
  final String quantity;
  final String? preparation;
  final String mealType;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final Map<String, dynamic>? nutritionData;
  final String? dataSource;
  final DateTime mealDate;
  final DateTime? loggedAt;

  MealEntry({
    this.id,
    required this.userId,
    required this.foodItem,
    required this.quantity,
    this.preparation,
    required this.mealType,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.nutritionData,
    this.dataSource,
    required this.mealDate,
    this.loggedAt,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'],
      userId: json['user_id'],
      foodItem: json['food_item'],
      quantity: json['quantity'],
      preparation: json['preparation'],
      mealType: json['meal_type'],
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      fiberG: json['fiber_g']?.toDouble(),
      sugarG: json['sugar_g']?.toDouble(),
      sodiumMg: json['sodium_mg']?.toDouble(),
      nutritionData: json['nutrition_data'],
      dataSource: json['data_source'],
      mealDate: DateTime.parse(json['meal_date']),
      loggedAt: json['logged_at'] != null 
          ? DateTime.parse(json['logged_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'food_item': foodItem,
      'quantity': quantity,
      'preparation': preparation,
      'meal_type': mealType,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'nutrition_data': nutritionData,
      'data_source': dataSource,
      'meal_date': mealDate.toIso8601String(),
      'logged_at': loggedAt?.toIso8601String(),
    };
  }

  MealEntry copyWith({
    String? id,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    return MealEntry(
      id: id ?? this.id,
      userId: userId,
      foodItem: foodItem,
      quantity: quantity,
      preparation: preparation,
      mealType: mealType,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG,
      sugarG: sugarG,
      sodiumMg: sodiumMg,
      nutritionData: nutritionData,
      dataSource: dataSource,
      mealDate: mealDate,
      loggedAt: loggedAt,
    );
  }
}