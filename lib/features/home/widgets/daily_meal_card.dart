import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/tracking/screens/meal_history_page.dart';

class DailyGoalsCard extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onTap;
  final bool isCompact;
  
  const DailyGoalsCard({
    Key? key,
    required this.userProfile,
    this.onTap,
    this.isCompact = false,
  }) : super(key: key);
  
  @override
  State<DailyGoalsCard> createState() => _DailyGoalsCardState();
}

class _DailyGoalsCardState extends State<DailyGoalsCard> {
  late double _dailyCalorieGoal;
  late Map<String, double> _macroGoals;
  late double _userTdee;
  late String _weightGoal;
  late double _currentWeight;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateDailyGoals();
  }
  
  @override
  void didUpdateWidget(DailyGoalsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _loadUserData();
      _calculateDailyGoals();
    }
  }
  
  void _loadUserData() {
    // Get ACTUAL user data from profile
    print('Loading user data...');
    print('User Profile: ${widget.userProfile.toMap()}');
    
    // Get TDEE from user's actual calculated value
    if (widget.userProfile.formData != null) {
      _userTdee = widget.userProfile.tdee ?? 2000.0;
    }
    
    // Get user's actual weight goal
    _weightGoal = widget.userProfile.primaryGoal ?? 'maintain_weight';
    
    // Get user's current weight
    _currentWeight = widget.userProfile.weight?.toDouble() ?? 
                     widget.userProfile.weight ?? 70.0;
    
    print('User TDEE: $_userTdee');
    print('Weight Goal: $_weightGoal');
    print('Current Weight: $_currentWeight');
  }
  
  void _calculateDailyGoals() {
    try {
      // Use the actual user's TDEE
      final tdee = _userTdee;
      
      // Calculate daily calorie goal based on user's actual goal
      switch (_weightGoal.toLowerCase()) {
        case 'lose_weight':
        case 'lose weight':
        case 'weight_loss':
        case 'fat_loss':
          // 18% deficit for weight loss
          _dailyCalorieGoal = tdee * 0.82;
          break;
        case 'gain_weight':
        case 'gain weight':
        case 'muscle_gain':
        case 'build_muscle':
        case 'weight_gain':
          // 12% surplus for muscle gain
          _dailyCalorieGoal = tdee * 1.12;
          break;
        case 'maintain_weight':
        case 'maintain':
        case 'maintenance':
        default:
          // Maintenance calories
          _dailyCalorieGoal = tdee;
      }
      
      // Calculate macro goals based on user's goal and weight
      _calculateMacroGoals();
      
      print('Daily Calorie Goal: $_dailyCalorieGoal');
      print('Macros: $_macroGoals');
      
    } catch (e) {
      print('Error calculating goals: $e');
      // Fallback to TDEE if calculation fails
      _dailyCalorieGoal = _userTdee;
      _calculateMacroGoals();
    }
  }
  
  void _calculateMacroGoals() {
    try {
      // Adjust macros based on user's actual goal and body weight
      double proteinPerKg;
      double proteinPercent;
      double carbPercent;
      double fatPercent;
      
      if (_weightGoal.toLowerCase().contains('lose') || 
          _weightGoal.toLowerCase().contains('fat')) {
        // Higher protein for weight loss to preserve muscle
        proteinPerKg = 2.0; // 2g per kg body weight
        proteinPercent = 0.30;
        carbPercent = 0.35;
        fatPercent = 0.35;
      } else if (_weightGoal.toLowerCase().contains('gain') || 
                 _weightGoal.toLowerCase().contains('muscle') ||
                 _weightGoal.toLowerCase().contains('build')) {
        // Moderate protein, higher carbs for muscle gain
        proteinPerKg = 1.8; // 1.8g per kg body weight
        proteinPercent = 0.25;
        carbPercent = 0.50;
        fatPercent = 0.25;
      } else {
        // Balanced for maintenance
        proteinPerKg = 1.5; // 1.5g per kg body weight
        proteinPercent = 0.25;
        carbPercent = 0.45;
        fatPercent = 0.30;
      }
      
      // Calculate protein based on body weight first
      final proteinGrams = _currentWeight * proteinPerKg;
      final proteinCalories = proteinGrams * 4;
      
      // If protein from body weight calculation is more than percentage, use that
      final proteinFromPercent = (_dailyCalorieGoal * proteinPercent) / 4;
      final finalProteinGrams = proteinGrams > proteinFromPercent ? proteinGrams : proteinFromPercent;
      
      // Adjust other macros accordingly
      final remainingCalories = _dailyCalorieGoal - (finalProteinGrams * 4);
      
      // Split remaining calories between carbs and fats
      double carbGrams;
      double fatGrams;
      
      if (_weightGoal.toLowerCase().contains('gain') || 
          _weightGoal.toLowerCase().contains('muscle')) {
        // 65% of remaining calories from carbs, 35% from fat
        carbGrams = (remainingCalories * 0.65) / 4;
        fatGrams = (remainingCalories * 0.35) / 9;
      } else if (_weightGoal.toLowerCase().contains('lose')) {
        // 50% of remaining calories from carbs, 50% from fat
        carbGrams = (remainingCalories * 0.50) / 4;
        fatGrams = (remainingCalories * 0.50) / 9;
      } else {
        // 60% of remaining calories from carbs, 40% from fat
        carbGrams = (remainingCalories * 0.60) / 4;
        fatGrams = (remainingCalories * 0.40) / 9;
      }
      
      _macroGoals = {
        'protein': finalProteinGrams,
        'carbs': carbGrams,
        'fat': fatGrams,
      };
      
    } catch (e) {
      print('Error calculating macros: $e');
      // Fallback to percentage-based calculation
      final proteinCalories = _dailyCalorieGoal * 0.25;
      final carbCalories = _dailyCalorieGoal * 0.50;
      final fatCalories = _dailyCalorieGoal * 0.25;
      
      _macroGoals = {
        'protein': proteinCalories / 4,
        'carbs': carbCalories / 4,
        'fat': fatCalories / 9,
      };
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(_weightGoal),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Top Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 20,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getGoalDescription(_weightGoal),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getGoalLabel(_weightGoal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Calorie Display with User's Actual Data
                  Column(
                    children: [
                      Text(
                        'Daily Calorie Target',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_dailyCalorieGoal.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TDEE: ${_userTdee.round()} kcal',
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
            
            // Macro Section with User's Personalized Targets
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MACRO TARGETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Based on ${_currentWeight.round()}kg body weight',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Macro Cards with User's Actual Targets
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroCard(
                          'Protein',
                          _macroGoals['protein']?.round() ?? 0,
                          const Color(0xFF4A90E2),
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMacroCard(
                          'Carbs',
                          _macroGoals['carbs']?.round() ?? 0,
                          const Color(0xFFF5A623),
                          Icons.grain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMacroCard(
                          'Fats',
                          _macroGoals['fat']?.round() ?? 0,
                          const Color(0xFF9B59B6),
                          Icons.water_drop,
                        ),
                      ),
                    ],
                  ),
                  
                  // Info Section
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getDetailedInfo(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        // Log Meals button (expanded)
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: widget.onTap,
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text(
                              'Log Your Meals',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _getGradientColors(_weightGoal)[0],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // History button (compact)
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              foregroundColor: _getGradientColors(_weightGoal)[0],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.history, size: 18),
                                SizedBox(width: 4),
                                Text('History', style: TextStyle(fontSize: 12)),
                              ],
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
      ),
    );
  }
  
  Widget _buildMacroCard(String label, int grams, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
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
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDetailedInfo() {
    final deficit = _userTdee - _dailyCalorieGoal;
    if (deficit > 0) {
      return 'Daily deficit of ${deficit.round()} kcal for sustainable fat loss';
    } else if (deficit < 0) {
      return 'Daily surplus of ${(-deficit).round()} kcal to support muscle growth';
    }
    return 'Maintaining current weight with balanced nutrition';
  }
  
  // Helper methods
  List<Color> _getGradientColors(String goal) {
    if (goal.toLowerCase().contains('lose') || 
        goal.toLowerCase().contains('fat')) {
      return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
    } else if (goal.toLowerCase().contains('gain') || 
               goal.toLowerCase().contains('muscle') ||
               goal.toLowerCase().contains('build')) {
      return [const Color(0xFF4FACFE), const Color(0xFF00F2FE)];
    }
    return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
  }
  
  String _getGoalDescription(String goal) {
    if (goal.toLowerCase().contains('lose')) {
      return 'Deficit for fat loss (~0.5-0.7 kg/week)';
    } else if (goal.toLowerCase().contains('gain') || 
               goal.toLowerCase().contains('muscle')) {
      return 'Surplus for muscle gain (~0.3-0.5 kg/week)';
    }
    return 'Maintains current weight';
  }
  
  String _getGoalLabel(String goal) {
    if (goal.toLowerCase().contains('lose') || 
        goal.toLowerCase().contains('fat')) return 'Fat Loss';
    if (goal.toLowerCase().contains('gain') || 
        goal.toLowerCase().contains('muscle') ||
        goal.toLowerCase().contains('build')) return 'Muscle Gain';
    return 'Maintenance';
  }
}