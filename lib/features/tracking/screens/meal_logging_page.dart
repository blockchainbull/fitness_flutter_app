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
      final summary = await _apiService.getDailySummary(
        widget.userProfile.id!,
        date: DateTime.now().toIso8601String(),
      );
      
      setState(() {
        _dailySummary = summary;
      });
    } catch (e) {
      print('Error loading daily summary: $e');
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
    
    setState(() => _isAnalyzing = true);
    
    try {
      final response = await _apiService.analyzeMeal({
        'user_id': widget.userProfile.id,
        'food_item': _foodController.text,
        'quantity': _quantityController.text,
        'preparation': _preparationController.text,
        'meal_type': _selectedMealType,
        'meal_date': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        _nutritionData = response['nutrition'];
        _isAnalyzing = false;
      });
      
      // Show results
      _showNutritionResults();
      
      // Reload meals and summary
      _loadTodaysMeals();
      _loadDailySummary();
      
      // Clear form
      _foodController.clear();
      _quantityController.clear();
      _preparationController.clear();
      
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
  
  void _showNutritionResults() {
    if (_nutritionData == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Nutrition Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              Text(
                _nutritionData!['serving_description'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              
              // Calories highlight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, 
                        color: Colors.orange, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      '${_nutritionData!['calories']} calories',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Macros grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMacroCard('Protein', 
                      _nutritionData!['protein_g'], 'g', Colors.red),
                  _buildMacroCard('Carbs', 
                      _nutritionData!['carbs_g'], 'g', Colors.blue),
                  _buildMacroCard('Fat', 
                      _nutritionData!['fat_g'], 'g', Colors.amber),
                ],
              ),
              const SizedBox(height: 20),
              
              // Additional nutrients
              if (_nutritionData!['fiber_g'] != null)
                _buildNutrientRow('Fiber', 
                    '${_nutritionData!['fiber_g']}g'),
              if (_nutritionData!['sugar_g'] != null)
                _buildNutrientRow('Sugar', 
                    '${_nutritionData!['sugar_g']}g'),
              if (_nutritionData!['sodium_mg'] != null)
                _buildNutrientRow('Sodium', 
                    '${_nutritionData!['sodium_mg']}mg'),
              
              const SizedBox(height: 20),
              
              // Health score
              Row(
                children: [
                  const Text('Healthiness Score: ', 
                      style: TextStyle(fontSize: 16)),
                  ...List.generate(10, (index) {
                    return Icon(
                      Icons.star,
                      size: 20,
                      color: index < (_nutritionData!['healthiness_score'] ?? 0)
                          ? Colors.amber
                          : Colors.grey[300],
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Notes and suggestions
              if (_nutritionData!['nutrition_notes'] != null) ...[
                Text(
                  _nutritionData!['nutrition_notes'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              
              if (_nutritionData!['suggestions'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, 
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _nutritionData!['suggestions'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMacroCard(String label, dynamic value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$value$unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
    }
 
 Widget _buildNutrientRow(String label, String value) {
   return Padding(
     padding: const EdgeInsets.symmetric(vertical: 4),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(label, style: TextStyle(color: Colors.grey[600])),
         Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
       ],
     ),
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
           // Daily Summary Card
           if (_dailySummary != null)
             _buildDailySummaryCard(),
           
           // Meal Input Form
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
           
           // Quick Add Section
           _buildQuickAddSection(),
           
           // Today's Meals
           if (_todayMeals.isNotEmpty)
             _buildTodaysMealsSection(),
         ],
       ),
     ),
   );
 }
 
 Widget _buildDailySummaryCard() {
   final totals = _dailySummary!['totals'];
   final goals = _dailySummary!['goals'];
   
   final calorieProgress = (totals['calories'] / goals['calories']).clamp(0.0, 1.0);
   final proteinProgress = (totals['protein_g'] / goals['protein_g']).clamp(0.0, 1.0);
   
   return Container(
     margin: const EdgeInsets.all(16),
     padding: const EdgeInsets.all(20),
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
               'Today\'s Progress',
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
               ),
             ),
             Text(
               DateFormat('MMM d').format(DateTime.now()),
               style: const TextStyle(
                 color: Colors.white70,
                 fontSize: 14,
               ),
             ),
           ],
         ),
         const SizedBox(height: 20),
         
         // Calories
         _buildProgressRow(
           'Calories',
           totals['calories'].toInt(),
           goals['calories'].toInt(),
           calorieProgress,
           Icons.local_fire_department,
         ),
         const SizedBox(height: 16),
         
         // Protein
         _buildProgressRow(
           'Protein',
           totals['protein_g'].toInt(),
           goals['protein_g'].toInt(),
           proteinProgress,
           Icons.fitness_center,
           unit: 'g',
         ),
         const SizedBox(height: 16),
         
         // Meals count
         Row(
           children: [
             Icon(Icons.restaurant, color: Colors.white.withOpacity(0.8)),
             const SizedBox(width: 8),
             Text(
               '${totals['meals_count']} meals logged today',
               style: TextStyle(
                 color: Colors.white.withOpacity(0.9),
                 fontSize: 14,
               ),
             ),
           ],
         ),
       ],
     ),
   );
 }
 
 Widget _buildProgressRow(
   String label,
   int current,
   int goal,
   double progress,
   IconData icon, {
   String unit = '',
 }) {
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Row(
             children: [
               Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
               const SizedBox(width: 8),
               Text(
                 label,
                 style: TextStyle(
                   color: Colors.white.withOpacity(0.9),
                   fontSize: 14,
                 ),
               ),
             ],
           ),
           Text(
             '$current$unit / $goal$unit',
             style: const TextStyle(
               color: Colors.white,
               fontSize: 14,
               fontWeight: FontWeight.bold,
             ),
           ),
         ],
       ),
       const SizedBox(height: 8),
       LinearProgressIndicator(
         value: progress,
         backgroundColor: Colors.white.withOpacity(0.3),
         valueColor: AlwaysStoppedAnimation<Color>(
           progress > 0.9 ? Colors.amber : Colors.white,
         ),
         minHeight: 6,
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