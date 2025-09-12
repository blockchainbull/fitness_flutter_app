class NutritionData {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final int sodiumMg;
  final String? nutritionNotes;
  final int? healthinessScore;
  final String? suggestions;
  final List<Map<String, dynamic>>? components;

  NutritionData({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    this.nutritionNotes,
    this.healthinessScore,
    this.suggestions,
    this.components,
  });

  factory NutritionData.fromMap(Map<String, dynamic> map) {
    return NutritionData(
      calories: _parseToInt(map['calories']),
      proteinG: _parseToDouble(map['protein_g']),
      carbsG: _parseToDouble(map['carbs_g']),
      fatG: _parseToDouble(map['fat_g']),
      fiberG: _parseToDouble(map['fiber_g']),
      sugarG: _parseToDouble(map['sugar_g']),
      sodiumMg: _parseToInt(map['sodium_mg']),
      nutritionNotes: map['nutrition_notes']?.toString(),
      healthinessScore: map['healthiness_score'] != null 
          ? _parseToInt(map['healthiness_score']) 
          : null,
      suggestions: map['suggestions']?.toString(),
      components: map['components'] != null 
          ? List<Map<String, dynamic>>.from(map['components'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'nutrition_notes': nutritionNotes,
      'healthiness_score': healthinessScore,
      'suggestions': suggestions,
      'components': components,
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