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
    // Handle nested meal object from flutter_compat response
    final mealData = map['meal'] ?? map;
    
    return MealEntry(
      id: mealData['id']?.toString(),
      userId: mealData['user_id']?.toString() ?? mealData['userId']?.toString() ?? '',
      foodItem: mealData['food_item'] ?? mealData['foodItem'] ?? mealData['name'] ?? '',
      quantity: mealData['quantity']?.toString() ?? '1 serving',
      preparation: mealData['preparation'],
      mealType: mealData['meal_type'] ?? mealData['mealType'] ?? '',
      calories: _parseToDouble(mealData['calories']),
      proteinG: _parseToDouble(mealData['protein_g'] ?? mealData['protein']),
      carbsG: _parseToDouble(mealData['carbs_g'] ?? mealData['carbs']),
      fatG: _parseToDouble(mealData['fat_g'] ?? mealData['fat']),
      fiberG: _parseToDouble(mealData['fiber_g'] ?? mealData['fiber']),
      sugarG: _parseToDouble(mealData['sugar_g'] ?? mealData['sugar']),
      sodiumMg: _parseToDouble(mealData['sodium_mg'] ?? mealData['sodium']),
      nutritionData: mealData['nutrition_data'] ?? {
        'healthiness_score': mealData['healthiness_score'],
        'suggestions': mealData['suggestions'],
        'nutrition_notes': mealData['nutrition_notes'],
        'components': mealData['components'],
      },
      dataSource: mealData['data_source'] ?? 'ai',
      mealDate: _parseDateTime(mealData['meal_date'] ?? mealData['logged_at']),
      loggedAt: _parseDateTime(mealData['logged_at']),
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

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (e) {
        print('Error parsing date: $value - $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}