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
  final _targetWeightController = TextEditingController();
  double _currentWeight = 0;

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

  @override
  void initState() {
    super.initState();
    _selectedWeightGoal = widget.formData['weightGoal'] ?? '';
    _currentWeight = widget.formData['weight'] ?? 0.0;
    _targetWeightController.text = '';
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  setState(() {
                    _selectedWeightGoal = goal['title'];
                  });
                  widget.onDataChanged('weightGoal', goal['title']);
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
          
          // Target weight
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
            decoration: const InputDecoration(
              hintText: 'Enter your target weight',
              prefixIcon: Icon(Icons.flag),
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isNotEmpty) {
                widget.onDataChanged('targetWeight', double.parse(value));
              }
            },
          ),
        ],
      ),
    );
  }
}