// lib/features/onboarding/screens/weight_goal_page.dart
import 'package:flutter/material.dart';

class WeightGoalPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const WeightGoalPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<WeightGoalPage> createState() => _WeightGoalPageState();
}

class _WeightGoalPageState extends State<WeightGoalPage> {
  String _selectedWeightGoal = '';
  String _selectedTimeline = '';
  final _targetWeightController = TextEditingController();
  double _currentWeight = 0;
  String? _weightError;

  final List<Map<String, dynamic>> _weightGoals = [
    {
      'title': 'Lose Weight',
      'description': 'Burn fat and reduce overall weight',
      'icon': Icons.trending_down,
    },
    {
      'title': 'Maintain Weight',
      'description': 'Stay at your current weight',
      'icon': Icons.compare_arrows,
    },
    {
      'title': 'Gain Weight',
      'description': 'Add healthy weight to your frame',
      'icon': Icons.trending_up,
    },
  ];

  // UPDATED: Changed from months to weeks
  final List<Map<String, dynamic>> _timelines = [
    {
      'title': 'Gradual',
      'description': '16-24 weeks',
      'value': '20_weeks', // Backend value
      'weeks': 20, // Average weeks
    },
    {
      'title': 'Moderate', 
      'description': '8-16 weeks',
      'value': '12_weeks', // Backend value
      'weeks': 12, // Average weeks
    },
    {
      'title': 'Ambitious',
      'description': '4-8 weeks',
      'value': '6_weeks', // Backend value
      'weeks': 6, // Average weeks
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeightGoal = widget.formData['weightGoal'] ?? '';
    _currentWeight = widget.formData['weight'] ?? 0.0;
    _selectedTimeline = widget.formData['goalTimeline'] ?? '';
    
    // If target weight is already set, use it
    if (widget.formData['targetWeight'] != null) {
      _targetWeightController.text = widget.formData['targetWeight'].toString();
    } else if (_selectedWeightGoal == 'Maintain Weight') {
      // For maintain weight, set target same as current
      _targetWeightController.text = _currentWeight.toString();
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  // Validate the target weight based on the selected goal
  bool _validateTargetWeight(String value) {
    if (value.isEmpty) {
      setState(() {
        _weightError = 'Please enter a target weight';
      });
      return false;
    }

    double? targetWeight = double.tryParse(value);
    if (targetWeight == null) {
      setState(() {
        _weightError = 'Please enter a valid number';
      });
      return false;
    }

    // Validation based on goal
    if (_selectedWeightGoal == 'Lose Weight' && targetWeight >= _currentWeight) {
      setState(() {
        _weightError = 'Target weight should be less than current weight';
      });
      return false;
    } else if (_selectedWeightGoal == 'Gain Weight' && targetWeight <= _currentWeight) {
      setState(() {
        _weightError = 'Target weight should be more than current weight';
      });
      return false;
    }

    setState(() {
      _weightError = null;
    });
    return true;
  }

  // Calculate recommended timeline based on weight difference
  String _getRecommendedTimeline() {
    if (_targetWeightController.text.isEmpty || _selectedWeightGoal.isEmpty) {
      return '';
    }

    double? targetWeight = double.tryParse(_targetWeightController.text);
    if (targetWeight == null) return '';

    double weightDifference = (_currentWeight - targetWeight).abs();
    
    // Safe weight change: 0.5-1 kg per week
    // Calculate weeks needed
    int weeksNeeded = (weightDifference / 0.75).round(); // Using 0.75kg/week as average
    
    if (weeksNeeded <= 8) {
      return 'Ambitious (4-8 weeks) - Recommended for ${weightDifference.toStringAsFixed(1)}kg change';
    } else if (weeksNeeded <= 16) {
      return 'Moderate (8-16 weeks) - Recommended for ${weightDifference.toStringAsFixed(1)}kg change';
    } else {
      return 'Gradual (16-24 weeks) - Recommended for ${weightDifference.toStringAsFixed(1)}kg change';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate weight difference for display
    double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;
    double weightDifference = (targetWeight - _currentWeight).abs();
    bool shouldShowWeightDifference = 
        _selectedWeightGoal.isNotEmpty && 
        _selectedWeightGoal != 'Maintain Weight' &&
        _targetWeightController.text.isNotEmpty &&
        _weightError == null;
    
    String actionText = _selectedWeightGoal == 'Lose Weight' ? 'Lose' : 'Gain';
    Color buttonColor = _selectedWeightGoal == 'Lose Weight' 
        ? Colors.red 
        : (_selectedWeightGoal == 'Gain Weight' ? Colors.green : Colors.blue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your weight goal?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current weight: ${_currentWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Weight goal selection
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _weightGoals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final goal = _weightGoals[index];
              final isSelected = _selectedWeightGoal == goal['title'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWeightGoal = goal['title'];
                    
                    // Set target weight to current if maintaining
                    if (goal['title'] == 'Maintain Weight') {
                      _targetWeightController.text = _currentWeight.toString();
                    }
                  });

                  // Save to form data with correct key format
                  String weightGoalKey = '';
                  switch (goal['title']) {
                    case 'Lose Weight':
                      weightGoalKey = 'lose_weight';
                      break;
                    case 'Gain Weight':
                      weightGoalKey = 'gain_weight';
                      break;
                    case 'Maintain Weight':
                      weightGoalKey = 'maintain_weight';
                      break;
                  }
                  
                  // Save to form data
                  widget.onDataChanged('weightGoal', weightGoalKey);
                  
                  // Validate if target weight is already entered
                  if (_targetWeightController.text.isNotEmpty) {
                    _validateTargetWeight(_targetWeightController.text);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        goal['icon'],
                        size: 30,
                        color: isSelected ? Colors.blue : Colors.grey[600],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Target weight input (show only if a weight goal is selected)
          if (_selectedWeightGoal.isNotEmpty && _selectedWeightGoal != 'Maintain Weight')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'What\'s your target weight?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target weight (kg)',
                    hintText: 'Enter your target weight',
                    suffixText: 'kg',
                    errorText: _weightError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (_validateTargetWeight(value)) {
                      widget.onDataChanged('targetWeight', double.tryParse(value) ?? 0);
                    }
                  },
                ),
              ],
            ),
          
          // Weight difference display
          if (shouldShowWeightDifference)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: buttonColor, width: 1),
                ),
                child: Text(
                  '$actionText ${weightDifference.toStringAsFixed(1)} kg',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: buttonColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          
          // Show recommended timeline
          if (shouldShowWeightDifference)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getRecommendedTimeline(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          // Timeline selection (only show if a valid weight goal is set)
          if (_selectedWeightGoal.isNotEmpty && (_selectedWeightGoal != 'Maintain Weight' ? _weightError == null && _targetWeightController.text.isNotEmpty : true))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'How quickly do you want to reach your goal?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a realistic timeline. Healthy weight change is 0.5-1 kg per week.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Timeline options
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _timelines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final timeline = _timelines[index];
                    final isSelected = _selectedTimeline == timeline['value'];
                    
                    // Calculate weekly rate for this timeline
                    double weeklyRate = weightDifference / timeline['weeks'];
                    bool isSafe = weeklyRate <= 1.0; // Max 1kg per week is safe
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeline = timeline['value'];
                        });
                        widget.onDataChanged('goalTimeline', timeline['value']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  timeline['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.blue : Colors.black87,
                                  ),
                                ),
                                if (!isSafe && _selectedWeightGoal == 'Lose Weight')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Aggressive',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeline['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rate: ${weeklyRate.toStringAsFixed(2)} kg/week',
                              style: TextStyle(
                                fontSize: 13,
                                color: isSafe ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}