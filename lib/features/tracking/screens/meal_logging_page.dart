// lib/features/tracking/screens/ai_meal_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/features/tracking/screens/meal_history_page.dart';
import 'package:intl/intl.dart';

class MealLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const MealLoggingPage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<MealLoggingPage> createState() => _MealLoggingPageState();
}

class _MealLoggingPageState extends State<MealLoggingPage> {
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final _foodController = TextEditingController();
  final _quantityController = TextEditingController();
  final _preparationController = TextEditingController();
  
  // State variables
  String _selectedMealType = 'Lunch';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _nutritionData;
  Map<String, dynamic>? _dailySummary;
  List<Map<String, dynamic>> _todayMeals = [];
  
  @override
  void initState() {
    super.initState();
    _setMealTypeByTime();
    _loadTodaysMeals();
    _loadDailySummary();
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

  Future<void> _editMeal(Map<String, dynamic> meal) async {
    final foodController = TextEditingController(text: meal['food_item']);
    final quantityController = TextEditingController(text: meal['quantity']);
    final caloriesController = TextEditingController(text: meal['calories'].toString());
    final proteinController = TextEditingController(text: meal['protein_g'].toString());
    final carbsController = TextEditingController(text: meal['carbs_g'].toString());
    final fatController = TextEditingController(text: meal['fat_g'].toString());
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodController,
                decoration: const InputDecoration(
                  labelText: 'Food Item',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Call update API
              final response = await _apiService.updateMeal(
                meal['id'],
                {
                  'food_item': foodController.text,
                  'quantity': quantityController.text,
                  'calories': double.tryParse(caloriesController.text) ?? 0,
                  'protein_g': double.tryParse(proteinController.text) ?? 0,
                  'carbs_g': double.tryParse(carbsController.text) ?? 0,
                  'fat_g': double.tryParse(fatController.text) ?? 0,
                },
              );
              
              if (response['success']) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      _loadTodaysMeals();
      _loadDailySummary();
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _apiService.deleteMeal(mealId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal deleted')),
        );
        _loadTodaysMeals();
        _loadDailySummary();
      }
    }
  }
  
  Future<void> _loadTodaysMeals() async {
    try {
      final meals = await _apiService.getMealHistory(
        widget.userProfile.id!,
        date: DateTime.now().toIso8601String(),
      );
      
      setState(() {
        _todayMeals = meals;
      });
    } catch (e) {
      print('Error loading meals: $e');
    }
  }
  
  Future<void> _loadDailySummary() async {
    try {
      final userId = widget.userProfile.id ?? '';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final summary = await _apiService.getDailySummary(
        userId,
        date: todayStr,
      );
      
      // Only set state if we got valid data
      if (summary != null && summary['success'] == true) {
        setState(() {
          _dailySummary = summary;
        });
      } else {
        print('Invalid daily summary response');
        setState(() {
          _dailySummary = null;
        });
      }
    } catch (e) {
      print('Error loading daily summary: $e');
      setState(() {
        _dailySummary = null;
      });
    }
  }
  
  Future<void> _analyzeMeal() async {
    if (_foodController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter what you ate and how much'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
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
      print('🔍 About to analyze meal with user ID: "${widget.userProfile.id}"');

      final response = await _apiService.analyzeMeal({
        'user_id': widget.userProfile.id ?? '',
        'food_item': _foodController.text,
        'quantity': _quantityController.text,
        'preparation': _preparationController.text,
        'meal_type': _selectedMealType,
        'meal_date': DateTime.now().toIso8601String(),
      });
      

      print('🔍 Full API Response: $response'); // Debug
      print('🔍 Response meal data: ${response['meal']}'); // Debug
      
      setState(() {
        _nutritionData = response['meal'];
        _isAnalyzing = false;
      });
      
      print('🔍 Nutrition data set: $_nutritionData'); // Debug
      print('🔍 About to call _showNutritionResults()'); // Debug
      
      // Show results
      _showNutritionResults();
      
      print('🔍 Called _showNutritionResults()');

      // Reload meals and summary
      _loadTodaysMeals();
      _loadDailySummary();
      
      // Clear form
      _foodController.clear();
      _quantityController.clear();
      _preparationController.clear();
      
    } catch (e) {
      print('❌ Error in _analyzeMeal: $e');
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showNutritionResults() {
    print('[DEBUG] _showNutritionResults called');
    print('[DEBUG] _nutritionData: $_nutritionData');
    print('[DEBUG] mounted: $mounted');
    
    if (_nutritionData == null) {
      print('[DEBUG] No nutrition data - returning');
      return;
    }
    
    if (!mounted) {
      print('[DEBUG] Widget not mounted - returning');
      return;
    }
    
    print('[DEBUG] About to show dialog');
    
    // Use showDialog instead of showModalBottomSheet for better web compatibility
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        print('[DEBUG] Dialog builder called');
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 600), // Fixed: Use constraints instead
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView( // Added to handle overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nutrition Analysis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          print('[DEBUG] Close button pressed');
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Food info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_nutritionData!['name'] ?? 'Food'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_nutritionData!['quantity'] ?? 'Unknown quantity'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Calories
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Calories',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_nutritionData!['calories'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Macros
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleMacro('Protein', '${_nutritionData!['protein'] ?? 0}g', Colors.red),
                      _buildSimpleMacro('Carbs', '${_nutritionData!['carbs'] ?? 0}g', Colors.blue),
                      _buildSimpleMacro('Fat', '${_nutritionData!['fat'] ?? 0}g', Colors.amber),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Health score
                  if (_nutritionData!['healthiness_score'] != null) ...[
                    Row(
                      children: [
                        const Text('Health Score: ', style: TextStyle(fontSize: 16)),
                        ...List.generate(
                          (_nutritionData!['healthiness_score'] as int? ?? 0).clamp(0, 10),
                          (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
                        ),
                        Text(' ${_nutritionData!['healthiness_score']}/10'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Notes
                  if (_nutritionData!['nutrition_notes'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💡 ${_nutritionData!['nutrition_notes']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Suggestions
                  if (_nutritionData!['suggestions'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✨ ${_nutritionData!['suggestions']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print('[DEBUG] Great button pressed');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Great! 🎉'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
 
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meal Tracker'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MealHistoryPage(
                    userProfile: widget.userProfile,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Total Calories Card (NEW - Always visible)
            _buildDailyCaloriesCard(),
            
            // Daily Summary Card (Your existing one)
            if (_dailySummary != null && 
                _dailySummary!['totals'] != null &&
                _dailySummary!['goals'] != null)
              _buildDailySummaryCard(),
            
            // Meal Input Form (Your existing form - unchanged)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Your Meal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Meal type selector
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'Breakfast',
                        'Lunch',
                        'Dinner',
                        'Snack',
                      ].map((type) {
                        final isSelected = _selectedMealType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedMealType = type;
                              });
                            },
                            selectedColor: Colors.green,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Food input
                  TextField(
                    controller: _foodController,
                    decoration: InputDecoration(
                      labelText: 'What did you eat?',
                      hintText: 'e.g., Grilled chicken breast with rice',
                      prefixIcon: const Icon(Icons.restaurant, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity input
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'How much?',
                      hintText: 'e.g., 1 plate, 200 grams, 2 cups',
                      prefixIcon: const Icon(Icons.scale, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preparation method (optional)
                  TextField(
                    controller: _preparationController,
                    decoration: InputDecoration(
                      labelText: 'How was it prepared? (Optional)',
                      hintText: 'e.g., fried in olive oil, steamed, raw',
                      prefixIcon: const Icon(Icons.kitchen, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Analyze button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAnalyzing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Analyzing...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics),
                                SizedBox(width: 8),
                                Text(
                                  'Analyze & Log Meal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Add Section (Your existing section)
            _buildQuickAddSection(),
            
            // Today's Meals (Your existing section)
            if (_todayMeals.isNotEmpty)
              _buildTodaysMealsSection(),
          ],
        ),
      ),
    );
  }
 
  Widget _buildDailyCaloriesCard() {
    // Calculate total calories from today's meals
    double totalCalories = 0;
    for (var meal in _todayMeals) {
      totalCalories += (meal['calories'] as num?)?.toDouble() ?? 0;
    }
    
    // Also try to get from daily summary if available
    if (_dailySummary != null && _dailySummary!['totals'] != null) {
      final summaryCalories = (_dailySummary!['totals']['calories'] as num?)?.toDouble() ?? 0;
      if (summaryCalories > totalCalories) {
        totalCalories = summaryCalories;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Calories",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalCalories.toStringAsFixed(0)} cal',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_todayMeals.length} meals',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDailySummaryCard() {
    if (_dailySummary == null) {
      return const SizedBox.shrink();
    }
    
    final totals = _dailySummary!['totals'] as Map<String, dynamic>? ?? {};
    
    // Safely extract values with defaults
    final calories = (totals['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (totals['protein_g'] as num?)?.toDouble() ?? 0.0;
    final carbs = (totals['carbs_g'] as num?)?.toDouble() ?? 0.0;
    final fat = (totals['fat_g'] as num?)?.toDouble() ?? 0.0;
    final fiber = (totals['fiber_g'] as num?)?.toDouble() ?? 0.0;
    final sugar = (totals['sugar_g'] as num?)?.toDouble() ?? 0.0;
    final sodium = (totals['sodium_mg'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.today, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Today's Nutrition",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMM d').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main Calories Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${calories.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'CALORIES TODAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Macronutrients Row
          Row(
            children: [
              Expanded(
                child: _buildMacroIndicator('Protein', '${protein.toStringAsFixed(1)}g', Colors.red.shade300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroIndicator('Carbs', '${carbs.toStringAsFixed(1)}g', Colors.orange.shade300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroIndicator('Fat', '${fat.toStringAsFixed(1)}g', Colors.blue.shade300),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Additional Nutrients Row
          Row(
            children: [
              Expanded(
                child: _buildMicroIndicator('Fiber', '${fiber.toStringAsFixed(1)}g'),
              ),
              Expanded(
                child: _buildMicroIndicator('Sugar', '${sugar.toStringAsFixed(1)}g'),
              ),
              Expanded(
                child: _buildMicroIndicator('Sodium', '${sodium.toStringAsFixed(0)}mg'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroIndicator(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

 Widget _buildQuickAddSection() {
   final quickItems = [
     {'name': 'Water', 'icon': Icons.water_drop, 'quantity': '1 glass'},
     {'name': 'Apple', 'icon': Icons.apple, 'quantity': '1 medium'},
     {'name': 'Coffee', 'icon': Icons.coffee, 'quantity': '1 cup'},
     {'name': 'Banana', 'icon': Icons.breakfast_dining, 'quantity': '1 medium'},
   ];
   
   return Container(
     margin: const EdgeInsets.symmetric(horizontal: 16),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
           'Quick Add',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
           ),
         ),
         const SizedBox(height: 12),
         SizedBox(
           height: 80,
           child: ListView.builder(
             scrollDirection: Axis.horizontal,
             itemCount: quickItems.length,
             itemBuilder: (context, index) {
               final item = quickItems[index];
               return GestureDetector(
                 onTap: () {
                   _foodController.text = item['name'] as String;
                   _quantityController.text = item['quantity'] as String;
                   _analyzeMeal();
                 },
                 child: Container(
                   width: 80,
                   margin: const EdgeInsets.only(right: 12),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.05),
                         blurRadius: 5,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         item['icon'] as IconData,
                         color: Colors.green,
                         size: 30,
                       ),
                       const SizedBox(height: 8),
                       Text(
                         item['name'] as String,
                         style: const TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
               );
             },
           ),
         ),
       ],
     ),
   );
 }
 
 Widget _buildTodaysMealsSection() {
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
         const SizedBox(height: 12),
         ..._todayMeals.map((meal) => _buildMealCard(meal)),
       ],
     ),
   );
 }
 
 Widget _buildMealCard(Map<String, dynamic> meal) {
   final mealTypeIcons = {
     'Breakfast': Icons.breakfast_dining,
     'Lunch': Icons.lunch_dining,
     'Dinner': Icons.dinner_dining,
     'Snack': Icons.cookie,
   };
   
   final mealTypeColors = {
     'Breakfast': Colors.orange,
     'Lunch': Colors.green,
     'Dinner': Colors.purple,
     'Snack': Colors.brown,
   };
   
   return Container(
     margin: const EdgeInsets.only(bottom: 12),
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: Colors.white,
       borderRadius: BorderRadius.circular(12),
       boxShadow: [
         BoxShadow(
           color: Colors.black.withOpacity(0.05),
           blurRadius: 5,
           offset: const Offset(0, 2),
         ),
       ],
     ),
     child: Row(
       children: [
         Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: (mealTypeColors[meal['meal_type']] ?? Colors.grey)
                 .withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
           ),
           child: Icon(
             mealTypeIcons[meal['meal_type']] ?? Icons.restaurant,
             color: mealTypeColors[meal['meal_type']] ?? Colors.grey,
             size: 24,
           ),
         ),
         const SizedBox(width: 16),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 meal['food_item'],
                 style: const TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               const SizedBox(height: 4),
               Text(
                 '${meal['quantity']} • ${meal['calories']} cal',
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[600],
                 ),
               ),
             ],
           ),
         ),
         Column(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             Text(
               meal['meal_type'],
               style: TextStyle(
                 fontSize: 12,
                 color: Colors.grey[500],
                 fontWeight: FontWeight.w500,
               ),
             ),
             const SizedBox(height: 4),
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editMeal(meal),
              color: Colors.grey[600],
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteMeal(meal['id']),
              color: Colors.red[300],
            ),
          ],
             ),
           ],
         ),
       ],
     ),
   );
 }
 
 @override
 void dispose() {
   _foodController.dispose();
   _quantityController.dispose();
   _preparationController.dispose();
   super.dispose();
 }
}