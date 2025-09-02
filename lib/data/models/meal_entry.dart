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

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'],
      userId: map['user_id'] ?? map['userId'],  
      foodItem: map['food_item'] ?? map['foodItem'],
      quantity: map['quantity'],
      preparation: map['preparation'],
      mealType: map['meal_type'] ?? map['mealType'],
      calories: (map['calories'] ?? 0).toDouble(),
      proteinG: (map['protein_g'] ?? map['proteinG'] ?? 0).toDouble(),
      carbsG: (map['carbs_g'] ?? map['carbsG'] ?? 0).toDouble(),
      fatG: (map['fat_g'] ?? map['fatG'] ?? 0).toDouble(),
      fiberG: (map['fiber_g'] ?? map['fiberG'])?.toDouble(),
      sugarG: (map['sugar_g'] ?? map['sugarG'])?.toDouble(),
      sodiumMg: (map['sodium_mg'] ?? map['sodiumMg'])?.toDouble(),
      nutritionData: map['nutrition_data'] ?? map['nutritionData'],
      dataSource: map['data_source'] ?? map['dataSource'],
      mealDate: DateTime.parse(map['meal_date'] ?? map['mealDate']).toLocal(),  
      loggedAt: map['logged_at'] != null || map['loggedAt'] != null
          ? DateTime.parse(map['logged_at'] ?? map['loggedAt']).toLocal()  
          : null,
    );
}

  Map<String, dynamic> toMap() {
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