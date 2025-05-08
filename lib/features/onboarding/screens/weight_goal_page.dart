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

  final List<Map<String, dynamic>> _timelines = [
    {
      'title': 'Gradual',
      'description': '(4-6 months)',
    },
    {
      'title': 'Moderate',
      'description': '(2-4 months)',
    },
    {
      'title': 'Ambitious',
      'description': '(1-2 months)',
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

    if (_selectedWeightGoal == 'Lose Weight' && targetWeight >= _currentWeight) {
      setState(() {
        _weightError = 'Target weight must be less than current weight';
      });
      return false;
    }

    if (_selectedWeightGoal == 'Gain Weight' && targetWeight <= _currentWeight) {
      setState(() {
        _weightError = 'Target weight must be greater than current weight';
      });
      return false;
    }

    if (_selectedWeightGoal == 'Maintain Weight' && targetWeight != _currentWeight) {
      setState(() {
        _targetWeightController.text = _currentWeight.toString();
      });
      widget.onDataChanged('targetWeight', _currentWeight);
    }

    setState(() {
      _weightError = null;
    });
    return true;
  }

  double _calculateWeightDifference() {
    if (_targetWeightController.text.isEmpty) return 0;
    final targetWeight = double.tryParse(_targetWeightController.text) ?? _currentWeight;
    return (_currentWeight - targetWeight).abs();
  }

  void _updateWeightGoal(String goalTitle) {
    setState(() {
      _selectedWeightGoal = goalTitle;
      _weightError = null;
      
      // Reset target weight based on the selected goal
      if (goalTitle == 'Maintain Weight') {
        _targetWeightController.text = _currentWeight.toString();
        widget.onDataChanged('targetWeight', _currentWeight);
      } else {
        // Clear the target weight for other goals, but set a default value
        // instead of null to avoid type errors
        _targetWeightController.text = '';
        // Don't update the form data yet - wait for valid input
      }
    });
    
    widget.onDataChanged('weightGoal', goalTitle);
  }

  @override
  Widget build(BuildContext context) {
    final weightDifference = _calculateWeightDifference();
    final shouldShowWeightDifference = _targetWeightController.text.isNotEmpty && 
        _weightError == null &&
        (_selectedWeightGoal == 'Lose Weight' || _selectedWeightGoal == 'Gain Weight');
    
    final isLosing = _selectedWeightGoal == 'Lose Weight';
    final actionText = isLosing ? 'Lose' : 'Gain';
    final buttonColor = isLosing ? Colors.blue : Colors.green;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your weight goal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your current weight is the starting point for your fitness journey.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Current weight display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_weight,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Weight',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$_currentWeight kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Weight goal selection
          const Text(
            'What\'s your weight goal?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Weight goal cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _weightGoals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final goal = _weightGoals[index];
              final isSelected = _selectedWeightGoal == goal['title'];
              
              return GestureDetector(
                onTap: () => _updateWeightGoal(goal['title']),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        goal['icon'],
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                          Text(
                            goal['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.blue[700] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Target weight (disabled for maintain weight)
          const Text(
            'Target Weight (kg)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _targetWeightController,
            enabled: _selectedWeightGoal != 'Maintain Weight', // Disable for maintain weight
            decoration: InputDecoration(
              hintText: 'Enter your target weight',
              prefixIcon: const Icon(Icons.flag),
              suffixText: 'kg',
              errorText: _weightError,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              if (value.isNotEmpty) {
                try {
                  if (_validateTargetWeight(value)) {
                    final targetWeight = double.parse(value);
                    widget.onDataChanged('targetWeight', targetWeight);
                    setState(() {}); // Refresh to update weight difference
                  }
                } catch (e) {
                  setState(() {
                    _weightError = 'Please enter a valid number';
                  });
                }
              } else {
                setState(() {
                  _weightError = 'Please enter a target weight';
                });
              }
            },
          ),
          
          // Weight difference display
          if (shouldShowWeightDifference)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$actionText ${weightDifference.toStringAsFixed(1)} kg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                const SizedBox(height: 16),
                
                // Timeline options
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _timelines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final timeline = _timelines[index];
                    final isSelected = _selectedTimeline == timeline['title'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeline = timeline['title'];
                        });
                        widget.onDataChanged('goalTimeline', timeline['title']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              timeline['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeline['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
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