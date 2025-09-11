// lib/features/tracking/screens/enhanced_meal_logging_page.dart
import 'dart:convert';
import 'package:intl/intl.dart';
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
  int _dailyMealGoal = 3;
  double _dailyCalorieGoal = 2000;
  Map<String, double> _macroGoals = {
    'protein': 150.0,
    'carbs': 225.0,
    'fat': 67.0,
  };
  List<Map<String, dynamic>> _todaysMeals = [];
  
  
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
    _loadTodaysMeals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDailyGoals();
      if (mounted) setState(() {});
    });
    _dailyMealGoal = widget.userProfile.dailyMealsCount ?? 3;
    _setMealTypeByTime();
  }

  Future<void> _loadTodaysMeals() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final meals = await _apiService.getMealHistory(
        widget.userProfile.id!,
        date: dateStr,
      );
      
      setState(() {
        _todaysMeals = meals;
      });
    } catch (e) {
      print('Error loading today\'s meals: $e');
    }
  }

  void _calculateDailyGoals() {
    try {
      // Safely get TDEE with default value
      final tdee = (widget.userProfile.formData?['tdee'] ?? 2000).toDouble();
      final weightGoal = widget.userProfile.primaryGoal ?? 'maintain_weight';
      
      // Calculate daily calorie goal
      if (weightGoal.toLowerCase().contains('lose')) {
        _dailyCalorieGoal = tdee * 0.82; // 18% deficit
      } else if (weightGoal.toLowerCase().contains('gain')) {
        _dailyCalorieGoal = tdee * 1.12; // 12% surplus  
      } else {
        _dailyCalorieGoal = tdee;
      }
      
      // Initialize macro goals map if null
      _macroGoals ??= {};
      
      // Calculate macros
      _calculateMacroGoals();
      
    } catch (e) {
      print('Error calculating goals: $e');
      // Set default values to prevent crashes
      _dailyCalorieGoal = 2000;
      _macroGoals = {
        'protein': 150.0,
        'carbs': 225.0,
        'fat': 67.0,
      };
    }
  }
  
  void _calculateMacroGoals() {
    try {
      final weightGoal = widget.userProfile.primaryGoal ?? 'maintain_weight';
      
      double proteinPercent;
      double carbPercent;
      double fatPercent;
      
      if (weightGoal.toLowerCase().contains('lose')) {
        proteinPercent = 0.30;
        carbPercent = 0.35;
        fatPercent = 0.35;
      } else if (weightGoal.toLowerCase().contains('gain')) {
        proteinPercent = 0.25;
        carbPercent = 0.50;
        fatPercent = 0.25;
      } else {
        proteinPercent = 0.25;
        carbPercent = 0.45;
        fatPercent = 0.30;
      }
      
      // Calculate with null safety
      final proteinCalories = _dailyCalorieGoal * proteinPercent;
      final carbCalories = _dailyCalorieGoal * carbPercent;
      final fatCalories = _dailyCalorieGoal * fatPercent;
      
      _macroGoals = {
        'protein': proteinCalories / 4,
        'carbs': carbCalories / 4,
        'fat': fatCalories / 9,
      };
    } catch (e) {
      print('Error calculating macros: $e');
      // Set defaults
      _macroGoals = {
        'protein': 150.0,
        'carbs': 225.0,
        'fat': 67.0,
      };
    }
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
            // Daily Macro Goal
            _buildDailyGoalsSection(),

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

            _buildTodaysMeals(),
            
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
                VoiceInputWidget(
                  onTextReceived: (text) {
                    setState(() {
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
              'Add food items:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
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
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      hintText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
        // Handle the response structure properly
        if (response.containsKey('meal')) {
          _nutritionData = response['meal'];
        } else if (response.containsKey('data')) {
          _nutritionData = response['data'];
        } else {
          _nutritionData = response;
        }
        
        _isAnalyzing = false;
        
        // Debug logging to see the structure
        print('Nutrition Data Structure: ${_nutritionData?.keys.toList()}');
        print('Calories: ${_nutritionData?['calories']}');
        print('Protein: ${_nutritionData?['protein_g']} or ${_nutritionData?['protein']}');
        print('Carbs: ${_nutritionData?['carbs_g']} or ${_nutritionData?['carbs']}');
        print('Fat: ${_nutritionData?['fat_g']} or ${_nutritionData?['fat']}');
      });

      String dataSource = _nutritionData?['data_source'] ?? 'Unknown';
      print('Data source used: $dataSource');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal analyzed successfully! (${_nutritionData?['calories']?.round() ?? 0} calories)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

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
      print('Error details: $e');
    }
  }

  Widget _buildTodaysMeals() {
    if (_todaysMeals.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Meals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._todaysMeals.map((meal) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getMealTypeColor(meal['meal_type']).withOpacity(0.2),
                child: Text(
                  meal['meal_type']?.substring(0, 1).toUpperCase() ?? 'S',
                  style: TextStyle(
                    color: _getMealTypeColor(meal['meal_type']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(meal['food_item']),
              subtitle: Text('${meal['quantity']} • ${meal['calories']} cal'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editMeal(meal),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteMeal(meal),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_nutritionData == null) return const SizedBox.shrink();
    
    final components = _nutritionData!['components'] as List?;
    
    return Column(
      children: [
        // Nutrition analysis card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with calories
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
                      '${(_nutritionData!['calories'] ?? 0).round()} cal',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Progress bar
              const SizedBox(height: 12),
              _buildCalorieProgress(),
              
              // Data source badge
              if (_nutritionData!['data_source'] != null) ...[
                const SizedBox(height: 12),
                _buildDataSourceBadge(),
              ],
              
              // Food components (if multi-food meal)
              if (components != null && components.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFoodComponents(components),
              ],
              
              // Macro breakdown
              const SizedBox(height: 16),
              _buildMacroBreakdown(),
              
              // Additional nutrients
              const SizedBox(height: 12),
              _buildAdditionalNutrients(),
              
              // Health score
              if (_nutritionData!['healthiness_score'] != null) ...[
                const SizedBox(height: 16),
                _buildHealthScore(_nutritionData!['healthiness_score']),
              ],
              
              // Suggestions
              if (_nutritionData!['suggestions'] != null &&
                  _nutritionData!['suggestions'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSuggestions(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalsCard() {
    // Safely get values with null checks
    final tdee = (widget.userProfile.formData?['tdee'] ?? 2000).toDouble();
    final weightGoal = widget.userProfile.primaryGoal ?? 'maintain_weight';
    
    // Calculate goals with null safety
    _calculateDailyGoals();
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Modern Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(weightGoal),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Nutrition Goals',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getGoalDescription(weightGoal),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getGoalIcon(weightGoal),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getGoalLabel(weightGoal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Main Calorie Display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Daily Calorie Target',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_dailyCalorieGoal.round()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'kcal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'TDEE: ${tdee.round()} kcal',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Macro Targets Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MACRO TARGETS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Beautiful Macro Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildModernMacroCard(
                        'Protein',
                        _macroGoals['protein']?.round() ?? 0,
                        const Color(0xFF4A90E2),
                        Icons.fitness_center,
                        '${((_macroGoals['protein'] ?? 0) * 100 / (_dailyCalorieGoal / 4)).round()}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernMacroCard(
                        'Carbs',
                        _macroGoals['carbs']?.round() ?? 0,
                        const Color(0xFFF5A623),
                        Icons.grain,
                        '${((_macroGoals['carbs'] ?? 0) * 100 / (_dailyCalorieGoal / 4)).round()}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernMacroCard(
                        'Fats',
                        _macroGoals['fat']?.round() ?? 0,
                        const Color(0xFF9B59B6),
                        Icons.water_drop,
                        '${((_macroGoals['fat'] ?? 0) * 100 / (_dailyCalorieGoal / 9)).round()}%',
                      ),
                    ),
                  ],
                ),
                
                // Info Section
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade100,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getInfoText(weightGoal),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMacroCard(
    String label,
    int grams,
    Color color,
    IconData icon,
    String percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${grams}g',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(String goal, String calories, String purpose) {
    final isHeader = goal == 'Weight Goal';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade800 : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              goal,
              style: TextStyle(
                color: isHeader ? Colors.grey.shade400 : Colors.white,
                fontSize: isHeader ? 12 : 13,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              calories,
              style: TextStyle(
                color: isHeader ? Colors.grey.shade400 : Colors.green.shade400,
                fontSize: isHeader ? 12 : 13,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              purpose,
              style: TextStyle(
                color: isHeader ? Colors.grey.shade400 : Colors.grey.shade300,
                fontSize: isHeader ? 12 : 12,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTarget(String label, int grams, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${grams}g',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieProgress() {
    final calories = (_nutritionData!['calories'] ?? 0).toDouble();
    final progress = calories / _dailyCalorieGoal;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress towards daily goal',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: progress > 1.0 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 1.0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBreakdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroCard(
          'Protein',
          (_nutritionData!['protein_g'] ?? _nutritionData!['protein'] ?? 0).toDouble(),
          'g',
          Colors.blue,
        ),
        _buildMacroCard(
          'Carbs',
          (_nutritionData!['carbs_g'] ?? _nutritionData!['carbs'] ?? 0).toDouble(),
          'g',
          Colors.orange,
        ),
        _buildMacroCard(
          'Fat',
          (_nutritionData!['fat_g'] ?? _nutritionData!['fat'] ?? 0).toDouble(),
          'g',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAdditionalNutrients() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMacroCard(
          'Fiber',
          (_nutritionData!['fiber_g'] ?? _nutritionData!['fiber'] ?? 0).toDouble(),
          'g',
          Colors.green,
        ),
        _buildMacroCard(
          'Sugar',
          (_nutritionData!['sugar_g'] ?? _nutritionData!['sugar'] ?? 0).toDouble(),
          'g',
          Colors.pink,
        ),
        _buildMacroCard(
          'Sodium',
          (_nutritionData!['sodium_mg'] ?? _nutritionData!['sodium'] ?? 0).toDouble(),
          'mg',
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, double value, String unit, Color color) {
    // Calculate percentage of daily goal
    double goalValue = 0;
    double percentage = 0;
    
    if (_macroGoals != null) {
      switch (label.toLowerCase()) {
        case 'protein':
          goalValue = _macroGoals['protein'] ?? 0;
          break;
        case 'carbs':
          goalValue = _macroGoals['carbs'] ?? 0;
          break;
        case 'fat':
          goalValue = _macroGoals['fat'] ?? 0;
          break;
      }
      
      if (goalValue > 0) {
        percentage = (value / goalValue) * 100;
      }
    }
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (percentage > 0) ...[
          Text(
            '${percentage.toStringAsFixed(0)}% of goal',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthScore(dynamic healthinessScore) {
    final score = (healthinessScore ?? 0).toDouble();
    final scoreInt = score.round();
    
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    
    if (scoreInt >= 8) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (scoreInt >= 6) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Good';
      scoreIcon = Icons.sentiment_satisfied;
    } else if (scoreInt >= 4) {
      scoreColor = Colors.orange;
      scoreLabel = 'Needs Improvement';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
      scoreIcon = Icons.sentiment_dissatisfied;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(scoreIcon, color: scoreColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Score: $scoreInt/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: scoreColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
            ),
            child: Center(
              child: Text(
                '$scoreInt',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalsSection() {
    // Get user profile data (you'll need to pass this from your state management)
    final userTdee = widget.userProfile?.tdee ?? 2000.0;
    final weightGoal = widget.userProfile?.weightGoal ?? 'maintain';
    
    // Calculate daily calorie goal based on weight goal
    double dailyCalorieGoal;
    String goalDescription;
    
    switch (weightGoal.toLowerCase()) {
      case 'lose_weight':
      case 'lose weight':
        dailyCalorieGoal = userTdee * 0.82; // 18% deficit
        goalDescription = 'Deficit for fat loss (~0.5-0.7 kg/week)';
        break;
      case 'gain_weight':
      case 'gain weight':
        dailyCalorieGoal = userTdee * 1.12; // 12% surplus
        goalDescription = 'Surplus for muscle gain (~0.3-0.5 kg/week)';
        break;
      default:
        dailyCalorieGoal = userTdee;
        goalDescription = 'Maintains current weight';
    }
    
    // Calculate macro goals (you can adjust these percentages based on goals)
    final proteinPercent = weightGoal.contains('gain') ? 0.30 : 0.25;
    final carbPercent = 0.45;
    final fatPercent = 1.0 - proteinPercent - carbPercent;
    
    final proteinCalories = dailyCalorieGoal * proteinPercent;
    final carbCalories = dailyCalorieGoal * carbPercent;
    final fatCalories = dailyCalorieGoal * fatPercent;
    
    final proteinGrams = proteinCalories / 4; // 4 cal per gram
    final carbGrams = carbCalories / 4;
    final fatGrams = fatCalories / 9; // 9 cal per gram
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Daily Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGoalColor(weightGoal),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getGoalLabel(weightGoal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Calorie Goal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calorie Target',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${dailyCalorieGoal.round()} cal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  goalDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Macro Goals
          const Text(
            'Macro Targets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildMacroGoalCard(
                  'Protein',
                  proteinGrams.round(),
                  Colors.blue,
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroGoalCard(
                  'Carbs',
                  carbGrams.round(),
                  Colors.orange,
                  Icons.grain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroGoalCard(
                  'Fat',
                  fatGrams.round(),
                  Colors.purple,
                  Icons.opacity,
                ),
              ),
            ],
          ),
          
          // TDEE Reference
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Your TDEE: ${userTdee.round()} cal/day',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroGoalCard(String label, int grams, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '${grams}g',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceBadge() {
    final dataSource = _nutritionData!['data_source'] ?? 'unknown';
    final confidenceScore = _nutritionData!['confidence_score'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDataSourceColor(dataSource),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDataSourceIcon(dataSource),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Source: $dataSource',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (confidenceScore != null) ...[
            const SizedBox(width: 8),
            Text(
              '(${(confidenceScore * 100).toInt()}% confidence)',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodComponents(List components) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                '${(item['calories'] ?? 0).round()} cal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _nutritionData!['suggestions'] ?? '';
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
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
              suggestions,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Delete meal with confirmation
  Future<void> _confirmDeleteMeal(Map<String, dynamic> meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal['food_item']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _deleteMeal(meal);
    }
  }

  // Delete meal
  Future<void> _deleteMeal(Map<String, dynamic> meal) async {
    try {
      final success = await _apiService.deleteMeal(meal['id']);
      
      if (success) {
        // Reload meals after deletion
        await _loadTodaysMeals();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete meal');
      }
    } catch (e) {
      print('Error deleting meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit meal - opens a dialog or navigates to edit page
  void _editMeal(Map<String, dynamic> meal) {
    // Option 1: Show edit dialog
    showDialog(
      context: context,
      builder: (context) => _EditMealDialog(
        meal: meal,
        onSave: (updatedMeal) async {
          await _updateMeal(meal['id'], updatedMeal);
          await _loadTodaysMeals();
        },
      ),
    );
  }

  // Update meal
  Future<void> _updateMeal(String mealId, Map<String, dynamic> updatedData) async {
    try {
      await _apiService.updateMeal(mealId, updatedData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating meal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getGoalColor(String goal) {
    if (goal.toLowerCase().contains('lose')) return Colors.red;
    if (goal.toLowerCase().contains('gain')) return Colors.green;
    return Colors.blue;
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

  Color _getMealTypeColor(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getDataSourceColor(String? dataSource) {
    switch (dataSource?.toLowerCase()) {
      case 'usda':
        return Colors.green;
      case 'multi-food-parser':
        return Colors.blue;
      case 'chatgpt':
      case 'openai':
        return Colors.purple;
      case 'manual':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDataSourceIcon(String? dataSource) {
    switch (dataSource?.toLowerCase()) {
      case 'usda':
        return Icons.verified;
      case 'multi-food-parser':
        return Icons.restaurant_menu;
      case 'chatgpt':
      case 'openai':
        return Icons.psychology;
      case 'manual':
        return Icons.edit;
      default:
        return Icons.info_outline;
    }
  }

  List<Color> _getGradientColors(String goal) {
    if (goal.toLowerCase().contains('lose')) {
      return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
    } else if (goal.toLowerCase().contains('gain')) {
      return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
    }
    return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
  }

  IconData _getGoalIcon(String goal) {
    if (goal.toLowerCase().contains('lose')) return Icons.trending_down;
    if (goal.toLowerCase().contains('gain')) return Icons.trending_up;
    return Icons.trending_flat;
  }

  String _getGoalDescription(String goal) {
    if (goal.toLowerCase().contains('lose')) {
      return 'Caloric deficit for healthy weight loss';
    } else if (goal.toLowerCase().contains('gain')) {
      return 'Caloric surplus for muscle building';
    }
    return 'Balanced intake for weight maintenance';
  }

  String _getInfoText(String goal) {
    if (goal.toLowerCase().contains('lose')) {
      return 'Your plan creates an 18% caloric deficit for sustainable fat loss of 0.5-0.7 kg per week.';
    } else if (goal.toLowerCase().contains('gain')) {
      return 'Your plan includes a 12% caloric surplus to support muscle growth of 0.3-0.5 kg per week.';
    }
    return 'Your plan maintains your current weight with balanced nutrition.';
  }

  String _getGoalLabel(String goal) {
    if (goal.toLowerCase().contains('lose')) return 'Fat Loss';
    if (goal.toLowerCase().contains('gain')) return 'Muscle Gain';
    return 'Maintenance';
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

class _EditMealDialog extends StatefulWidget {
  final Map<String, dynamic> meal;
  final Function(Map<String, dynamic>) onSave;
  
  const _EditMealDialog({
    required this.meal,
    required this.onSave,
  });
  
  @override
  State<_EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<_EditMealDialog> {
  late TextEditingController _foodController;
  late TextEditingController _quantityController;
  String? _selectedMealType;
  
  @override
  void initState() {
    super.initState();
    _foodController = TextEditingController(text: widget.meal['food_item']);
    _quantityController = TextEditingController(text: widget.meal['quantity']);
    _selectedMealType = widget.meal['meal_type'];
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Meal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _foodController,
            decoration: const InputDecoration(
              labelText: 'Food Item',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: const InputDecoration(
              labelText: 'Meal Type',
              border: OutlineInputBorder(),
            ),
            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedMealType = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              'food_item': _foodController.text,
              'quantity': _quantityController.text,
              'meal_type': _selectedMealType,
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _foodController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}