// lib/features/tracking/screens/enhanced_meal_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/features/tracking/screens/meal_history_page.dart';
import 'package:user_onboarding/features/tracking/widgets/voice_input_widget.dart';


class EnhancedMealLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const EnhancedMealLoggingPage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<EnhancedMealLoggingPage> createState() => _EnhancedMealLoggingPageState();
}

class _EnhancedMealLoggingPageState extends State<EnhancedMealLoggingPage> {
  final ApiService _apiService = ApiService();
  
  // Controllers
  final _multiLineController = TextEditingController();
  final _quantityController = TextEditingController();
  
  // State
  String _selectedMealType = 'Lunch';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _nutritionData;
  List<Map<String, dynamic>> _foodItems = [];
  bool _useMultiLineEntry = false;
  
  
  // Common meal combos for quick selection
  final List<Map<String, dynamic>> _mealCombos = [
    {
      'name': 'Breakfast Combo',
      'items': '2 scrambled eggs, 2 slices whole wheat toast, 1 cup orange juice',
      'icon': Icons.egg_alt,
    },
    {
      'name': 'Lunch Combo',
      'items': 'Grilled chicken sandwich with lettuce and tomato, side salad, apple',
      'icon': Icons.lunch_dining,
    },
    {
      'name': 'Dinner Plate',
      'items': '6 oz grilled salmon, 1 cup brown rice, steamed broccoli',
      'icon': Icons.dinner_dining,
    },
    {
      'name': 'Burger Meal',
      'items': 'Cheeseburger and medium fries with diet coke',
      'icon': Icons.fastfood,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setMealTypeByTime();
  }
  
  void _setMealTypeByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = 'Breakfast';
    } else if (hour < 15) {
      _selectedMealType = 'Lunch';
    } else if (hour < 20) {
      _selectedMealType = 'Dinner';
    } else {
      _selectedMealType = 'Snack';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Meal Logging'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Meal Type Selector
            _buildMealTypeSelector(),
            
            // Entry Mode Toggle
            _buildEntryModeToggle(),
            
            // Quick Meal Combos
            if (!_useMultiLineEntry) _buildQuickCombos(),
            
            // Main Entry Area
            _buildEntryArea(),
            
            // Individual Items List (for manual mode)
            if (!_useMultiLineEntry && _foodItems.isNotEmpty) 
              _buildItemsList(),
            
            // Analyze Button
            _buildAnalyzeButton(),
            
            // Results
            if (_nutritionData != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mealTypes.length,
        itemBuilder: (context, index) {
          final mealType = mealTypes[index];
          final isSelected = _selectedMealType == mealType;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedMealType = mealType),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  mealType,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useMultiLineEntry = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_useMultiLineEntry ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: !_useMultiLineEntry ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Items',
                      style: TextStyle(
                        color: !_useMultiLineEntry ? Colors.green : Colors.grey,
                        fontWeight: !_useMultiLineEntry ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useMultiLineEntry = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _useMultiLineEntry ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: _useMultiLineEntry ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Describe Meal',
                      style: TextStyle(
                        color: _useMultiLineEntry ? Colors.green : Colors.grey,
                        fontWeight: _useMultiLineEntry ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCombos() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mealCombos.length,
        itemBuilder: (context, index) {
          final combo = _mealCombos[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _useMultiLineEntry = true;
                _multiLineController.text = combo['items'];
              });
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    combo['icon'],
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    combo['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to use',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryArea() {
    if (_useMultiLineEntry) {
      // Text description mode
      return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe your meal:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can list multiple items separated by commas, "and", or "with"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _multiLineController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., grilled chicken with rice and salad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add the Voice Input Widget here
              VoiceInputWidget(
                onTextReceived: (text) {
                  setState(() {
                    // Append to existing text or replace
                    if (_multiLineController.text.isEmpty) {
                      _multiLineController.text = text;
                    } else {
                      _multiLineController.text += ', $text';
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  } else {
      // Individual items mode
      return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Food Item:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _multiLineController,
                  decoration: InputDecoration(
                    hintText: 'Food item',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
                VoiceInputWidget(
                onTextReceived: (text) {
                  setState(() {
                    _multiLineController.text = text;
                  });
                },
              ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      hintText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addFoodItem,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.green,
                  iconSize: 40,
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildItemsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items to log:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._foodItems.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item['food']),
              subtitle: Text(item['quantity']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _foodItems.remove(item);
                  });
                },
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final hasContent = _useMultiLineEntry 
        ? _multiLineController.text.isNotEmpty 
        : _foodItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasContent && !_isAnalyzing ? _analyzeMeal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isAnalyzing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Analyze Meal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResults() {
    final components = _nutritionData!['components'] as List?;
    if (_nutritionData == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_nutritionData!['calories'] ?? 0} cal',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (_nutritionData?['data_source'] != null)
            Chip(
              label: Text(
                'Source: ${_nutritionData!['data_source']}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _nutritionData!['data_source'] == 'USDA' 
                  ? Colors.blue.shade100 
                  : Colors.purple.shade100,
            ),


          if (components != null && components.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Food Components:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...components.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['food']} (${item['quantity']})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${item['calories']} cal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
          
          // Macro breakdown
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCard('Protein', _nutritionData!['protein_g'] ?? 0, 'g', Colors.blue),
              _buildMacroCard('Carbs', _nutritionData!['carbs_g'] ?? 0, 'g', Colors.orange),
              _buildMacroCard('Fat', _nutritionData!['fat_g'] ?? 0, 'g', Colors.purple),
            ],
          ),
          
          // Additional nutrients
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroCard('Fiber', _nutritionData!['fiber_g'] ?? 0, 'g', Colors.green),
              _buildMacroCard('Sugar', _nutritionData!['sugar_g'] ?? 0, 'g', Colors.pink),
              _buildMacroCard('Sodium', _nutritionData!['sodium_mg'] ?? 0, 'mg', Colors.grey),
            ],
          ),
          
          // Health score
          if (_nutritionData!['healthiness_score'] != null) ...[
            const SizedBox(height: 16),
            _buildHealthScore(_nutritionData!['healthiness_score']),
          ],
          
          // Suggestions
          if (_nutritionData!['suggestions'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nutritionData!['suggestions'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, dynamic value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$value$unit',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScore(int score) {
    Color scoreColor;
    String scoreText;
    
    if (score >= 8) {
      scoreColor = Colors.green;
      scoreText = 'Excellent';
    } else if (score >= 6) {
      scoreColor = Colors.orange;
      scoreText = 'Good';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Needs Improvement';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: scoreColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Health Score: $score/10',
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($scoreText)',
            style: TextStyle(
              color: scoreColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _addFoodItem() {
    if (_multiLineController.text.isNotEmpty) {
      setState(() {
        _foodItems.add({
          'food': _multiLineController.text,
          'quantity': _quantityController.text.isEmpty ? '1 serving' : _quantityController.text,
        });
        _multiLineController.clear();
        _quantityController.clear();
      });
    }
  }

  Future<void> _analyzeMeal() async {
    if (widget.userProfile.id == null || widget.userProfile.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      String mealDescription;
      String quantity = '1 serving';
      
      if (_useMultiLineEntry) {
        mealDescription = _multiLineController.text;
      } else {
        // Combine individual items
        mealDescription = _foodItems
            .map((item) => '${item['quantity']} ${item['food']}')
            .join(', ');
      }

      // Use the existing analyzeMeal method with Map parameter
      final response = await _apiService.analyzeMeal({
        'user_id': widget.userProfile.id,
        'food_item': mealDescription,
        'quantity': quantity,
        'meal_type': _selectedMealType,
        'meal_date': DateTime.now().toIso8601String(),
      });

      setState(() {
        // The response has 'meal' key which contains the nutrition data
        _nutritionData = response['meal'] ?? response;
        _isAnalyzing = false;
      });

      String dataSource = _nutritionData?['data_source'] ?? 'Unknown';
      print('Data source used: $dataSource');

      // Clear the form after successful analysis
      _multiLineController.clear();
      _quantityController.clear();
      _foodItems.clear();
      
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewHistory() {
    // Navigate to meal history page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealHistoryPage(userProfile: widget.userProfile),
      ),
    );
  }
}