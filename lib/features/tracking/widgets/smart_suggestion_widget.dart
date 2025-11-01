import 'package:flutter/material.dart';

class SmartSuggestionsWidget extends StatelessWidget {
  final String mealType;
  final Function(String) onSuggestionTap;
  
  const SmartSuggestionsWidget({
    Key? key,
    required this.mealType,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestionsForMealType(mealType);
    
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onSuggestionTap(suggestions[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Center(
                child: Text(
                  suggestions[index],
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getSuggestionsForMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return [
          'oatmeal with berries',
          'eggs and toast',
          'yogurt parfait',
          'smoothie bowl',
          'cereal with milk',
        ];
      case 'lunch':
        return [
          'chicken salad',
          'turkey sandwich',
          'pasta with veggies',
          'soup and bread',
          'rice bowl',
        ];
      case 'dinner':
        return [
          'grilled salmon with rice',
          'chicken stir fry',
          'pasta marinara',
          'steak and potatoes',
          'veggie curry',
        ];
      default:
        return [
          'apple with peanut butter',
          'protein shake',
          'mixed nuts',
          'greek yogurt',
          'fruit salad',
        ];
    }
  }
}