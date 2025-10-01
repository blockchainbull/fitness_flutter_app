// lib/features/tracking/screens/enhanced_meal_logging_page.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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
  final _searchController = TextEditingController();
  
  // State
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
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
  
  // Enhanced features state
  List<Map<String, dynamic>> _mealPresets = [];
  List<Map<String, dynamic>> _recentMeals = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _showCalendar = false;
  bool _showRecentMeals = false;
  bool _showPresets = false;
  
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
    _loadPresets();
    _loadRecentMeals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDailyGoals();
      if (mounted) setState(() {});
    });
    _dailyMealGoal = widget.userProfile.dailyMealsCount ?? 3;
    _setMealTypeByTime();
    
    // Add listener for search
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _multiLineController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_searchController.text.length > 2) {
      _performSearch(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final queryLower = query.toLowerCase();
    
    // Search in both recent meals and presets
    final List<Map<String, dynamic>> results = [];
    
    // Search recent meals
    for (final meal in _recentMeals) {
      final foodItem = meal['food_item']?.toString().toLowerCase() ?? '';
      if (foodItem.contains(queryLower)) {
        results.add({...meal, 'type': 'recent'});
      }
    }
    
    // Search presets
    for (final preset in _mealPresets) {
      final presetName = preset['preset_name']?.toString().toLowerCase() ?? '';
      if (presetName.contains(queryLower)) {
        results.add({...preset, 'type': 'preset'});
      }
    }
    
    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _loadPresets() async {
    try {
      final response = await _apiService.getMealPresets(widget.userProfile.id!);
      setState(() {
        _mealPresets = response['presets'] ?? [];
      });
    } catch (e) {
      print('Error loading presets: $e');
    }
  }

  Future<void> _loadRecentMeals() async {
    try {
      final response = await _apiService.getMealSuggestions(widget.userProfile.id!);
      setState(() {
        _recentMeals = response['recent_meals'] ?? [];
      });
    } catch (e) {
      print('Error loading recent meals: $e');
    }
  }

  Future<void> _loadMealsForDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final meals = await _apiService.getMealHistory(
        widget.userProfile.id!,
        date: dateStr,
      );
      
      setState(() {
        if (DateUtils.isSameDay(date, DateTime.now())) {
          _todaysMeals = meals;
        }
      });
    } catch (e) {
      print('Error loading meals: $e');
    }
  }

  Future<void> _loadTodaysMeals() async {
    await _loadMealsForDate(DateTime.now());
  }

  void _calculateDailyGoals() {
    try {
      final tdee = (widget.userProfile.formData?['tdee'] ?? 2000).toDouble();
      final weightGoal = widget.userProfile.primaryGoal ?? 'maintain_weight';
      
      if (weightGoal.toLowerCase().contains('lose')) {
        _dailyCalorieGoal = tdee * 0.82;
      } else if (weightGoal.toLowerCase().contains('gain')) {
        _dailyCalorieGoal = tdee * 1.12;
      } else {
        _dailyCalorieGoal = tdee;
      }
      
      _macroGoals ??= {};
      _calculateMacroGoals();
      
    } catch (e) {
      print('Error calculating goals: $e');
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
        title: Text(DateUtils.isSameDay(_selectedDate, DateTime.now()) 
          ? 'Smart Meal Logging' 
          : 'Log Meals - ${DateFormat('MMM d').format(_selectedDate)}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.close : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: _openPresetsModal,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Calendar (collapsible)
              if (_showCalendar) _buildCalendar(),
              
              // Date indicator if not today
              if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
                _buildDateIndicator(),
              
              // Search bar
              _buildSearchBar(),
              
              // Search results dropdown
              if (_searchResults.isNotEmpty) _buildSearchResults(),
              
              // Meal Type Selector
              _buildMealTypeSelector(),
              
              // Recent Meals (collapsible section)
              _buildRecentMealsSection(),
              
              // Entry Mode Toggle
              _buildEntryModeToggle(),
              
              // Quick Meal Combos
              if (!_useMultiLineEntry) _buildQuickCombos(),
              
              // Main Entry Area
              _buildEntryArea(),
              
              // Individual Items List
              if (!_useMultiLineEntry && _foodItems.isNotEmpty) 
                _buildItemsList(),
              
              // Analyze Button
              _buildAnalyzeButton(),

              // Today's Meals
              _buildTodaysMeals(),
              
              // Results
              if (_nutritionData != null) _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _selectedDate,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _showCalendar = false;
          });
          _loadMealsForDate(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.lightGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDateIndicator() {
    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Logging meals for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search meals, presets, or enter new food...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                  });
                },
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          final isPreset = item['type'] == 'preset';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPreset ? Colors.amber.shade100 : Colors.green.shade100,
              child: Icon(
                isPreset ? Icons.star : Icons.history,
                color: isPreset ? Colors.amber : Colors.green,
              ),
            ),
            title: Text(isPreset ? item['preset_name'] : item['food_item']),
            subtitle: Text(
              isPreset 
                ? '${item['total_calories']}cal preset'
                : '${item['quantity']} • ${item['calories']}cal',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Chip(
              label: Text(isPreset ? 'Preset' : 'Recent', 
                style: const TextStyle(fontSize: 10)),
              backgroundColor: isPreset ? Colors.amber.shade100 : Colors.blue.shade100,
            ),
            onTap: () {
              if (isPreset) {
                _usePreset(item);
              } else {
                _quickAddMeal(item);
              }
              _searchController.clear();
              setState(() {
                _searchResults = [];
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentMealsSection() {
    if (_recentMeals.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showRecentMeals = !_showRecentMeals;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _showRecentMeals ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Meals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_recentMeals.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showRecentMeals) ...[
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentMeals.length,
                itemBuilder: (context, index) {
                  final meal = _recentMeals[index];
                  return _buildRecentMealCard(meal);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentMealCard(Map<String, dynamic> meal) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => _quickAddMeal(meal),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['food_item'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  meal['quantity'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, 
                      size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${meal['calories']}cal',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        'meal_date': _selectedDate.toIso8601String(),
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
      });

      String dataSource = _nutritionData?['data_source'] ?? 'Unknown';
      print('Data source used: $dataSource');

      if (DateUtils.isSameDay(_selectedDate, DateTime.now()) && 
          (response['success'] == true || _nutritionData != null)) {
        _showSaveAsPresetDialog(_nutritionData!);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal analyzed successfully! (${_nutritionData?['calories']?.round() ?? 0} calories)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      await _loadMealsForDate(_selectedDate);

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

  void _usePreset(Map<String, dynamic> preset) {
    setState(() {
      _useMultiLineEntry = true;
      _multiLineController.text = preset['food_items'] ?? preset['preset_name'] ?? '';
      _selectedMealType = preset['meal_type'] ?? _selectedMealType;
      
      // Pre-populate nutrition data if available
      if (preset['nutrition_data'] != null) {
        _nutritionData = preset['nutrition_data'];
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "${preset['preset_name']}" loaded'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _quickAddMeal(Map<String, dynamic> meal) async {
    setState(() => _isAnalyzing = true);
    
    try {
      // Directly log the meal since we already have the data
      final response = await _apiService.analyzeMeal({
        'user_id': widget.userProfile.id,
        'food_item': meal['food_item'],
        'quantity': meal['quantity'] ?? '1 serving',
        'meal_type': _selectedMealType,
        'meal_date': _selectedDate.toIso8601String(),
        // Include cached nutrition data if available
        'cached_nutrition': meal['nutrition_data'],
      });
      
      setState(() {
        _isAnalyzing = false;
        if (response['success'] == true) {
          _nutritionData = response['meal'] ?? response['data'];
        }
      });
      
      await _loadMealsForDate(_selectedDate);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openPresetsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Presets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _mealPresets.isEmpty
                  ? const Center(
                      child: Text('No presets saved yet'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _mealPresets.length,
                      itemBuilder: (context, index) {
                        final preset = _mealPresets[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber.shade100,
                              child: const Icon(Icons.star, color: Colors.amber),
                            ),
                            title: Text(preset['preset_name'] ?? 'Unnamed Preset'),
                            subtitle: Text(
                              '${preset['total_calories']?.round() ?? 0} cal • '
                              'P: ${preset['protein']?.round() ?? 0}g • '
                              'C: ${preset['carbs']?.round() ?? 0}g • '
                              'F: ${preset['fat']?.round() ?? 0}g',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _usePreset(preset);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () => _deletePreset(preset['id']),
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
        ),
      ),
    );
  }

  Future<void> _deletePreset(String presetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _apiService.deleteMealPreset(presetId);
        await _loadPresets();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preset deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting preset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSaveAsPresetDialog(Map<String, dynamic> nutritionData) {
    final presetNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Preset?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Save this meal as a preset for quick access later?'),
            const SizedBox(height: 16),
            TextField(
              controller: presetNameController,
              decoration: const InputDecoration(
                hintText: 'Preset name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveAsPreset(nutritionData, presetNameController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsPreset(Map<String, dynamic> nutritionData, String presetName) async {
    try {
      final foodItem = nutritionData['food_item'] ?? _multiLineController.text;
      final name = presetName.isNotEmpty ? presetName : foodItem;
      
      await _apiService.createPreset({
        'user_id': widget.userProfile.id,
        'preset_name': name,
        'food_items': foodItem,
        'meal_type': _selectedMealType,
        'nutrition_data': nutritionData,
        'total_calories': nutritionData['calories'],
        'protein': nutritionData['protein'],
        'carbs': nutritionData['carbs'],
        'fat': nutritionData['fat'],
      });
      
      await _loadPresets();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal saved as preset!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealHistoryPage(
          userProfile: widget.userProfile,
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadTodaysMeals(),
      _loadPresets(),
      _loadRecentMeals(),
    ]);
  }

  void _addFoodItem() {
    if (_multiLineController.text.isNotEmpty) {
      setState(() {
        _foodItems.add({
          'food': _multiLineController.text,
          'quantity': _quantityController.text.isNotEmpty 
            ? _quantityController.text 
            : '1 serving',
        });
        _multiLineController.clear();
        _quantityController.clear();
      });
    }
  }

  Widget _buildTodaysMeals() {
    if (_todaysMeals.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Meals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_todaysMeals.length}/$_dailyMealGoal meals',
                style: TextStyle(
                  color: _todaysMeals.length >= _dailyMealGoal 
                    ? Colors.green 
                    : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress indicators
          _buildNutritionProgress(),
          const SizedBox(height: 12),
          // Meal list
          ..._todaysMeals.map((meal) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Text(
                  meal['meal_type']?.substring(0, 1) ?? 'M',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(meal['food_item'] ?? ''),
              subtitle: Text(
                '${meal['calories']?.round() ?? 0} cal • ${meal['quantity'] ?? ''}',
              ),
              trailing: Text(
                meal['logged_at'] != null 
                  ? DateFormat('h:mm a').format(DateTime.parse(meal['logged_at']))
                  : '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNutritionProgress() {
    // Calculate totals from today's meals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in _todaysMeals) {
      totalCalories += (meal['calories'] ?? 0).toDouble();
      totalProtein += (meal['protein'] ?? 0).toDouble();
      totalCarbs += (meal['carbs'] ?? 0).toDouble();
      totalFat += (meal['fat'] ?? 0).toDouble();
    }
    
    return Column(
      children: [
        _buildProgressBar('Calories', totalCalories, _dailyCalorieGoal, Colors.orange),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMacroChip('Protein', totalProtein, _macroGoals['protein']!, Colors.red),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMacroChip('Carbs', totalCarbs, _macroGoals['carbs']!, Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMacroChip('Fat', totalFat, _macroGoals['fat']!, Colors.yellow.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double current, double goal, Color color) {
    final percentage = (current / goal).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${current.round()} / ${goal.round()}'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildMacroChip(String label, double current, double goal, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            '${current.round()}g',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '/ ${goal.round()}g',
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_nutritionData == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _nutritionData = null;
                  });
                },
              ),
            ],
          ),
          const Divider(),
          Text(
            _nutritionData!['food_item'] ?? 'Analyzed Meal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientInfo('Calories', 
                '${_nutritionData!['calories']?.round() ?? 0}', 'kcal'),
              _buildNutrientInfo('Protein', 
                '${_nutritionData!['protein']?.round() ?? 0}', 'g'),
              _buildNutrientInfo('Carbs', 
                '${_nutritionData!['carbs']?.round() ?? 0}', 'g'),
              _buildNutrientInfo('Fat', 
                '${_nutritionData!['fat']?.round() ?? 0}', 'g'),
            ],
          ),
          if (_nutritionData!['data_source'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Source: ${_nutritionData!['data_source']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}